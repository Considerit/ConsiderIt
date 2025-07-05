#!/usr/bin/env ruby

require 'webrick'
require 'uri'
require 'cgi'

class SublimeHandler < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(request, response)
    # Enable CORS
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type'
    
    if request.path == '/open'
      file_path = request.query['file']
      line_number = request.query['line'] || '1'
      
      if file_path && File.exist?(file_path)
        # Use the subl command to open the file
        system("subl", "#{file_path}:#{line_number}")
        
        response.status = 200
        response['Content-Type'] = 'application/json'
        response.body = { success: true, message: "Opened #{file_path}:#{line_number}" }.to_json
      else
        response.status = 404
        response['Content-Type'] = 'application/json'
        response.body = { success: false, message: "File not found: #{file_path}" }.to_json
      end
    else
      response.status = 404
      response['Content-Type'] = 'text/plain'
      response.body = 'Not found'
    end
  end
  
  def do_OPTIONS(request, response)
    # Handle CORS preflight requests
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Content-Type'
    response.status = 200
    response.body = ''
  end
end

# Create server
server = WEBrick::HTTPServer.new(
  Port: 9999,
  Logger: WEBrick::Log.new(nil, WEBrick::Log::ERROR)  # Suppress logs
)

# Mount the handler
server.mount('/open', SublimeHandler)

# Handle shutdown gracefully
trap('INT') { server.shutdown }

puts "🚀 Sublime Text HTTP server running on http://localhost:9999"
puts "💡 Use this to open files from the color analysis reports"
puts "⭐ Press Ctrl+C to stop"

# Start the server
server.start