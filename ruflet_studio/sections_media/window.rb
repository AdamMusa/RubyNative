# frozen_string_literal: true

module RufletStudio
  module SectionsMedia
    def build_window(page, status)
      page.window(key: "studio_window", width: 900, height: 700, resizable: true)

      column(
        spacing: 8,
        children: [
          status,
          row(
            spacing: 8,
            wrap: true,
            children: [
              text_button(content: text(value: "Ready"), on_click: ->(_e) {
                invoke_studio_window(page, status, :wait_until_ready_to_show, "Window ready")
              }),
              text_button(content: text(value: "Center"), on_click: ->(_e) {
                invoke_studio_window(page, status, :center_window, "Window centered")
              }),
              text_button(content: text(value: "To front"), on_click: ->(_e) {
                invoke_studio_window(page, status, :window_to_front, "Window moved to front")
              })
            ]
          )
        ]
      )
    end

    def invoke_studio_window(page, status, method_name, success_message)
      page.public_send(method_name, on_result: ->(_result, error) {
        page.update(status, value: error ? "Window error: #{error}" : success_message)
      })
    end
  end
end
