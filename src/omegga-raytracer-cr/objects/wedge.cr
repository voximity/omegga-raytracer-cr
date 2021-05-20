class WedgeObject < MeshObject
  def self.fix_point(p : Vector3, matrix : Matrix, size : Vector3) : Vector3
    ps = p * size
    (matrix * Matrix.new(ps.x, ps.y, ps.z)).pos
  end

  def self.verts : Array(Vector3)
    [
      # top tri
      Vector3.new(1, -1, 1),
      Vector3.new(-1, 1, 1),
      Vector3.new(-1, -1, 1),

      # front tri 1
      Vector3.new(-1, -1, 1),
      Vector3.new(-1, 1, 1),
      Vector3.new(-1, -1, -1),

      # front tri 2
      Vector3.new(-1, 1, 1),
      Vector3.new(-1, 1, -1),
      Vector3.new(-1, -1, -1),

      # hypot tri 1
      Vector3.new(1, -1, 1),
      Vector3.new(1, -1, -1),
      Vector3.new(-1, 1, 1),

      # hypot tri 2
      Vector3.new(-1, 1, 1),
      Vector3.new(1, -1, -1),
      Vector3.new(-1, 1, -1),

      # left tri 1
      Vector3.new(1, -1, 1),
      Vector3.new(-1, -1, 1),
      Vector3.new(1, -1, -1),

      # left tri 2
      Vector3.new(-1, -1, 1),
      Vector3.new(-1, -1, -1),
      Vector3.new(1, -1, -1),

      # bottom tri
      Vector3.new(-1, -1, -1),
      Vector3.new(-1, 1, -1),
      Vector3.new(1, -1, -1)
    ] of Vector3
  end

  getter matrix : Matrix
  getter size : Vector3

  def initialize(@matrix, @size, color, reflectiveness = 0.0, transparency = 0.0)
    tris = WedgeObject.verts.in_groups_of(3).map do |tri_verts|
      verts = tri_verts.map { |v| WedgeObject.fix_point(v.not_nil!, @matrix, @size) }
      Triangle.new(verts[0], verts[1], verts[2])
    end

    super(tris, color, reflectiveness, transparency)
  end
end
