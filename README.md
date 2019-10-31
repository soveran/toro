# Toro

![Toro](http://files.soveran.com/toro/img/toro.png)

![CI](https://github.com/soveran/toro/workflows/Crystal%20CI/badge.svg)

Tree Oriented Routing

## Usage

Here's a `hello world` app that you can copy and paste to get a
sense of how Toro works:

```crystal
require "toro"

class App < Toro::Router
  def routes
    get do
      text "hello world"
    end
  end
end

App.run(8080)
```

Save it to a file called `hello_world.cr` and run it with
`crystal run hello_world.cr`. Then access your `hello world` application with
your browser, or simply by calling `curl http://localhost:8080/` from the
command line.

What follows is an example that showcases some basic routing features:

```crystal
require "toro"

class App < Toro::Router

  # You must define the `routes` methods. It will be the
  # entry point to your web application.
  def routes

    # The `get` matcher will execute the block when two conditions
    # are met: the `REQUEST_METHOD` is equal to "GET", and there are
    # no more path segments to match. In this case, as we haven't
    # consumed any path segment, the only way for this block to run
    # would be to have a "GET" request to "/". Check the API section
    # to see all available matchers.
    get do

      # The text method sets the Content-Type to "text/plain", and
      # prints the string to the response.
      text "hello world"
    end

    # A `String` matcher will run the block only if its content is equal
    # to the next segment in the current path. In this example, it will
    # match the request if the first segment is equal to "users".
    # You can always inspect the current path by looking at `path.curr`.
    on "users" do

      # If we get here it's because the previous matcher succeeded. It
      # means we were able to consume a segment off the current path. More
      # specifically, we consumed the "users" segment, and if we now
      # inspect the `path.prev` string we will find its value is "/users".
      #
      # With the next matcher we want to capture a segment. Let's say a
      # request is made to "/users/42". When we arrive at this point, this
      # symbol will match the number "42" and store it in the inbox.
      on :id do

        # If there are no more segments in the request path and if the
        # request method is "GET", this block will run.
        get do

          # Now, `inbox[:id]` has the value "42". The templates have access
          # to the inbox and to any other variables defined here.
          #
          # The `html` macro expects a path to a template. It automatically
          # appends the `.ecr` extension, which stands for Embedded Crystal
          # and is part of the standard library. It also sets the content
          # type to "text/html". For the html example to work, you need to
          # create the file ./views/users/show.ecr with the following content:
          #
          #   hello user <%= inbox[:id] %>
          #
          #
          # Once you have created the file, uncomment the line below.
          #
          # html "views/users/show"


          # As a placeholder, the following directive renders the same message
          # as plain text. Once you have the HTML template in place, you can
          # comment or remove both this comment and the `text` directive.
          #
          text "hello user #{inbox[:id]}"
        end
      end
    end

    # The `default` matcher always succeeds, but it doesn't mean the program's
    # flow will always reach this point. Once a matcher succeeds and runs a
    # block, the control is never returned. There's an implicit return at the
    # end of every block, which stops the processing of the request and
    # returns the response immediately.
    #
    # This route will match all the requests that don't have "users" as the
    # first segment (because of the previous matcher), and it will pass the
    # control to the `Guests` application, which has to be an instance of
    # `Toro::Router`. This illustrates how you can compose your applications
    # and split the logic among different routers.
    default do
      mount Guests
    end
  end
end

# This is another Toro application. You can mount apps on top of other Toro
# in order to achieve a modular design.
class Guests < Toro::Router
  def routes
    on "about" do
      get do
        text "about this site"
      end
    end
  end
end

# Start the app on port 8080.
App.run(8080)
```

Once you have this application running, try the requests below:

```shell
$ curl http://localhost:8080/
$ curl http://localhost:8080/about
$ curl http://localhost:8080/users/42
```

The routes are evaluated in a sandbox where the following methods
are available: `context`, `path`, `inbox`, `mount`, `basic_auth`,
`root`, `root?`, `default`, `on`, `get`, `put`, `head`, `post`,
`patch`, `delete`, `options`, `text`, `html`, `json`, `write` and
`render`.

## API

`context`: Environment variables for the request.

`path`: Helper object that tracks the previous and current path.

`inbox`: Hash with captures and potentially other variables local
to the request.

`mount`: Mounts a sub app.

`basic_auth`: Yields a username and password from the Authorization
header, and returns whatever the block returns or nil.

`root?`: Returns true if the path yet to be consumed is empty.

`root`: Receives a block and calls it only if `root?` is true.

`default`: Receives a block that will be executed inconditionally.

`on`: Receives a value to be matched, and a block that will be
executed only if the request is matched.

`get`: Receives a block and calls it only if `root?` and `get?` are
true.

`put`: Receives a block and calls it only if `root?` and `put?` are
true.

`head`: Receives a block and calls it only if `root?` and `head?`
are true.

`post`: Receives a block and calls it only if `root?` and `post?`
are true.

`patch`: Receives a block and calls it only if `root?` and `patch?`
are true.

`delete`: Receives a block and calls it only if `root?` and `delete?`
are true.

`options`: Receives a block and calls it only if `root?` and
`options?` are true.

## Matchers

The `on` method can receive a `String` to perform path matches; a
`Symbol` to perform path captures; and a boolean to match any true
values.

Each time `on` matches or captures a segment of the PATH, that part
of the path is consumed. The current and previous paths can be
queried by calling `prev` and `curr` on the `path` object: `path.prev`
returns the part of the path already consumed, and `path.curr`
provides the current version of the path. Any expression that
evaluates to a boolean can also be used as a matcher.

Captures
--------

When a symbol is provided, `on` will try to consume a segment of
the path. A segment is defined as any sequence of characters after
a slash and until either another slash or the end of the string.
The captured value is stored in the `inbox` hash under the key that
was provided as the argument to `on`. For example, after a call to
`on(:user_id)`, the value for the segment will be stored at
`inbox[:user_id]`.

Security
--------

There are no security features built into this routing library. A
framework using this library should implement the security layer.

Rendering
---------

The most basic way of returning a string is by calling the method
`text`. It sets the `Content-Type` header to `text/plain` and writes
the passed string to the response. A similar helper is called `html`:
it takes as an argument the path to an `ECR` template and renders
its content. A lower level `render` macro is available: it also
expects the path to a template, but it doesn't modify the headers.
There's a `json` helper method expecting a Crystal generic Object.
It will call the `to_json` serializer on the generic object. Please
note that you need to require JSON from the standard library in
order to use this helper (adding `require "json"` to your app should
suffice). The lower level `write` method writes a string to the
response object. It is used internally by `text` and `json`.

Running the server
------------------

If `App` is an instance of `Toro`, then you can start the server
by calling `App.run`. You can pass any options you would use with
the `HTTP::Server` constructor from the standard library.

For example, you can start the server on port 80:

```crystal
App.run(80)
```

Or you can further configure server by using a block. The following
example shows how to configure SSL certificates:

```crystal
App.run(443) do |server|
  ssl = OpenSSL::SSL::Context::Server.new
  ssl.private_key = "path/to/private_key"
  ssl.certificate_chain = "path/to/certificate_chain"
  server.tls = ssl
end
```

Refer to Crystal's documentation for more options.

Status codes
------------

The default status code is `404`. It can be changed and queried
with the `status` method:

```crystal
  status
  #=> 404

  status 200

  status
  #=> 200
```

When a request method matcher succeeds, the status code for the
request is changed to `200`.

Basic Auth
----------

The `basic_auth` method checks the `Authentication` header and, if
present, yields to the block the values for username and password.

Here's an example of how you can use it:

```crystal
class A < Toro::Router
  def users(user : User)
    get do
      text "Hello #{user.name}"
    end
  end

  def users(user : Nil)
    get do
      text "Hello guest!"
    end
  end

  def routes
    user = basic_auth do |name, pass|
      User.authenticate(name, pass)
    end

    users(user)
  end
end
```

The example overloads the `users` method so that it can deal both
with instances of `User` and with `nil`. The flow of your router
will naturally continue in one of those methods. You are free to
define any other methods like `users` in order to split the logic
of your application.

To illustrate the `basic_auth` feature we used an imaginary `User`
class that responds to the `authenticate` method and returns either
an instance of `User` or nil.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  toro:
    github: soveran/toro
    branch: master
```
