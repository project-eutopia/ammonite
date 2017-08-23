require "./index.cr"

module Ammonite
  private class Broadcaster
    class BroadcasterIterator
      include Iterator(Tuple(MultiIndex, MultiIndex, MultiIndex))

      @broadcaster : Broadcaster
      @broadcast_shape : Array(Int32)
      @multi_index_iterator : MultiIndexIterator

      def initialize(@broadcaster : Broadcaster)
        @broadcast_shape = @broadcaster.broadcast_shape
        @multi_index_iterator = MultiIndexIterator.new @broadcast_shape
      end

      # Returns Tuple of multi_index1, multi_index2, and broadcasting multi_index
      # TODO: handle case with blank arrays (setting individual values)
      def next
        next_multi_index = @multi_index_iterator.next

        if next_multi_index.is_a? Iterator::Stop
          return stop
        else
          {
            @broadcaster.indexes1_from_broadcasting_indexes(next_multi_index),
            @broadcaster.indexes2_from_broadcasting_indexes(next_multi_index),
            next_multi_index
          }
        end
      end
    end

    getter shape1 : Array(Int32)
    getter shape2 : Array(Int32)
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

    def shape1_contains_shape2
      shape_contains_shape(@shape1, @shape2)
    end

    def shape2_contains_shape1
      shape_contains_shape(@shape2, @shape1)
    end

    def indexes1_from_broadcasting_indexes(indexes : MultiIndex)
      indexes_from_broadcasting_shape(indexes, @shape1)
    end

    def indexes2_from_broadcasting_indexes(indexes : MultiIndex)
      indexes_from_broadcasting_shape(indexes, @shape2)
    end

    def iterator
      BroadcasterIterator.new(self)
    end

    private def indexes_from_broadcasting_shape(broadcasting_multi_index : MultiIndex, shape : Array(Int32))
      # Cut off last part of array
      indexes = broadcasting_multi_index.indexes[(broadcasting_multi_index.indexes.size - shape.size)..-1]

      # Fix indexes corresponding to collapsed axes
      offset = shape.size-1
      (0...shape.size).each do |i|
        if shape[offset-i] == 1
          indexes[offset-i] = 0
        end
      end

      MultiIndex.new shape, indexes
    end

    # Checks if right is contained within left (left >= right)
    private def shape_contains_shape(left : Array(Int32), right : Array(Int32))
      return false if left.size < right.size
      # Focus on part that overlaps
      left = left[(left.size-right.size)..-1]

      left.each_with_index.all? do |v1, i|
        v2 = right[i]
        v1 >= v2
      end
    end
  end
end
