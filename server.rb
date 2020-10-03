# frozen_string_literal: true

# ab -n 10000 -c 100 -p ./section_one/ostechnix.txt localhost:1234/
# head -c 100000 /dev/urandom > section_one/ostechnix_big.txt

require 'socket'
require 'uri'
require './lib/response'
require './lib/request'
MAX_EOL = 2

WEB_ROOT = './public'

CONTENT_TYPE_MAPPING = {
  'html' => 'text/html',
  'txt' => 'text/plain',
  'png' => 'image/png',
  'jpg' => 'image/jpeg'
}.freeze

DEFAULT_CONTENT_TYPE = 'application/octet-stream'

socket = TCPServer.new(ENV['HOST'], ENV['PORT'])

def content_type(filepath)
  ext = File.extname(filepath)
  CONTENT_TYPE_MAPPING[ext] || DEFAULT_CONTENT_TYPE
end

def get_file(path)
  if File.exist?(path) && !File.directory?(path)
    File.open(path, 'rb') do |file|
      socket.print "HTTP/1.1 200 OK\r\n" \
                   "Content-Type: #{content_type(file)}\r\n" \
                   "Content-Length: #{file.size}\r\n" \
                   "Connection: close\r\n"
      socket.print "\r\n"
    end
  else
    message = "File not found\n"
    socket.print "HTTP/1.1 404 Not Found\r\n" \
                 "Content-Type: text/plain\r\n" \
                 "Content-Length: #{message.size}\r\n" \
                 "Connection: close\r\n"
    socket.print "\r\n"
    socket.print message
  end
end

def handle_request(request_text, client)
  request  = Request.new(request_text)
  # puts "#{client.peeraddr[3]} #{request.path}"
  filepath = [WEB_ROOT, request.uri.path].join
  content = get_file(filepath)

  response = Response.new(code: 200, data: content)
  response.send(client)
  client.shutdown
end

def handle_connection(client)
  puts "Getting new client #{client}"
  request_text = ''
  eol_count = 0

  loop do
    buf = client.recv(1)
    puts "#{client} #{buf}"
    request_text += buf

    eol_count += 1 if buf == "\n"

    if eol_count == MAX_EOL
      handle_request(request_text, client)
      break
    end
  end
rescue StandardError => e
  puts "Error: #{e}"

  response = Response.new(code: 500, data: 'Internal Server Error')
  response.send(client)

  client.close
end

puts "Listening on #{ENV['HOST']}:#{ENV['PORT']}. Press CTRL+C to cancel."

loop do
  Thread.start(socket.accept) do |client|
    handle_connection(client)
  end
end
