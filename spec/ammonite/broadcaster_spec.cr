require "../spec_helper"
require "../../src/ammonite/broadcaster.cr"

# Open up module to access private internal class Broadcaster
module Ammonite
  describe Broadcaster do
    describe "#broadcast_shape" do
      context "both empty shapes" do
        it "is also empty" do
          b = Broadcaster.new([] of Int32, [] of Int32)
          b.broadcast_shape.should eq [] of Int32
        end
      end

      context "one empty shape" do
        it "is equal to the other shape" do
          b1 = Broadcaster.new([2, 4], [] of Int32)
          b1.broadcast_shape.should eq [2, 4]
          b2 = Broadcaster.new([] of Int32, [3, 5])
          b2.broadcast_shape.should eq [3, 5]
        end
      end

      context "both shapes non-empty" do
        context "with same values but different sizes" do
          it "is equal to the longer shape" do
            b1 = Broadcaster.new([2,3], [3])
            b1.broadcast_shape.should eq [2,3]

            b2 = Broadcaster.new([2,3], [5,5,2,3])
            b2.broadcast_shape.should eq [5,5,2,3]
          end
        end

        context "some values 1" do
          it "expands the axes where one of the shapes is 1" do
            b1 = Broadcaster.new([2,1], [3])
            b1.broadcast_shape.should eq [2,3]

            b2 = Broadcaster.new([3,1,4], [3,1,1])
            b2.broadcast_shape.should eq [3,1,4]
          end
        end

        context "different lengths and some values 1" do
          it "retains shape values for longer shape and expands coincide 1 axes" do
            b = Broadcaster.new([3, 1, 4, 1, 1, 9], [4, 1, 5, 1])
            b.broadcast_shape.should eq [3, 1, 4, 1, 5, 9]
          end
        end
      end
    end

    describe "indexes from broadcasting_indexes" do
      it "handles long shapes and shapes with collapsed indexes" do
        b = Broadcaster.new([3, 1, 4, 1, 1, 9], [4, 1, 5, 1])

        b.indexes1_from_broadcasting_indexes([0, 0, 0, 0, 0, 0]).should eq [0, 0, 0, 0, 0, 0]
        b.indexes2_from_broadcasting_indexes([0, 0, 0, 0, 0, 0]).should eq [0, 0, 0, 0]

        b.indexes1_from_broadcasting_indexes([2, 0, 3, 0, 4, 8]).should eq [2, 0, 3, 0, 0, 8]
        b.indexes2_from_broadcasting_indexes([2, 0, 3, 0, 4, 8]).should eq [3, 0, 4, 0]
      end
    end
  end
end
