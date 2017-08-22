module Ammonite
  private struct Index
    # Either an individual index (Int32)
    # Or a start/end tuple (nil meaning til the end)
    # Or a start/step/end tuple
    private alias IndexPure = Int32
    private alias IndexFullSlice = Nil
    private alias IndexStartEndSlice = Tuple(Nil | Int32, Nil | Int32)
    private alias IndexStartStepEndSlice = Tuple(Nil | Int32, Int32, Nil | Int32)
    private alias IndexSlice = IndexStartEndSlice | IndexStartStepEndSlice
    private alias IndexType = IndexPure | IndexFullSlice | IndexSlice

    getter axis : Int32

    # front = back => single index extraction (axis is collapsed)
    # front < back, extract slice from [front, back)
    getter front : Int32
    getter back : Int32
    getter step : Int32

    # True if we are collapsing axis by picking a single value out
    getter collapsed : Bool

    def initialize(shape, @axis : Int32, index : IndexType)
      if index.is_a?(IndexPure)
        @collapsed = true
        @front = index
        @back = index
        @step = 0
      else
        @collapsed = false

        @step = index.is_a?(IndexStartStepEndSlice) ? index[1] : 1
        raise "Step size cannot be zero" if @step == 0

        @front = case index
                 when IndexFullSlice
                   0
                 else
                   case j = index[0]
                   when Nil
                     @step > 0 ? 0 : shape[axis]-1
                   else
                     j >= 0 ? j : j + shape[axis]
                   end
                 end

        @back = case index
                when IndexFullSlice
                  shape[axis]
                else
                  j = index.is_a?(IndexStartEndSlice) ? index[1] : index[2]
                  case j
                  when Nil
                    @step > 0 ? shape[axis] : -1
                  else
                    j >= 0 ? j : j + shape[axis]
                  end
                end

        # Set step to 0 if we slice over nothing (shape is 0 along this axis)
        if @step > 0
          @step = 0 if @front > @back
          raise "Invalid index: #{index}" unless @front >= 0 && @back <= shape[axis]
        elsif @step < 0
          @step = 0 if @front < @back
          raise "Invalid index: #{index}" unless @front < shape[axis] && @back >= -1
        end
      end
    end

    def base : Int32
      @front
    end

    def axis_shape : (Nil | Int32)
      # When set equal, we are a single index so axis collapsed
      if @collapsed
        nil
      # step == 0 is special value for empty axis
      elsif @step == 0
        0
      else
        ((@back - @front).abs + @step.abs - 1) / @step.abs
      end
    end
  end

  struct MultiIndex
    include Comparable(MultiIndex)

    getter shape : Array(Int32)
    getter indexes : Array(Int32)

    def initialize(@shape, @indexes)
    end

    def <=>(other : MultiIndex)
      raise "Invalid MultiIndex comparison" unless indexes.size == other.indexes.size

      indexes.each_with_index do |index1, axis|
        index2 = other.indexes[axis]

        if index1 < index2
          return -1
        elsif index1 > index2
          return 1
        end
      end

      0
    end

    # Returns true if overflow
    def increment
      increment(shape.size - 1)
    end

    private def increment(axis)
      return true if axis < 0

      if indexes[axis] == shape[axis]-1
        if axis > 0
          indexes[axis] = 0
          increment(axis-1)
        else
          indexes[axis] += 1
        end
      else
        indexes[axis] += 1
      end
    end
  end

  private struct MulitIndexIterator
    include Iterator(MultiIndex)

    @shape : Array(Int32)
    @n : Int32
    @multi_index : MultiIndex
    @end_index : MultiIndex

    def initialize(@shape)
      @n = 0
      @multi_index = initial_multi_index
      @end_index = MultiIndex.new(@shape, @shape.map {|i| i-1})
    end

    def next
      @multi_index.increment if @n > 0
      return stop if @multi_index > @end_index
      @n += 1
      @multi_index
    end

    def rewind
      @n = 0
      @multi_index = initial_multi_index
      self
    end

    private def initial_multi_index
      MultiIndex.new @shape, @shape.size.times.map {|_| 0}.to_a
    end
  end
end
