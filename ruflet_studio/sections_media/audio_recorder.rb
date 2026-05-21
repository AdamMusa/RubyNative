# frozen_string_literal: true

require "tmpdir"

module RufletStudio
  module SectionsMedia
    def build_audio_recorder(page, status)
      recorder = page.audio_recorder(key: "studio_audio_recorder")
      recording_path = File.join(Dir.tmpdir, "ruflet_studio_recording.m4a")

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
              }),
              text_button(content: text(value: "Start"), on_click: ->(_e) {
                page.update(status, value: "Requesting microphone permission...")
                recorder.has_permission(on_result: ->(allowed, permission_error) {
                  if permission_error
                    page.update(status, value: "Permission error: #{permission_error}")
                  elsif !allowed
                    page.update(status, value: "Microphone permission is required before recording.")
                  else
                    page.update(status, value: "Recording to #{recording_path}")
                    recorder.start_recording(output_path: recording_path, on_result: ->(result, error) {
                      page.update(status, value: error ? "Start error: #{error}" : "Recording started: #{result.inspect}")
                    })
                  end
                })
              }),
              text_button(content: text(value: "Stop"), on_click: ->(_e) {
                recorder.stop_recording(on_result: ->(result, error) {
                  page.update(status, value: error ? "Stop error: #{error}" : "Recording saved: #{result.inspect || recording_path}")
                })
              }),
              text_button(content: text(value: "Cancel"), on_click: ->(_e) {
                recorder.cancel_recording(on_result: ->(result, error) {
                  page.update(status, value: error ? "Cancel error: #{error}" : "Recording cancelled: #{result.inspect}")
                })
              })
            ]
          )
        ]
      )
    end
  end
end
