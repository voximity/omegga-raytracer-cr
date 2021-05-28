# Build this file for the Omegga plugin

require "./omegga-raytracer-cr"

include Omegga

module Plugin
  extend self
  
  alias ConfigOptionType = ConfigOption(Int32) | ConfigOption(Float64) | ConfigOption(Vector3) | ConfigOption(Bool) | ConfigOption(String)

  @@on_values = ["on", "true", "enabled", "yes", "y", "1"]
  @@off_values = ["off", "false", "disabled", "no", "n", "0"]

  def on_values
    @@on_values
  end

  def off_values
    @@off_values
  end

  class ConfigOption(T)
    getter name : String
    getter description : String
    getter aliases : Array(String)
    property value : T
    getter default : T
    getter apply_to_scene : Raytracer::Scene, T ->
  
    def initialize(@name : String, @aliases : Array(String), @value, @description, &block : Raytracer::Scene, T ->)
      @apply_to_scene = block
      @default = @value
    end
  end
end

include Plugin

config_options = [] of ConfigOptionType

config_options << ConfigOption(Int32).new("Width", ["width", "w"], 300, "The width of the output image.") { |scene, w| scene.camera.vw = w }
config_options << ConfigOption(Int32).new("Height", ["height", "h"], 200, "The height of the output image.") { |scene, h| scene.camera.vh = h }
config_options << ConfigOption(Float64).new("Field of View", ["fov", "fieldofview", "field_of_view"], 60.0, "The field of view of the camera.") { |scene, fov| scene.camera.fov = fov }
config_options << ConfigOption(Float64).new("Ambient", ["ambient", "amb"], 0.4, "The ambient coefficient for the entire scene.") { |scene, c| scene.ambient_coefficient = c }
config_options << ConfigOption(Vector3).new("Sun Vector", ["sunvector", "lightvector", "sun_vector", "light_vector"],
  Vector3.new(-0.6, -0.4, -0.8).normalize, "A unit vector representing the direction of the sun.") { |scene, vec| scene.light_vector = vec.normalize }
config_options << ConfigOption(Float64).new("Shadow Coefficient", ["shadow", "shadowcoefficient", "shadow_coefficient"],
  0.4, "The coefficient of diffuse/specular light for the sun when in shadow. Does not apply to other lights.") { |scene, sh| scene.shadow_coefficient = sh }
config_options << ConfigOption(Int32).new("Max Reflection Depth", ["reflectiondepth", "maxreflectiondepth", "reflection_depth", "max_reflection_depth"],
  3, "The maximum amount of times any given ray is allowed to bounce from reflections or refractions. Used to prevent infinite bounces.") { |scene, mrd| scene.max_reflection_depth = mrd }
config_options << ConfigOption(Bool).new("Sun", ["sun", "do_sun"], true, "Whether or not a SunLight should be added.") { |scene, ds| scene.do_sun = ds }
config_options << ConfigOption(Int32).new("Supersampling", ["ss", "supersampling", "aa", "antialiasing"],
  1, "The supersampling level. When set to 1, no supersampling is calculated. Total ray lookups per pixel will become n^2 where n is the supersampling value.") { |scene, ss| scene.supersampling = ss }
config_options << ConfigOption(Bool).new("Ground Plane", ["groundplane", "rendergroundplane", "ground_plane", "render_ground_plane"],
  true, "Whether or not to render the ground plane.") { |scene, gp| scene.render_ground_plane = gp }
config_options << ConfigOption(Bool).new("Ground Plane Texture", ["groundplanetexture", "ground_plane_texture"],
  true, "Whether or not to render the ground plane texture.") { |scene, gpt| scene.stud_texture = gpt }
config_options << ConfigOption(Bool).new("Players", ["players", "renderplayers", "render_players"], false, "Whether or not to render players.") { |scene, rp| scene.render_players = rp }
config_options << ConfigOption(Bool).new("Area Lights", ["arealights", "area_lights"], false, "Whether or not lights with bMatchBrickShape should be area lights.") { |scene, al| scene.area_lights = al }

#config_options << ConfigOption(String).new("Skybox", ["skybox", "sky"], "skybox.png", "The image name of the skybox to use.") { |scene, sb| scene.skybox = Raytracer::Skybox.new(sb) }

