# Copyright (c) 2016 Michel Martens
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
require "seg"
require "http/server"

module Toro
  abstract class Router
    class Halt < Exception
    end

    def self.call(context : HTTP::Server::Context)
      new(context).call
    end

    def self.call(context : HTTP::Server::Context, path : Seg)
      new(context, path).call
    end

    def self.run(port = 8080)
      server = HTTP::Server.new(port) do |context|
        call(context)
      end

      Signal::INT.trap do
        server.close
        exit
      end

      puts "#{name} - Listening on port #{port}"
      server.listen
    end

    getter path : Seg
    getter inbox : Hash(Symbol, String)
    getter context : HTTP::Server::Context

    @inbox = Hash(Symbol, String).new

    def initialize(@context)
      @path = Seg.new(@context.request.path.as String)
    end

    def initialize(@context, @path)
    end

    def call
      status 404
      routes
    rescue Halt
    end

    def halt
      raise Halt.new
    end

    def auth_header
      context.request.headers["Authorization"]?
    end

    def basic_auth
      auth = auth_header

      if auth
        type, cred = auth.split(" ")
        user, pass = Base64.decode_string(cred).split(":")

        if type == "Basic"
          yield(user, pass) || nil
        end
      end
    end

    def default
      yield
      halt
    end

    def on(cond : Bool)
      default { yield } if cond
    end

    def on(str : String)
      on(path.consume(str)) { yield }
    end

    def on(sym : Symbol)
      on(path.capture(sym, inbox)) { yield }
    end

    def root?
      path.root?
    end

    def root
      default { yield } if root?
    end

    {% for method in %w(get put head post patch delete options) %}
      def {{method.id}}?
        context.request.method == {{method.upcase}}
      end

      def {{method.id}}
        return unless {{method.id}}?

        root do
          status 200
          yield
        end
      end
    {% end %}

    def run(app)
      app.call(context, path)
    end

    abstract def routes

    macro status
      context.response.status_code
    end

    macro status(code)
      context.response.status_code = {{code}}
    end

    macro header(name, value)
      context.response.headers[{{name}}] = {{value}}
    end

    macro content_type(type)
      context.response.content_type = {{type}}
    end

    macro write(str)
      context.response.puts({{str}})
    end

    macro render(template)
      ECR.embed "#{ {{template}} }.ecr", context.response
    end

    macro text(str)
      header "Content-Type", "text/plain"
      write {{str}}
    end

    macro html(template)
      header "Content-Type", "text/html"
      render {{template}}
    end

    macro redirect(url)
      status 302
      header "Location", url
    end
  end
end
