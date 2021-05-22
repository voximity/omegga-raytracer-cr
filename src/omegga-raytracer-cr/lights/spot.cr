class SpotLight < PositionLight
  getter direction : Vector3
  getter outer : Float64
  getter inner : Float64

  def initialize(position, @direction, outer, inner, color, intensity)
    super(position, color, intensity)

    @outer = Math.cos(outer)
    @inner = Math.cos(inner)
  end

  def intensity_at(vec : Vector3) : Float64
    light_dir = (@position - vec).normalize
    theta = light_dir.dot(-@direction)
    epsilon = @inner - @outer
    int_a = ((theta - @outer) / epsilon).clamp(0.0..1.0)

    dist = (@position - vec).magnitude
    (int_a * @intensity) / (dist / 100.0) ** 2
  end
end
