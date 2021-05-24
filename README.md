# omegga-raytracer-cr

![Sample render](https://i.imgur.com/voHg4G9.png)

This [Omegga](https://github.com/brickadia-community/omegga) plugin acts as a basic raytracer. It allows you
to capture small scenes in your Brickadia server and render them out to bricks or an image.

This project [started in JavaScript](https://github.com/voximity/omegga-raytracer), featuring raytracing
features like shadows, reflections, and basic diffuse lighting. Since, I have reimplemented the entire
raytracer in [Crystal](https://crystal-lang.org/) and added more features like refractions, lighting,
Blinn-Phong shading, meshes, materials, textures, skyboxes, and more. The above screenshot is a sample
raw output from the raytracer demonstrating some of these features.

### Practicality

This raytracer is highly experimental, and I would not suggest it for real use. It is feasible to render
small scenes of less than 1,000 bricks with a few lights, but it is highly unoptimized and does exactly
what you tell it to. Be careful rendering massive scenes.

## Installation

First, install [Crystal](https://crystal-lang.org/). Then,

`omegga install gh:voximity/raytracer-cr`

## Usage

See the original plugin above for usage instructions.

## Contributing

1. Fork it (<https://github.com/voximity/omegga-raytracer-cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [voximity](https://github.com/voximity) - creator and maintainer
- [Meshiest](https://github.com/Meshiest) - Omegga
