# frozen_string_literal: true

module RufletStudio
  module SectionsMedia
    def build_permission_handler(page, status)
      permissions = page.permission_handler(key: "studio_permission_handler")

      column(
        spacing: 8,
        children: [
          status,
          row(
            spacing: 8,
            wrap: true,
            children: [
              text_button(content: text(value: "Microphone status"), on_click: ->(_e) {
                permissions.get_status("microphone", on_result: ->(result, error) {
                  page.update(status, value: error ? "Status error: #{error}" : "Microphone: #{result.inspect}")
                })
              }),
              text_button(content: text(value: "Request mic"), on_click: ->(_e) {
                permissions.request("microphone", on_result: ->(result, error) {
                  page.update(status, value: error ? "Microphone request error: #{error}" : "Microphone request: #{result.inspect}")
                })
              }),
              text_button(content: text(value: "Request camera"), on_click: ->(_e) {
                permissions.request("camera", on_result: ->(result, error) {
                  page.update(status, value: error ? "Camera request error: #{error}" : "Camera request: #{result.inspect}")
                })
              }),
              text_button(content: text(value: "Open settings"), on_click: ->(_e) {
                permissions.open_app_settings(on_result: ->(result, error) {
                  page.update(status, value: error ? "Settings error: #{error}" : "Opened: #{result.inspect}")
                })
              })
            ]
          )
        ]
      )
    end
  end
end
