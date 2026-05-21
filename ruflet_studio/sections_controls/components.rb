# frozen_string_literal: true

module RufletStudio
  module SectionsControls
    SUPPORTED_COMPONENTS = [
      { label: "Hello World", slug: "hello-world", icon: Ruflet::MaterialIcons::WAVING_HAND },
      { label: "Text", slug: "text", icon: Ruflet::MaterialIcons::TEXT_FIELDS },
      { label: "Button", slug: "button", icon: Ruflet::MaterialIcons::TOUCH_APP },
      { label: "Container", slug: "container", icon: Ruflet::MaterialIcons::CROP_SQUARE },
      { label: "Row", slug: "row", icon: Ruflet::MaterialIcons::VIEW_COLUMN },
      { label: "Column", slug: "column", icon: Ruflet::MaterialIcons::VIEW_STREAM },
      { label: "TextField", slug: "text-field", icon: Ruflet::MaterialIcons::EDIT },
      { label: "Icon", slug: "icon", icon: Ruflet::MaterialIcons::STAR },
      { label: "Image", slug: "image", icon: Ruflet::MaterialIcons::IMAGE },
      { label: "Dialog", slug: "dialog", icon: Ruflet::MaterialIcons::OPEN_IN_NEW },
      { label: "DataTable", slug: "data-table", icon: Ruflet::MaterialIcons::TABLE_CHART },
      { label: "ListTile", slug: "list-tile", icon: Ruflet::MaterialIcons::LIST },
      { label: "Switch", slug: "switch", icon: Ruflet::MaterialIcons::TOGGLE_ON },
      { label: "Slider", slug: "slider", icon: Ruflet::MaterialIcons::TUNE }
    ].freeze

    def build_components(page, status)
      column(
        spacing: 8,
        horizontal_alignment: "stretch",
        children: [
          status,
          text(value: "Supported widgets", style: { size: 18, weight: "w700", color: color_text(page) }),
          *SUPPORTED_COMPONENTS.map do |component|
            slug = component.fetch(:slug)
            control(
              :list_tile,
              bgcolor: color_surface(page),
              content_padding: { left: 12, right: 12, top: 8, bottom: 8 },
              leading: icon(icon: component.fetch(:icon), color: color_icon(page)),
              title: text(value: component.fetch(:label), style: { size: 16, color: color_text(page) }),
              trailing: icon(icon: Ruflet::MaterialIcons::CHEVRON_RIGHT, color: color_subtle(page)),
              on_click: ->(_e) { page.go("/components/#{slug}") }
            )
          end
        ]
      )
    end

    def build_component_detail(page, status, slug)
      column(
        spacing: 12,
        horizontal_alignment: "stretch",
        children: [
          status,
          component_panel(component_title(slug), component_demo(page, status, slug))
        ]
      )
    end

    def component_title(slug)
      SUPPORTED_COMPONENTS.find { |component| component.fetch(:slug) == slug }&.fetch(:label) || "Components"
    end

    def component_demo(page, status, slug)
      case slug
      when "hello-world"
        text(value: "Hello world", style: { size: 28, weight: "w700", color: color_text(page) })
      when "text"
        column(
          spacing: 8,
          children: [
            text(value: "Text"),
            text(value: "Large bold text", style: { size: 22, weight: "w700", color: "#9dccff" }),
            text(value: "Muted secondary text", style: { size: 14, color: color_subtle(page) })
          ]
        )
      when "button"
        row(
          spacing: 8,
          wrap: true,
          children: [
            filled_button(content: text(value: "Filled"), on_click: ->(_e) { page.update(status, value: "Filled button clicked") }),
            button(content: text(value: "Button"), on_click: ->(_e) { page.update(status, value: "Button clicked") }),
            text_button(content: text(value: "Text"), on_click: ->(_e) { page.update(status, value: "Text button clicked") })
          ]
        )
      when "container"
        container(
          width: 260,
          height: 120,
          padding: 16,
          bgcolor: "#172033",
          border_radius: 8,
          content: text(value: "Container with padding, color, radius, width, and height.")
        )
      when "row"
        row(
          spacing: 8,
          children: [
            component_chip("First"),
            component_chip("Second"),
            component_chip("Third")
          ]
        )
      when "column"
        column(
          spacing: 8,
          children: [
            component_chip("Top"),
            component_chip("Middle"),
            component_chip("Bottom")
          ]
        )
      when "text-field"
        text_field(label: "Name", value: "Ruflet")
      when "icon"
        row(
          spacing: 12,
          children: [
            icon(icon: Ruflet::MaterialIcons::HOME, color: "#74c0fc"),
            icon(icon: Ruflet::MaterialIcons::SETTINGS, color: "#adb5bd"),
            icon(icon: Ruflet::MaterialIcons::CHECK_CIRCLE, color: "#69db7c")
          ]
        )
      when "image"
        container(
          width: 260,
          height: 140,
          clip_behavior: "antiAlias",
          border_radius: 8,
          content: image(src: "https://picsum.photos/520/280", fit: "cover")
        )
      when "dialog"
        dialog = alert_dialog(
          open: false,
          modal: true,
          title: text(value: "Dialog"),
          content: text(value: "Hello world from a Ruflet dialog."),
          actions: [
            text_button(content: text(value: "Close"), on_click: ->(_e) { page.pop_dialog })
          ]
        )
        filled_button(content: text(value: "Open dialog"), on_click: ->(_e) { page.show_dialog(dialog) })
      when "data-table"
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
      when "list-tile"
        control(
          :list_tile,
          leading: icon(icon: Ruflet::MaterialIcons::INFO),
          title: text(value: "ListTile title"),
          subtitle: text(value: "Subtitle"),
          trailing: icon(icon: Ruflet::MaterialIcons::CHEVRON_RIGHT)
        )
      when "switch"
        control(:switch, label: "Enabled", value: true, on_change: ->(_e) { page.update(status, value: "Switch changed") })
      when "slider"
        control(:slider, min: 0, max: 100, divisions: 10, value: 35, label: "Value = {value}")
      else
        text(value: "Component not found.")
      end
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

    def component_chip(label)
      container(
        padding: { left: 12, right: 12, top: 8, bottom: 8 },
        bgcolor: "#172033",
        border_radius: 8,
        content: text(value: label)
      )
    end
  end
end
