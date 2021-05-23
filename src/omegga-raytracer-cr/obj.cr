module OBJ
  class FileData
    getter verts = [] of Vector3
    getter faces = [] of Tuple(Int32, Int32, Int32)

    def initialize
    end

    def load(filename : String, omegga : RPCClient)
      @verts = [] of Vector3
      @faces = [] of Tuple(Int32, Int32, Int32)
      non_tri_count = 0

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
            non_tri_count += 1 if tri.size > 3
            faces << {tri[0], tri[1], tri[2]}
          end
        rescue ex
          raise "Error parsing line #{n}"
        end

        n += 1
      end

      omegga.broadcast "Poly count (non-triangles): #{non_tri_count}"
    end

    def build_tris(pos : Vector3) : Array(Triangle)
      tris = [] of Triangle
      @faces.each do |(i0, i1, i2)|
        tris << Triangle.new(verts[i0] + pos, verts[i1] + pos, verts[i2] + pos)
      end
      tris
    end

    # Centers all the verts.
    def center
      vmin = Vector3.new(@verts.min_of(&.x), @verts.min_of(&.y), @verts.min_of(&.z))
      vmax = Vector3.new(@verts.max_of(&.x), @verts.max_of(&.y), @verts.max_of(&.z))
      vcenter = (vmin + vmax) * 0.5
      @verts = @verts.map { |v| v - vcenter }
    end

    def dilate(scale : Float64)
      @verts = @verts.map { |v| v * scale }
    end

    def apply_matrix(matrix : Matrix)
      @verts = @verts.map { |v| (matrix * Matrix.new(v)).pos }
    end
  end
end
