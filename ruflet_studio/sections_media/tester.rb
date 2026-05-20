# frozen_string_literal: true

module RufletStudio
  module SectionsMedia
    def build_tester(page, status)
      page.tester(key: "studio_tester")

      column(
        spacing: 8,
        children: [
          status,
          row(
            spacing: 8,
            children: [
              text_button(content: text(value: "Pump"), on_click: ->(_e) {
                page.tester_pump(duration: 100, on_result: ->(_result, error) {
                  page.update(status, value: error ? "Tester pump failed: #{error}" : "Tester pump completed")
                })
              }),
              text_button(content: text(value: "Find Gallery"), on_click: ->(_e) {
                page.find_by_text("Gallery", on_result: ->(result, error) {
                  page.update(status, value: error ? "Find failed: #{error}" : "Finder: #{result.inspect}")
                })
              })
            ]
          )
        ]
      )
    end
  end
end
