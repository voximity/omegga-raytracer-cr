module Raytracer
  class FuzzTexture < Texture
    getter intensity

    def initialize(@intensity : Float64 = 0.1)
    end

    def random_unit : Vector3
      Vector3.new(Random.rand * 2.0 - 1.0, Random.rand * 2.0 - 1.0, Random.rand * 2.0 - 1.0).normalize
    end

    def normal_for(base_normal : Vector3, hit_pos : Vector3, ray_origin : Vector3) : Vector3
      base_normal + random_unit * @intensity
    end
  end
end
