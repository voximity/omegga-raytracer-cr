# Require this file if you want to interface the Raytracer code itself.

require "omegga-cr"
require "stumpy_png"
require "open-simplex-noise"

include Omegga

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
