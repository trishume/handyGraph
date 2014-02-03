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

PAPER_WIDTH = 21.59
PAPER_HEIGHT = 27.94

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

def draw_lines(pdf, num, length, vert)
  op = vert ? :vertical_line : :horizontal_line
  pdf.stroke_color "00abeb"
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

def draw_ex(pdf, x, y, s = 5.0)
  # puts "ex at #{x},#{y}"
  pdf.stroke_color "000000"
  pdf.line_width = 3.0
  pdf.line [x-s, y-s], [x+s,y+s]
  pdf.line [x-s, y+s], [x+s,y-s]
  pdf.stroke
end

def plot_data(pdf, data, x_scale, y_scale)
  puts "plotting at scale #{x_scale}, #{y_scale}"

  data.each do |x, y|
    x_paper = (x / x_scale).cm
    y_paper = (y / y_scale).cm
    draw_ex(pdf, x_paper, y_paper)
  end
end

def draw_axes(pdf, width, height, x_scale, y_scale)

end

def graph(data, width = 19, height = 25)
  x_scale = find_scale(data.keys, width)
  y_scale = find_scale(data.values, height)

  margin_x = (PAPER_WIDTH - width)/2.0
  margin_y = (PAPER_HEIGHT - height)/2.0
  Prawn::Document.generate("output.pdf", :margin => [0,0,0,0]) do |pdf|
    pdf.bounding_box([margin_x.cm, (PAPER_HEIGHT - margin_y).cm], width: width.cm, height: height.cm) do
      # pdf.stroke_axis
      draw_grid(pdf, width, height)
      plot_data(pdf, data, x_scale, y_scale)
    end
  end
end

graph(data)
