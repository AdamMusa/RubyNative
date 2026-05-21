# frozen_string_literal: true

module RufletStudio
  module SectionsMedia
    def build_geolocator(page, status)
      geo = page.geolocator(key: "studio_geolocator")

      column(
        spacing: 8,
        children: [
          status,
          row(
            spacing: 8,
            wrap: true,
            children: [
              text_button(content: text(value: "Permission"), on_click: ->(_e) {
                geo.get_permission_status(on_result: ->(result, error) {
                  page.update(status, value: error ? "Permission error: #{error}" : "Permission: #{result.inspect}")
                })
              }),
              text_button(content: text(value: "Location enabled"), on_click: ->(_e) {
                geo.is_location_service_enabled(on_result: ->(result, error) {
                  page.update(status, value: error ? "Location error: #{error}" : "Enabled: #{result.inspect}")
                })
              })
            ]
          )
        ]
      )
    end
  end
end
