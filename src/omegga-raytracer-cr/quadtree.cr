module Raytracer
  class Quadtree
    alias Branch = Color | Nil | Array(Branch)

    getter ih : Int32
    getter iw : Int32
    getter img : Array(Array(Color))
    getter tree : Branch

    def initialize(@img)
      @ih = @img.size
      @iw = @img[0].size
      @tree = [] of Branch
    end

    def width
      Math.pw2ceil(Math.max(iw, ih))
    end

    def depth
      Math.log2(width)
    end

    def get_pixel_position(imm_depth, branch_width) : {Int32, Int32}
      {(imm_depth % 2 * branch_width // 2).to_i32, ((imm_depth > 1 ? 1 : 0) * branch_width // 2).to_i32}
    end

    def create_tree
      @tree = create_branch([] of Int32)
    end

    def create_branch(depth_history : Array(Int32)) : Branch
      if (depth - 1) - depth_history.size > 0
        return [
          create_branch(depth_history + [0]),
          create_branch(depth_history + [1]),
          create_branch(depth_history + [2]),
          create_branch(depth_history + [3])
        ] of Branch
      else
        branch = [] of Branch
        4.times do |i|
          pixel_loc = [0, 0]
          depth_history.size.times do |j|
            depth_position = get_pixel_position(depth_history[j], 2 ** (depth - j))
            pixel_loc[0] += depth_position[0]
            pixel_loc[1] += depth_position[1]
          end
          final_depth_pos = get_pixel_position(i, 2)
          pixel_loc[0] += final_depth_pos[0]
          pixel_loc[1] += final_depth_pos[1]
          if pixel_loc[0] >= @iw || pixel_loc[1] >= @ih
            branch << nil
          else
            branch << @img[pixel_loc[1]][pixel_loc[0]]
          end
        end
        return branch
      end
    end

    def optimize_tree
      @tree = optimize_branch(@tree)
    end

    def optimize_branch(branch : Branch) : Branch
      # if this is a leaf, don't do anything
      return branch if branch.nil? || branch.is_a?(Color)

      # first, try to optimize child branches
      4.times do |i|
        if !branch[i].nil? && branch[i].is_a?(Array(Branch))
          # is a branch
          branch[i] = optimize_branch(branch[i])
        end
      end

      # return if any child branches still exist
      return branch if branch.any? { |b| b.is_a?(Array(Branch)) }

      # merge if leaves are identical
      first_leaf = branch[0]
      leaves_equal = true
      (1..3).each do |i|
        next unless leaves_equal
        if first_leaf == branch[i]
          next
        else
          leaves_equal = false
        end
      end

      return leaves_equal ? first_leaf : branch
    end

    def build_branch_bricks(base_pos : BRS::Vector, branch : Array(Branch), branch_depth : Array(Int32)) : Array(BRS::Brick)
      bricks = [] of BRS::Brick
      4.times do |i|
        if branch[i].nil?
          # discard this, it's not a brick
        elsif branch[i].is_a?(Array(Branch))
          # this is a branch, build its parts
          build_branch_bricks(base_pos, branch[i].as(Array(Branch)), branch_depth + [i]).each { |b| bricks << b }
        else
          # this is a leaf
          leaf_size_units = (2 ** (depth - branch_depth.size - 1)).to_i32
          pixel_pos = [0, 0]
          branch_depth.size.times do |j|
            depth_pos = get_pixel_position(branch_depth[j], 2 ** (depth - j))
            pixel_pos[0] += depth_pos[0]
            pixel_pos[1] += depth_pos[1]
          end
          final_depth_pos = get_pixel_position(i, leaf_size_units * 2)
          pixel_pos[0] += final_depth_pos[0]
          pixel_pos[1] += final_depth_pos[1]
          brick = BRS::Brick.new

          brick.asset_name_index = 0
          brick.size = BRS::Vector.new(1, leaf_size_units, leaf_size_units)
          brick.position = BRS::Vector.new(base_pos.x, base_pos.y + 20 + pixel_pos[0] * 2 + leaf_size_units, base_pos.z + @ih * 2 - (pixel_pos[1] * 2 + leaf_size_units))
          brick.color = branch[i].as(Color).to_a

          bricks << brick
        end
      end
      bricks
    end

    def build_bricks(base_pos : BRS::Vector) : Array(BRS::Brick)
      build_branch_bricks(base_pos, @tree.as(Array(Branch)), [] of Int32)
    end
  end
end
