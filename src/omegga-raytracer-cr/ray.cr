module Raytracer
  struct Ray
    getter origin : Vector3
    getter direction : Vector3
    getter m : Vector3

    def initialize(@origin, direction)
      @direction = direction.normalize
      @m = @direction.inverse
    end

    def closest_point(vec : Vector3) : Vector3
      ap = vec - @origin
      ab = @direction
      point_along(ap.dot(ab) / ab.dot(ab))
    end

    def point_along(t : Float64) : Vector3
      @direction * t + @origin
    end
  end
end
