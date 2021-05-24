module Raytracer
  class SunLight < Light
    getter vector : Vector3
    getter shadow_coefficient : Float64

    def initialize(vector, color, intensity, shadow_coefficient = 0.4)
      super(color, intensity, specular_power: 32)
      @shadow_coefficient = shadow_coefficient
      @vector = vector.normalize
    end

    def shading(ray : Ray, hit : Hit, &shadow_test : Ray -> NamedTuple(object: SceneObject, hit: Hit)?) : LightShading
      lvec = -@vector
      
      # calculate diffuse
      diffuse = Math.max(hit.normal.dot(lvec), 0.0)

      # calculate specular (blinn-phong)
      halfway_dir = (lvec - ray.direction).normalize
      specular = Math.max(0.0, hit.normal.dot(halfway_dir)) ** @specular_power

      # apply shadowing
      hit_pos = ray.point_along(hit.near)
      shadow_ray = Ray.new(hit_pos + hit.normal * 0.00001, lvec)
      shadow_hit = shadow_test.call(shadow_ray)
      unless shadow_hit.nil?
        sd_amount = Scene.remap(shadow_hit[:object].material.transparency, 0, 1, @shadow_coefficient, 1)
        diffuse *= sd_amount
        specular *= sd_amount
      end

      LightShading.new(diffuse, specular, @intensity)
    end
  end
end
