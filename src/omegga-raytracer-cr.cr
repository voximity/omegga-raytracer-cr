require "omegga-cr"
require "stumpy_png"
require "open-simplex-noise"

require "./omegga-raytracer-cr/lights/light"
require "./omegga-raytracer-cr/lights/area"
require "./omegga-raytracer-cr/lights/point"
require "./omegga-raytracer-cr/lights/spot"
require "./omegga-raytracer-cr/lights/sun"

require "./omegga-raytracer-cr/objects/object"
require "./omegga-raytracer-cr/objects/box"
require "./omegga-raytracer-cr/objects/cylinder"
require "./omegga-raytracer-cr/objects/mesh"
require "./omegga-raytracer-cr/objects/microbrick"
require "./omegga-raytracer-cr/objects/plane"
require "./omegga-raytracer-cr/objects/sphere"
require "./omegga-raytracer-cr/objects/wedge"

require "./omegga-raytracer-cr/textures/texture"
require "./omegga-raytracer-cr/textures/foil_texture"
require "./omegga-raytracer-cr/textures/fuzz_texture"
require "./omegga-raytracer-cr/textures/mixed"
require "./omegga-raytracer-cr/textures/stud_texture"

require "./omegga-raytracer-cr/camera"
require "./omegga-raytracer-cr/color"
require "./omegga-raytracer-cr/hit"
require "./omegga-raytracer-cr/material"
require "./omegga-raytracer-cr/matrix"
require "./omegga-raytracer-cr/obj"
require "./omegga-raytracer-cr/quadtree"
require "./omegga-raytracer-cr/ray"
require "./omegga-raytracer-cr/scene"
require "./omegga-raytracer-cr/skybox"

include Omegga

class Config
  property width : Int32 = 300
  property height : Int32 = 200
  property fov : Int32 = 60
  property ambient : Float64 = 0.4
  property light_vector : Vector3 = Vector3.new(-0.6, -0.4, -0.8).normalize
  property shadow : Float64 = 0.4
  property max_reflection_depth : Int32 = 3
  property render_players : Bool = true
  property render_ground_plane : Bool = true
  property do_sun = true
  property supersampling : Int32 = 1

  def initialize
  end
end

omegga = RPCClient.new
config = Config.new
skybox = Skybox.new("skybox.png")

omegga.on_init do
  omegga.broadcast "Raytracer loaded."
end

omegga.on_chat_command "test" do |user|
  omegga.broadcast "#{Matrix.new(Vector3.new(0, 0, 0)).up_vector}"
end

omegga.on_chat_command "set" do |user, args|
  unless args.size >= 2
    omegga.broadcast "Expected a setting and at least one value."
    next
  end
  
  thing = args[0]

  case thing
  when "res", "resolution"
    config.width = args[1].to_i32
    config.height = args[2].to_i32
    omegga.broadcast "Resolution set to (#{config.width}, #{config.height})."
  when "fov"
    config.fov = args[1].to_i32
    omegga.broadcast "FOV set to #{config.fov}."
  when "ambient"
    config.ambient = args[1].to_f64
    omegga.broadcast "Ambient coefficient set to #{config.ambient}."
  when "light", "lightvector", "lightVector", "light_vector"
    x = args[1].to_f64
    y = args[2].to_f64
    z = args[3].to_f64
    config.light_vector = Vector3.new(x, y, z).normalize
    omegga.broadcast "Light vector set to #{config.light_vector}."
  when "shadow", "shadowCoefficient", "shadow_coefficient"
    config.shadow = args[1].to_f64
    omegga.broadcast "Shadow coefficient set to #{config.shadow}."
  when "supersampling", "ss", "aa", "antialiasing"
    config.supersampling = args[1].to_i32
    omegga.broadcast "Supersampling set to #{config.supersampling}."
  when "maxReflectionDepth", "max_reflection_depth", "reflectionDepth", "reflection_depth"
    config.max_reflection_depth = args[1].to_i32
    omegga.broadcast "Max reflection depth set to #{config.max_reflection_depth}."
  when "renderPlayers", "render_players", "players"
    if ["on", "true", "1"].includes? args[1]
      config.render_players = true
      omegga.broadcast "Rendering players enabled."
    elsif ["off", "false", "0"].includes? args[1]
      config.render_players = false
      omegga.broadcast "Rendering players disabled."
    else
      omegga.broadcast "Invalid option for rendering players."
    end
  when "renderGroundPlane", "render_ground_plane", "groundPlane", "ground_plane", "ground", "plane"
    if ["on", "true", "1"].includes? args[1]
      config.render_ground_plane = true
      omegga.broadcast "Rendering ground plane enabled."
    elsif ["off", "false", "0"].includes? args[1]
      config.render_ground_plane = false
      omegga.broadcast "Rendering ground plane disabled."
    else
      omegga.broadcast "Invalid option for rendering ground plane."
    end
  when "doSun", "do_sun", "sun"
    if ["on", "true", "1"].includes? args[1]
      config.do_sun = true
      omegga.broadcast "Sun enabled."
    elsif ["off", "false", "0"].includes? args[1]
      config.do_sun = false
      omegga.broadcast "Sun disabled."
    else
      omegga.broadcast "Invalid option for sun."
    end
  else
    omegga.broadcast "Invalid setting \"#{args[0]}\"."
  end
