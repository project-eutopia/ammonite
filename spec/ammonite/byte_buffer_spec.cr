require "../spec_helper"
require "../../src/ammonite/byte_buffer.cr"

describe Ammonite::ByteBuffer do
  it "is a slice of UInt8" do
    buffer = Ammonite::ByteBuffer.new(12, 0_u8)
    buffer[0].should eq 0
    buffer[11].should eq 0

    expect_raises do
      buffer[12]
    end

    buffer[2] = 15_u8
    buffer[2].should eq 15_u8
  end
end
