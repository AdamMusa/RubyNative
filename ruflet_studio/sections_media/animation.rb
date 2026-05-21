# frozen_string_literal: true

module RufletStudio
  module SectionsMedia
    def build_animation(page, status)
      size = 26
      duration = 2000
      width = 520
      height = 280

      colors = ["#4dabf7", "#69db7c", "#ffd43b", "#ff922b", "#f06595", "#7950f2"]
      orbit = [
        [40, 40], [140, 40], [240, 40], [340, 40], [440, 40],
        [440, 120], [440, 200], [340, 200], [240, 200], [140, 200],
        [40, 200], [40, 120]
      ]

      scattered = true
      motion = animation(duration, curve: Ruflet::AnimationCurve::EASE_IN_OUT_CUBIC)
      bounce = animation(duration, curve: Ruflet::AnimationCurve::BOUNCE_OUT)

      parts_controls = orbit.map.with_index do |_point, index|
        container(
          animate: motion,
          animate_position: motion,
          animate_rotation: bounce,
          left: rand(width),
          top: rand(height),
          bgcolor: colors[index % colors.length],
          width: rand((size / 2).to_i..(size * 2)),
          height: rand((size / 2).to_i..(size * 2)),
          border_radius: 8,
          rotate: rand(0..90) * Math::PI / 180
        )
      end

      canvas = stack(
        width: width,
        height: height,
        animate_scale: bounce,
        animate_opacity: motion,
        scale: 3,
        opacity: 0.3
      )
      canvas.children.replace(parts_controls)

      btn = button(content: text(value: "Go!"))
      toggle = lambda do
        scattered = !scattered
        page.update(canvas, scale: scattered ? 3 : 1, opacity: scattered ? 0.3 : 1)
        parts_controls.each_with_index do |control, idx|
          px, py = orbit[idx]
          if scattered
            page.update(
              control,
              left: rand(width),
              top: rand(height),
              width: rand((size / 2).to_i..(size * 2)),
              height: rand((size / 2).to_i..(size * 2)),
              border_radius: 8,
              rotate: rand(0..90) * Math::PI / 180
            )
          else
            page.update(
              control,
              left: px,
              top: py,
              width: size,
              height: size,
              border_radius: 13,
              rotate: 0
            )
          end
        end
        page.update(btn, content: text(value: scattered ? "Go!" : "Again!"))
        page.update(status, value: scattered ? "Shapes scattered." : "Shapes aligned.")
      end
      btn.on(:click) { |_e| toggle.call }

      container(
        alignment: "center",
        content: column(
          alignment: "center",
          horizontal_alignment: "center",
          tight: true,
          children: [canvas, btn]
        )
      )
    end
  end
end
