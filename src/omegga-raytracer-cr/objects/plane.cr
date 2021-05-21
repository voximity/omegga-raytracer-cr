class PlaneObject < SceneObject
  TEXTURE_INTENSITY = 0.3
  MAX_TEXTURE_DISTANCE = 2500.0

  getter pos : Vector3
  getter normal : Vector3
  getter render_texture : Bool

  def initialize(@pos, @normal, color, @reflectiveness = 0.0, @transparency = 0.0, @render_texture = true)
    super(color, reflectiveness, transparency)
  end

  def stud_texture_normal_raw(hit : Vector3) : Vector3
    xo = hit.x % 10.0 - 5.0
    yo = hit.y % 10.0 - 5.0
    xoa = xo.abs
    yoa = yo.abs

    mid_range = (-2.5..2.5)
    if mid_range.includes?(xo) && mid_range.includes?(yo)
      Vector3.new(0, 0, 1)
    elsif xoa > yoa && xo > 0.0
      # positive x
      Vector3.new(TEXTURE_INTENSITY, 0.0, 1.0).normalize
    elsif xoa > yoa && xo < 0.0
      # negative x
      Vector3.new(-TEXTURE_INTENSITY, 0.0, 1.0).normalize
    elsif xoa < yoa && yo > 0.0
      # positive y
      Vector3.new(0.0, TEXTURE_INTENSITY, 1.0).normalize
    elsif xoa < yoa && yo < 0.0
      # negative y
      Vector3.new(0.0, -TEXTURE_INTENSITY, 1.0).normalize
    else
      @normal
    end
  end

  def stud_texture_normal(ray : Ray, t : Float64) : Vector3
    normal = stud_texture_normal_raw(ray.point_along(t))
    normal.lerp(Vector3.new(0, 0, 1), Math.min(1.0, t / MAX_TEXTURE_DISTANCE))
  end

  def intersection_with_ray(ray : Ray) : Hit?
    denom = @normal.dot(ray.direction)
    if denom.abs > 0.0001
      t = (@pos - ray.origin).dot(@normal) / denom
      return Hit.new(t, t, @render_texture ? stud_texture_normal(ray, t) : @normal) if t >= 0
    end
    nil
  end

  def internal_raycast(ray : Ray) : NamedTuple(t: Float64, normal: Vector3)?
    hit = intersection_with_ray(ray)
    return nil if hit.nil?

    {t: hit.far, normal: hit.normal}
  end
end
