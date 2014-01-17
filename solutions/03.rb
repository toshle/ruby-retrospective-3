module Graphics
  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
      @canvas = Array.new(height) { Array.new(width, false) }
    end

    def set_pixel(x, y)
      @canvas[y][x] = true
    end

    def pixel_at?(x, y)
      @canvas[y][x]
    end

    def draw(figure)
      figure.draw(self)
    end

    def render_as(renderer)
      renderer.render(@canvas)
    end
  end

  module Renderers
    class Ascii
      def self.render(canvas)
        canvas.map(&:join).join("\n").gsub('true', '@').gsub('false', '-')
      end
    end

    class Html
      HEADER = '  <!DOCTYPE html>
                    <html>
                    <head>
                      <title>Rendered Canvas</title>
                      <style type="text/css">
                        .canvas {
                          font-size: 1px;
                          line-height: 1px;
                        }
                        .canvas * {
                          display: inline-block;
                          width: 10px;
                          height: 10px;
                          border-radius: 5px;
                        }
                        .canvas i {
                          background-color: #eee;
                        }
                        .canvas b {
                          background-color: #333;
                        }
                      </style>
                    </head>
                    <body>
                      <div class="canvas">'

      FOOTER = '    </div>
                    </body>
                    </html>'

      def self.render(canvas)
        HEADER +
        canvas.map(&:join).join("<br>").gsub("true", "<b></b>")
              .gsub("false", "<i></i>") + FOOTER
      end
    end
  end

  class Point
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def ==(other)
      @x == other.x and @y == other.y
    end

    def draw(canvas)
      canvas.set_pixel @x, @y
    end

    def hash
      @x.hash + y
    end

    def eql?(other)
      hash == other.hash
    end
  end

  class Line
    attr_reader :from, :to

    def initialize(from, to)
      @from = from
      @to = to
    end

    def ==(other)
      @from == other.from and @to == other.to
    end

    def hash
      @from.hash + @to.hash
    end

    def eql?(other)
      hash == other.hash
    end

    def draw(canvas)
      copy_coordinates
      while @from_x != @to_x or @from_y != @to_y
        canvas.set_pixel(@from_x, @from_y)
        move_to_next_point
      end
      canvas.set_pixel(@from_x, @from_y)
    end

    private

    def move_to_next_point
      if 2 * @error >= -@delta_y
        @error -= @delta_y
        @from_x += @step_x
      end
      if 2 * @error < @delta_x
        @error += @delta_x
        @from_y += @step_y
      end
    end

    def copy_coordinates
      @from_x = @from.x
      @to_x = @to.x
      @to_y = @to.y
      @from_y = @from.y
      calculate_error
    end

    def calculate_error
      @delta_x = (@to_x - @from_x).abs
      @delta_y = (@to_y - @from_y).abs
      @step_x = @from_x < @to_x ? 1 : -1
      @step_y = @from_y < @to_y ? 1 : -1
      @error = @delta_x - @delta_y
    end
  end

  class Rectangle
    attr_reader :left, :right

    def initialize(left, right)
      @left = left
      @right = right
    end

    def top_left
      Point.new([@left.x, @right.x].min, [@left.y, @right.y].min)
    end

    def top_right
      Point.new([@left.x, @right.x].max, [@left.y, @right.y].min)
    end

    def bottom_right
      Point.new([@left.x, @right.x].max, [@left.y, @right.y].max)
    end

    def bottom_left
      Point.new([@left.x, @right.x].min, [@left.y, @right.y].max)
    end

    def ==(other)
      (@left == other.left and @right == other.right) or
      (@left == other.right and @right == other.left)
    end

    def hash
      @left.hash + @right.hash
    end

    def eql?(other)
      hash == other.hash
    end

    def draw(canvas)
      Line.new(Point.new(@left.x, @left.y), Point.new(@left.x, @right.y)).draw canvas
      Line.new(Point.new(@left.x, @right.y), Point.new(@right.x, @right.y)).draw canvas
      Line.new(Point.new(@right.x, @right.y), Point.new(@right.x, @left.y)).draw canvas
      Line.new(Point.new(@left.x, @left.y), Point.new(@right.x, @left.y)).draw canvas
    end
  end
end