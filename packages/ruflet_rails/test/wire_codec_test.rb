# frozen_string_literal: true

require_relative "test_helper"

class RufletRailsWireCodecTest < Minitest::Test
  def test_unpack_decodes_flet_message_pack_ext_values
    assert_equal "2026-05-20T12:30:00+00:00", Ruflet::Rails::Protocol::WireCodec.unpack(ext8(1, "2026-05-20T12:30:00+00:00"))
    assert_equal "09:45", Ruflet::Rails::Protocol::WireCodec.unpack(ext8(2, "09:45"))
    assert_equal 123_456, Ruflet::Rails::Protocol::WireCodec.unpack(ext8(3, "123456"))
    assert_equal "js-value", Ruflet::Rails::Protocol::WireCodec.unpack(ext8(4, "js-value"))
  end

  private

  def ext8(type, payload)
    bytes = payload.b
    "\xc7".b + [bytes.bytesize, type].pack("Cc") + bytes
  end
end
