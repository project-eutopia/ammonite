require "./index.cr"

module Ammonite
  private class Broadcaster
    class BroadcasterIterator
      include Iterator(Tuple(MultiIndex, MultiIndex, MultiIndex))

      @broadcast_shape : MultiIndex
      @multi_index_iterator : MultiIndexIterator

      def initialize(broadcaster : Broadcaster)
        @broadcast_shape = broadcast_shape.broadcast_shape
        @multi_index_iterator = MultiIndexIterator.new @broadcast_shape
      end

      # Returns Tuple of multi_index1, multi_index2, and broadcasting multi_index
      # TODO: handle case with blank arrays (setting individual values)
      def next
        next_multi_index = @multi_index_iterator.next
        return stop if next_multi_index == Iterator::Stop::INSTANCE

        # FIXME
        # stop
      end
    end

    @shape1 : Array(Int32)
    @shape2 : Array(Int32)
    getter broadcast_shape : Array(Int32)

    def initialize(@shape1, @shape2)
      @broadcast_shape = [] of Int32

      shape1_tmp = @shape1.clone
      shape2_tmp = @shape2.clone

      while !shape1_tmp.empty? || !shape2_tmp.empty?
        if shape1_tmp.empty?
          @broadcast_shape << shape2_tmp.pop
        elsif shape2_tmp.empty?
          @broadcast_shape << shape1_tmp.pop
        else
          if shape1_tmp[-1] == 1
            @broadcast_shape << shape2_tmp.pop
            shape1_tmp.pop
          elsif shape2_tmp[-1] == 1
            @broadcast_shape << shape1_tmp.pop
            shape2_tmp.pop
          else
            raise "Invalid broadcasting shapes #{@shape1} and #{@shape2}" if shape1_tmp[-1] != shape2_tmp[-1]
            @broadcast_shape << shape1_tmp.pop
            shape2_tmp.pop
          end
        end
      end

      @broadcast_shape = @broadcast_shape.reverse
    end

    def indexes1_from_broadcasting_indexes(indexes : Array(Int32))
      indexes_from_broadcasting_shape(indexes, @shape1)
    end

    def indexes2_from_broadcasting_indexes(indexes : Array(Int32))
      indexes_from_broadcasting_shape(indexes, @shape2)
    end

    def iterator
      BroadcasterIterator.new(self)
    end

    private def indexes_from_broadcasting_shape(broadcasting_indexes : Array(Int32), shape : Array(Int32))
      # Cut off last part of array
      indexes = broadcasting_indexes[(broadcasting_indexes.size - shape.size)..-1]

      # Fix indexes corresponding to collapsed axes
      offset = shape.size-1
      (0...shape.size).each do |i|
        if shape[offset-i] == 1
          indexes[offset-i] = 0
        end
      end

      indexes
    end
  end
end
