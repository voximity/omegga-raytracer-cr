module Raytracer
  # A Texture containing a list of more textures. Give it a block to determine when each texture is used.
  class MixedTexture < Texture
    getter textures : Array(Texture)
    getter proc : Proc(Vector3, Int32?)

    # Initialize a MixedTexture. Give it a list of Textures. The block will be called whenever a texture must be determined. It must return an index to one of the textures, or nil if no texture.
    def initialize(@textures = [] of Texture, &block : Vector3 -> Int32?)
      @proc = block
    end

    def normal_for(base_normal : Vector3, hit_pos : Vector3, ray_origin : Vector3) : Vector3
      resulting_index = @proc.call(base_normal)
      return base_normal if resulting_index.nil?
      @textures[resulting_index].normal_for(base_normal, hit_pos, ray_origin)
    end
  end
end
