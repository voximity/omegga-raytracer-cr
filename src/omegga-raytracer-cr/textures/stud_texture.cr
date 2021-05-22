class StudTexture < Texture
  MAX_TEXTURE_DISTANCE = 2500.0

  getter plane_pos
  getter plane_norm
  getter intensity

  def initialize(@plane_pos : Vector3, @plane_norm : Vector3, @intensity : Float64 = 0.3)
  end

  def normal_for(base_normal : Vector3, hit_pos : Vector3, ray_origin : Vector3) : Vector3
    hit_in_plane_space = ((hit_pos - @plane_pos) + (Vector3.new(0, 0, 1) - @plane_norm))

    xo = hit_in_plane_space.x % 10.0 - 5.0
    yo = hit_in_plane_space.y % 10.0 - 5.0
    xoa = xo.abs
    yoa = yo.abs

    mid_range = (-2.5..2.5)
    out_normal = Vector3.new(0, 0, 1)
    if mid_range.includes?(xo) && mid_range.includes?(yo)
      out_normal = Vector3.new(0, 0, 1)
    elsif xoa > yoa && xo > 0.0
      # positive x
      out_normal = Vector3.new(@intensity, 0.0, 1.0).normalize
    elsif xoa > yoa && xo < 0.0
      # negative x
      out_normal = Vector3.new(-@intensity, 0.0, 1.0).normalize
    elsif xoa < yoa && yo > 0.0
      # positive y
      out_normal = Vector3.new(0.0, @intensity, 1.0).normalize
    elsif xoa < yoa && yo < 0.0
      # negative y
      out_normal = Vector3.new(0.0, -@intensity, 1.0).normalize
    end

    (out_normal + (base_normal - Vector3.new(0, 0, 1))).normalize.lerp(base_normal, ((hit_pos - ray_origin).magnitude / MAX_TEXTURE_DISTANCE).clamp(0.0..1.0))
  end
end
