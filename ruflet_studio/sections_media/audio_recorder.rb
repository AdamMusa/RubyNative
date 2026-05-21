# frozen_string_literal: true

module RufletStudio
  module SectionsMedia
    def build_audio_recorder(page, status)
      recorder = page.audio_recorder(key: "studio_audio_recorder")
      permissions = page.permission_handler(key: "studio_audio_permissions")
      recording_path = "ruflet_studio_recording.wav"

      column(
        spacing: 8,
        children: [
          status,
          row(
            spacing: 8,
            wrap: true,
            children: [
              text_button(content: text(value: "Permission"), on_click: ->(_e) {
                permissions.get_status("microphone", on_result: ->(result, error) {
                  page.update(status, value: error ? "Permission status error: #{error}" : "Microphone permission: #{result.inspect}")
                })
              }),
              text_button(content: text(value: "Input devices"), on_click: ->(_e) {
                recorder.get_input_devices(on_result: ->(result, error) {
                  page.update(status, value: error ? "Devices error: #{error}" : "Devices: #{result.inspect}")
                })
              }),
              text_button(content: text(value: "Start"), on_click: ->(_e) {
                page.update(status, value: "Requesting microphone permission...")
                permissions.request("microphone", on_result: ->(permission_result, permission_error) {
                  if permission_error
                    page.update(status, value: "Permission error: #{permission_error}")
                    next
                  end

                  unless %w[granted limited].include?(permission_result.to_s)
                    page.update(status, value: "Microphone permission: #{permission_result.inspect}")
                    next
                  end

                  recorder.has_permission(on_result: ->(allowed, recorder_error) {
                    if recorder_error
                      page.update(status, value: "Recorder permission error: #{recorder_error}")
                    elsif !allowed
                      page.update(status, value: "Recorder still has no microphone permission.")
                    else
                      page.update(status, value: "Recording to #{recording_path}")
                      recorder.start_recording(output_path: recording_path, configuration: { encoder: "wav" }, on_result: ->(result, error) {
                        page.update(status, value: error ? "Start error: #{error}" : "Recording started: #{result.inspect}")
                      })
                    end
                  })
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
