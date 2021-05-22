class FoilTexture < Texture
  getter noise_x
  getter noise_y
  getter noise_z
  getter intensity = 0.06
  getter scale = 0.5

  def initialize
    @noise_x = OpenSimplexNoise.new(0)
    @noise_y = OpenSimplexNoise.new(1)
    @noise_z = OpenSimplexNoise.new(2)
  end

  def normal_for(base_normal : Vector3, hit_pos : Vector3, ray_origin : Vector3) : Vector3
    pos = hit_pos * scale
    pos_oct2 = pos * 1.7

    nx = @noise_x.generate(pos.x, pos.y, pos.z) + @noise_x.generate(pos_oct2.x, pos_oct2.y, pos_oct2.z) * 0.5
    ny = @noise_y.generate(pos.x, pos.y, pos.z) + @noise_y.generate(pos_oct2.x, pos_oct2.y, pos_oct2.z) * 0.5
    nz = @noise_z.generate(pos.x, pos.y, pos.z) + @noise_z.generate(pos_oct2.x, pos_oct2.y, pos_oct2.z) * 0.5

    base_normal + Vector3.new(nx, ny, nz) * intensity
  end
end
