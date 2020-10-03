# frozen_string_literal: true

require 'socket'
require 'porebrick/request'
require 'porebrick/response'
require 'porebrick/version'

module Porebrick
  class Error < StandardError; end
  # Your code goes here...

  def self.run
    socket = TCPServer.new(ENV['HOST'], ENV['PORT'])
    puts "Listening on #{ENV['HOST']}:#{ENV['PORT']}. Press CTRL+C to cancel."

    loop.do
    Thread.start(socket.accept) do |client|
      handler = Porebrick::Handler.new(client)
      handler.handle_connection
    end
  end
end
