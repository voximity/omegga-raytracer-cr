module Raytracer
  class PointLight < PositionLight
    def initialize(position, color, intensity, shadow_coefficient = 0.0)
      super(position, color, intensity, shadow_coefficient: shadow_coefficient)
    end

    def shading(ray : Ray, hit : Hit, &shadow_test : Ray -> NamedTuple(object: SceneObject, hit: Hit)?) : LightShading
      hit_pos = ray.point_along(hit.near)
      diff = @position - hit_pos
      lvec = diff.normalize
      dist = diff.magnitude
      
      # calculate diffuse
      diffuse = Math.max(hit.normal.dot(lvec), 0.0)

      # calculate specular (blinn-phong)
      halfway_dir = (lvec - ray.direction).normalize
      specular = Math.max(0.0, hit.normal.dot(halfway_dir)) ** @specular_power

      # apply shadowing
      shadow_ray = Ray.new(hit_pos + hit.normal * 0.00001, lvec)
      shadow_hit = shadow_test.call(shadow_ray)
      unless shadow_hit.nil?
        if shadow_hit[:hit].near <= dist
          sd_amount = Scene.remap(shadow_hit[:object].material.transparency, 0, 1, @shadow_coefficient, 1)
          diffuse *= sd_amount
          specular *= sd_amount
        end
      end

      # calculate intensity
      lint = @intensity / (dist / 100.0) ** 2

      LightShading.new(diffuse, specular, lint)
    end
  end
end