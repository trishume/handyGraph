# handyGraph by Tristan Hume
# draws PDF graphs using the science graphing rules from Bell High School

require "prawn"
require "prawn/measurement_extensions"
require "pry"

data = {
  50 => 18,
  100 => 19,
  200 => 20,
  500 => 25,
  800 => 33,
  1000 => 49
}

def round_scale(exact_scale)
  exp = Math.log10(exact_scale).floor
  poss = [1,2,5,10].map {|x| x*(10**exp)}

  poss.find {|x| x >= exact_scale}.to_f
end

# Returns a good scale for the array of numbers given
# for a graph paper with a certain number of segments
def find_scale(nums, segments)
  m = nums.max
  exact_scale = m / segments.to_f

  round_scale(exact_scale)
end

def scales(data, size)
  x_scale = find_scale(data.keys, size.first)
  y_scale = find_scale(data.values, size.last)
  [x_scale, y_scale]
end

def draw_lines(pdf, num, length, vert)
  op = vert ? :vertical_line : :horizontal_line
  (num * 10 + 1).times do |x|
    pdf.line_width = case x % 10
      when 0 then 0.8
      when 5 then 0.5
      else
        0.2
    end
    pdf.send(op, 0, length.cm, :at => (x/10.0).cm)
    pdf.stroke
  end
end

def draw_grid(pdf, width, height)
  draw_lines(pdf, width, height, true)
  draw_lines(pdf, height, width, false)
end

def graph(data, width = 19, height = 25)
  scal = scales(data, size)


  Prawn::Document.generate("output.pdf", :margin => [0,0,0,0]) do |pdf|
    pdf.bounding_box([(1.3).cm, (26.47).cm], width: width.cm, height: height.cm) do
      # pdf.stroke_axis
      draw_grid(pdf, width, height)
    end
  end
end

graph(data)
