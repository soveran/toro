module Crotest
  struct Context
    property id : String?
    property block : Proc(Void)

    def initialize(@id : String?, @block : Proc(Void))
    end
  end

  class ContextPlan
    @@scopes_stack = [] of String
    @@before_contexts = [] of Context
    @@after_contexts = [] of Context

    def self.add_before(&block)
      @@before_contexts.push Context.new(current_scope, block)
    end

    def self.add_after(&block)
      @@after_contexts.push Context.new(current_scope, block)
    end

    def self.current_scope
      @@scopes_stack.last?
    end

    def self.drop_scoped_contexts
      context_matches_id = ->(c : Context) { c.id == current_scope }

      @@before_contexts.reject! &context_matches_id
      @@after_contexts.reject! &context_matches_id
      @@scopes_stack.pop?
    end

    def self.setup
      @@before_contexts.each &.block.call
    end

    def self.stack_scope(id : String)
      @@scopes_stack.push id
    end

    def self.teardown
      @@after_contexts.reverse_each &.block.call
    end
  end
end
