class StudTexture < Texture
  MAX_TEXTURE_DISTANCE = 2500.0

  getter plane_pos
  getter intensity

  def initialize(@plane_pos : Vector3, @intensity : Float64 = 0.3)
  end

  def normal_for(base_normal : Vector3, hit_pos : Vector3, ray_origin : Vector3) : Vector3
    hpd = hit_pos - @plane_pos
    xvec = Vector3.new(1, 0, 0)
    yvec = Vector3.new(0, 1, 0)

    if base_normal ==Vector3.new(0, 0, 1)
      # z+: up
      # defaults are fine
    elsif base_normal ==Vector3.new(0, 0, -1)
      # z-: down
      xvec = Vector3.new(-1, 0, 0)
      yvec = Vector3.new(0, -1, 0)
    elsif base_normal ==Vector3.new(1, 0, 0)
      # x+: forward
      xvec = Vector3.new(0, 1, 0)
      yvec = Vector3.new(0, 0, 1)
    elsif base_normal ==Vector3.new(-1, 0, 0)
      # x-: backward
      xvec = Vector3.new(0, -1, 0)
      yvec = Vector3.new(0, 0, 1)
    elsif base_normal ==Vector3.new(0, 1, 0)
      # y+: right
      xvec = Vector3.new(1, 0, 0)
      yvec = Vector3.new(0, 0, 1)
    elsif base_normal ==Vector3.new(0, -1, 0)
      # y-: left
      xvec = Vector3.new(-1, 0, 0)
      yvec = Vector3.new(0, 0, 1)
    end

    xo = (hpd * xvec).magnitude % 10.0 - 5.0
    yo = (hpd * yvec).magnitude % 10.0 - 5.0
    xoa = xo.abs
    yoa = yo.abs
    mid_range = (-2.5..2.5)
    out_normal = base_normal
    if mid_range.includes?(xo) && mid_range.includes?(yo)
      # base normal is fine
    elsif xoa > yoa && xo > 0.0
      # positive x
      out_normal = (xvec * @intensity + base_normal).normalize
    elsif xoa > yoa && xo < 0.0
      # negative x
      out_normal = (xvec * -@intensity + base_normal).normalize
    elsif xoa < yoa && yo > 0.0
      # positive y
      out_normal = (yvec * @intensity + base_normal).normalize
    elsif xoa < yoa && yo < 0.0
      # negative y
      out_normal = (yvec * -@intensity + base_normal).normalize
    end

    out_normal
  end
end
