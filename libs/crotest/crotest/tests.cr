module Crotest
  abstract class Test
    def initialize(@name : String, @file : String, @line : Int32, @exception : Exception? = nil)
      print @id
      increment_counter
    end

    def present
      description(@exception)
    end

    def description(ex : Nil)
      raise "subclass responsibility"
    end

    def description(ex : Exception)
      raise "subclass responsibility"
    end

    def increment_counter
      Crotest.increment(@counter_key)
    end

    private def print_header(title : String)
      puts "\n  #{title}:\n\t\"#{@name}\" [#{@file}:#{@line}]\n"
    end

    private def print_backtrace(ex : Exception)
      puts "\n\t#{ex} (#{ex.class})\n"
    end
  end

  class PassedTest < Test
    @id = ""
    @counter_key = :passed

    def description(ex : Nil)
      # Do nothing
    end
  end

  class FailedTest < Test
    @id = "F"
    @counter_key = :failures

    def description(ex : Exception)
      print_header "Failed"
      print_backtrace ex
    end
  end

  class ErroredTest < Test
    @id = "E"
    @counter_key = :errors

    def description(ex : Exception)
      print_header "Error"
      print_backtrace ex
    end
  end

  class PendingTest < Test
    @id = "P"
    @counter_key = :pending

    def description(ex : Nil)
      print_header "Pending"
    end
  end
end
