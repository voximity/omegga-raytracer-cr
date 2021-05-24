module Raytracer
  struct Hit
    property near : Float64
    property far : Float64
    property normal : Vector3

    def initialize(@near, @far, @normal)
    end

    def pos(ray : Ray)
      ray.point_along(near)
    end
  end
end
