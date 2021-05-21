abstract class SceneObject
  getter color : Color
  getter reflectiveness : Float64
  getter transparency : Float64

  def initialize(@color, @reflectiveness = 0.0, @transparency = 0.0)
  end

  # Intersection of ray with this object.
  abstract def intersection_with_ray(ray : Ray) : Hit?
  
  # Cast a ray, returning the far hit.
  abstract def internal_raycast(ray : Ray) : NamedTuple(t: Float64, normal: Vector3)?
end
