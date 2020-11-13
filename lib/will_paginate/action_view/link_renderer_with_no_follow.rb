module WillPaginate
  module ActionView
    class LinkRendererWithNoFollow < LinkRenderer
      def rel_value(_page)
        'nofollow'
      end
    end
  end
end
