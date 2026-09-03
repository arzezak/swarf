# frozen_string_literal: true

require "prism"

module Swarf
  # Cyclomatic complexity per method, parsed from source text.
  module Complexity
    Method = Struct.new(:path, :name, :cc, :start_line, :body, keyword_init: true) do
      # Branches are attributed over the whole definition, because an endless method holds
      # its branches on the `def` line itself.
      def range = start_line..(body&.last || start_line)
    end

    def self.analyze(source, path:)
      result = Prism.parse(source)
      visitor = Visitor.new(path)
      result.value.accept(visitor)
      visitor.methods
    end

    class Visitor < Prism::Visitor
      attr_reader :methods

      def initialize(path)
        @path = path
        @methods = []
        @stack = []
        @scope = []
        @singleton = 0
        super()
      end

      def visit_class_node(node)
        in_scope(node.constant_path.slice) { super }
      end

      def visit_module_node(node)
        in_scope(node.constant_path.slice) { super }
      end

      def visit_singleton_class_node(node)
        @singleton += 1
        super
        @singleton -= 1
      end

      def visit_def_node(node)
        method = Method.new(path: @path, name: qualify(node), cc: 1,
                            start_line: node.location.start_line, body: body_range(node))
        @methods << method
        @stack.push(method)
        super
        @stack.pop
      end

      # Blocks are deliberately absent: `rows.each { ... }` is iteration, not a decision,
      # and counting it inflates declarative DSL code without finding real risk.
      DECISIONS = %i[
        if unless while until for when in rescue rescue_modifier and or
      ].freeze

      DECISIONS.each do |construct|
        define_method(:"visit_#{construct}_node") do |node|
          decision
          super(node)
        end
      end

      def visit_call_node(node)
        decision if node.safe_navigation?
        super
      end

      private

      # Decisions outside any method body belong to no method, so they are dropped.
      def decision
        @stack.last&.cc += 1
      end

      def in_scope(name)
        @scope.push(name)
        yield
        @scope.pop
      end

      def qualify(node)
        separator = node.receiver || @singleton.positive? ? "." : "#"
        return node.name.to_s if @scope.empty?

        "#{@scope.join("::")}#{separator}#{node.name}"
      end

      # The `def` line executes when the class is defined, so it reads as covered even for a
      # method nothing ever calls. Only an endless method genuinely lives on its `def` line.
      def body_range(node)
        return nil unless node.body

        first = node.body.location.start_line
        last = node.body.location.end_line
        return first..last if node.equal_loc

        # An implicit `begin`/`rescue` claims the whole `def`, keyword lines included.
        clamped = [first, node.location.start_line + 1].max..[last, node.location.end_line - 1].min
        # ...but a one-liner shares its lines with those keywords, so clamping empties it.
        clamped.begin > clamped.end ? first..last : clamped
      end
    end
  end
end
