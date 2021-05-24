module Raytracer
  abstract class SceneObject
    getter material : Material

    def initialize(@material)
    end

    # Intersection of ray with this object.
    abstract def intersection_with_ray(ray : Ray) : Hit?
    
    # Cast a ray, returning the far hit.
    abstract def internal_raycast(ray : Ray) : NamedTuple(t: Float64, normal: Vector3)?
  end
end
