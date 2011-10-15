$: << File.dirname(__FILE__)

require 'bundler/setup'
require 'sinatra'

require 'lib/basic_auth'
require 'lib/escape_helper'
require 'lib/render_partial'

require 'haml'
require 'sass'

require 'digest/sha1'
require 'ostruct'
require 'erb'

require 'redcarpet'
require 'pdfkit'

require 'twitter'

set :root, File.dirname(__FILE__)
set :scss, :style => :compact
set :hashtag, "doc475"

configure do
  PDFKit.configure do |config|
    config.wkhtmltopdf = File.join(settings.root, 'bin', 'wkhtmltopdf-amd64').to_s
    config.default_options = { :print_media_type => true }
  end
end

helpers do
  def tweets(tag, page)
    search = Twitter::Search.new
    search.hashtag(tag).page(page)
    return search.fetch, search
  end

  def template(name, data)
    template = ERB.new File.new(name).read
    template.result(OpenStruct.new(data).instance_eval { binding })
  end

  def to_pdf(content)
    markdown = Redcarpet.new(content)
    html = markdown.to_html

    kit = PDFKit.new(html)
    kit.stylesheets << File.join(settings.root, 'public', 'pdf.css').to_s
    pdf = kit.to_pdf
  end

  def attach(name, content)
    response['Content-Length'] = content.length
    attachment name
    content
  end

  def shorten(string, count = 40)
		shortened = string[0, count]
    shortened += '...' if string.length > count
    shortened
  end

  def urlize(text)
    text.gsub!(URI.regexp('http')) { |m|
      url = Twitter.resolve(m)
      "<a href='#{m}'>#{url.nil? ? m : url[m]}</a>"
    }
    text.gsub!(/@(\w+)/, "<a href='https://twitter.com/\\1'>@\\1</a>")
    text.gsub!(/#(\w+)/, "<a href='https://twitter.com/#!/search/%23\\1'>\#\\1</a>")
    text
  end
end

get '/style.css' do
  scss :style
end

get '/' do
  haml :index
end

get '/notes', :provides => 'html' do
  page = params[:page].nil? ? 1 : params[:page].to_i
  @tweets, search = tweets(settings.hashtag, page)

  @previous = page - 1 if page > 1
  @next = page + 1 if search.next_page?

  @form_id = Digest::SHA1.hexdigest("#{Time.now}")[0,8]
  haml :notes
end

post '/notes', :provides => 'application/pdf' do
  # Build the notes
  page = params[:page].nil? ? 1 : params[:page].to_i
  tweets, search = tweets(settings.hashtag, page)
  text = template('views/_notes.md.erb', { :tweets => tweets })

  # Return to the user
  attach("notes-#{params[:form_id]}.pdf", to_pdf(text))
end

get '/diary/?', :provides => 'html' do
  @form_id = Digest::SHA1.hexdigest("#{Time.now}")[0,8]
  haml :diary
end

post '/diary/?', :provides => 'application/pdf' do
  # Build the diary
  text = template('views/_diary.md.erb', params)

  # Return to the user
  attach("diary-#{params[:form_id]}.pdf", to_pdf(text))
end

error do
  "There was and error '#{env['sinatra.error'].name}'"
end
