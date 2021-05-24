module Raytracer
  class Scene
    EPSILON = 0.00001

    def self.lerp(a : Float64, b : Float64, c : Float64) : Float64
      a + (b - a) * c
    end

    def self.remap(x : Float64, fmin : Float64, fmax : Float64, tmin : Float64, tmax : Float64) : Float64
      d = (x - fmin) / (fmax - fmin)
      tmin + (tmax - tmin) * d
    end

    def self.name_value(name : String) : Int32
      value = 0
      name.chars.each_with_index do |char, i|
        cval = char.ord
        rind = name.size - i
        rind = rind - 1 if name.size % 2 == 1
        cval = -cval if rind % 4 >= 2
        value += cval
      end
      value
    end

    def self.player_colors : Array(Color)
      [
        Color.new(196, 40, 28),
        Color.new(13, 105, 172),
        Color.new(39, 70, 45),
        Color.new(107, 50, 124),
        Color.new(218, 133, 65),
        Color.new(245, 205, 48),
        Color.new(232, 186, 200),
        Color.new(245, 205, 48)
      ] of Color
    end

    def self.player_color(name : String) : Color
      arr = Scene.player_colors
      arr[Scene.name_value(name) % arr.size]
    end

    property camera = Camera.new
    property objects = [] of SceneObject
    property lights = [] of Light

    property ambient_coefficient = 0.6
    property skybox : Skybox? = nil
    property light_vector : Vector3 = Vector3.new(-0.6, -0.4, -0.8).normalize
    property light_color = Color.new(255, 255, 255)
    property shadow_coefficient = 0.6
    property max_reflection_depth = 8
    property render_players = false
    property render_ground_plane = true
    property ground_plane_color = Color.new(92, 148, 84)
    property do_refraction = true
    property stud_texture = true
    property do_fog = false
    property fog_color = Color.new(206, 225, 245)
    property fog_density = 0.00007
    property do_sun = true
    property supersampling : Int32 = 1
    property do_progress = true

    getter total_rays_cast = 0

    @omegga : RPCClient

    def initialize(@omegga)
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
      return Ray.new(hitp_in, in_ray.direction) if internal_hit.nil?
      out_ref_vec = Scene.refraction_vector(Ray.new(hitp_in, ref_vec), -internal_hit[:normal], to_ior, from_ior)
      hitp2 = internal_ray.point_along(internal_hit[:t])
      return Ray.new(hitp_in, in_ray.direction) if out_ref_vec.nil?
      Ray.new(hitp2, out_ref_vec)
    end

    def self.reflect(incidence : Vector3, normal : Vector3) : Vector3
      incidence - normal * (2 * incidence.dot(normal))
    end

    def self.random_unit : Vector3
      Vector3.new(Random.rand * 2.0 - 1.0, Random.rand * 2.0 - 1.0, Random.rand * 2.0 - 1.0).normalize
    end

    def self.fuzz_reflect(incidence : Vector3, normal : Vector3, fuzz : Float64) : Vector3
      (Scene.reflect(incidence, normal) + Scene.random_unit * fuzz).normalize
    end

    def self.random_float(range : Range(Float64, Float64)) : Float64
      Random.rand * (range.end - range.begin) + range.begin
    end

    def populate_scene(save : BRS::Save)
      @objects = [] of SceneObject
      @lights = [] of Light
      @lights << SunLight.new(@light_vector, @light_color, 1.0) if @do_sun

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

        color_raw = (brick.color.is_a?(Int32) ? Color.new(save.colors[brick.color.as(Int32)]) : Color.new(brick.color.as(Array(UInt8))))
        color = color_raw.srgb
        asset_name = save.brick_assets[brick.asset_name_index]
        material_name = save.materials[brick.material_index]

        material = Material.new(
          color: color,
          reflectiveness: material_name == "BMC_Metallic" ? (color_raw == Color.new(255, 255, 255) ? 1.0 : 0.4) : 0.0,
          transparency: material_name == "BMC_Glass" ? 1.0 - (brick.material_intensity / 10.0) : 0.0,
          ior: 1.333,
          emissive: material_name == "BMC_Glow"
        )

        brick_matrix = Matrix.from_brick_orientation(pos, brick.direction, brick.rotation)

        up_stud_tex = MixedTexture.new([StudTexture.new(Vector3.new(pos.x - nsx, pos.y - nsy, pos.z - nsz), 0.4)] of Texture) do |normal|
          next 0 if normal == Vector3.from_direction(brick.direction)
        end

        if brick.visibility
          case asset_name
          when "PB_DefaultBrick", "PB_DefaultMicroBrick", "PB_DefaultTile", "PB_DefaultSmoothTile"
            if asset_name == "PB_DefaultBrick"
              material.texture = up_stud_tex
            end

            @objects << AxisAlignedBoxObject.new(pos, size, material)
          when "PB_DefaultStudded"
            if nsx == nsy && nsy == nsz
              @objects << SphereObject.new(pos, Math.max(size.x, Math.max(size.y, size.z)), material) # render as sphere
            else
              material.texture = StudTexture.new(Vector3.new(pos.x - nsx, pos.y - nsy, pos.z - nsz), 0.4)
              @objects << AxisAlignedBoxObject.new(pos, size, material)
            end
          when "PB_DefaultMicroWedge", "PB_DefaultSideWedge"
            @objects << MicroBrickObject.new(MicroBrickObject.wedge_verts, brick_matrix, brick.size.to_v3, material)
          when "PB_DefaultMicroWedgeTriangleCorner"
            @objects << MicroBrickObject.new(MicroBrickObject.wedge_triangle_verts, brick_matrix, brick.size.to_v3, material)
          when "PB_DefaultMicroWedgeOuterCorner"
            @objects << MicroBrickObject.new(MicroBrickObject.wedge_outer_verts, brick_matrix, brick.size.to_v3, material)
          when "PB_DefaultMicroWedgeInnerCorner"
            @objects << MicroBrickObject.new(MicroBrickObject.wedge_inner_verts, brick_matrix, brick.size.to_v3, material)
          when "PB_DefaultMicroWedgeCorner"
            @objects << MicroBrickObject.new(MicroBrickObject.wedge_corner_verts, brick_matrix, brick.size.to_v3, material)
          when "PB_DefaultWedge"
            @objects << WedgeObject.new(brick.size.to_v3, brick_matrix, material, &->WedgeObject.build_wedge_tris(Vector3, Matrix))
          when "PB_DefaultRamp"
            material.texture = up_stud_tex
            @objects << WedgeObject.new(brick.size.to_v3, brick_matrix, material) do |vec, matr|
              WedgeObject.build_ramp_tris(vec, matr, flipped: false)
            end
          when "PB_DefaultRampInverted"
            material.texture = up_stud_tex
            @objects << WedgeObject.new(brick.size.to_v3, brick_matrix, material) do |vec, matr|
              WedgeObject.build_ramp_tris(vec, matr, flipped: true)
            end
          else
            @omegga.broadcast "Unknown brick asset #{asset_name}"
          end
        end

        # lights
        if brick.components.has_key?("BCD_PointLight")
          lcomp = brick.components["BCD_PointLight"]

          color_raw = lcomp["Color"].as(Array(Int32 | Float64)).map &.to_i32
          color = lcomp["bUseBrickColor"].as(Bool) ? color : Color.new(color_raw[0], color_raw[1], color_raw[2])
          intensity = lcomp["Brightness"].as(Int32 | Float64).to_f64 / 100.0

          if lcomp["bMatchBrickShape"].as(Bool)
            # area light
            @lights << AreaLight.new(pos, size, color, intensity, accuracy: 4)
          else
            # point light
            @lights << PointLight.new(pos, color, intensity)
          end
        end

        if brick.components.has_key?("BCD_SpotLight")
          lcomp = brick.components["BCD_SpotLight"]

          color_raw = lcomp["Color"].as(Array(Int32 | Float64)).map &.to_i32
          color = lcomp["bUseBrickColor"].as(Bool) ? color : Color.new(color_raw[0], color_raw[1], color_raw[2])
          intensity = lcomp["Brightness"].as(Int32 | Float64).to_f64 / 10.0
          angle_inner = lcomp["InnerConeAngle"].as(Int32 | Float64).to_f64 * Math::PI / 180.0
          angle_outer = lcomp["OuterConeAngle"].as(Int32 | Float64).to_f64 * Math::PI / 180.0
          rotation = lcomp["Rotation"].as(Array(Int32 | Float64)).map { |n| n.to_f64 * Math::PI / 180.0 }
          matrix = Matrix.from_angles_xyz(0, -Math::PI / 2.0, 0) * Matrix.from_angles_zyx(0, -rotation[0], -rotation[1]) * Matrix.from_brick_orientation(Vector3.new(0, 0, 0), brick.direction, brick.rotation)
          vec = matrix.forward_vector

          @lights << SpotLight.new(pos, vec, angle_outer, angle_inner, color, intensity)
        end
      end

      if @render_players
        player_obj = OBJ::FileData.new
        player_obj.load("assets/brickhead.obj", @omegga)
        player_obj.center
        player_obj.dilate 6.8
        player_obj.apply_matrix Matrix.from_angles_xyz(0, 0, -Math::PI / 2.0)

        player_posns = @omegga.get_all_player_positions

        # get player positions and rotations
        spawn do
          player_posns.each do |plr_pos|
            @omegga.writeln "Chat.Command /GetTransform #{plr_pos[:player].name}"
          end
        end

        watcher = Log::WatcherBundled.new(/Transform: X=(-?[0-9,.]+) Y=(-?[0-9,.]+) Z=(-?[0-9,.]+) Roll=(-?[0-9,.]+) Pitch=(-?[0-9,.]+) Yaw=(-?[0-9,.]+)/, timeout: 200.milliseconds, debounce: true)
        @omegga.wrangler.watchers << watcher
        matches = watcher.receive_bundled(@omegga.wrangler)
        transforms = matches.map do |match|
          {
            x: match[1].tr(",", "").to_f64,
            y: match[2].tr(",", "").to_f64,
            z: match[3].tr(",", "").to_f64,
            roll: match[4].tr(",", "").to_f64,
            pitch: match[5].tr(",", "").to_f64,
            yaw: match[6].tr(",", "").to_f64
          }
        end

        player_colors = [

        ] of Color

        player_posns.each do |plr_pos|
          pos = plr_pos[:position]
          next if (@camera.origin - pos).magnitude <= 1.0
          current_transform = transforms.min_by { |tup| (pos - Vector3.new(tup[:x], tup[:y], tup[:z])).magnitude }

          obj = MeshObject.new(
            player_obj.build_tris(pos, Matrix.from_angles_xyz(0, 0, Math::PI + current_transform[:yaw] * Math::PI / 180.0)),
            material: Material.new(color: Scene.player_color(plr_pos[:player].name))
          )

          @objects << obj
        end
      end

      plane_material = Material.new(color: @ground_plane_color, texture: StudTexture.new(Vector3.new(0, 0, 0), 0.3))
      @objects << PlaneObject.new(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1), plane_material) if @render_ground_plane
    end

    def cast_ray(ray : Ray, objs : Array(SceneObject)) : NamedTuple(object: SceneObject, hit: Hit)?
      @total_rays_cast += 1

      intersected = [] of NamedTuple(object: SceneObject, hit: Hit)
      objs.each do |obj|
        res = obj.intersection_with_ray(ray)
        unless res.nil?
          res.normal = obj.material.texture.not_nil!.normal_for(res.normal, ray.point_along(res.near), ray.origin) unless obj.material.texture.nil?
          intersected << {object: obj, hit: res} unless res.nil?
        end
      end

      return nil if intersected.size == 0
      return intersected[0] if intersected.size == 1
      intersected.sort { |a, b| a[:hit].near <=> b[:hit].near }[0]
    end

    def get_ray_color(ray : Ray, reflection_depth : Int32 = 0) : Color
      hit = cast_ray(ray, @objects)

      if hit.nil?
        begin
          return @skybox.not_nil!.vec_to_color(ray.direction) unless @skybox.nil?
        rescue
          @omegga.broadcast ray.direction.to_s
        end
        return Color.new(0, 0, 0)
      end

      mat = hit[:object].material

      # skip all lighting/reflection/refraction checks if the object is emissive
      return mat.color if mat.emissive

      color = mat.color

      # phong lighting for all lights
      colv = color.to_v3
      sun_col = @light_color.to_v3
      ambient = sun_col * @ambient_coefficient
      hit_pos = ray.point_along(hit[:hit].near)

      sum_vecs = ambient
      lights.each do |light|
        if light.is_a?(PositionLight)
          next if light.max_distance <= (light.position - hit_pos).magnitude
        end

        lcol = light.color.to_v3
        shading = light.shading(ray, hit[:hit]) { |inc_ray| cast_ray(inc_ray, @objects) }
        
        # color from diffuse/specular
        diffuse = lcol * shading.diffuse
        specular = lcol * (shading.specular * light.specular_strength)

        sum_vecs += (diffuse + specular) * shading.intensity
      end

      color = Color.new(sum_vecs * colv)

      # refraction calculation (IOR for transparent materials is assumed to be 1.45)
      if mat.transparency > 0.1 && mat.reflectiveness < 0.1
        if !@do_refraction || reflection_depth >= @max_reflection_depth
          continuing = Ray.new(ray.point_along(hit[:hit].far + 0.01), ray.direction)
          continuing_color = get_ray_color(continuing, reflection_depth)
          color = color.lerp(continuing_color, mat.transparency)
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

            continuing_color = get_ray_color(ray_out, reflection_depth + 1)
            mixed_color = continuing_color.lerp(reflection_hit_color, rr_amount.clamp(0.0, 1.0))
            color = color.lerp(mixed_color, mat.transparency)
          end
        end
      end

      # reflection calculation
      if reflection_depth < @max_reflection_depth && mat.reflectiveness > 0.1
        reflection_ray = Ray.new(ray.point_along(hit[:hit].near) + hit[:hit].normal * EPSILON, Scene.reflect(ray.direction, hit[:hit].normal))
        #Scene.fuzz_reflect(ray.direction, hit[:hit].normal, 0.1))
        reflection_hit_color = get_ray_color(reflection_ray, reflection_depth + 1)
        color = color.lerp(reflection_hit_color, mat.reflectiveness)
      end

      # fog
      if do_fog
        fog_amount = hit[:hit].near * fog_density
        color = color.lerp(fog_color, Math.min(1.0, fog_amount))
      end

      color
    end

    def render : Array(Array(Color))
      @total_rays_cast = 0

      ray_timer = Time::Span.new
      last_time = Time.monotonic
      start_time = Time.monotonic

      img = [] of Array(Color)
      @camera.vh.times do |y|
        img << [] of Color
        @camera.vw.times do |x|
          if supersampling > 1
            sampled_colors = [] of Color
            ss2 = supersampling * supersampling
            sinv = 1.0 / supersampling
            ss2.times do |i|
              ssx = (i % supersampling).to_f64 / supersampling
              ssy = (i // supersampling).to_f64 / supersampling
              rgx = ((x + ssx)..(x + ssx + sinv))
              rgy = ((y + ssy)..(y + ssy + sinv))
              sampled_colors << get_ray_color(Ray.new(@camera.origin, @camera.direction_for_screen_point(Scene.random_float(rgx), Scene.random_float(rgy))))
            end
            vecs = sampled_colors.map(&.to_v3)
            vecsum = Vector3.new(0, 0, 0)
            vecs.each { |vec| vecsum += vec }
            img[y] << Color.new(vecsum / ss2.to_f64)
          else
            img[y] << get_ray_color(Ray.new(@camera.origin, @camera.direction_for_screen_point(x.to_f64, y.to_f64)))
          end
          now_time = Time.monotonic
          ray_timer += now_time - last_time
          last_time = now_time

          if @do_progress && ray_timer >= Time::Span.new(seconds: 10)
            ray_timer -= Time::Span.new(seconds: 10)
            progress = (x + y * @camera.vw).to_f64 / (@camera.vw * @camera.vh)
            @omegga.broadcast "[#{(progress * 100.0).round.to_i32}%] Cast #{@total_rays_cast.format} rays, #{(now_time - start_time).to_s} elapsed"
          end
        end
      end
      img
    end
  end
end
