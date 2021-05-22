class PlasticTexture < Texture
  getter noise_x
  getter noise_y
  getter noise_z
  getter intensity = 0.12
  getter scale = 1.5

  def initialize
    @noise_x = OpenSimplexNoise.new(0)
    @noise_y = OpenSimplexNoise.new(1)
    @noise_z = OpenSimplexNoise.new(2)
  end

  def normal_for(base_normal : Vector3, hit_pos : Vector3, ray_origin : Vector3) : Vector3
    pos = hit_pos * scale
    nx = @noise_x.generate(pos.x, pos.y, pos.z)
    ny = @noise_y.generate(pos.x, pos.y, pos.z)
    nz = @noise_z.generate(pos.x, pos.y, pos.z)

    base_normal + Vector3.new(nx, ny, nz) * intensity
  end
end