omegga = RPCClient.new
skybox = Raytracer::Skybox.new("assets/skybox.png")
authorized_users = [] of String

def transform_of(user : String, omegga : RPCClient)
  omegga.writeln "Chat.Command /GetTransform #{user}"

  watcher = Log::Watcher.new(/Transform: X=(-?[0-9,.]+) Y=(-?[0-9,.]+) Z=(-?[0-9,.]+) Roll=(-?[0-9,.]+) Pitch=(-?[0-9,.]+) Yaw=(-?[0-9,.]+)/, timeout: 1.second)
  omegga.wrangler.watchers << watcher
  match = watcher.receive(omegga.wrangler)

  {
    x: match[1].tr(",", "").to_f64,
    y: match[2].tr(",", "").to_f64,
    z: match[3].tr(",", "").to_f64,
    roll: match[4].tr(",", "").to_f64,
    pitch: match[5].tr(",", "").to_f64,
    yaw: match[6].tr(",", "").to_f64
  }
end

omegga.on_init do |conf|
  omegga.broadcast "Raytracer loaded."

  conf["authorized"].as_a.map { |usr| usr.as_h["name"].as_s }.each { |name| authorized_users << name }
end

omegga.on_chat_command "set" do |user, args|
  next unless authorized_users.includes?(user)

  unless args.size >= 2
    omegga.broadcast "Expected a setting and at least one value.".br_colorize(:red)
    next
  end
  
  option = config_options.find { |o| o.aliases.includes?(args[0].downcase) }
  if option.nil?
    omegga.broadcast "Unable to find an option with the alias #{args[0].br_colorize(:red)}."
    next
  end

  if args[1].downcase == "default"
    if option.is_a? ConfigOption(Int32); option.value = option.default
    elsif option.is_a? ConfigOption(Float64); option.value = option.default
    elsif option.is_a? ConfigOption(Vector3); option.value = option.default
    elsif option.is_a? ConfigOption(String); option.value = option.default
    elsif option.is_a? ConfigOption(Bool); option.value = option.default end
    omegga.broadcast "Set option #{option.name.br_colorize(:yellow)} to default, #{option.value.to_s.br_colorize(:cyan)}."
    next
  end

  if option.is_a? ConfigOption(Int32)
    # parse ints

    parsed = args[1].to_i32?
    if parsed.nil?
      omegga.broadcast "Please pass a #{"valid integer".br_colorize(:red)} for the option #{option.name.br_colorize(:yellow)}."
      next
    end
    option.value = parsed

  elsif option.is_a? ConfigOption(Float64)
    # parse doubles

    parsed = args[1].to_f64?
    if parsed.nil?
      omegga.broadcast "Please pass a #{"valid decimal number".br_colorize(:red)} for the option #{option.name.br_colorize(:yellow)}."
      next
    end
    option.value = parsed

  elsif option.is_a? ConfigOption(Vector3)
    # parse vectors

    if args.size < 4
      omegga.broadcast "Please pass #{"three valid vector components".br_colorize(:red)} for the option #{option.name.br_colorize(:yellow)}."
      next
    end
    x = args[1].to_f64?
    y = args[2].to_f64?
    z = args[3].to_f64?
    if x.nil? || y.nil? || z.nil?
      omegga.broadcast "Please pass #{"three valid vector components".br_colorize(:red)} for the option #{option.name.br_colorize(:yellow)}."
      next
    end
    option.value = Vector3.new(x, y, z)

  elsif option.is_a? ConfigOption(Bool)
    # parse booleans

    passed = args[1].downcase
    is_yes = Plugin.on_values.includes?(passed)
    is_no = Plugin.off_values.includes?(passed)
    if !is_yes && !is_no
      omegga.broadcast "Please specify #{"yes/y/on/true".br_colorize(:green)}/#{"no/n/off/false".br_colorize(:red)} for the option #{option.name.br_colorize(:yellow)}."
      next
    end
    option.value = is_yes

  elsif option.is_a? ConfigOption(String)
    # parse strings

    option.value = args[1]

  end

  omegga.broadcast "Set option #{option.name.br_colorize(:yellow)} to #{option.value.to_s.br_colorize(:cyan)}."
end

omegga.on_chat_command "clear" do |user|
  next unless authorized_users.includes?(user)

  omegga.clear_bricks(Raytracer::BUILD_USER.id.to_s, quiet: false)
