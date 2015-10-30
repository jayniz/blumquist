# Blumquist [![Circle CI](https://circleci.com/gh/moviepilot/blumquist/tree/master.svg?style=svg)](https://circleci.com/gh/moviepilot/blumquist/tree/master) [![Coverage Status](https://coveralls.io/repos/moviepilot/blumquist/badge.svg?branch=master&service=github)](https://coveralls.io/github/moviepilot/blumquist?branch=master)

![](https://dl.dropboxusercontent.com/u/1953503/blumquist.jpg)

Given a JSON schema and some data, Blumquist will give you an immutable object that has getters defined for all properties from the JSON schema. Works well with schemas using JSON pointers as well as for properties that are themselves objects or arrays.

## Usage

1. Give it a schema
2. Give it some data
3. Get an object with getters

(Sorry, no profit step.)

### 1. Give it a schema

```json
schema = {
  "$schema": "http://json-schema.org/draft-04/schema#",

  "definitions": {
    "address": {
      "type": "object",
      "properties": {
        "street": { "type": "string" },
        "city":   { "type": "string" },
        "state":  { "type": "string" }
      },
      "required": ["street", "city", "state"]
    }
  },

  "type": "object",

  "properties": {
    "name": { "type": "string" },
    "current_address": { "$ref": "#/definitions/address" },
    "old_addresses": { "type": "array", "items": { "$ref": "#/definitions/address"   } }
  }
}
```

### 2. Give it some data
```ruby
data = {
  "name": "Moviepilot, Inc.",
  "current_address": {
    "street_address": "Friedrichstr. 58",
    "city": "Berlin",
    "state": "Berlin"
  },
  "old_addresses": [
    {
      "street_address": "Blücherstr. 22",
      "city": "Berlin",
      "state": "Berlin"
    },
    {
      "street_address": "Mehringdamm 33",
      "city": "Berlin",
      "state": "Berlin"
    }
  ]
}

```
### 3. And you get...
... an object with getters for all properties defined in the schema

```ruby
> b = Blumquist.new(schema: schema, data: data)
=> #<Blumquist:0x0....>
> b.name
=> "Moviepilot, Inc."
> b.old_addresses.first.street
=> "Blücherstr. 22"
```

### Validation

By default, Blumquist will validate the data. If you don't want that to happen, do as follows:

```ruby
> b = Blumquist.new(schema: schema, data: data, validate: false)
=> ...
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blumquist'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install blumquist

## Contributing

Bug reports and pull requests are welcome on GitHub in the [issues section](https://github.com/moviepilot/blumquist/issues). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
