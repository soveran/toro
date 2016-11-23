module Toro
  def self.drive(router)
    Driver.new(router)
  end

  def self.drive(router, method, path)
    drive(router).call(method, path)
  end

  class Driver
    getter router : Toro::Router.class

    def initialize(@router)
    end

    def call(req : HTTP::Request)
      io  = IO::Memory.new
      res = HTTP::Server::Response.new(io)

      @router.call(HTTP::Server::Context.new(req, res))

      res.close

      HTTP::Client::Response.from_io(io.rewind, decompress: false)
    end

    def call(method : String, path : String)
      call(HTTP::Request.new(method, path))
    end
  end
end