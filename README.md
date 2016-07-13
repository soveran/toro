# Toro

![Toro](http://files.soveran.com/toro/img/toro.png)

Tree Oriented Routing

## Usage


```crystal
require "toro"

class App < Toro::Router
  def routes
    get do
      text "hello world"
    end

    on "users" do
      on :id do
        get do
          html "views/users/show"
        end
      end
    end
    
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
