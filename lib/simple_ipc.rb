#!/usr/bin/env ruby

require "yaml"
require "socket"
require "timeout"

class SimpleIPC

  LOCALHOST   = "127.0.0.1" ;
  LENGTH_CODE = 'N' ;
  LENGH_SIZE  = [0].pack(LENGTH_CODE).size ;

  attr_accessor :cfg ;
  
  def initialize( args = {} )
    @cfg = { :port => 5000, :host => LOCALHOST, :timeout => 0 } ;
    @cfg.merge! args ;
    @socket = UDPSocket.new ;
  end
  
  # send something to the server
  # @param [Object] something an object
  def send(something)
    payload = YAML.dump(something) ;
    length = [payload.size].pack(LENGTH_CODE) ;
    @socket.connect @cfg[:host], @cfg[:port] ;
    @socket.print length ;
    @socket.print payload ;
    return payload ;
  end
  
  def listen
    @socket.bind(LOCALHOST,@cfg[:port])
  end
  
  def close
    @socket.close
  end
  
  def get
    result = nil
    begin
      if @cfg[:timeout] > 0 then
        Timeout::timeout(@cfg[:timeout]) do |to|
          result = get_
        end
      else
        result = get_
      end
    rescue Timeout::Error
      result = nil 
    end
    return result
  end
  
  #private
  def get_
    msg, sender = @socket.recvfrom(LENGH_SIZE)
    length = msg.unpack(LENGTH_CODE)[0]
    msg, sender = @socket.recvfrom(length)
    return YAML.load(msg)
  end
  
end


if $0 == __FILE__ then
  if ARGV[0] == "server" then
    from_client = SimpleIPC . new :port => 5000, :timeout => 10
    from_client . listen
    p from_client.get
  else
    obj = { :a => 1, :b => [1,2,3,4,"pippo", { :mona => "ti" } ] }
    to_server = SimpleIPC . new :port => 5000
    to_server.send obj
    to_server.close
  end
end