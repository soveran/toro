# Toro

![Toro](http://files.soveran.com/toro/img/toro.png)

Tree Oriented Routing

## Usage

There's an example that showcases basic routing features:

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

      # The text macro sets the Content-Type to "text/plain", and
      # prints the text to the response.
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
          # The `html` macro expects the path to a template. It automatically
          # appends the `.ecr` extension, which stands for Embedded Crystal
          # and is part of the standard library. It also sets the content
          # type to "text/html".
          html "views/users/show"
        end
      end
    end

    # The `default` matcher always succeeds, but it doesn't mean the program's
    # flow will always reach this point. Once a matcher succeeds and runs a
    # block, the control is never returned. There's an implicit call to `halt`
    # at the end of every block. A call to `halt` stops the processing of
    # the request and returns the response immediately.
    #
    # This route will match all the requests that don't have "users" as the
    # first segment (because of the previous matcher), and it will pass the
    # control to the `Guests` application, which has to be an instance of
    # `Toro::Router`. This illustrates how you can compose your applications
    # and split the logic among different routers.
    default do
      run Guests
    end
  end
end
```

The routes are evaluated in a sandbox where the following methods
are available: `context`, `path`, `inbox`, `run`, `halt`, `basic_auth`,
`root`, `root?`, `default`, `on`, `get`, `put`, `head`, `post`,
`patch`, `delete`, `options`, `text`, `html` and `render`.

## API

`context`: Environment variables for the request.

`path`: Helper object that tracks the previous and current path.

`inbox`: Hash with captures and potentially other variables local
to the request.

`run`: Runs a sub app.

`halt`: Terminates the request.

`basic_auth`: Yields a username and password from the Authorization
header, and returns whatever the block returns or nil.

`root?`: Returns true if the path yet to be consumed is empty.

`default`: Receives a block that will be executed inconditionally.

`on`: Receives a value to be matched, and a block that will be
executed only if the request is matched.

`root`: Receives a block and calls it only if `root?` is true.

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
its content. A lower level `render` method is available: it also
expects the path to a template, but it doesn't modify the headers.

Status codes
------------

The default status code is `404`. It can be changed and queried
with the `status` macro:

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

To illustrate the `basic_auth` feature we user an imaginary `User`
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
