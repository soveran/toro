require "./tests"

module Crotest::DSL
  macro describe(name, file = __FILE__, line = __LINE__, &block)
    %id = "#{ {{name.stringify}} }-#{ {{file}} }:#{ {{line}} }"

    Crotest::ContextPlan.stack_scope %id

    {{ yield }}

    Crotest::ContextPlan.drop_scoped_contexts
  end

  macro before(file = __FILE__, line = __LINE__, &block)
    Crotest::ContextPlan.add_before do
      {{ block.body }}
    end
  end

  macro after(file = __FILE__, line = __LINE__, &block)
    Crotest::ContextPlan.add_after do
      {{ block.body }}
    end
  end

  macro it(name, file = __FILE__, line = __LINE__, &block)
    Crotest::ContextPlan.setup

    begin
      {{ yield }}
    rescue %exception : Crotest::AssertionFailed
      %result = Crotest::FailedTest.new {{name}}, {{file}}, {{line}}, %exception
    rescue %exception : Exception
      %result = Crotest::ErroredTest.new {{name}}, {{file}}, {{line}}, %exception
    ensure
      %result ||= Crotest::PassedTest.new {{name}}, {{file}}, {{line}}

      Crotest.report %result
    end

    Crotest::ContextPlan.teardown
  end

  macro pending(name, file = __FILE__, line = __LINE__)
    Crotest.report Crotest::PendingTest.new({{name}}, {{file}}, {{line}})
  end

  macro pending(name, file = __FILE__, line = __LINE__, &block)
    pending {{name}}, {{file}}, {{line}}
  end
end
