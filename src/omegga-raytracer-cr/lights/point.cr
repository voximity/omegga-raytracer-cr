class PointLight < PositionLight
  def initialize(position, color, intensity)
    super(position, color, intensity)
  end

  def intensity_at(vec : Vector3) : Float64
    dist = (@position - vec).magnitude
    @intensity / (dist / 100.0) ** 2
  end
end
