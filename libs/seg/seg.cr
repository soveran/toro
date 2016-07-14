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
struct Seg
  SLASH = '/'
  @path : String
  @size : Int32

  def self.new(path : Nil)
    new("/")
  end

  def initialize(@path)
    @size = @path.size
    @init = 0
    @pos = 0
  end

  def curr
    @path[@pos, @size - @pos]
  end

  def prev
    @path[@init, @pos]
  end

  def root?
    @size <= @pos.succ
  end

  def init?
    @init == @pos
  end

  def extract
    return nil if root?

    offs = @pos.succ
    @pos = @path.index(SLASH, offs) || @size

    return @path[offs, @pos - offs]
  end

  def retract
    return nil if init?

    offs = @pos.pred
    @pos = @path.rindex(SLASH, offs).as(Int32)

    return @path[@pos.succ, offs - @pos]
  end

  def consume(str : String)
    orig = @pos

    if str == extract
      return true
    else
      @pos = orig
      return false
    end
  end

  def restore(str : String)
    orig = @pos

    if str == retract
      return true
    else
      @pos = orig
      return false
    end
  end

  def capture(key : Symbol, store : Hash(Symbol, String))
    str = extract

    if str
      store[key] = str
      return true
    else
      return false
    end
  end
end
