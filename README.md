# remote_ruby
[![Lint & Test](https://github.com/Nu-hin/remote_ruby/actions/workflows/main.yml/badge.svg)](https://github.com/Nu-hin/remote_ruby/actions/workflows/main.yml)
[![Coverage Status](https://coveralls.io/repos/github/Nu-hin/remote_ruby/badge.svg?branch=master)](https://coveralls.io/github/Nu-hin/remote_ruby?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/e57430aa6f626aeca41d/maintainability)](https://codeclimate.com/github/Nu-hin/remote_ruby/maintainability)
[![Gem Version](https://badge.fury.io/rb/remote_ruby.svg)](https://badge.fury.io/rb/remote_ruby)

RemoteRuby allows you to execute Ruby code on remote servers via SSH right from the Ruby script running on your local machine, as if it was executed locally.

## Contents
* [Requirements](#requirements)
* [Overview](#overview)
	* [How it works](#how-it-works)
	* [Key features](#key-features)
	* [Limitations](#limitations)
* [Installation](#installation)
* [Usage](#usage)
	* [Basic usage](#basic-usage)
	* [Output](#output)
	* [Parameters](#parameters)
	* [Local variables and return value](#local-variables-and-return-value)
	* [Caching](#caching)
  * [Text mode](#text-mode)
  * [Plugins](#plugins)
    * [Adding custom plugins](#adding-custom-plugins)
    * [Rails](#rails)
* [Contributing](#contributing)
* [License](#license)

## Requirements

RemoteRuby requires at least Ruby 2.7 to run.

## Overview

Here is a short example on how you can run your code remotely.

```ruby
# This is test.rb file on the local developer machine

require 'remote_ruby'

remotely(host: 'my_ssh_server') do
  # Everything inside this block is executed on my_ssh_server
  puts 'Hello, RemoteRuby!'
end
```

### How it works

When you call `#remotely` or `RemoteRuby::ExecutionContext#execute`, the passed block source is read and is then transformed to a standalone Ruby script, which also includes serialization/deserialization of local variables and return value, and other features (see [compiler.rb](lib/remote_ruby/compiler.rb) for more detail).

After that, RemoteRuby opens an SSH connection to the specified host, copies the script to the host (to a temporary file), and then launches runs this script using the Ruby interpreter on the host. Standard output and standard error streams of SSH client are being captured. Standard input is passed to the remote code as well.

### Key features

* Access local variables inside the remote block, just as in case of a regular block:

```ruby
user_id = 1213

remotely(host: 'my_ssh_server') do
  puts user_id # => 1213
end
```

* Access return value of the remote block, just as in case of a regular block:

```ruby
res = remotely(host: 'my_ssh_server') do
  'My result'
end

puts res # => My result
```

* Assignment to local variables inside remote block, just as in case of a regular block:

```ruby
a = 1

remotely(host: 'my_ssh_server') do
  a = 100
end

puts a # => 100
```

* Reading from the client's standard input in the remote block:


```ruby
remotely(host: 'my_ssh_server') do
  puts 'What is your name?'
  name = gets
  puts "Hello, #{name}!"
end
```

### Limitations
*  Remote SSH server must be accessible with public-key authentication. Password authentication is not supported.

* As RemoteRuby reads the block source from the script's source file, the script source file should reside on your machine's disk (e.g. you cannot use RemoteRuby from IRB console).

* Since local and server scripts have different execution contexts, can have different gems (and even Ruby versions) installed, sometimes local variables as well as the block return value, will not be accessible, assigned or can even cause exception. See [usage](#local-variables-and-return-value) section below for more detail.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'remote_ruby'
```

And then execute:
```bash
bundle
```

Alternatively, install RemoteRuby in your gemset with the following command:
```bash
gem install remote_ruby
```

## Usage

### Basic usage

The main class to work with is the `ExecutionContext`, which provides an `#execute` method:

```ruby
my_server = ::RemoteRuby::ExecutionContext.new(host: 'my_ssh_server')

my_server.execute do
  puts Dir.pwd
end
```

You can easily define more than one context to access several servers.

Along with `ExecutionContext#execute` method there is also `.remotely` method, which is included into the global scope. For instance, the code above is equivalent to the code below:

```ruby
remotely(host: 'my_ssh_server') do
  puts Dir.pwd
end
```

All parameters passed to the `remotely` method will be passed to the underlying `ExecutionContext` initializer. The only exception is an optional `locals` parameter, which will be passed to the `#execute` method (see [below](#local-variables-and-return-value)).

### Parameters

| Parameter | Type | Required | Default value | Description |
| --------- | ---- | ---------| ------------- | ----------- |
| host | String | no | - | Name of the SSH host to connect to. If omitted, the code will be executed on the local host, in a separate Ruby process |
| working_dir | String | no | '~' if running over SSH, or current dir, if running locally | Path to the directory where the script should be executed |
| user | String | no | - | Name of the SSH user. Only specify is running over SSH |
| use_cache | Boolean | no | `false` | Specifies if the cache should be used for execution of the block (if the cache is available). Refer to the [Caching](#caching) section to find out more about caching. |
| save_cache | Boolean | no | `false` | Specifies if the result of the block execution (i.e. output and error streams) should be cached for the subsequent use. Refer to the [Caching](#caching) section to find out more about caching. |
| cache_dir | String | no | ./cache | Path to the directory on the local machine, where cache files should be saved. If the directory doesn't exist, RemoteRuby will try to create it. Refer to the [Caching](#caching) section to find out more about caching. |
| in_stream | Stream open for reading | no | `$stdin` | Source stream for server standard input |
| out_stream | Stream open for writing | no | `$stdout` | Redirection stream for server standard output |
| err_stream | Stream open for writing | no | `$stderr` | Redirection stream for server standard error|
| text_mode | Boolean or Hash | no | `false` | Specifies, if the connection should be run in text mode. See [Text Mode](#text-mode) section below to find out more about text mode. |
| code_dump_dir | String | no | `nil` | Specifies a directory to dump the actual code, executed by the context on the remote server. The directory must exist. |

### Output

Standard output and standard error streams from the remote process are captured, and then, depending on your parameters are either forwarded to local STDOUT/STDERR or to the specified streams.

```ruby
  remotely(host: 'my_ssh_server', working_dir: '/home/john') do
    puts 'This is an output'
    warn 'This is a warning'
  end
```

### Input

Standard input from the client is captured and passed to the remote code. By default the input is captured from STDIN.

```ruby
  name = remotely(host: 'my_ssh_server') do
    puts "What is your name?"
    gets
  end

  puts "Hello locally, #{name}!"
```

### Local variables and return value

When you call a remote block RemoteRuby will try to serialize all local variables from the calling context, and include them to the remote script.

If you do not want all local variables to be sent to the server, you can explicitly specify a set of local variables and their values.

```ruby
some_number = 3
name = 'Alice'

# Explicitly setting locals with .remotely method
remotely(locals: { name: 'John Doe' }, host: 'my_ssh_server') do
  # name is 'John Doe', not 'Alice'
  puts name # => John Doe
  # some_number is not defined
  puts some_number # undefined local variable or method `some_number'
end

# Explicitly setting locals with ExecutionContext#execute method
execution_context = ::RemoteRuby::ExecutionContext.new(host: 'my_ssh_server')

execution_context.execute(name: 'John Doe') do
  # name is 'John Doe', not 'Alice'
  puts name # => John Doe
  # some_number is not defined
  puts some_number # undefined local variable or method `some_number'
end
```

However, some objects cannot be serialized. In this case, RemoteRuby will print a warning, and the variable **will not be defined** inside the remote block.

```ruby
# We cannot serialize a file stream
file = File.open('some_file.txt', 'rb')

remotely(host: 'my_ssh_server') do
  puts file.read # undefined local variable or method `file'
end
```

Moreover, if such variables are assigned to in the remote block, their value **will not change** in the calling scope:

```ruby
file = File.open('some_file.txt', 'rb')

remotely(host: 'my_ssh_server') do
  file = 3 # No exception here, as we are assigning
end

# Old value is retained
puts file == 3 # false
```

If the variable can be serialized, but the remote server context lacks the knowledge on how to deserialize it, the variable will be defined inside the remote block, but its value will be `nil`:

```ruby
# Something, that is not present on the remote server
special_thing = SomeSpecialGem::SpecialThing.new

remotely(host: 'my_ssh_server') do
  # special_thing is defined, but its value is nil
  puts special_thing.nil? # => true

  # but we can still reassign it:
  special_thing = 3
end

puts special_thing == 3 # => true
```

If RemoteRuby cannot deserialize variable on server side, it will print a warning to server's STDERR stream.

If remote block returns a value which cannot be deserialized on the client side, or if it assigns such a value to the local variable, the exception on the client side will be always raised:

```ruby
# Unsupportable return value example

remotely(host: 'my_ssh_server') do
  # this is not present in the client context
  server_specific_var = ServerSpecificClass.new
end

# RemoteRuby::Unmarshaler::UnmarshalError
```

```ruby
# Unsupportable local value example

my_local = nil

remotely(host: 'my_ssh_server') do
  # this is not present in the client context
  my_local = ServerSpecificClass.new
  nil
end

# RemoteRuby::Unmarshaler::UnmarshalError
```

To avoid these situations, do not assign/return values unsupported on the client side, or, if you don't need any return value, add `nil` at the end of your block:

```ruby
# No exception

remotely(host: 'my_ssh_server') do
  # this is not present in the client context
  server_specific_var = ServerSpecificClass.new
  nil
end
```

### Caching

RemoteRuby allows you to save the result of previous block excutions in the local cache on the client machine to save you time on subsequent script runs. To enable saving of the cache, set `save_cache: true` parameter. To turn reading from cache on, use `use_cache: true` parameter.

```ruby
# Caching example
# First time this script will take 60 seconds to run,
# but on subsequent runs it will return the result immidiately

require 'remote_ruby'

res = remotely(host: 'my_ssh_server', save_cache: true, use_cache: true) do
  60.times do
    puts 'One second has passed'
    sleep 1
  end

  'Some result'
end

puts res # => Some result
```

You can specify where to put your cache files explicitly, by passing `cache_dir` parameter which is the "cache" directory inside your current working directory by default.

RemoteRuby calculates the cache file to use, based on the code you pass to the remote block, as well as on ExecutionContext 'contextual' parameters (e. g. server or working directory) and serialized local variables. Therefore, if you change anything in your remote block, local variables (passed to the block), or in any of the 'contextual' parameters, RemoteRuby will use different cache file. However, if you revert all your changes back, the old file will be used again.

**IMPORTANT**: RemoteRuby does not know when to clear the cache. Therefore, it is up to you to take care of cleaning the cache when you no longer need it. This is especially important if your output can contain sensitive data.

### Text mode

Text mode allows to treat the output and/or the standard error of the remote process as text. If it is enabled, the server output is prefixed with some string, which makes it easier to distinguish local ouput, and the output coming from the remote code. Additionally it may help distinguishing when the output is taken from cache.

The text mode is controlled by the `text_mode` parameter to the `::RemoteRuby::ExecutionContext` initializer, and is `false` by default.

The easiest way to enable it is to set `text_mode` to `true`.

```ruby
ctx = ::RemoteRuby::ExecutionContext.new(
  host: 'my_ssh_server',
  user: 'jdoe'
  text_mode: true,
)

ctx.execute do
  puts "This is a greeting"
  warn "This is an error"
end
```

This will produce:

```
jdoe@my_ssh_server:~> This is a greeting
jdoe@my_ssh_server:~> This is a greeting
```

By default, the prefixes for stdout and stderr can be different when running over SSH and locally. Output prefix is marked with green italic, and error with red italic. If the cache is used, the default configuration will append a bold blue '[C]' prefix in front of each ouput line.


You can fine-tune the text mode to your needs by passing a hash as a value to `text_mode` parameter:

```ruby
ctx = ::RemoteRuby::ExecutionContext.new(
  host: 'my_ssh_server',
  user: 'jdoe'
  text_mode: {
    stdout_prefix: 'server says: ',
    stdout_prefix: 'server warns: ',
    stdout_mode: { color: :blue, mode: :underline }
  }
)
```

This will produce

```
server says: This is a greeting
server warns: This is a greeting
```

It is reasonable to avoid text mode if you want to put binary data to stdout:

```ruby
# copy_avatar.rb
# Reads a file from remote server and writes it to client's stdout.

remotely(host: 'my_ssh_server', text_mode: false) do
  STDOUT.write File.read('avatar.jpg')
end
```

Now you could do:

```shell
ruby copy_avatar.rb > avatar.jpg
```


The complete list of text mode parameters is in the table below:

| Parameter | Type | Default value | Description |
|-|-|-|-|
| stdout_prefix | String | `user@host:/path/to/working/dir> ` | Prepended to standard output lines. Set to `nil` to disable |
| stderr_prefix | String | `user@host:/path/to/working/dir> ` | Prepended to standard error lines. Set to `nil` to disable |
| cache_prefix | String | `'[C] '` | Prepended to standard output and standard error lines if the context is using cache. Only added if corresponding prefix is not `nil`. Set to `nil` to disable |
| disable_unless_tty | Boolean | true | Disables the text mode if the corresponding IO is not TTY. Useful if you want to disable the prefixes and coloring when e.g. outputting to a file |
| stdout_mode | Hash | `{ color: :green, mode: :italic }` | Text effects and colors applied to the standard output prefix. See [colorize gem](https://github.com/fazibear/colorize) for available parameters.
| stderr_mode | Hash | `{ color: :red, mode: :italic }` | Text effects and colors applied to the standard error prefix. See [colorize gem](https://github.com/fazibear/colorize) for available parameters.
| cache_mode | Hash | `{ color: :blue, mode: :bold }` | Text effects and colors applied to the cache prefix. See [colorize gem](https://github.com/fazibear/colorize) for available parameters.

### Plugins
RemoteRuby can be extended with plugins. Plugins are used to insert additional code to the script, which is executed in the remote context. There is also a built-in plugin that allows for automatically loading Rails environment.

#### Adding custom plugins

RemoteRuby plugin must be a class. Instances of a plugin class must respond to `#code_header` method without any parameters. Plugins are instantiated when the `ExecutionContext` is created.

You may inherit your class from `::RemoteRuby::Plugin` class but that is not necessary.

Let's take a look at an example plugin:

```ruby
class UsernamePlugin < RemoteRuby::Plugin
# This plugin prints a name of the user on the calling host.
  attr_reader :username

  def initialize(username:)
    @username = username
  end

  def code_header
    <<~RUBY
      puts "This code is run by #{username}"
    RUBY
  end
end
```

In order to be used, the plugin needs to be registered. You can register a plugin by calling `#register_plugin` method.

```ruby
RemoteRuby.configure do |c|
  c.register_plugin(:username_printer, UsernamePlugin)
end
```

Now, when creating an `ExecutionContext` we can use `username_printer` argument to the initializer. Plugin argument value must be a hash. All hash values will be passed to plugin class initializer as name arguments.

```ruby
  ec = RemoteRuby::ExecutionContext.new(
    host: 'my_ssh_server',
    username_printer: { username: ENV['USER'] }
  )

  ec.execute do
    puts "Hello world!"
  end
```

This should print the following:

```
This code is run by jdoe
Hello world!
```


#### Rails plugin
RemoteRuby can load Rails environment for you, if you want to execute a script in a Rails context. To do this, simply add add built-in Rails plugin by adding `rails` argument to your call:

```ruby
# Rails integration example

require 'remote_ruby'

remote_service = ::RemoteRuby::ExecutionContext.new(
  host: 'rails-server',
  working_dir: '/var/www/rails_app/www/current',
  # This specifies ENV['RAILS_ENV'] and can be changed
  rails: { environment: :production }
 )

user_email = 'john_doe@mydomain.com'

phone = remote_service.execute do
  user = User.find_by(email: user_email)
  user.try(:phone)
end

puts phone
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nu-hin/remote_ruby.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
