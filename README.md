# Jass

Roll ES6 and VueJS single file components with the Rails asset pipeline - no Webpack required!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jass'
```

You need a working NodeJS installation.

## Configuration

In Rails apps the location of your custom npm dependencies will be automatically
set to:

```
Jass.vendor_modules_root = Rails.root.join('vendor')
```

For other frameworks, it needs to be set manually using the above method.

## Usage

Use `yarn` to install your custom npm dependencies into `vendor/node_modules`.
`vendor/package.json` and `vendor/yarn.lock` should be checked into source control.

Create your bundle entry points as `.jass` files under `app/assets/javascripts` in regular
ES6 syntax (`import`, `async/await`).

External dependencies can be declared to Sprockets using the `external` comment:

```js
// application.jass
//= external vue
//= external vue-router

import Vue from 'vue'
import Foo from 'custom-dependency'
```
