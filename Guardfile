# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'livereload' do
  watch(%r{^\@client/templates/.+\.(erb|haml|slim)$})
  watch(%r{^\@server/views/.+\.(erb|haml|slim)$})  
  watch(%r{^\@server/helpers/.+\.rb})
  watch(%r{^public/.+\.(css|js|html)})
  watch(%r{^config/locales/.+\.yml})
  # Rails Assets Pipeline
  watch(%r{^assets/\w+/(.+\.(css|js|html)).*}) { |m| "/assets/#{m[1]}" }
end
