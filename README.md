# YapiCheck

[en](./README.md) | [zh-CN](./README.zh-CN.md)

> YAPI is an excellent tool for managing API documentation, but maintaining consistency between the API documentation and code can be challenging. Instead of relying on manual recognition, let this tool automate the process for you.

This is a tool for checking the consistency and conformity between YAPI API documentation and code, ensuring strong consistency and adherence to standards.

## Key Features

### 1. Request Parameter Check
+ Scans the source code of actions, captures the lucky_param parameters of actions, and matches them with the input metadata of YAPI documentation.
  + Supports mandatory and optional validation
  + JSON parameters support type validation, including String, Float, and Integer types
  + Parameter checks require each field to be on a separate line, like:
    ```ruby
      required(:name, :String) # Name
      required(:phone, :Integer) # Phone number
      required(:height, :Float) # Height
      optional(:email, :Email) # Email
      optional(:tags, :ArrayJSON) # Tags
    ```
### 2. Response Parameter Check
+ Matches Jbuilder source code with the output metadata of YAPI documentation.
  + Supports sub-views
  + Supports paths relative to the root directory or the current file directory
  + Action names must match the Jbuilder file names
  + Output requires each returned field to be on a separate line
  + Output requires mandatory type conversion:
    + Strings: Recognized using to_s, json.attr_name ... to_s
    + Integers: Recognized using to_i, json.attr_name ... to_i
    + Floats: Recognized using to_f, json.attr_name ... to_f
    + Arrays: Recognized using to_a or do, json.attr_name ... each do
    + Hashes: Recognized using to_h or do, json.attr_name each do
  ```ruby
  json.user do
    json.name   user.name.to_s
    json.phone  user.phone.to_i
    json.height user.height.to_f
    json.email  user.email.to_s
    json.tags   user.tags.to_a
  end
  ```
  + Does not support boolean types; use integers instead
  + Attributes must be included in the data object, such as: {"code":200, "data":{}}
### 3. Batch Check
+ Supports checking all interfaces of a single project
+ Supports checking a single interface
+ Supports checking interfaces under a single tag

## Usage Instructions

1. Add the following line to your Rails project's Gemfile:

```ruby
gem 'yapi_check'
```

2. Run bundle install:

```shell
$ bundle install
```

3. Insert the following code into your project's Rakefile:

```ruby
require 'yapi_check/tasks'
ENV['YAPI_PROJECT_TOKEN'] = 'THE_TOKEN_FROM_YOUR_YAPI_PROJECT' # YAPI project unique identifier (required), recommended to configure in the project. You can find this token in the YAPI project settings.
ENV['YAPI_PROJECT_DOMAIN'] = 'http://YOUR_YAPI_WEBSITE' # YAPI project domain, recommended to configure on your local machine to avoid changes in ~/.bashrc or ~/.zshrc
ENV['YAPI_API_PREFIX'] = '' # YAPI project API prefix, can be set to '', defaults to /api/v1 if not set
```

4. Run YAPI check:
Note: If using zsh, install the rake plugin in ~/.zshrc to support special syntax plugins=(... rake)

```shell
# Full check
$ bundle exec rake yapi:check
# or
$ rails yapi:check

# Check a single interface
$ bundle exec rake yapi:check[/healthy_lives/exit_healthy_life]
# or
$ noglob rails yapi:check[/healthy_lives/exit_healthy_life]
# or
$ rails 'yapi:check[/healthy_lives/exit_healthy_life]'

# Check a single tag
$ bundle exec rake yapi:check[,3.3.0]
# or
$ noglob rails yapi:check[,3.3.0]
# or
$ rails 'yapi:check[,3.3.0]'
```

## Notes

This tool is only for Rails projects. Request parameter checks heavily depend on [lucky_param](https://github.com/shootingfly/lucky_param), and response parameter checks heavily depend on [Jbuilder](https://github.com/rails/jbuilder).

## Contributing

1. Fork it ( https://github.com/shootingfly/yapi_check/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Make your changes
4. Run `ruby test/yapi_check_test.rb` to run the tests
5. Commit your changes (git commit -am 'Add some feature')
6. Push to the branch (git push origin my-new-feature)
7. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
