module Raytracer
  struct Color
    getter r, g, b

    def self.srgb_channel(c : Float64) : Float64
      c > 0.0031308 ? 1.055 * c ** (1.0 / 2.4) - 0.055 : 12.92 * c
    end

    def self.linear_channel(c : Float64) : Float64
      c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4
    end

    def initialize(@r : UInt8, @g : UInt8, @b : UInt8)
    end

    def self.new(r : Int32, g : Int32, b : Int32) : self
      new(r.to_u8, g.to_u8, b.to_u8)
    end

    def self.new(arr : Array(UInt8)) : self
      new(arr[0], arr[1], arr[2])
    end

    def self.new(vec : Vector3) : self
      rg = (0.0..1.0)
      new((vec.x.clamp(rg) * 255).to_u8, (vec.y.clamp(rg) * 255).to_u8, (vec.z.clamp(rg) * 255).to_u8)
    end

    def rf : Float64
      @r.to_f64
    end

    def gf : Float64
      @g.to_f64
    end

    def bf : Float64
      @b.to_f64
    end

    def to_v3
      Vector3.new(@r.to_f64 / 255.0, @g.to_f64 / 255.0, @b.to_f64 / 255.0)
    end

    def lerp(other : Color, c : Float64) : self
      Color.new(
        (rf + (other.rf - rf) * c).to_u8,
        (gf + (other.gf - gf) * c).to_u8,
        (bf + (other.bf - bf) * c).to_u8
      )
    end

    def srgb : self
      Color.new(
        (Color.srgb_channel(rf / 255) * 255).to_u8,
        (Color.srgb_channel(gf / 255) * 255).to_u8,
        (Color.srgb_channel(bf / 255) * 255).to_u8
      )
    end

    def linear : self
      Color.new(
        (Color.linear_channel(rf / 255) * 255).to_u8,
        (Color.linear_channel(gf / 255) * 255).to_u8,
        (Color.linear_channel(bf / 255) * 255).to_u8
      )
    end

    def *(c : Float64) : self
      Color.new(
        (rf * c).to_u8,
        (gf * c).to_u8,
        (bf * c).to_u8
      )
    end

    def to_a : Array(UInt8)
      [@r, @g, @b]
    end
  end
end
