require "./spec_helper"

class A < Toro::Router
  def routes
    on false do
      context.response.puts "shouldn't get here"
    end

    on true do
      context.response.puts "true"

      on false do
        context.response.puts "shouldn't get here"
      end

      on true do
        context.response.puts "again true"
      end
    end

    on true do
      context.response.puts "shouldn't get here"
    end
  end
end

describe "boolean matchers" do
  response = Toro.drive(A, "GET", "/")

  it "should only progress when the value is true" do
    assert_equal "true\nagain true\n", response.body
  end

  it "should return 404 unless a verb is matched" do
    assert_equal 404, response.status_code
  end
end

class B < Toro::Router
  def routes
    on "bar" do
      text "shouldn't get here"
    end

    on "foo" do
      text "got here"

      on "foo" do
        text "shouldn't get here"
      end

      on "bar" do
        text "and here"
      end
    end

    on true do
      text "shouldn't get here"
    end
  end
end

describe "string matchers" do
  request = Toro.drive(B, "GET", "/foo/bar")

  it "should only progress when the string matches a path segment" do
    assert_equal "got here\nand here\n", request.body
  end
end

class C < Toro::Router
  def routes
    on :x do
      text "got :x == #{inbox[:x]}"
    end

    on :y do
      text "got :y == #{inbox[:y]}"
    end

    on true do
      text "shouldn't get here"
    end
  end
end

describe "symbol matchers" do
  response = Toro.drive(C, "GET", "/foo/bar")

  it "should only progress when there are segments to capture" do
    assert_equal "got :x == foo\n", response.body
  end
end

class D < Toro::Router
  def routes
    default do
      text "got here"
    end

    default do
      text "not here"
    end
  end
end

describe "default matcher" do
  response = Toro.drive(D, "GET", "/foo/bar")

  it "should always progress" do
    assert_equal "got here\n", response.body
  end
end

class E < Toro::Router
  def routes
    root do
      text "not here"
    end

    on "foo" do
      root do
        text "got here"
      end
    end

    default do
      text "not here"
    end
  end
end

describe "root matcher" do
  response = Toro.drive(E, "GET", "/foo")

  it "should progress when there are no segments left in the path" do
    assert_equal "got here\n", response.body
  end
end

class F < Toro::Router
  def routes
    root do
      write "root"
    end

    on "bar" do
      mount E
    end

    default do
      write "not here"
    end
  end
end

describe "mounted apps" do
  response = Toro.drive(F, "GET", "/bar/foo")

  it "should process the request and the rest of the path" do
    assert_equal "got here\n", response.body
  end
end

class G < Toro::Router
  def routes
    get do
      text "here at root"
    end

    post do
      text "not here"
    end

    on "foo" do
      get do
        text "not here"
      end

      post do
        text "here!"
      end
    end

    default do
      text "not here either"
    end
  end
end

describe "verb matchers" do
  response = Toro.drive(G, "GET", "/")

  it "should work at root" do
    assert_equal "here at root\n", response.body
  end

  it "should return 200" do
    assert_equal 200, response.status_code
  end

  response = Toro.drive(G, "POST", "/foo")

  it "should progress when the verb matches" do
    assert_equal "here!\n", response.body
  end

  it "should return 200" do
    assert_equal 200, response.status_code
  end
end

class H < Toro::Router
  def routes
    get do
      @name = "foo"

      html "spec/views/index"
    end
  end
end

describe "html renderer" do
  it "should render the template" do
    response = Toro.drive(H, "GET", "/")

    assert_equal 200, response.status_code
    assert_equal "hello foo!", response.body
  end

  it "should not render if not found" do
    response = Toro.drive(H, "PUT", "/")

    assert_equal 404, response.status_code
    assert_equal "", response.body
  end
end

class I < Toro::Router
  def routes
    post do
      redirect "/dashboard"
    end
  end
end

describe "redirects" do
  response = Toro.drive(I, "POST", "/")

  it "should return 302" do
    assert_equal 302, response.status_code
  end

  it "should return a location" do
    assert_equal "/dashboard", response.headers["Location"]
  end
end

class J < Toro::Router
  def routes
    user = basic_auth do |name, pass|
      name == "foo" &&
      pass == "bar" &&
      "user:1"
    end

    post do
      text user.to_s
    end
  end
end

describe "basic auth" do
  headers = HTTP::Headers.new

  auth1 = sprintf("Basic %s", Base64.strict_encode("foo:bar"))
  auth2 = sprintf("Basic %s", Base64.strict_encode("bar:baz"))

  it "should return nil if there's no Authorization header" do
    response = Toro.drive(J, "POST", "/")

    assert_equal "\n", response.body
  end

  it "should return nil if the credentials are wrong" do
    headers["Authorization"] = "Basic %s" % Base64.strict_encode("bar:baz")

    request = HTTP::Request.new("POST", "/", headers)

    response = Toro.drive(J).call(request)

    assert_equal "\n", response.body
  end

  it "should return the result of the basic_auth block if credentials match" do
    headers["Authorization"] = "Basic %s" % Base64.strict_encode("foo:bar")

    request = HTTP::Request.new("POST", "/", headers)

    response = Toro.drive(J).call(request)

    assert_equal "user:1\n", response.body
  end
end

class K < Toro::Router
  getter counter = 0

  def incr
    @counter += 1
  end

  def routes
    on incr == 1 do
      text "here"
    end

    on incr == 2 do
      text "not here"
    end

    text "counter: #{counter}"
  end
end

describe "halt" do
  response = Toro.drive(K, "GET", "/foo/bar")

  it "should stop the execution once a matcher succeeds" do
    assert_equal "here\n", response.body
  end
end

require "json"

class L < Toro::Router
  def routes
    post do
      test = {"hello" => "world"}
      json test
    end
  end
end

describe "json method helper" do
  response = Toro.drive(L, "POST", "/")

  it "should return json content-type" do
    assert_equal "application/json", response.headers["Content-Type"]
  end

  it "should return json {\"hello\":\"world\"}" do
    assert_equal "{\"hello\":\"world\"}", response.body
  end
end
