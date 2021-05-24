module Raytracer
  abstract class Texture
    abstract def normal_for(base_normal : Vector3, hit_pos : Vector3, ray_origin : Vector3) : Vector3
  end
end
