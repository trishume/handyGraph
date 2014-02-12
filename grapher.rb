# handyGraph by Tristan Hume
# draws PDF graphs using the science graphing rules from Bell High School

require "prawn"
require "prawn/measurement_extensions"
require "pry"

class Grapher
  PAPER_WIDTH = 21.59
  PAPER_HEIGHT = 27.94

  attr_accessor :data

  def initialize(d)
    @data = d
  end

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
        when 5 then 0.4
        else
          0.15
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
    pdf.line_width = 1.5
    pdf.line [x-s, y-s], [x+s,y+s]
    pdf.line [x-s, y+s], [x+s,y-s]
    pdf.stroke
  end

  def plot_data(pdf, x_scale, y_scale)
    puts "plotting at scale #{x_scale}, #{y_scale}"

    data.each do |x, y|
      x_paper = (x / x_scale).cm
      y_paper = (y / y_scale).cm
      draw_ex(pdf, x_paper, y_paper)
    end
  end

  def draw_axes(pdf, width, height, x_scale, y_scale)
    pdf.stroke_color "000000"
    pdf.horizontal_line 0, width.cm,  at: 0.0
    pdf.vertical_line   0, height.cm, at: 0.0
    pdf.stroke

    (0..width).each do |x|
      label = (x * x_scale).floor.to_s
      pdf.draw_text(label, :at => [x.cm - (2.0*label.length), -10], :size => 7)
    end

    (0..height).each do |y|
      label = (y * y_scale).floor.to_s
      pdf.text_box(label, :at => [-30, y.cm + 2.0], :size => 7,
        :width => 20, :align => :right)
    end
  end

  def graph(options = {})
    options = {
        layout: :landscape,
        axes: true,
        data: true,
        grid: true,
        name: "output.pdf",
        save: true,
        single_page: false
      }.merge(options)

    width = 19
    height = 25
    margin_x = (PAPER_WIDTH - width)/2.0
    margin_y = (PAPER_HEIGHT - height)/2.0

    # switch for landscape if needed
    if options[:layout] == :landscape
      width, height = height, width
      margin_x, margin_y = margin_y, margin_x
    end

    x_scale = find_scale(data.keys, width)
    y_scale = find_scale(data.values, height)
    # y_scale = 2.0
    pdf = Prawn::Document.new(:margin => [0,0,0,0], :page_layout => options[:layout])
    pdf.bounding_box([margin_x.cm, pdf.bounds.top - margin_y.cm], width: width.cm, height: height.cm) do
      # pdf.stroke_axis
      draw_grid(pdf, width, height) if options[:grid]
      pdf.start_new_page unless options[:single_page]
      plot_data(pdf, x_scale, y_scale) if options[:data]
      draw_axes(pdf, width, height, x_scale, y_scale) if options [:axes]
    end
    if options[:save]
      pdf.render_file options[:name]
    else
      pdf.render
    end
  end
end

if __FILE__ == $0
  data = {
    50 => 18,
    100 => 19,
    200 => 20,
    500 => 25,
    800 => 33,
    1000 => 49
  }

  g = Grapher.new(data)

  g.graph(name: "full.pdf")
  g.graph(name: "trace.pdf", grid: false, single_page: true)
  g.graph(name: "grid.pdf", axes: false, data: false, single_page: true)
end
