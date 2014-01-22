module Graphics
  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width  = width
      @height = height
      @canvas = {}
    end

    def set_pixel(x, y)
      @canvas[[x, y]] = true
    end

    def pixel_at?(x, y)
      @canvas[[x, y]]
    end

    def draw(figure)
      figure.draw(self)
    end

    def render_as(renderer)
      renderer.new(self).render
    end
  end

  module Renderers
    class Base
      attr_reader :canvas

      def initialize(canvas)
        @canvas = canvas
      end

      def render
        raise NotImplementedError
      end
    end

    class Ascii < Base
      def render
        pixels = 0.upto(canvas.height.pred).map do |y|
          0.upto(canvas.width.pred).map do |x|
            fill_pixel(x, y)
          end
        end
        pixels.map(&:join).join("\n")
      end

      private

      def fill_pixel(x, y)
        canvas.pixel_at?(x, y) ? '@' : '-'
      end
    end

    class Html < Ascii
      TEMPLATE = '<!doctypehtml>
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
          <div class="canvas">
            %s
          </div>
        </body>
        </html>
      '.freeze

      def render
        pixels = 0.upto(canvas.height.pred).map do |y|
          0.upto(canvas.width.pred).map do |x|
            fill_pixel(x, y)
          end
        end
        TEMPLATE % pixels.map(&:join).join("<br>")
      end

      private

      def fill_pixel(x, y)
        canvas.pixel_at?(x, y) ? '<b></b>' : '<i></i>'
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

    alias eql? ==

    def draw(canvas)
      canvas.set_pixel @x, @y
    end

    def hash
      @x.hash + y
    end
  end

  class Line
    attr_reader :from, :to

    def initialize(from, to)
      if from.x > to.x or (from.x == to.x and from.y > to.y)
        @from = to
        @to   = from
      else
        @from = from
        @to   = to
      end
    end

    def ==(other)
      @from == other.from and @to == other.to
    end

    alias eql? ==

    def hash
      @from.hash + @to.hash
    end

    def draw(canvas)
      BresenhamRasterization.new(from.x, from.y, to.x, to.y).draw(canvas)
    end

    class BresenhamRasterization
      def initialize(from_x, from_y, to_x, to_y)
        @from_x, @from_y = from_x, from_y
        @to_x, @to_y     = to_x, to_y
      end

      def draw(canvas)
        initialize_from_and_to_coordinates
        rotate_coordinates_by_ninety_degrees if steep_slope?
        swap_from_and_to if @drawing_from_x > @drawing_to_x

        draw_line_pixels_on canvas
      end

      def steep_slope?
        (@to_y - @from_y).abs > (@to_x - @from_x).abs
      end

      def initialize_from_and_to_coordinates
        @drawing_from_x, @drawing_from_y = @from_x, @from_y
        @drawing_to_x, @drawing_to_y     = @to_x, @to_y
      end

      def rotate_coordinates_by_ninety_degrees
        @drawing_from_x, @drawing_from_y = @drawing_from_y, @drawing_from_x
        @drawing_to_x, @drawing_to_y     = @drawing_to_y, @drawing_to_x
      end

      def swap_from_and_to
        @drawing_from_x, @drawing_to_x = @drawing_to_x, @drawing_from_x
        @drawing_from_y, @drawing_to_y = @drawing_to_y, @drawing_from_y
      end

      def error_delta
        delta_x = @drawing_to_x - @drawing_from_x
        delta_y = (@drawing_to_y - @drawing_from_y).abs

        delta_y.to_f / delta_x
      end

      def vertical_drawing_direction
        @drawing_from_y < @drawing_to_y ? 1 : -1
      end

      def draw_line_pixels_on(canvas)
        @error = 0.0
        @y     = @drawing_from_y

        @drawing_from_x.upto(@drawing_to_x).each do |x|
          set_pixel_on canvas, x, @y
          calculate_next_y_approximation
        end
      end

      def calculate_next_y_approximation
        @error += error_delta

        if @error >= 0.5
          @error -= 1.0
          @y += vertical_drawing_direction
        end
      end

      def set_pixel_on(canvas, x, y)
        if steep_slope?
          canvas.set_pixel y, x
        else
          canvas.set_pixel x, y
        end
      end
    end
  end

  class Rectangle
    attr_reader :left, :right

    def initialize(left, right)
      if left.x > right.x or (left.x == right.x and left.y > right.y)
        @left  = right
        @right = left
      else
        @left  = left
        @right = right
      end
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
      top_left == other.top_left and bottom_right == other.bottom_right
    end

    alias eql? ==

    def hash
      @left.hash + @right.hash
    end

    def draw(canvas)
      [
        Line.new(top_left, top_right),
        Line.new(top_right, bottom_right),
        Line.new(bottom_right, bottom_left),
        Line.new(bottom_left, top_left),
      ].each { |line| line.draw canvas }
    end
  end
end