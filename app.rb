$: << File.dirname(__FILE__)

require 'rubygems'
#require 'bundler/setup'
require 'sinatra'

require 'lib/basic_auth'
require 'lib/escape_helper'
require 'lib/render_partial'

require 'haml'
require 'sass'

require 'digest/sha1'
require 'ostruct'
require 'erb'

require 'tempfile'
require 'maruku'

set :scss, :style => :compact
set :show_exceptions, false

helpers do
  def build_pdf(name, content)
    document = Maruku.new(content)
    latex = document.to_latex_document

    Dir.mktmpdir('form') do |dir|
      # Construct document
      File.open("#{dir}/#{name}.tex", 'w+') { |file| file << latex }

      # Build up document
      2.times { system "pdflatex -output-directory #{dir} #{dir}/#{name}.tex" }

      [File.read("#{dir}/#{name}.pdf"), File.size("#{dir}/#{name}.pdf")]
    end
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
  content, length = build_pdf(name, form)

  # Return to the user
  response['Content-Length'] = length
  attachment "#{name}.pdf"

  content
end

error do
  "There was and error '#{env['sinatra.error'].name}'"
end
