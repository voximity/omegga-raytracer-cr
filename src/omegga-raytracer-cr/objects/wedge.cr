module Raytracer
  class WedgeObject < MeshObject
    def self.build_wedge_tris(size : Vector3, matrix : Matrix)
      x = size.x
      y = size.y
      z = size.z
      lip = 2.0

      verts = [
        # wedge tri 1
        Vector3.new(-x, -y, z),
        Vector3.new(x, -y, -z + lip),
        Vector3.new(x, y, -z + lip),

        # wedge tri 2
        Vector3.new(x, y, -z + lip),
        Vector3.new(-x, y, z),
        Vector3.new(-x, -y, z),

        # wedge lip tri 1
        Vector3.new(x, -y, -z + lip),
        Vector3.new(x, -y, -z),
        Vector3.new(x, y, -z + lip),

        # wedge lip tri 2
        Vector3.new(x, -y, -z),
        Vector3.new(x, y, -z),
        Vector3.new(x, y, -z + lip),

        # right triangle tri
        Vector3.new(-x, y, z),
        Vector3.new(x, y, -z + lip),
        Vector3.new(-x, y, -z + lip),

        # right bottom tri 1
        Vector3.new(-x, y, -z),
        Vector3.new(-x, y, -z + lip),
        Vector3.new(x, y, -z),

        # right bottom tri 2
        Vector3.new(x, y, -z),
        Vector3.new(-x, y, -z + lip),
        Vector3.new(x, y, -z + lip),

        # left triangle tri
        Vector3.new(-x, -y, z),
        Vector3.new(-x, -y, -z + lip),
        Vector3.new(x, -y, -z + lip),

        # left bottom tri 1
        Vector3.new(-x, -y, -z),
        Vector3.new(x, -y, -z),
        Vector3.new(-x, -y, -z + lip),

        # left bottom tri 2
        Vector3.new(x, -y, -z),
        Vector3.new(x, -y, -z + lip),
        Vector3.new(-x, -y, -z + lip),

        # back tri 1
        Vector3.new(-x, -y, z),
        Vector3.new(-x, y, z),
        Vector3.new(-x, -y, -z),

        # back tri 2
        Vector3.new(-x, y, z),
        Vector3.new(-x, y, -z),
        Vector3.new(-x, -y, -z),

        # bottom tri 1
        Vector3.new(-x, -y, -z),
        Vector3.new(x, -y, -z),
        Vector3.new(-x, y, -z),

        # bottom tri 2
        Vector3.new(x, y, -z),
        Vector3.new(-x, y, -z),
        Vector3.new(x, -y, -z)
      ] of Vector3

      verts.map! { |v| apply_matrix(v, matrix) }
      triangulate(verts)
    end

    def self.build_ramp_tris(size : Vector3, matrix : Matrix, flipped : Bool = false)
      x = size.x
      y = size.y
      z = size.z
      lip = 2.0

      verts = [
        # wedge tri 1
        Vector3.new(-x + 10.0, -y, z),
        Vector3.new(x, -y, -z + lip),
        Vector3.new(x, y, -z + lip),

        # wedge tri 2
        Vector3.new(x, y, -z + lip),
        Vector3.new(-x + 10.0, y, z),
        Vector3.new(-x + 10.0, -y, z),

        # wedge lip tri 1
        Vector3.new(x, -y, -z + lip),
        Vector3.new(x, -y, -z),
        Vector3.new(x, y, -z + lip),

        # wedge lip tri 2
        Vector3.new(x, -y, -z),
        Vector3.new(x, y, -z),
        Vector3.new(x, y, -z + lip),

        # right triangle tri
        Vector3.new(-x + 10.0, y, z),
        Vector3.new(x, y, -z + lip),
        Vector3.new(-x + 10.0, y, -z + lip),

        # right bottom tri 1
        Vector3.new(-x + 10.0, y, -z),
        Vector3.new(-x + 10.0, y, -z + lip),
        Vector3.new(x, y, -z),

        # right bottom tri 2
        Vector3.new(x, y, -z),
        Vector3.new(-x + 10.0, y, -z + lip),
        Vector3.new(x, y, -z + lip),

        # left triangle tri
        Vector3.new(-x + 10.0, -y, z),
        Vector3.new(-x + 10.0, -y, -z + lip),
        Vector3.new(x, -y, -z + lip),

        # left bottom tri 1
        Vector3.new(-x + 10.0, -y, -z),
        Vector3.new(x, -y, -z),
        Vector3.new(-x + 10.0, -y, -z + lip),

        # left bottom tri 2
        Vector3.new(x, -y, -z),
        Vector3.new(x, -y, -z + lip),
        Vector3.new(-x + 10.0, -y, -z + lip),

        # back tri 1
        Vector3.new(-x, -y, z),
        Vector3.new(-x, y, z),
        Vector3.new(-x, -y, -z),

        # back tri 2
        Vector3.new(-x, y, z),
        Vector3.new(-x, y, -z),
        Vector3.new(-x, -y, -z),

        # bottom tri 1
        Vector3.new(-x, -y, -z),
        Vector3.new(x, -y, -z),
        Vector3.new(-x, y, -z),

        # bottom tri 2
        Vector3.new(x, y, -z),
        Vector3.new(-x, y, -z),
        Vector3.new(x, -y, -z),

        # top tri 1
        Vector3.new(-x, -y, z),
        Vector3.new(-x + 10.0, -y, z),
        Vector3.new(-x, y, z),

        # top tri 2
        Vector3.new(-x + 10.0, -y, z),
        Vector3.new(-x + 10.0, y, z),
        Vector3.new(-x, y, z),

        # right tri 1
        Vector3.new(-x, y, -z),
        Vector3.new(-x, y, z),
        Vector3.new(-x + 10.0, y, -z),

        # right tri 2
        Vector3.new(-x + 10.0, y, -z),
        Vector3.new(-x, y, z),
        Vector3.new(-x + 10.0, y, z),

        # left tri 1
        Vector3.new(-x, -y, -z),
        Vector3.new(-x + 10.0, -y, -z),
        Vector3.new(-x, -y, z),

        # left tri 2
        Vector3.new(-x + 10.0, -y, -z),
        Vector3.new(-x + 10.0, -y, z),
        Vector3.new(-x, -y, z)
      ] of Vector3

      verts.map! do |v|
        if flipped
          v *= Vector3.new(1, 1, -1)
        end
        apply_matrix(v, matrix)
      end

      if flipped # god this is cursed
        verts = verts.in_groups_of(3).map { |tv| vs = tv.map(&.not_nil!); vs[0].z == vs[1].z && vs[1].z == vs[2].z ? vs : [vs[0], vs[2], vs[1]] }.flatten
      end

      triangulate(verts)
    end

    def self.apply_matrix(vert : Vector3, matrix : Matrix) : Vector3
      (matrix * Matrix.new(vert.x, vert.y, vert.z)).pos
    end

    def self.triangulate(verts : Array(Vector3)) : Array(Triangle)
      verts.in_groups_of(3).map do |tri_verts|
        verts = tri_verts.map(&.not_nil!)
        Triangle.new(verts[0], verts[1], verts[2])
      end
    end

    def initialize(size : Vector3, matrix : Matrix, material : Material, &tri_builder : Vector3, Matrix -> Array(Triangle))
      super(tri_builder.call(size, matrix), material)
    end
  end
end
