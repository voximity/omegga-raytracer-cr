require "omegga-cr"

require "./omegga-raytracer-cr/objects/object"
require "./omegga-raytracer-cr/objects/box"
require "./omegga-raytracer-cr/objects/cylinder"
require "./omegga-raytracer-cr/objects/plane"

require "./omegga-raytracer-cr/camera"
require "./omegga-raytracer-cr/color"
require "./omegga-raytracer-cr/hit"
require "./omegga-raytracer-cr/matrix"
require "./omegga-raytracer-cr/quadtree"
require "./omegga-raytracer-cr/ray"
require "./omegga-raytracer-cr/scene"

include Omegga

class Config
  property width : Int32 = 64
  property height : Int32 = 64
  property fov : Int32 = 50
  property diffuse : Float64 = 1.0
  property ambient : Float64 = 0.3
  property light_vector : Vector3 = Vector3.new(-0.8, -0.5, -1.0).normalize
  property shadows : Bool = true
  property shadow : Float64 = 0.4
  property max_reflection_depth : Int32 = 3
  property render_players : Bool = true
  property render_ground_plane : Bool = true

  def initialize
  end
end

omegga = RPCClient.new
config = Config.new

omegga.on_init do
  omegga.broadcast "Raytracer loaded."
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
  when "diffuse"
    config.diffuse = args[1].to_f64
    omegga.broadcast "Diffuse coefficient set to #{config.diffuse}."
  when "ambient"
    config.ambient = args[1].to_f64
    omegga.broadcast "Ambient coefficient set to #{config.ambient}."
  when "light", "lightvector", "lightVector", "light_vector"
    x = args[1].to_f64
    y = args[2].to_f64
    z = args[3].to_f64
    config.light_vector = Vector3.new(x, y, z)
    omegga.broadcast "Light vector set to #{config.light_vector}."
  when "shadows", "castShadows", "castshadows", "cast_shadows"
    if ["on", "true", "1"].includes? args[1]
      config.shadows = true
      omegga.broadcast "Casting shadows enabled."
    elsif ["off", "false", "0"].includes? args[1]
      config.shadows = false
      omegga.broadcast "Casting shadows disabled."
    else
      omegga.broadcast "Invalid option for casting shadows."
    end
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
  else
    omegga.broadcast "Invalid setting \"#{args[1]}\"."
  end
end

omegga.on_chat_command "trace" do |user, args|
  next unless user == "x"
  yaw = -45.0
  pitch = -25.0

  if args.size >= 1
    yaw = args[0].to_f64? || -45.0
  end

  if args.size >= 2
    pitch = args[1].to_f64? || -25.0
  end

  omegga.broadcast "Reading bricks..."
  save = omegga.get_save_data

  pos = omegga.get_player_position(user)
  cam = Camera.new(150, 100, pos, 50.0, yaw * Math::PI / 180, pitch * Math::PI / 180)
  scene = Scene.new(cam)

  omegga.broadcast "Scene initialized. Populating scene objects..."
  scene.populate_scene save

  omegga.broadcast "Scene populated. Rendering..."
  img = scene.render

  omegga.broadcast "Rendered. Optimizing quadtree and importing..."
  quadtree = Quadtree.new(img)
  quadtree.create_tree
  quadtree.optimize_tree
  
  bricks = quadtree.build_bricks(BRS::Vector.new(pos.x.round.to_i32, pos.y.round.to_i32, pos.z.round.to_i32))
  new_save = BRS::Save.new
  new_save.bricks = bricks
  new_save.brick_assets = ["PB_DefaultMicroBrick"]
  omegga.load_save_data(new_save, quiet: false)
  omegga.broadcast "Raytrace complete."
end

omegga.start
