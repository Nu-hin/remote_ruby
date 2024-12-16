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
	* [Adapters](#adapters)
		* [SSH STDIN adapter](#ssh-stdin-adapter)
		* [Local SDIN adapter](#local-stdin-adapter)
		* [Evaluating adapter](#evaluating-adapter)
	* [Rails](#rails)
* [Contributing](#contributing)
* [License](#license)

## Requirements

RemoteRuby requires at least Ruby 2.6 to run.

## Overview

Here is a short example on how you can run your code remotely.

```ruby
# This is test.rb file on the local developer machine

require 'remote_ruby'

remotely(server: 'my_ssh_server') do
  # Everything inside this block is executed on my_ssh_server
  puts 'Hello, RemoteRuby!'
end
```

### How it works

When you call `#remotely` or `RemoteRuby::ExecutionContext#execute`, the passed block source is read and is then transformed to a standalone Ruby script, which also includes serialization/deserialization of local variables and return value, and other features (see [compiler.rb](lib/remote_ruby/compiler.rb) for more detail).

After that, RemoteRuby opens an SSH connection to the specified host, launches Ruby interpreter there, and feeds the generated script to it. Standard output and standard error streams of SSH client are being captured.

### Key features

* Access local variables inside the remote block, just as in case of a regular block:

```ruby
user_id = 1213

remotely(server: 'my_ssh_server') do
  puts user_id # => 1213
end

```

* Access return value of the remote block, just as in case of a regular block:
```ruby
res = remotely(server: 'my_ssh_server') do
  'My result'
end

puts res # => My result

```

* Assignment to local variables inside remote block, just as in case of a regular block:

```ruby
a = 1

remotely(server: 'my_ssh_server') do
  a = 100
end

puts a # => 100
```

### Limitations
*  Remote SSH server must be accessible with public-key authentication. Password authentication is not supported.

* Currently, code to be executed remotely cannot read anything from STDIN, because STDIN is used to pass the source to the Ruby interpreter.

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
my_server = ::RemoteRuby::ExecutionContext.new(server: 'my_ssh_server')

my_server.execute do
  put Dir.pwd
end
```

You can easily define more than one context to access several servers.

Along with `ExecutionContext#execute` method there is also `.remotely` method, which is included into the global scope. For instance, the code above is equivalent to the code below:

```ruby
remotely(server: 'my_ssh_server') do
  put Dir.pwd
end
```

All parameters passed to the `remotely` method will be passed to the underlying `ExecutionContext` initializer. The only exception is an optional `locals` parameter, which will be passed to the `#execute` method (see [below](#local-variables-and-return-value)).

### Parameters

Parameters, passed to the `ExecutionContext` can be general and _adapter-specific_. For adapter-specific parameters, refer to the [Adapters](#adapters) section below.

The list of general parameters:

| Parameter | Type | Required | Default value | Description |
| --------- | ---- | ---------| ------------- | ----------- |
| adapter | Class | no | `::RemoteRuby::SSHStdinAdapter` | An adapter to use. Refer to the [Adapters](#adapters) section to learn about available adapters. |
| use_cache | Boolean | no | `false` | Specifies if the cache should be used for execution of the block (if the cache is available). Refer to the [Caching](#caching) section to find out more about caching. |
| save_cache | Boolean | no | `false` | Specifies if the result of the block execution (i.e. output and error streams) should be cached for the subsequent use. Refer to the [Caching](#caching) section to find out more about caching. |
| cache_dir | String | no | ./cache | Path to the directory on the local machine, where cache files should be saved. If the directory doesn't exist, RemoteRuby will try to create it. Refer to the [Caching](#caching) section to find out more about caching. |
| out_prefix | String | no | `nil` | Specifies a prefix to be added to each line of output stream |
| out_prefix | String | no | `'[CACHE] '` | Specifies a prefix to be added to each line of output stream, when the context is reading from cache |
| stdout | Stream open for writing | no | `$stdout` | Redirection stream for server standard output |
| stderr | Stream open for writing | no | `$stderr` | Redirection stream for server standard error output |

### Output

Standard output and standard error streams from the remote process are captured, and then, depending on your parameters are either forwarded to local STOUT/STDERR or to the specified streams. RemoteRuby will add a prefix to each line of server output to distinguish between local and server output. STDOUT prefix is displayed in green, STDERR prefix is red. If output is read from cache, then `[CACHE]` prefix will also be added. The prefix may also depend on the adapter used.

```ruby
  remotely(server: 'my_ssh_server', working_dir: '/home/john') do
    puts 'This is an output'
    warn 'This is a warning'
  end
```

```bash
my_ssh_server:/home/john> This is an output
my_ssh_server:/home/john> This is a warning
```

### Local variables and return value

When you call a remote block RemoteRuby will try to serialize all local variables from the calling context, and include them to the remote script.

If you do not want all local variables to be sent to the server, you can explicitly specify a set of local variables and their values.

```ruby
some_number = 3
name = 'Alice'

# Explicitly setting locals with .remotely method
remotely(locals: { name: 'John Doe' }, server: 'my_ssh_server') do
  # name is 'John Doe', not 'Alice'
  puts name # => John Doe
  # some_number is not defined
  puts some_number # undefined local variable or method `some_number'
end

# Explicitly setting locals with ExecutionContext#execute method
execution_context = ::RemoteRuby::ExecutionContext.new(server: 'my_ssh_server')

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

remotely(server: 'my_ssh_server') do
  puts file.read # undefined local variable or method `file'
end
```

Moreover, if such variables are assigned to in the remote block, their value **will not change** in the calling scope:

```ruby
file = File.open('some_file.txt', 'rb')

remotely(server: 'my_ssh_server') do
  file = 3 # No exception here, as we are assigning
end

# Old value is retained
puts file == 3 # false
```

If the variable can be serialized, but the remote server context lacks the knowledge on how to deserialize it, the variable will be defined inside the remote block, but its value will be `nil`:

```ruby
# Something, which is not present on the remote server
special_thing = SomeSpecialGem::SpecialThing.new

remotely(server: 'my_ssh_server') do
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

remotely(server: 'my_ssh_server') do
  # this is not present in the client context
  server_specific_var = ServerSpecificClass.new
end

# RemoteRuby::Unmarshaler::UnmarshalError
```

```ruby
# Unsupportable local value example

my_local = nil

remotely(server: 'my_ssh_server') do
  # this is not present in the client context
  my_local = ServerSpecificClass.new
  nil
end

# RemoteRuby::Unmarshaler::UnmarshalError
```

To avoid these situations, do not assign/return values unsupported on the client side, or, if you don't need any return value, add `nil` at the end of your block:

```ruby
# No exception

remotely(server: 'my_ssh_server') do
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

res = remotely(server: 'my_ssh_server', save_cache: true, use_cache: true) do
  60.times do
    puts 'One second has passed'
    STDOUT.flush
    sleep 1
  end

  'Some result'
end

puts res # => Some result
```

You can specify where to put your cache files explicitly, by passing `cache_dir` parameter which is the "cache" directory inside your current working directory by default.

RemoteRuby calculates the cache file to use, based on the code you pass to the remote block, as well as on ExecutionContext 'contextual' parameters (e. g. server or working directory) and serialized local variables. Therefore, if you change anything in your remote block, local variables (passed to the block), or in any of the 'contextual' parameters, RemoteRuby will use different cache file. However, if you revert all your changes back, the old file will be used again.

**IMPORTANT**: RemoteRuby does not know when to clear the cache. Therefore, it is up to you to take care of cleaning the cache when you no longer need it. This is especially important if your output can contain sensitive data.

### Adapters

RemoteRuby can use different adapters to execute remote Ruby code. To specify an adapter you want to use, pass an `:adapter` argument to the initializer of `ExecutionContext` or to the `remotely` method.

#### SSH STDIN adapter

This adapter uses SSH console client to connect to the remote machine, launches Ruby interpreter there, and feeds the script to the interpreter via STDIN. This is the main and the **default** adapter. It assumes that the SSH client is installed on the client machine, and that the access to the remote host is possible with public-key authenitcation. Password authentication is not supported. To use this adapter, pass `adapter: ::RemoteRuby::SSHStdinAdapter` parameter to the `ExecutionContext` initializer, or do not specify adapter at all.

##### Parameters

| Parameter | Type | Required | Default value | Description |
| --------- | ---- | ---------| ------------- | ----------- |
| server | String | yes | - | Name of the SSH server to connect to |
| working_dir | String | no | ~ | Path to the directory on the remote server where the script should be executed |
| user | String | no | - | User on the remote host to connect as |
| key_file| String | no | - | Path to the private SSH key |
| bundler | Boolean | no | false | Specifies, whether the code should be executed with `bundle exec` on the remote server |


#### Local STDIN adapter

This adapter changes to the specified directory on the **local** machine, launches Ruby interpreter there, and feeds the script to the interpreter via STDIN. Therefore everything will be executed on the local machine, but in a child process. This adapter can be used for testing, or it can be useful if you want to execute some code in context of several code bases you have on the local machine. To use this adapter, pass `adapter: ::RemoteRuby::LocalStdinAdapter` parameter to the `ExecutionContext` initializer.


| Parameter | Type | Required | Default value | Description |
| --------- | ---- | ---------| ------------- | ----------- |
| working_dir | String | no | . | Path to the directory on the local machine where the script should be executed |
| bundler | Boolean | no | false | Specifies, whether the code should be executed with `bundle exec` |


#### Evaluating adapter

This adapter executes Ruby code in the same process, by running it in an isolated scope. It can optionally change to a specified directory before execution (and change back after completion). There is also an option to run this asynchronously; if enabled, the code will run on a separate thread to mimic SSH connection to a remote machine. Please note, that async feature is experimental, and probably will not work on all platforms. This adapter is intended for testing, and it shows better performance than `LocalStdinAdapter`. To use this adapter, pass `adapter: ::RemoteRuby::EvalAdapter` parameter to the `ExecutionContext` initializer.

| Parameter | Type | Required | Default value | Description |
| --------- | ---- | ---------| ------------- | ----------- |
| working_dir | String | no | . | Path to the directory on the local machine where the script should be executed |
| async | Boolean | no | false | Enables or disables asynchronous mode of the adapter |


### Rails
RemoteRuby can load Rails environment for you, if you want to execute a script in a Rails context. To do this, simply add `rails` parameter to your call:

```ruby
# Rails integration example

require 'remote_ruby'

remote_service = ::RemoteRuby::ExecutionContext.new(
  server: 'rails-server',
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
