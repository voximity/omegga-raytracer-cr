module OBJ
  class FileData
    getter verts = [] of Vector3
    getter faces = [] of Tuple(Int32, Int32, Int32)
    getter tris = [] of Triangle

    def initialize
    end

    def load(filename : String)
      @verts = [] of Vector3
      @faces = [] of Tuple(Int32, Int32, Int32)

      n = 1
      File.each_line(filename) do |line|
        next if line.starts_with? '#'

        begin
          if line.starts_with? "v "
            # vertex definition
            nums = line[2..].split(' ')
            verts << Vector3.new(nums[0].to_f64, nums[1].to_f64, nums[2].to_f64)
          elsif line.starts_with? "f "
            # face definition (triangle)
            tri = line[2..].split(' ').map { |v| v.split('/')[0].to_i32 - 1 }
            faces << {tri[0], tri[1], tri[2]}
          end
        rescue ex
          raise "Error parsing line #{n}"
        end

        n += 1
      end
    end

    def build_tris
      @tris = [] of Triangle
      @faces.each do |(i0, i1, i2)|
        tris << Triangle.new(verts[i0], verts[i1], verts[i2])
      end
    end

    def dilate(scale : Float64)
      @verts = @verts.map { |v| v * scale }
    end

    def shift(vec : Vector3)
      @verts = @verts.map { |v| v + vec }
    end
  end
end
