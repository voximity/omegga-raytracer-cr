struct Triangle
  EPSILON = 0.000000001

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
end

# A SceneObject representing a collection of Triangles.
class MeshObject < SceneObject
  getter triangles : Array(Triangle)

  def initialize(@triangles, material)
    super(material)
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

  def internal_raycast(ray : Ray) : NamedTuple(t: Float64, normal: Vector3)?
    # run hits for all of the triangles
    hits = [] of NamedTuple(tri: Triangle, t: Float64)
    triangles.each do |tri|
      t = tri.ray_intersection(ray)
      next if t.nil?

      hits << {tri: tri, t: t}
    end

    # sort the hits by their t
    hits.sort! { |a, b| a[:t] <=> b[:t] }

    # return nil if there was one or zero hits
    return nil if hits.size < 2
    {t: hits[1][:t], normal: hits[1][:tri].normal}
  end
end
