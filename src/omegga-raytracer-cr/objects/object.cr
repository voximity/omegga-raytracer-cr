abstract class SceneObject
  getter color : Color
  getter reflectiveness : Float64
  getter transparency : Float64

  def initialize(@color, @reflectiveness = 0.0, @transparency = 0.0)
  end

  abstract def intersection_with_ray(ray : Ray) : Hit?
end
