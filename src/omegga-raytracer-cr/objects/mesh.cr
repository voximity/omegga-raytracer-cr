struct Triangle
  EPSILON = 0.000001

  getter v0 : Vector3
  getter v1 : Vector3
  getter v2 : Vector3
  getter normal : Vector3

  @edge1 : Vector3
  @edge2 : Vector3

  def initialize(@v0, @v1, @v2)
    @edge1 = @v1 - @v0
    @edge2 = @v2 - @v0
    @normal = @edge1.cross(@edge2).normalize
  end

  def ray_intersection(ray : Ray) : Float64?
    h = ray.direction.cross(@edge2)
    a = @edge1.dot(h)
    return nil if a > -EPSILON && a < EPSILON

    f = 1.0 / a
    s = ray.origin - @v0
    u = f * s.dot(h)
    return nil if u < 0.0 || u > 1.0

    q = s.cross(@edge1)
    v = f * ray.direction.dot(q)
    return nil if v < 0.0 || u + v > 1.0

    t = f * @edge2.dot(q)
    return t if t > EPSILON
    nil
  end

  def ray_intersection_old(ray : Ray) : Float64?
    # step 1: finding P
    ndrd = @normal.dot(ray.direction)
    return nil if ndrd.abs < EPSILON

    # compute d using equation 2
    d = @normal.dot(@v0)

    # compute t
    t = (@normal.dot(ray.origin) + d) / ndrd
    return nil if t < 0

    # compute the intersection point
    p = ray.point_along(t)

    # step 2: inside outside test
    c : Vector3

    # edge 0
    edge0 = @v1 - @v0
    vp0 = p - @v0
    c = edge0.cross(vp0)
    return nil if @normal.dot(c) < 0

    # edge 1
    edge1 = @v2 - @v1
    vp1 = p - @v1
    c = edge1.cross(vp1)
    return nil if @normal.dot(c) < 0

    # edge 2
    edge2 = @v0 - @v2
    vp2 = p - v2
    c = edge2.cross(vp2)
    return nil if @normal.dot(c) < 0

    t
  end
end

# A SceneObject representing a collection of Triangles.
class MeshObject < SceneObject
  getter triangles : Array(Triangle)

  def initialize(@triangles, color, reflectiveness = 0.0, transparency = 0.0)
    super(color, reflectiveness, transparency)
  end

  def intersection_with_ray(ray : Ray) : Hit?
    # run hits for all of the triangles
    hits = [] of NamedTuple(tri: Triangle, t: Float64)
    triangles.each do |tri|
      t = tri.ray_intersection(ray)
      next if t.nil?

      hits << {tri: tri, t: t}
    end

    # sort the hits by their t
    hits.sort! { |a, b| a[:t] <=> b[:t] }

    # return nil if there weren't any hits
    return nil if hits.size == 0

    # return a hit of the only hit if there was just one hit
    return Hit.new(hits[0][:t], hits[0][:t], hits[0][:tri].normal) if hits.size == 1

    # return a hit including the t's of the nearest and next nearest tris (concave shapes should only return the first two hits, any past hits are ignored)
    return Hit.new(hits[0][:t], hits[1][:t], hits[0][:tri].normal)
  end
end
