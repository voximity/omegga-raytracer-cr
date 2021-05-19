class Scene
  def self.lerp(a : Float64, b : Float64, c : Float64) : Float64
    a + (b - a) * c
  end

  property camera : Camera
  property objects = [] of SceneObject
  property diffuse_coefficient = 1.0
  property ambient_coefficient = 0.4
  property atmosphere_color = Color.new(206, 225, 245)
  property light_vector : Vector3 = -Vector3.new(-0.8, -0.5, -1.0).normalize
  property cast_shadows = true
  property shadow_coefficient = 0.5
  property max_reflection_depth = 8
  property render_players = true
  property render_ground_plane = true
  property ground_plane_color = Color.new(92, 148, 84)

  def initialize(@camera)
    # other fields can be changed as they are properties
  end

  def populate_scene(save : BRS::Save)
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
      @objects << AxisAlignedBoxObject.new(
        pos, size, color,
        reflectiveness: save.materials[brick.material_index] == "BMC_Metallic" ? 0.4 : 0.0,
        transparency: save.materials[brick.material_index] == "BMC_Glass" ? 1.0 - (brick.material_intensity / 10.0) : 0.0 # todo: this should work with the glass material and material intensity
      )
    end

    # todo: rendering players

    @objects << PlaneObject.new(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1), @ground_plane_color) if @render_ground_plane
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

    coeff = Scene.lerp(@diffuse_coefficient, @ambient_coefficient, Math.min(@light_vector.angle_between(hit[:hit].normal) / Math::PI * 0.5, 1.0))
    color = hit[:object].color.srgb * coeff

    # transparency calculation
    if hit[:object].transparency > 0.1 && hit[:object].reflectiveness < 0.1
      continuing = Ray.new(ray.point_along(hit[:hit].far + 0.01), ray.direction)
      continuing_color = get_ray_color(continuing, reflection_depth)
      color = color.lerp(continuing_color, hit[:object].transparency)
    end

    # shadow calculation
    if @cast_shadows
      shadow_ray = Ray.new(ray.point_along(hit[:hit].near) + (hit[:hit].normal * 0.01), @light_vector)
      shadow_hit = cast_ray(shadow_ray, @objects)
      color = color * @shadow_coefficient unless shadow_hit.nil?
    end

    # reflection calculation
    if reflection_depth < @max_reflection_depth && hit[:object].reflectiveness > 0.1
      reflection_ray = Ray.new(ray.point_along(hit[:hit].near) + (hit[:hit].normal * 0.01), ray.direction - (hit[:hit].normal * (2 * ray.direction.dot(hit[:hit].normal))))
      reflection_hit_color = get_ray_color(reflection_ray, reflection_depth + 1)
      color = color.lerp(reflection_hit_color, hit[:object].reflectiveness)
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
