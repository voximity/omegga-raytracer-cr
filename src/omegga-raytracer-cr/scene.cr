class Scene
  EPSILON = 0.00001

  def self.lerp(a : Float64, b : Float64, c : Float64) : Float64
    a + (b - a) * c
  end

  def self.remap(x : Float64, fmin : Float64, fmax : Float64, tmin : Float64, tmax : Float64) : Float64
    d = (x - fmin) / (fmax - fmin)
    tmin + (tmax - tmin) * d
  end

  property camera : Camera
  property objects = [] of SceneObject
  property diffuse_coefficient = 1.0
  property ambient_coefficient = 0.6
  property atmosphere_color = Color.new(206, 225, 245)
  property light_vector : Vector3 = -Vector3.new(-0.8, -0.5, -1.0).normalize
  property light_color = Color.new(255, 255, 255)
  property cast_shadows = true
  property shadow_coefficient = 0.6
  property max_reflection_depth = 8
  property render_players = true
  property render_ground_plane = true
  property ground_plane_color = Color.new(92, 148, 84)
  property do_refraction = true
  property stud_texture = true
  property do_fog = true
  property fog_color = Color.new(206, 225, 245)
  property fog_density = 0.00007
  property do_specular = true
  property specular_pow = 32
  property specular_strength = 0.4

  def initialize(@camera)
    # other fields can be changed as they are properties
  end

  def self.refraction_vector(in_ray : Ray, normal : Vector3, from_ior : Float64, to_ior : Float64) : Vector3?
    n = from_ior / to_ior
    cos_i = -normal.dot(-in_ray.direction)
    sin_t2 = n * n * (1.0 - cos_i * cos_i)
    return nil if sin_t2 > 1.0
    cos_t = Math.sqrt(1.0 - sin_t2)
    in_ray.direction * n + normal * (n * cos_i - cos_t)
  end

  def self.refract(in_ray : Ray, hit : Hit, obj : SceneObject, from_ior : Float64, to_ior : Float64) : Ray?
    ref_vec = Scene.refraction_vector(in_ray, hit.normal, from_ior, to_ior)
    hitp_out = in_ray.point_along(hit.near - EPSILON)
    hitp_in = in_ray.point_along(hit.near + EPSILON)
    return Ray.new(in_ray.point_along(hit.far + EPSILON), in_ray.direction) if ref_vec.nil?
    internal_ray = Ray.new(hitp_in, ref_vec)
    internal_hit = obj.internal_raycast(Ray.new(hitp_out, ref_vec))
    return Ray.new(in_ray.point_along(hit.far + EPSILON), in_ray.direction) if internal_hit.nil?
    out_ref_vec = Scene.refraction_vector(Ray.new(hitp_in, ref_vec), -internal_hit[:normal], to_ior, from_ior)
    hitp2 = internal_ray.point_along(internal_hit[:t])
    return Ray.new(in_ray.point_along(hit.far + EPSILON), in_ray.direction) if out_ref_vec.nil?
    Ray.new(hitp2, out_ref_vec)
  end

  def self.reflect(incidence : Vector3, normal : Vector3) : Vector3
    incidence - normal * (2 * incidence.dot(normal))
  end

  def populate_scene(save : BRS::Save, omegga : RPCClient)
    @objects = [] of SceneObject

    save.bricks.each do |brick|
      pos = brick.position.to_v3
      dir = brick.direction.value
      rot = brick.rotation.value % 2
      nsx = 0
      nsy = 0
      nsz = 0

      if dir == 0 || dir == 1
        nsx = brick.size.z
        nsy = rot == 0 ? brick.size.y : brick.size.x
        nsz = rot == 0 ? brick.size.x : brick.size.y
      elsif dir == 2 || dir == 3
        nsx = rot == 0 ? brick.size.y : brick.size.x
        nsy = brick.size.z
        nsz = rot == 0 ? brick.size.x : brick.size.y
      elsif dir == 4 || dir == 5
        nsx = rot == 0 ? brick.size.x : brick.size.y
        nsy = rot == 0 ? brick.size.y : brick.size.x
        nsz = brick.size.z
      end

      size = Vector3.new(nsx, nsy, nsz)
      color = brick.color.is_a?(Int32) ? Color.new(save.colors[brick.color.as(Int32)]) : Color.new(brick.color.as(Array(UInt8)))
      
      material = save.materials[brick.material_index]
      reflectiveness = material == "BMC_Metallic" ? 0.4 : 0.0
      transparency = material == "BMC_Glass" ? 1.0 - (brick.material_intensity / 10.0) : 0.0
      asset_name = save.brick_assets[brick.asset_name_index]

      if asset_name == "PB_DefaultStudded" && (nsx != nsy || nsy != nsz)
        asset_name = "PB_DefaultBrick"
      end

      case asset_name
      when "PB_DefaultBrick", "PB_DefaultMicroBrick", "PB_DefaultTile", "PB_DefaultSmoothTile"
        @objects << AxisAlignedBoxObject.new(
          pos, size, color,
          reflectiveness: reflectiveness,
          transparency: transparency
        )
      when "PB_DefaultStudded"
        @objects << SphereObject.new(
          pos, Math.max(size.x, Math.max(size.y, size.z)), color,
          reflectiveness: reflectiveness,
          transparency: transparency
        )
      when "PB_DefaultMicroWedge"
        @objects << WedgeObject.new(
          WedgeObject.wedge_verts, Matrix.from_brick_orientation(pos, brick.direction, brick.rotation), brick.size.to_v3, color,
          reflectiveness: reflectiveness,
          transparency: transparency
        )
      when "PB_DefaultMicroWedgeTriangleCorner"
        @objects << WedgeObject.new(
          WedgeObject.wedge_triangle_verts, Matrix.from_brick_orientation(pos, brick.direction, brick.rotation), brick.size.to_v3, color,
          reflectiveness: reflectiveness,
          transparency: transparency
        )
      when "PB_DefaultMicroWedgeOuterCorner"
        @objects << WedgeObject.new(
          WedgeObject.wedge_outer_verts, Matrix.from_brick_orientation(pos, brick.direction, brick.rotation), brick.size.to_v3, color,
          reflectiveness: reflectiveness,
          transparency: transparency
        )
      when "PB_DefaultMicroWedgeInnerCorner"
        @objects << WedgeObject.new(
          WedgeObject.wedge_inner_verts, Matrix.from_brick_orientation(pos, brick.direction, brick.rotation), brick.size.to_v3, color,
          reflectiveness: reflectiveness,
          transparency: transparency
        )
      when "PB_DefaultMicroWedgeCorner"
        @objects << WedgeObject.new(
          WedgeObject.wedge_corner_verts, Matrix.from_brick_orientation(pos, brick.direction, brick.rotation), brick.size.to_v3, color,
          reflectiveness: reflectiveness,
          transparency: transparency
        )
      else
        omegga.broadcast asset_name
      end
    end

    # todo: rendering players

    @objects << PlaneObject.new(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1), @ground_plane_color.linear, render_texture: @stud_texture) if @render_ground_plane
  end

  def cast_ray(ray : Ray, objs : Array(SceneObject)) : NamedTuple(object: SceneObject, hit: Hit)?
    intersected = [] of NamedTuple(object: SceneObject, hit: Hit)
    objs.each do |obj|
      res = obj.intersection_with_ray(ray)
      intersected << {object: obj, hit: res} unless res.nil?
    end

    return nil if intersected.size == 0
    return intersected[0] if intersected.size == 1
    intersected.sort { |a, b| a[:hit].near <=> b[:hit].near }[0]
  end

  def get_ray_color(ray : Ray, reflection_depth : Int32 = 0) : Color
    hit = cast_ray(ray, @objects)
    return @atmosphere_color if hit.nil?

    color = hit[:object].color.srgb

    unless @do_specular
      coeff = Scene.lerp(@diffuse_coefficient, @ambient_coefficient, Math.min(@light_vector.angle_between(hit[:hit].normal) / Math::PI * 0.5, 1.0))
      color = hit[:object].color.srgb * coeff
    end

    # phong lighting
    if @do_specular
      colv = color.to_v3
      lightv = @light_color.to_v3

      ambient = lightv * @ambient_coefficient
      diff = Math.max(hit[:hit].normal.dot(@light_vector), 0.0)

      view_dir = ray.direction
      reflect_dir = Scene.reflect(@light_vector, hit[:hit].normal)
      spec = Math.max(view_dir.dot(reflect_dir), 0.0) ** @specular_pow

      if @cast_shadows
        shadow_ray = Ray.new(ray.point_along(hit[:hit].near) + (hit[:hit].normal * 0.01), @light_vector)
        shadow_hit = cast_ray(shadow_ray, @objects)
        unless shadow_hit.nil?
          sd_amount = Scene.remap(shadow_hit[:object].transparency, 0, 1, @shadow_coefficient, 1)
          spec *= sd_amount
          diff *= sd_amount
        end
      end

      diffuse = lightv * diff
      specular = lightv * (spec * @specular_strength)
      final = colv * (ambient + diffuse + specular)

      color = Color.new((ambient + diffuse + specular) * colv)
    end

    # refraction calculation (IOR for transparent materials is assumed to be 1.45)
    if hit[:object].transparency > 0.1 && hit[:object].reflectiveness < 0.1
      unless @do_refraction
        continuing = Ray.new(ray.point_along(hit[:hit].far + 0.01), ray.direction)
        continuing_color = get_ray_color(continuing, reflection_depth)
        color = color.lerp(continuing_color, hit[:object].transparency)
      else
        to_ior = 1.33
        from_ior = 1.0
        ray_out = Scene.refract(ray, hit[:hit], hit[:object], from_ior, to_ior)
        unless ray_out.nil?
          reflection_ray = Ray.new(ray.point_along(hit[:hit].near) + (hit[:hit].normal * EPSILON), ray.direction - (hit[:hit].normal * (2 * ray.direction.dot(hit[:hit].normal))))
          reflection_hit_color = get_ray_color(reflection_ray, reflection_depth + 1)

          # calculate how much of both we want
          # 0 is full refraction
          # 1 is full reflection
          rr_amount = (-ray.direction).angle_between(hit[:hit].normal) / (Math::PI * 0.45)
          rr_amount = Scene.remap(rr_amount * rr_amount, 0.0, 1.0, 0.2, 1.0)

          continuing_color = get_ray_color(ray_out, reflection_depth)
          #color = color.lerp(continuing_color, lerp(hit[:object].transparency)
          mixed_color = continuing_color.lerp(reflection_hit_color, rr_amount.clamp(0.0, 1.0))
          color = color.lerp(mixed_color, hit[:object].transparency)
        end
      end
    end

    # reflection calculation
    if reflection_depth < @max_reflection_depth && hit[:object].reflectiveness > 0.1
      reflection_ray = Ray.new(ray.point_along(hit[:hit].near) + (hit[:hit].normal * 0.01), ray.direction - (hit[:hit].normal * (2 * ray.direction.dot(hit[:hit].normal))))
      reflection_hit_color = get_ray_color(reflection_ray, reflection_depth + 1)
      color = color.lerp(reflection_hit_color, hit[:object].reflectiveness)
    end

    # fog
    if do_fog
      fog_amount = hit[:hit].near * fog_density
      color = color.lerp(fog_color, Math.min(1.0, fog_amount))
    end

    color
  end

  def render : Array(Array(Color))
    img = [] of Array(Color)
    @camera.vh.times do |y|
      img << [] of Color
      @camera.vw.times do |x|
        ray = Ray.new(@camera.origin, @camera.direction_for_screen_point(x.to_f64, y.to_f64))
        img[y] << get_ray_color(ray)
      end
    end
    img
  end
end