end

last_trace : NamedTuple(yaw: Float64, pitch: Float64, pos: Vector3, to_bricks: Bool)? = nil

omegga.on_chat_command "trace" do |user, args|
  next unless authorized_users.includes?(user)

  yaw : Float64
  pitch : Float64
  pos : Vector3
  to_bricks : Bool

  if args[0]? == "again"
    if last_trace.nil?
      omegga.broadcast "Please trace once to retrace from its position.".br_colorize(:red)
      next
    end

    yaw = last_trace.not_nil![:yaw]
    pitch = last_trace.not_nil![:pitch]
    pos = last_trace.not_nil![:pos]
    to_bricks = last_trace.not_nil![:to_bricks]

    omegga.broadcast "Using previous position for trace.".br_colorize(:gray)
  else
    transform = transform_of(user, omegga)

    yaw = transform[:yaw]
    pitch = 0.0
    pos = Vector3.new(transform[:x], transform[:y], transform[:z])
    to_bricks = true

    pitch = args[0].to_f64? || 0.0 if args.size >= 1
    to_bricks = args[1] != "img" if args.size >= 2

    last_trace = {yaw: yaw, pitch: pitch, pos: pos, to_bricks: to_bricks}
  end

  width = config_options[0].as(ConfigOption(Int32)).value
  height = config_options[1].as(ConfigOption(Int32)).value

  total_rays = 0
  elapsed = Time.measure do
    omegga.broadcast "#{"[1/4]".br_colorize(:gray)} Reading bricks..."
    save = omegga.get_save_data
    pos += Vector3.new(0, 0, 15) # eye pos roughly?
    scene = Raytracer::Scene.new(omegga)
    scene.camera.yaw = yaw * Math::PI / 180.0
    scene.camera.pitch = pitch * Math::PI / 180.0
    scene.camera.origin = pos
    scene.skybox = skybox
    config_options.each do |option|
      # why is this necessary
      if option.is_a? ConfigOption(Int32)
        option.apply_to_scene.call(scene, option.value)
      elsif option.is_a? ConfigOption(Float64)
        option.apply_to_scene.call(scene, option.value)
      elsif option.is_a? ConfigOption(Vector3)
        option.apply_to_scene.call(scene, option.value)
      elsif option.is_a? ConfigOption(String)
        option.apply_to_scene.call(scene, option.value)
      elsif option.is_a? ConfigOption(Bool)
        option.apply_to_scene.call(scene, option.value)
      end
    end

    omegga.broadcast "#{"[2/4]".br_colorize(:gray)} Scene initialized. Populating scene objects..."
    scene.populate_scene save

    omegga.broadcast "#{"[3/4]".br_colorize(:gray)} Scene populated. Rendering..."
    img_tup = scene.render
    img = img_tup[:image]

    if to_bricks
      # render out to bricks
      omegga.broadcast "#{"[4/4]".br_colorize(:gray)} Rendered. Optimizing quadtree and importing..."
      quadtree = Raytracer::Quadtree.new(img)
      quadtree.create_tree
      quadtree.optimize_tree
      
      bricks = quadtree.build_bricks(BRS::Vector.new(pos.x.round.to_i32, pos.y.round.to_i32, pos.z.round.to_i32))
      new_save = BRS::Save.new
      new_save.bricks = bricks
      new_save.brick_assets = ["PB_DefaultMicroBrick"]
      new_save.brick_owners = [Raytracer::BUILD_USER]
      omegga.load_save_data(new_save, quiet: false)
    else
      # write to file
      omegga.broadcast "#{"[4/4]".br_colorize(:gray)} Rendered. Writing to file..."
      canvas = StumpyPNG::Canvas.new(width, height)
      height.times do |y|
        width.times do |x|
          col = img[y][x]
          canvas[x, y] = StumpyPNG::RGBA.from_rgb_n(col.r, col.g, col.b, 8)
        end
      end
      StumpyPNG.write(canvas, "raytrace.png")
    end

    total_rays = img_tup[:rays]
  end

  omegga.broadcast "Operation complete in #{elapsed.to_s.br_colorize(:yellow)} for image #{"#{width}x#{height}".br_colorize(:yellow)}. Cast #{total_rays.format.br_colorize(:cyan)} rays."
end

omegga.start
