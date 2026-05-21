# Ruflet

Ruflet is a Ruby framework inspired by Flet for building web, desktop, and mobile apps in Ruby.

Current Ruby gems release in this repo: **0.0.14** (`ruflet`, `ruflet_core`, `ruflet_server`)
Current Rails integration release: **0.0.8**
Current Flutter embedded Ruby runtime package: **ruby_runtime ^0.0.3** from pub.dev

Class-based apps are the recommended and documented standard:
- `class MyApp < Ruflet::App`
- implement `def view(page)`

## Start Here

1. Install mobile client app from releases:
- [Ruflet Releases](https://github.com/AdamMusa/Ruflet/releases)
- Install the latest Android APK or iOS build.

2. Install gems from RubyGems:

```bash
gem install ruflet
```

3. Create and run your first app:

```bash
ruflet new my_app
cd my_app
bundle install
ruflet run main.rb
```

4. Open Ruflet mobile client and connect:
- Enter URL manually, or
- Tap `Scan QR` and scan QR shown by `ruflet run ...`

## Package Split

Ruflet is split into packages:

- `ruflet`: CLI/install package users install from RubyGems
- `ruflet_core`: core runtime implementation (protocol + UI)
- `ruflet_server`: WebSocket runtime
- `ruflet_rails`: Rails integration

Monorepo folders:

- `packages/ruflet`
- `packages/ruflet_core`
- `packages/ruflet_server`
- `packages/ruflet_rails`

## New Project Behavior

`ruflet new <appname>` generates a `Gemfile` with:

- `gem "ruflet_core"`
- `gem "ruflet_server"`

It does **not** add the CLI gem to app dependencies.

## Breaking Change

The CLI gem name changed:

- old: `gem install ruflet_cli`
- new: `gem install ruflet`

`ruflet` now keeps the old CLI dependency shape and does not bundle runtime gem dependencies.

That keeps CLI global/tooling-level and app deps runtime-focused.

## RubyGems Release Build

Build each release gem from its package directory. RubyGems validates files relative to the current package root, so do not build with a nested gemspec path from the monorepo root.

```bash
cd /Users/macbookpro/Documents/Izeesoft/FlutterApp/ruflet
(cd packages/ruflet_core && /opt/homebrew/opt/ruby/bin/gem build ruflet_core.gemspec)
(cd packages/ruflet && /opt/homebrew/opt/ruby/bin/gem build ruflet.gemspec)
(cd packages/ruflet_server && /opt/homebrew/opt/ruby/bin/gem build ruflet_server.gemspec)
(cd packages/ruflet_rails && /opt/homebrew/opt/ruby/bin/gem build ruflet_rails.gemspec)
```

Upload to RubyGems in dependency order:

```bash
(cd packages/ruflet_core && /opt/homebrew/opt/ruby/bin/gem push ruflet_core-0.0.14.gem)
(cd packages/ruflet && /opt/homebrew/opt/ruby/bin/gem push ruflet-0.0.14.gem)
(cd packages/ruflet_server && /opt/homebrew/opt/ruby/bin/gem push ruflet_server-0.0.14.gem)
(cd packages/ruflet_rails && /opt/homebrew/opt/ruby/bin/gem push ruflet_rails-0.0.8.gem)
```

## App Style (Required in docs/examples)

Use class-based apps:

```ruby
require "ruflet"

class MyApp < Ruflet::App
  def view(page)
    page.vertical_alignment = Ruflet::MainAxisAlignment::CENTER
    page.horizontal_alignment = Ruflet::CrossAxisAlignment::CENTER
    page.title = "Hello"
    page.add(page.text(value: "Hello Ruflet"))
  end
end

MyApp.new.run
```

## CLI

```bash
ruflet new <appname>
ruflet run [scriptname|path] [--web|--mobile|--desktop]
ruflet build <apk|ios|aab|web|macos|windows|linux|zip>
```

By default `ruflet build ...` looks for Flutter client at `./ruflet_client`.
Set `RUFLET_CLIENT_DIR` to override.

## Development (Monorepo)

```bash
cd /Users/macbookpro/Documents/Izeesoft/FlutterApp/ruflet
/opt/homebrew/opt/ruby/bin/bundle install
```

## Documentation

- [Creating New App](docs/creating_new_app.md)
- [Widgets Guide](docs/widgets.md)
- Example apps: [main.rb](examples/main.rb), [solitaire.rb](examples/solitaire.rb), [calculator.rb](examples/calculator.rb)
