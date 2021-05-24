module Raytracer
  class Camera
    property vw : Int32
    property vh : Int32
    property origin : Vector3
    property yaw : Float64
    property pitch : Float64
    getter fov : Float64
    getter chf : Float64

    def initialize(@vw = 300, @vh = 200, @origin = Vector3.new(0, 0, 0), @fov = 60.0, @yaw = 0.0, @pitch = 0.0)
      @chf = Math.tan((90 - @fov * 0.5) * 0.017453)
    end

    def fov=(val : Float64)
      @fov = val
      @chf = Math.tan((90 - @fov * 0.5) * 0.017453)
    end

    def direction_for_screen_point(x : Float64, y : Float64) : Vector3
      (Matrix.from_forward_vector(direction_from_fov(x, y)) * Matrix.from_angles_xyz(0, @pitch, -@yaw)).forward_vector
    end

    def direction_from_fov(x : Float64, y : Float64) : Vector3
      nx = x - @vw * 0.5
      ny = y - @vh * 0.5
      z = @vh * 0.5 * @chf
      Vector3.new(z, nx, -ny).normalize
    end
  end
end
