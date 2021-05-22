class SunLight < Light
  getter vector : Vector3

  def initialize(vector, color, intensity)
    super(color, intensity, specular_power: 32)
    @vector = vector.normalize
  end

  def vec_to_light(vec : Vector3) : Vector3
    -@vector
  end

  def intensity_at(vec : Vector3) : Float64
    @intensity
  end
end
