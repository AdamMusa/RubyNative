# frozen_string_literal: true

module RufletStudio
  module SectionsControls
    SUPPORTED_COMPONENTS = [
      "Text",
      "Button",
      "Container",
      "Row",
      "Column",
      "TextField",
      "Icon",
      "Image",
      "Dialog",
      "DataTable",
      "ListTile",
      "Switch",
      "Slider"
    ].freeze

    def build_components(page, status)
      dialog = nil
      dialog = alert_dialog(
        open: false,
        modal: true,
        title: text(value: "Dialog"),
        content: text(value: "Hello world from a Ruflet dialog."),
        actions: [
          text_button(content: text(value: "Close"), on_click: ->(_e) { page.update(dialog, open: false) })
        ]
      )

      column(
        spacing: 12,
        horizontal_alignment: "stretch",
        children: [
          status,
          component_panel(
            "Hello World",
            text(value: "Hello world", style: { size: 24, weight: "w700", color: color_text(page) })
          ),
          component_panel(
            "Button",
            row(
              spacing: 8,
              wrap: true,
              children: [
                filled_button(content: text(value: "Filled"), on_click: ->(_e) { page.update(status, value: "Filled button clicked") }),
                button(content: text(value: "Button"), on_click: ->(_e) { page.update(status, value: "Button clicked") }),
                text_button(content: text(value: "Text"), on_click: ->(_e) { page.update(status, value: "Text button clicked") })
              ]
            )
          ),
          component_panel(
            "Container Row Column",
            container(
              padding: 12,
              bgcolor: "#172033",
              border_radius: 8,
              content: column(
                spacing: 8,
                children: [
                  text(value: "Column item"),
                  row(
                    spacing: 8,
                    children: [
                      icon(icon: Ruflet::MaterialIcons::STAR, color: "#ffd43b"),
                      text(value: "Row item")
                    ]
                  )
                ]
              )
            )
          ),
          component_panel(
            "TextField",
            text_field(label: "Name", value: "Ruflet")
          ),
          component_panel(
            "Icon",
            row(
              spacing: 12,
              children: [
                icon(icon: Ruflet::MaterialIcons::HOME, color: "#74c0fc"),
                icon(icon: Ruflet::MaterialIcons::SETTINGS, color: "#adb5bd"),
                icon(icon: Ruflet::MaterialIcons::CHECK_CIRCLE, color: "#69db7c")
              ]
            )
          ),
          component_panel(
            "Dialog",
            filled_button(content: text(value: "Open dialog"), on_click: ->(_e) { page.show_dialog(dialog) })
          ),
          component_panel(
            "DataTable",
            data_table(
              [
                data_column("Widget"),
                data_column("Status")
              ],
              rows: [
                data_row([data_cell("Text"), data_cell("Supported")]),
                data_row([data_cell("Button"), data_cell("Supported")]),
                data_row([data_cell("Dialog"), data_cell("Supported")])
              ],
              column_spacing: 24,
              heading_row_height: 42,
              data_row_min_height: 38,
              data_row_max_height: 44
            )
          ),
          component_panel(
            "Supported widgets",
            column(
              spacing: 4,
              children: SUPPORTED_COMPONENTS.map do |name|
                row(
                  spacing: 8,
                  children: [
                    icon(icon: Ruflet::MaterialIcons::CHECK, color: "#69db7c"),
                    text(value: name)
                  ]
                )
              end
            )
          )
        ]
      )
    end

    def component_panel(title, content)
      container(
        padding: 12,
        bgcolor: "#111827",
        border_radius: 8,
        content: column(
          spacing: 8,
          children: [
            text(value: title, style: { size: 14, weight: "w600" }),
            content
          ]
        )
      )
    end
  end
end
