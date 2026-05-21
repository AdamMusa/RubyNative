# frozen_string_literal: true

module RufletStudio
  module SectionsMedia
    def build_animation(page, status)
      duration = 1800
      motion = animation(duration, curve: Ruflet::AnimationCurve::EASE_IN_OUT_CUBIC)
      bounce = animation(duration, curve: Ruflet::AnimationCurve::BOUNCE_OUT)

      expanded = false
      word = container(
        animate_position: motion,
        animate_scale: bounce,
        animate_opacity: motion,
        left: 96,
        top: 70,
        scale: 0.82,
        opacity: 0.72,
        content: text(
          value: "Ruflet",
          style: {
            size: 88,
            weight: "w700",
            color: "#9dccff"
          }
        )
      )

      underline = container(
        animate_position: motion,
        animate_size: motion,
        animate_opacity: motion,
        left: 142,
        top: 174,
        width: 120,
        height: 6,
        opacity: 0.55,
        bgcolor: "#4dabf7",
        border_radius: 3
      )

      stage = stack(
        width: 560,
        height: 230,
        children: [word, underline]
      )

      btn = button(content: text(value: "Go!"))
      toggle = lambda do
        expanded = !expanded
        page.update(
          word,
          left: expanded ? 72 : 96,
          top: expanded ? 54 : 70,
          scale: expanded ? 1.08 : 0.82,
          opacity: expanded ? 1.0 : 0.72
        )
        page.update(
          underline,
          left: expanded ? 96 : 142,
          top: expanded ? 186 : 174,
          width: expanded ? 360 : 120,
          opacity: expanded ? 1.0 : 0.55,
          bgcolor: expanded ? "#69db7c" : "#4dabf7"
        )
        page.update(btn, content: text(value: expanded ? "Again!" : "Go!"))
        page.update(status, value: expanded ? "Ruflet animated." : "Ruflet reset.")
      end
      btn.on(:click) { |_e| toggle.call }

      container(
        alignment: "center",
        content: column(
          alignment: "center",
          horizontal_alignment: "center",
          tight: true,
          spacing: 12,
          children: [stage, btn]
        )
      )
    end
  end
end
