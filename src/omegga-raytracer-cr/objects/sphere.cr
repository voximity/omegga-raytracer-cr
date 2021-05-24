module Raytracer
  class SphereObject < SceneObject
    getter pos : Vector3
    getter radius : Float64

    def initialize(@pos, @radius, material)
      super(material)
    end

    def intersection_with_ray(ray : Ray) : Hit?
      rad2 = @radius * @radius
      l = @pos - ray.origin
      t2 = l.dot(ray.direction)
      return nil if t2 < 0

      d2 = l.dot(l) - t2 * t2
      return nil if d2 > rad2

      t3 = Math.sqrt(rad2 - d2)
      t0 = t2 - t3
      t1 = t2 + t3
      
      Hit.new(t0, t1, (ray.point_along(t0) - @pos).normalize)
    end

    def internal_raycast(ray : Ray) : NamedTuple(t: Float64, normal: Vector3)?
      hit = intersection_with_ray(ray)
      return nil if hit.nil?

      {t: hit.far, normal: (ray.point_along(hit.far) - @pos).normalize}
    end
  end
end
