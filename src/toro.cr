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
    def self.call(context : HTTP::Server::Context)
      new(context).call
    end

    def self.call(context : HTTP::Server::Context, path : Seg)
      new(context, path).call
    end

    def self.run(*args)
      run(*args) {}
    end

    def self.run(port, *args, &block)
      server = HTTP::Server.new(*args) do |context|
        call(context)
      end

      Signal::INT.trap do
        server.close
        exit
      end

      yield server

      puts "#{name} - Listening on port #{port}"
      server.listen(port)
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

    def on?(cond : Bool)
      cond
    end

    def on?(str : String)
      path.consume(str)
    end

    def on?(sym : Symbol)
      path.capture(sym, inbox)
    end

    def root?
      path.root?
    end

    {% for method in %w(get put head post patch delete options) %}

      def {{method.id}}?
        context.request.method == {{method.upcase}}
      end

    {% end %}

    macro get
      root { status 200; {{yield}} } if get?
    end

    macro put
      root { status 200; {{yield}} } if put?
    end

    macro head
      root { status 200; {{yield}} } if head?
    end

    macro post
      root { status 200; {{yield}} } if post?
    end

    macro patch
      root { status 200; {{yield}} } if patch?
    end

    macro delete
      root { status 200; {{yield}} } if delete?
    end

    macro options
      root { status 200; {{yield}} } if options?
    end

    macro mount(app)
      {{app.id}}.call(context, path)
      return
    end

    macro default
      {{yield}}
      return
    end

    macro on(matcher)
      default { {{yield}} } if on?({{matcher}})
    end

    macro root
      default { {{yield}} } if root?
    end

    def status
      context.response.status_code
    end

    def status(code)
      context.response.status_code = code
    end

    def header(name, value)
      context.response.headers[name] = value
    end

    def content_type(type)
      context.response.content_type = type
    end

    def write(str)
      context.response.puts(str)
    end

    macro render(template)
      ECR.embed "#{ {{template}} }.ecr", context.response
    end

    def text(str)
      header "Content-Type", "text/plain"
      write str
    end

    macro html(template)
      header "Content-Type", "text/html"
      render {{template}}
    end

    def json(response)
      header "Content-Type", "application/json"
      response.to_json(context.response)
    end

    def redirect(url)
      status 302
      header "Location", url
    end

    abstract def routes
  end
end