end

omegga.on_chat_command "trace" do |user, args|
  next unless user == "x"
  yaw = -45.0
  pitch = -25.0

  to_bricks = true

  if args.size >= 1
    yaw = args[0].to_f64? || -45.0
  end

  if args.size >= 2
    pitch = args[1].to_f64? || -25.0
  end

  to_bricks = args[2] != "img" if args.size >= 3

  total_rays = 0
  elapsed = Time.measure do
    omegga.broadcast "Reading bricks..."
    save = omegga.get_save_data

    pos = omegga.get_player_position(user)
    cam = Camera.new(config.width, config.height, pos, config.fov.to_f64, yaw * Math::PI / 180, pitch * Math::PI / 180)
    scene = Scene.new(cam, omegga)
    scene.ambient_coefficient = config.ambient
    scene.light_vector = config.light_vector
    scene.shadow_coefficient = config.shadow
    scene.max_reflection_depth = config.max_reflection_depth
    scene.render_players = config.render_players
    scene.render_ground_plane = config.render_ground_plane
    scene.skybox = skybox
    scene.do_sun = config.do_sun
    scene.supersampling = config.supersampling

    omegga.broadcast "Scene initialized. Populating scene objects..."
    scene.populate_scene save

    omegga.broadcast "Scene populated. Rendering..."
    img = scene.render

    if to_bricks
      # render out to bricks
      omegga.broadcast "Rendered. Optimizing quadtree and importing..."
      quadtree = Quadtree.new(img)
      quadtree.create_tree
      quadtree.optimize_tree
      
      bricks = quadtree.build_bricks(BRS::Vector.new(pos.x.round.to_i32, pos.y.round.to_i32, pos.z.round.to_i32))
      new_save = BRS::Save.new
      new_save.bricks = bricks
      new_save.brick_assets = ["PB_DefaultMicroBrick"]
      omegga.load_save_data(new_save, quiet: false)
    else
      # write to file
      omegga.broadcast "Rendered. Writing to file..."
      canvas = StumpyPNG::Canvas.new(config.width, config.height)
      config.height.times do |y|
        config.width.times do |x|
          col = img[y][x]
          canvas[x, y] = StumpyPNG::RGBA.from_rgb_n(col.r, col.g, col.b, 8)
        end
      end
      StumpyPNG.write(canvas, "raytrace.png")
    end

    total_rays = scene.total_rays_cast
  end

  omegga.broadcast "Operation complete in #{elapsed} for image #{config.width}x#{config.height}. Cast #{total_rays.format} rays."
end

omegga.start
