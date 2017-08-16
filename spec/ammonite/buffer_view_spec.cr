require "../spec_helper"
require "../../src/ammonite/buffer_view.cr"

describe Ammonite do
  it "works" do
    buffer = Ammonite::ByteBuffer.new(12, 0_u8)
    buffer[0] = 1_u8

    view = Ammonite::BufferView(Int32).new(buffer)

    view[0].should eq 1

    buffer[3] = 1_u8
    view[0].should eq 16777217

    view2 = Ammonite::BufferView(Int16).new(buffer)

    view2[0].should eq 1
    view2[1].should eq 256
  end
end
