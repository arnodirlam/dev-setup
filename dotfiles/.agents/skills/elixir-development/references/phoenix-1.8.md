# Phoenix 1.8 generated conventions

Apply only when the project retains the relevant generated components and authentication structure. Prefer nearer project instructions when generated code has been customized.

- Start top-level LiveView templates with `<Layouts.app flash={@flash} ...>` and pass required assigns such as `current_scope`.
- Treat a missing `current_scope` as a routing or layout integration problem. Put authenticated LiveViews in the proper `live_session`, configure the expected `on_mount`, and pass the scope through the layout.
- Keep `<.flash_group>` inside the `Layouts` module.
- Use the generated `<.icon>` component rather than calling Heroicons modules directly.
- Use the generated `<.input>` component when it supports the required form control.
- Supply complete styling when overriding generated input classes because custom classes replace generated defaults.
