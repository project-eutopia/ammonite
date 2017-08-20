require "../spec_helper"
require "../../src/ammonite/buffer_view.cr"

describe Ammonite::BufferView do
  it "works" do
    buffer = Ammonite::ByteBuffer.new(12, 0_u8)
    buffer[0] = 1_u8
    buffer[11] = 100_u8

    view = Ammonite::BufferView(Int32).new(buffer)

    view[0].should eq 1

    buffer[3] = 1_u8
    view[0].should eq 16777217

    view2 = Ammonite::BufferView(Int16).new(buffer)

    view2[0].should eq 1
    view2[1].should eq 256

    buffer2 = Ammonite::BufferView(Int32).new(4, 0)
    buffer2[0] = 4
    buffer2[3] = 10
  end
end
