module Raytracer
  class AreaLight < PositionLight
    getter size : Vector3
    getter accuracy : Int32

    def initialize(position, @size, color, intensity, @accuracy = 4)
      super(position, color, intensity)
    end

    def sample_on_surface(point : Vector3)
      # for testing purposes, we assume the normal of the area light is the Z axis
      rx = Random.rand * 2.0 - 1.0
      ry = Random.rand * 2.0 - 1.0
      @position + Vector3.new(rx * size.x, ry * size.y, point.z > position.z ? size.z : -size.z)
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

      # calculate shadowing
      total_in_shadow = 0
      total_transparency = 0
      accuracy.times do
        sample_point = sample_on_surface(hit_pos)
        shadow_ray = Ray.new(hit_pos + hit.normal * 0.00001, (sample_point - hit_pos).normalize)
        shadow_hit = shadow_test.call(shadow_ray)
        unless shadow_hit.nil?
          if shadow_hit[:hit].near <= (sample_point - hit_pos).magnitude
            total_in_shadow += 1
            total_transparency += shadow_hit[:object].material.transparency
          end
        end
      end

      # calculate intensity
      lint = @intensity / (dist / 100.0) ** 2

      # apply shadowing
      shadow_amount = total_in_shadow / accuracy
      if shadow_amount > 0
        sd_amount = Scene.lerp(1, total_transparency / total_in_shadow, shadow_amount)
        diffuse *= sd_amount
        specular *= sd_amount
        lint *= sd_amount
      end

      LightShading.new(diffuse, specular, lint)
    end
  end
end