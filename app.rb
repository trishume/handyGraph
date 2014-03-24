require 'sinatra'
require "sinatra/streaming"
require_relative 'grapher'

helpers do
  def parse_data(data_str)
    hash = {}
    data_str.lines.each do |l|
      parts = l.split(':').map {|s| s.strip}
      next unless parts.length == 2
      x,y = parts.map {|s| s.to_f}
      hash[x] = y
    end
    hash
  end
end

get '/' do
  erb :index
end

post '/graph.pdf' do
  options = {
    save: false,
    grid: params[:grid],
    single_page: !params[:grid],
    layout: params[:landscape] ? :landscape : :portrait
  }

  data = parse_data(params[:points])
  g = Grapher.new(data, options)
  file = g.graph()

  content_type 'application/pdf'
  # attachment 'graph.pdf'
  file
end
