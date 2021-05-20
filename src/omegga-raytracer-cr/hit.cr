struct Hit
  getter near : Float64
  getter far : Float64
  getter normal : Vector3

  def initialize(@near, @far, @normal)
  end

  def pos(ray : Ray)
    ray.point_along(near)
  end
end
