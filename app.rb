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

set :root, File.dirname(__FILE__)
set :scss, :style => :compact

configure do
  PDFKit.configure do |config|
    config.wkhtmltopdf = File.join(settings.root, 'bin', 'wkhtmltopdf-amd64').to_s
    config.default_options = { :print_media_type => true }
  end
end

helpers do
 def build_pdf(name, content)
    markdown = Redcarpet.new(content)
    html = markdown.to_html

    kit = PDFKit.new(html)
    kit.stylesheets << File.join(settings.root, 'public', 'style.css').to_s
    kit.to_pdf
  end
end

get '/feedback_form.css' do
  scss :feedback_form
end

get '/feedback-form/?', :provides => 'html' do
  @form_id = Digest::SHA1.hexdigest("#{Time.now}")[0,8]
  haml :feedback_form
end

post '/feedback-form/?', :provides => 'application/pdf' do
  template = ERB.new File.new('views/_form.md.erb').read
  form = template.result(OpenStruct.new(params).instance_eval { binding })

  # Build the form
  name = "form-#{params[:form_id]}"
  content = build_pdf(name, form)

  # Return to the user
  response['Content-Length'] = content.length
  attachment "#{name}.pdf"

  content
end

error do
  "There was and error '#{env['sinatra.error'].name}'"
end
