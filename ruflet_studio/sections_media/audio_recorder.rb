# frozen_string_literal: true

module RufletStudio
  module SectionsMedia
    def build_audio_recorder(page, status)
      recorder = page.audio_recorder(key: "studio_audio_recorder")

      column(
        spacing: 8,
        children: [
          status,
          row(
            spacing: 8,
            wrap: true,
            children: [
              text_button(content: text(value: "Permission"), on_click: ->(_e) {
                recorder.has_permission(on_result: ->(result, error) {
                  page.update(status, value: error ? "Recorder error: #{error}" : "Permission: #{result.inspect}")
                })
              }),
              text_button(content: text(value: "Input devices"), on_click: ->(_e) {
                recorder.get_input_devices(on_result: ->(result, error) {
                  page.update(status, value: error ? "Devices error: #{error}" : "Devices: #{result.inspect}")
                })
              })
            ]
          )
        ]
      )
    end
  end
end
