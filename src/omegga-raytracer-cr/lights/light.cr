module Raytracer
  struct LightShading
    getter diffuse : Float64
    getter specular : Float64
    getter intensity : Float64

    def initialize(@diffuse, @specular, @intensity)
    end
  end

  abstract class Light
    getter color : Color
    getter intensity : Float64
    getter specular_power : Int32
    getter specular_strength : Float64

    def initialize(@color, @intensity, @specular_power = 64, @specular_strength = 0.5, @shadow_coefficient = 0.0)
    end

    abstract def shading(ray : Ray, hit : Hit, &shadow_test : Ray -> NamedTuple(object: SceneObject, hit: Hit)?) : LightShading
  end

  abstract class PositionLight < Light
    getter position : Vector3
    getter max_distance : Float64

    def initialize(@position, color, intensity, specular_power = 64, specular_strength = 0.5, @max_distance = 800.0, shadow_coefficient = 0.0)
      super(color, intensity, specular_power, specular_strength, shadow_coefficient)
    end
  end
end
