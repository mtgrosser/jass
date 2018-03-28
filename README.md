# Jass

Roll ES6 and VueJS single file components with the Rails asset pipeline - no Webpack required!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jass'
```

You need a working NodeJS installation.

## Usage

Use `yarn` to Install your custom node dependencies into vendor/node_modules.
`vendor/package.json` and `vendor/yarn.lock` should be checked into source control.

Create your bundle entry points as `.jass` files under `app/assets/javascripts` in regular
ES6 syntax (`import`, `async/await`).

External dependencies can be declared to Sprockets using the `external` comment:

```js
//= external vue
//= external vue-router
```
