class PlaneObject < SceneObject
  getter pos : Vector3
  getter normal : Vector3

  def initialize(@pos, @normal, color, @reflectiveness = 0.0, @transparency = 0.0)
    super(color, reflectiveness, transparency)
  end

  def intersection_with_ray(ray : Ray) : Hit?
    denom = @normal.dot(ray.direction)
    if denom.abs > 0.0001
      t = (@pos - ray.origin).dot(@normal) / denom
      return Hit.new(t, t, @normal) if t >= 0
    end
    nil
  end
end
