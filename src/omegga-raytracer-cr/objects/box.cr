class AxisAlignedBoxObject < SceneObject
  getter pos : Vector3
  getter size : Vector3

  def initialize(@pos, @size, color, reflectiveness = 0.0, transparency = 0.0)
    super(color, reflectiveness, transparency)
  end

  def intersection_with_ray(ray : Ray) : Hit?
    ro = ray.origin - @pos
    s = Vector3.new(
      ray.direction.x < 0 ? 1 : -1,
      ray.direction.y < 0 ? 1 : -1,
      ray.direction.z < 0 ? 1 : -1
    )
    t1 = ray.m * (-ro + (s * @size))
    t2 = ray.m * (-ro - (s * @size))
    tn = Math.max(Math.max(t1.x, t1.y), t1.z)
    tf = Math.min(Math.min(t2.x, t2.y), t2.z)
    return nil if tn >= tf || tf < 0
    normal : Vector3
    if t1.x > t1.y && t1.x > t1.z
      normal = Vector3.new(s.x, 0.0, 0.0)
    elsif t1.y > t1.z
      normal = Vector3.new(0.0, s.y, 0.0)
    else
      normal = Vector3.new(0.0, 0.0, s.z)
    end
    Hit.new(tn, tf, normal)
  end
end
