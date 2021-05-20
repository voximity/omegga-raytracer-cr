struct Matrix
  getter x, y, z, m00, m01, m02, m10, m11, m12, m20, m21, m22

  def initialize(
    @x : Float64, @y : Float64, @z : Float64,
    @m00 : Float64, @m01 : Float64, @m02 : Float64,
    @m10 : Float64, @m11 : Float64, @m12 : Float64,
    @m20 : Float64, @m21 : Float64, @m22 : Float64
  )
  end

  def self.from_angles_zyx(rx : Float64, ry : Float64, rz : Float64) : self
    Matrix.new(0, 0, 0, Math.cos(rz), -Math.sin(rz), 0, Math.sin(rz), Math.cos(rz), 0, 0, 0, 1) *
      Matrix.new(0, 0, 0, Math.cos(ry), 0, Math.sin(ry), 0, 1, 0, -Math.sin(ry), 0, Math.cos(ry)) *
      Matrix.new(0, 0, 0, 1, 0, 0, 0, Math.cos(rx), -Math.sin(rx), 0, Math.sin(rx), Math.cos(rx))
  end

  def self.from_angles_xyz(rx : Float64, ry : Float64, rz : Float64) : self
    Matrix.new(0, 0, 0, 1, 0, 0, 0, Math.cos(rx), -Math.sin(rx), 0, Math.sin(rx), Math.cos(rx)) *
      Matrix.new(0, 0, 0, Math.cos(ry), 0, Math.sin(ry), 0, 1, 0, -Math.sin(ry), 0, Math.cos(ry)) *
      Matrix.new(0, 0, 0, Math.cos(rz), -Math.sin(rz), 0, Math.sin(rz), Math.cos(rz), 0, 0, 0, 1)
  end

  def self.from_forward_vector(vec : Vector3) : self
    forward = vec.normalize
    right = Vector3.new(0, 1, 0).cross(vec)
    up = forward.cross(right)
    new(0, 0, 0, right.x, right.y, right.z, up.x, up.y, up.z, -forward.x, -forward.y, -forward.z)
  end

  def self.new(x : Float64, y : Float64, z : Float64) : self
    new(x, y, z, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0)
  end

  def self.new(v : Vector3) : self
    new(v.x, v.y, v.z)
  end

  def self.from_brick_orientation(pos : Vector3, o : BRS::Direction, r : BRS::Rotation) : self
    base = new(pos)
    
    # todo: make this exhaustive
    case o
    when BRS::Direction::ZPositive
      base * Matrix.from_angles_xyz(0, 0, r.value * Math::PI / 2.0)
    when BRS::Direction::ZNegative
      base * Matrix.from_angles_xyz(0, Math::PI, r.value * Math::PI / 2.0)
    when BRS::Direction::XPositive
      base * Matrix.from_angles_xyz(Math::PI, Math::PI / 2.0, r.value * Math::PI / 2.0)
    when BRS::Direction::XNegative
      base * Matrix.from_angles_xyz(0, -Math::PI / 2.0, r.value * Math::PI / 2.0)
    when BRS::Direction::YPositive
      base * Matrix.from_angles_xyz(0, 0, -Math::PI / 2.0) * Matrix.from_angles_xyz(0, -Math::PI / 2.0, r.value * Math::PI / 2.0)
    when BRS::Direction::YNegative
      base * Matrix.from_angles_xyz(0, 0, Math::PI / 2.0) * Matrix.from_angles_xyz(0, -Math::PI / 2.0, r.value * Math::PI / 2.0)
    else
      base * Matrix.new(0, 0, 500)
    end
  end

  def components : Array(Float64)
    [@m00, @m01, @m02, @x, @m10, @m11, @m12, @y, @m20, @m21, @m22, @z, 0, 0, 0, 1]
  end

  def rowed_components : Array(Array(Float64))
    [[@m00, @m01, @m02, @x], [@m10, @m11, @m12, @y], [@m20, @m21, @m22, @z], [0.0, 0.0, 0.0, 1.0]]
  end

  def *(other : Matrix) : self
    a = rowed_components
    b = other.rowed_components
    o = [[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0]]

    4.times do |i|
      4.times do |j|
        4.times do |k|
          o[i][j] += a[i][k] * b[k][j]
        end
      end
    end

    Matrix.new(o[0][3], o[1][3], o[2][3], o[0][0], o[0][1], o[0][2], o[1][0], o[1][1], o[1][2], o[2][0], o[2][1], o[2][2])
  end

  def forward_vector : Vector3
    Vector3.new(-@m20, -@m21, -@m22)
  end

  def pos : Vector3
    Vector3.new(@x, @y, @z)
  end
end
