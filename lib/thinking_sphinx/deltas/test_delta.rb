require 'thinking_sphinx'

# Does nothing, but can be hooked into by tests.
module ThinkingSphinx
  module Deltas
    class TestDelta < ThinkingSphinx::Deltas::DefaultDelta
      class_attribute :index_count, default: 0

      def delete(index, instance); end

      def index(_index)
        self.class.index_count += 1
      end
    end
  end
end
