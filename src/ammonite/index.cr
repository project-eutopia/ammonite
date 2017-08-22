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

    def initialize(shape, @axis : Int32, index : IndexType)
      @step = index.is_a?(IndexStartStepEndSlice) ? index[1] : 1

      @front = case index
               when IndexPure
                 index
               when IndexFullSlice
                 0
               else
                 case j = index[0]
                 when Nil
                   0
                 else
                   j
                 end
               end

      @back = case index
              when IndexPure
                index
              when IndexFullSlice
                shape[axis]
              else
                j = index.is_a?(IndexStartEndSlice) ? index[1] : index[2]
                case j
                when Nil
                  shape[axis]
                else
                  j
                end
              end

      raise "Invalid #{self}" unless @step > 0 && @front <= @back && @front >= 0 && @back <= shape[axis]
    end

    def base : Int32
      @front
    end

    def slice?
      @front < @back
    end

    def axis_shape : (Nil | Int32)
      if @front == @back
        nil
      else
        (@back - @front + @step - 1) / @step
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
    def increment : Bool
      increment(shape.size - 1)
    end

    private def increment(axis)
      return true if axis < 0

      if indexes[axis] == shape[axis]-1
        indexes[axis] = 0
        return increment(axis-1)
      else
        indexes[axis] += 1
        false
      end
    end
  end

  private struct MultiIndexEnumerator
    getter shape : Array(Int32)

    def initialize(@shape)
    end

    def each
      cur_multi_index = MultiIndex.new shape, shape.size.times.map {|_| 0}.to_a

      loop do
        yield cur_multi_index
        break if cur_multi_index.increment
      end
    end
  end
end
