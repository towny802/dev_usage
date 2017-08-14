require 'sinatra'
set :port, 3000
set :static, true
set :public_folder, "static"
set :views, "views"

require 'rubygems';
require 'nokogiri';
require 'json'

routes = {}
ip_list = Array.new

@conf = Nokogiri::XML(File.read(File.dirname(__FILE__) +'/dir.xml'));
@conf.xpath("//route").each do |route|
  routes[route.xpath('url').text] = route.xpath('file').text;
end

@conf.xpath("//ip").each do |addr|
  ip_list << addr.text
end

before do
  if !ip_list.include?(request.ip)
    halt
  end
end

get '/' do
  routes.to_json
end

get '/data' do
  send_file File.dirname(__FILE__)+'/graph.html'
end

get '/:route' do
  File.read(routes[params[:route]]).to_json
end

hist_t = @conf.xpath('//hist').text.to_i
timer = @conf.xpath('//timer').text.to_i

x = lambda { |r|
  hist_ary = []
  Thread.new {
    hist_t.times do |i|
      sleep timer;
      hist_ary << File.read(File.dirname(__FILE__)+'/'+r[1]);
      #puts ass_ary.to_s;
    end
    while true do
      sleep timer;
      hist_ary.shift;
      hist_ary << File.read(File.dirname(__FILE__)+'/'+r[1]);
    end
  }
  hist_ary
}

hist_list = Hash.new(routes.length-1)

routes.each do |i|
  hist_list[i[0]] = x.call(i)
end

get '/hist/:route' do
  #{:data=> hist_list[params[:route]]}.to_json
  hist_list[params[:route]].to_json
  #hist_list.to_json
end
