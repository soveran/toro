module Crotest
  class AssertionFailed < Exception
    getter file : String
    getter line : Int32

    def initialize(message , @file : String, @line : Int32)
      super(message)
    end
  end
end
