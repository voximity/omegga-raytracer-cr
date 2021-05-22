abstract class Light
  getter color : Color
  getter intensity : Float64
  getter specular_power : Int32
  getter specular_strength : Float64

  def initialize(@color, @intensity, @specular_power = 64, @specular_strength = 0.5)
  end

  abstract def vec_to_light(point : Vector3) : Vector3
  abstract def intensity_at(point : Vector3) : Float64
end

abstract class PositionLight < Light
  getter position : Vector3

  def initialize(@position, color, intensity, specular_power = 64, specular_strength = 0.5)
    super(color, intensity, specular_power, specular_strength)
  end

  def vec_to_light(point : Vector3) : Vector3
    (@position - point).normalize
  end
end
