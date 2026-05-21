# frozen_string_literal: true

require "minitest/autorun"

class ComponentsSectionTest < Minitest::Test
  def test_gallery_links_to_components_section
    gallery = File.read(File.expand_path("../views/gallery_view.rb", __dir__))
    app = File.read(File.expand_path("../app.rb", __dir__))
    controls = File.read(File.expand_path("../sections_controls.rb", __dir__))

    assert_includes gallery, "\"Components\""
    assert_includes gallery, "\"/components\""
    assert_includes app, "when \"/components\""
    assert_includes controls, "sections_controls/components"
  end

  def test_components_section_displays_supported_widgets
    source = File.read(File.expand_path("../sections_controls/components.rb", __dir__))

    %w[
      Hello
      Button
      Dialog
      DataTable
      Container
      Row
      Column
      TextField
      Icon
    ].each do |label|
      assert_includes source, label
    end

    assert_includes source, "alert_dialog("
    assert_includes source, "data_table("
    assert_includes source, "filled_button("
  end
end
