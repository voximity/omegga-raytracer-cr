module Raytracer
  class Material
    property reflectiveness : Float64
    property transparency : Float64
    property ior : Float64
    property emissive : Bool
    property color : Color
    property texture : Texture?

    def initialize(@color, @reflectiveness = 0.0, @transparency = 0.0, @ior = 1.5, @emissive = false, @texture = nil)
    end
  end
end
