class CylinderObject < SceneObject
  getter pa : Vector3
  getter pb : Vector3
  getter radius : Float64

  def initialize(@pa, @pb, @radius, color, reflectiveness = 0.0, transparency = 0.0)
    super(color, reflectiveness, transparency)
  end

  def intersection_with_ray(ray : Ray) : Hit?
    ba = @pb - @pa
    oc = ray.origin - @pa
    baba = ba.dot(ba)
    bard = ba.dot(ray.direction)
    baoc = ba.dot(oc)
    k2 = baba - bard ** 2
    k1 = baba * oc.dot(ray.direction) - baoc * bard
    k0 = baba * oc.dot(oc) - baoc ** 2 - @radius ** 2 * baba
    h = k1 ** 2 - k2 * k0
    return nil if h < 0
    h = Math.sqrt h
    t = (-k1 - h) / k2
    return nil if t < 0
    y = baoc + t * bard
    return Hit.new(t, t, oc + (ray.direction * t) - (ba * y * (1 / baba)) * (1 / @radius)) if y > 0 && y < baba
    t = ((y < 0 ? 0 : baba) - baoc) / bard
    return Hit.new(t, t, ba * (y == 0 ? 0 : (y > 0 ? 1 : -1)) * (1 / baba)) if (k1 + k2 * t).abs < h
    nil
  end

  def internal_raycast(ray : Ray) : NamedTuple(t: Float64, normal: Vector3)?
    nil # this cylinder implementation is cringe and doesn't return a tfar
  end
end
