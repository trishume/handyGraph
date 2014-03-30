# handyGraph by Tristan Hume
# draws PDF graphs using the science graphing rules from Bell High School

require "prawn"
require "prawn/measurement_extensions"
require 'linefit'
# require "pry"

class Grapher
  PAPER_WIDTH = 21.59
  PAPER_HEIGHT = 27.94

  attr_accessor :data

  def initialize(d, options = {})
    @data = d
    @options = {
        layout: :landscape,
        axes: true,
        data: true,
        grid: true,
        name: "output.pdf",
        save: true,
        single_page: false,
        fit_line: true,
        offset_x: 0.0
      }.merge(options)

    calc_attrs
  end

  def apply_exponent(n)
    new_data = {}
    @data.each do |k,v|
      new_data[k**n] = v
    end
    @data = new_data

    calc_attrs
  end

  def calc_attrs
    @width = 19
    @height = 25
    @margin_x = (PAPER_WIDTH - @width)/2.0 + @options[:offset_x]
    @margin_y = (PAPER_HEIGHT - @height)/2.0

    # switch for landscape if needed
    if @options[:layout] == :landscape
      @width, @height = @height, @width
      @margin_x, @margin_y = @margin_y, @margin_x
    end

    @x_scale = find_scale(data.keys, @width)
    @y_scale = find_scale(data.values, @height)
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

  def draw_grid(pdf)
    draw_lines(pdf, @width, @height, true)
    draw_lines(pdf, @height, @width, false)
  end

  def draw_ex(pdf, x, y, s = 5.0)
    # puts "ex at #{x},#{y}"
    pdf.stroke_color "000000"
    pdf.line_width = 1.5
    pdf.line [x-s, y-s], [x+s,y+s]
    pdf.line [x-s, y+s], [x+s,y-s]
    pdf.stroke
  end

  def plot_data(pdf)
    puts "plotting at scale #{@x_scale}, #{@y_scale}"

    data.each do |x, y|
      x_paper = (x / @x_scale).cm
      y_paper = (y / @y_scale).cm
      draw_ex(pdf, x_paper, y_paper)
    end
  end

  def axis_label(n, scale)
    # puts "Label for #{n} - #{scale}"
    if scale < 1.0
      (n * scale).round(3).to_s
    else
      (n * scale).floor.to_s
    end
  end

  def draw_axes(pdf)
    pdf.stroke_color "000000"
    pdf.horizontal_line 0, @width.cm,  at: 0.0
    pdf.vertical_line   0, @height.cm, at: 0.0
    pdf.stroke

    (0..@width).each do |x|
      label = axis_label(x,@x_scale)
      pdf.draw_text(label, :at => [x.cm - (2.0*label.length), -10], :size => 7)
    end

    (0..@height).each do |y|
      pdf.text_box(axis_label(y,@y_scale), :at => [-30, y.cm + 2.0], :size => 7,
        :width => 20, :align => :right)
    end
  end

  def calc_fit_line
    line_fit = LineFit.new
    line_fit.setData(data.keys,data.values)
    line_fit
  end

  def draw_fit_line(pdf)
    line_fit = calc_fit_line
    intercept, slope = line_fit.coefficients
    puts "Calculated fit of #{slope}*x + #{intercept}"

    x_intercept = (-intercept/slope)
    start = [[0.0,x_intercept/@x_scale].max.cm, [(intercept / @y_scale),0.0].max.cm]
    finish_y = slope*(@width*@x_scale) + intercept
    finish = [@width.cm,(finish_y/@y_scale).cm]

    pdf.stroke_color "000000"
    pdf.line_width = 2.0
    pdf.line start, finish
    pdf.stroke

    # draw stroke equation
    label = "Line of Best Fit:\ny = #{slope.round(3)}*x+#{intercept.round(3)}\nr-squared: #{line_fit.rSquared.round(3)}"
    pdf.text_box(label, :at => [20.0, @height.cm], :size => 18,
        :width => 6.cm, :align => :left)
  end

  def graph
    # @y_scale = 2.0
    pdf = Prawn::Document.new(:margin => [0,0,0,0], :page_layout => @options[:layout])
    pdf.bounding_box([@margin_x.cm, pdf.bounds.top - @margin_y.cm], width: @width.cm, height: @height.cm) do
      # pdf.stroke_axis
      draw_grid(pdf) if @options[:grid]
      pdf.start_new_page unless @options[:single_page]
      plot_data(pdf) if @options[:data]
      draw_axes(pdf) if @options [:axes]
      draw_fit_line(pdf) if @options[:fit_line]
    end
    if @options[:save]
      pdf.render_file @options[:name]
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

  g = Grapher.new(data, name: "trace.pdf", grid: false, single_page: true)
  # g.apply_exponent(2)
  g.graph()
  # g.graph(name: "trace.pdf", grid: false, single_page: true)
  # g.graph(name: "grid.pdf", axes: false, data: false, single_page: true)
end
