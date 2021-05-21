class Skybox
  getter canvas : StumpyPNG::Canvas
  getter box : AxisAlignedBoxObject
  getter cell : Int32

  def initialize(file : String)
    @canvas = StumpyPNG.read(file)
    @box = AxisAlignedBoxObject.new(Vector3.new(0, 0, 0), Vector3.new(1, 1, 1), Color.new(0, 0, 0))
    @cell = @canvas.width // 4
  end

  def color_from_cubemap_raw(cx : Int32, cy : Int32, x : Int32, y : Int32)
    r, g, b = @canvas[cx * @cell + x, cy * @cell + y].to_rgb8
    Color.new(r, g, b)
  end

  def blerp(tx : Float64, ty : Float64, c00 : Vector3, c10 : Vector3, c01 : Vector3, c11 : Vector3) : Vector3
    a = c00 * (1.0 - tx) + c10 * tx
    b = c01 * (1.0 - tx) + c11 * tx
    a * (1.0 - ty) + b * ty
  end

  def color_from_cubemap(cx : Int32, cy : Int32, ix : Float64, iy : Float64) : Color
    range = (0.0..((@cell - 1.0) / @cell))

    xm = ix.clamp(range) * @cell
    ym = iy.clamp(range) * @cell

    if xm == xm.floor && ym == ym.floor
      # perfectly matches a color
      color_from_cubemap_raw(cx, cy, xm.to_i32, ym.to_i32)
    else
      # bilinear interpolate to smoothen out the polled pixel

      minx = xm.floor
      miny = ym.floor
      maxx = xm.ceil
      maxy = ym.ceil
      tl = color_from_cubemap_raw(cx, cy, minx.to_i32, miny.to_i32).to_v3
      tr = color_from_cubemap_raw(cx, cy, maxx.to_i32, miny.to_i32).to_v3
      bl = color_from_cubemap_raw(cx, cy, minx.to_i32, maxy.to_i32).to_v3
      br = color_from_cubemap_raw(cx, cy, maxx.to_i32, maxy.to_i32).to_v3
      tx = xm - minx
      ty = ym - miny

      Color.new(blerp(tx, ty, tl, tr, bl, br))
    end
  end

  def vec_to_color(vec : Vector3) : Color
    ray = Ray.new(vec * 2, -vec)
    hit = box.intersection_with_ray(ray).not_nil!
    pos = (ray.point_along(hit.near) + Vector3.new(1, 1, 1)) / 2

    ix : Float64 = pos.y
    iy : Float64 = pos.x
    cx : Int32 = 1
    cy : Int32 = 0
    if hit.normal == Vector3.new(1, 0, 0)
      # forward
      ix = pos.y
      iy = 1.0 - pos.z
      cx = 1
      cy = 1
    elsif hit.normal == Vector3.new(-1, 0, 0)
      # backward
      ix = 1.0 - pos.y
      iy = 1.0 - pos.z
      cx = 3
      cy = 1
    elsif hit.normal == Vector3.new(0, -1, 0)
      # left
      ix = pos.x
      iy = 1.0 - pos.z
      cx = 0
      cy = 1
    elsif hit.normal == Vector3.new(0, 1, 0)
      # right
      ix = 1.0 - pos.x
      iy = 1.0 - pos.z
      cx = 2
      cy = 1
    elsif hit.normal == Vector3.new(0, 0, 1)
      # top
      ix = pos.y
      iy = pos.x
      cx = 1
      cy = 0
    elsif hit.normal == Vector3.new(0, 0, -1)
      # bottom
      ix = pos.y
      iy = 1.0 - pos.x
      cx = 1
      cy = 2
    end

    color_from_cubemap(cx, cy, ix.clamp(0.0..1.0), iy.clamp(0.0..1.0))
  end
end
