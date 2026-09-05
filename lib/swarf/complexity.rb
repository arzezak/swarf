# frozen_string_literal: true

require "prism"

module Swarf
  module Complexity
    Method = Struct.new(:path, :name, :cc, :start_line, :body) do
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

      def decision
        @stack.last&.cc += 1
      end

      def in_scope(name)
        @scope.push(name)
        yield
        @scope.pop
      end

      def qualify(node)
        return node.name.to_s if @scope.empty?

        separator = (node.receiver || @singleton.positive?) ? "." : "#"
        "#{@scope.join("::")}#{separator}#{node.name}"
      end

      def body_range(node)
        return nil unless node.body

        first = node.body.location.start_line
        last = node.body.location.end_line
        return first..last if node.equal_loc

        clamped = [first, node.location.start_line + 1].max..[last, node.location.end_line - 1].min
        (clamped.begin > clamped.end) ? first..last : clamped
      end
    end
  end
end
