# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'livereload' do
  watch(%r{^public/.+\.(css|js|html)})
  # Rails Assets Pipeline
  watch(%r{^\@client/assets/\w+/(.+\.(css|js|html)).*}) { |m| "/assets/#{m[1]}" }
end
