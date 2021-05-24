module Raytracer
  class PlaneObject < SceneObject
    getter pos : Vector3
    getter normal : Vector3

    def initialize(@pos, @normal, material)
      super(material)
    end

    def intersection_with_ray(ray : Ray) : Hit?
      denom = @normal.dot(ray.direction)
      if denom.abs > 0.0001
        t = (@pos - ray.origin).dot(@normal) / denom
        return Hit.new(t, t, @normal) if t >= 0
      end
      nil
    end

    def internal_raycast(ray : Ray) : NamedTuple(t: Float64, normal: Vector3)?
      hit = intersection_with_ray(ray)
      return nil if hit.nil?

      {t: hit.far, normal: hit.normal}
    end
  end
end
