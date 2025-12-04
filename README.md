# remote_ruby
[![Lint & Test](https://github.com/Nu-hin/remote_ruby/actions/workflows/main.yml/badge.svg)](https://github.com/Nu-hin/remote_ruby/actions/workflows/main.yml)
[![Coverage Status](https://coveralls.io/repos/github/Nu-hin/remote_ruby/badge.svg?branch=master)](https://coveralls.io/github/Nu-hin/remote_ruby?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/e57430aa6f626aeca41d/maintainability)](https://codeclimate.com/github/Nu-hin/remote_ruby/maintainability)
[![Gem Version](https://badge.fury.io/rb/remote_ruby.svg)](https://badge.fury.io/rb/remote_ruby)

RemoteRuby allows you to execute Ruby code on remote servers via SSH right from the Ruby script running on your local machine, as if it was executed locally.

[Changelog](CHANGELOG.md)

## Contents
* [Requirements](#requirements)
* [Overview](#overview)
	* [How it works](#how-it-works)
	* [Key features](#key-features)
	* [Limitations](#limitations)
* [Installation](#installation)
* [Usage](#usage)
  * [Configuration](#configuration)
	* [Basic usage](#basic-usage)
	* [Output](#output)
	* [Parameters](#parameters)
  * [SSH Parameters](#ssh-parameters)
  * [Local variables](#local-variables)
  * [Return value and remote assignments](#return-value-and-remote-assignments)
  * [Error handling](#error-handling)
  * [Caching](#caching)
    * [Cache cleanup and TTL](#cache-cleanup-and-ttl)
  * [Text mode](#text-mode)
  * [Encryption](#encryption)
  * [Plugins](#plugins)
    * [Adding custom plugins](#adding-custom-plugins)
    * [Rails](#rails)
* [Contributing](#contributing)
* [License](#license)

## Requirements

RemoteRuby requires at least Ruby 2.7 to run.

## Overview

Here is a short example of how you can run your code remotely.

```ruby
# This is test.rb file on the local developer machine

require 'remote_ruby'

execution_context =  RemoteRuby::ExecutionContext.new(host: 'my_ssh_server')

execution_context.execute do
  # Everything inside this block is executed on my_ssh_server
  puts 'Hello, RemoteRuby!'
end
```

### How it works

When you call `RemoteRuby::ExecutionContext#execute`, the passed block source is read and is then transformed to a standalone Ruby script, which also includes serialization/deserialization of local variables and return value, and other features (see [compiler.rb](lib/remote_ruby/compiler.rb) for more detail).

RemoteRuby then opens an SSH connection to the specified host, copies the script to a temporary file on the host, and launches it remotely using the Ruby interpreter. Standard output and standard error streams of SSH client are being captured. Standard input is passed to the remote code as well.

### Key features

Create a new execution context:

```ruby
execution_context =  RemoteRuby::ExecutionContext.new(host: 'my_ssh_server')
```

* Access local variables inside the remote block, just as in case of a regular block:

```ruby
user_id = 1213

execution_context.execute do
  puts user_id # => 1213
end
```

* Access return value of the remote block, just as in case of a regular block:

```ruby
execution_context.execute do
  'My result'
end

puts res # => My result
```

* Assignment to local variables inside remote block, just as in case of a regular block:

```ruby
a = 1

execution_context.execute do
  a = 100
end

puts a # => 100
```

* Reading from the client's standard input in the remote block:


```ruby
execution_context.execute do
  puts 'What is your name?'
  name = gets
  puts "Hello, #{name}!"
end
```

### Limitations
* macOS keychain is not supported. If you are using a private SSH key with a passphrase, and you don't want to enter a passphrase each time a context is executed, the identity must be added to the SSH-agent, e.g. using `ssh-add`.

* As RemoteRuby reads the block source from the script's source file, the script source file should reside on your machine's disk (e.g. you cannot use RemoteRuby from IRB console).

* Since local and server scripts have different execution contexts, can have different gems (and even Ruby versions) installed, sometimes local variables as well as the block return value, will not be accessible, assigned or can even cause exception. See the [usage](#local-variables-and-return-value) section below for more details.

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

### Configuration

There are a few options that may be configured on the global level.

```ruby
RemoteRuby.configure do |c|
  # Defines, where Remote Ruby will cache output, error and result streams on the
  # local machine.
  # By default they are saved to .remote_ruby/cache (relative to the working directory).
  c.cache_dir = File.join(Dir.pwd, '.remote_ruby/cache')

  # Defines, where Remote Ruby will store compiled code on the local machine, if
  # `dump_code` is set to `true` in the ExecutionContext.
  # By default code is saved to .remote_ruby/code (relative to the working directory).
  c.code_dir = File.join(Dir.pwd, '.remote_ruby/code')

  # Set to true if you don't want to see warnings about parser gem compatibility with
  # current Ruby version.
  # False by default.
  c.suppress_parser_warnings = false
end
```

### Basic usage

The main class to work with is the `ExecutionContext`, which provides an `#execute` method:

```ruby
my_server = RemoteRuby::ExecutionContext.new(host: 'my_ssh_server')

my_server.execute do
  puts Dir.pwd
end
```

You can easily define more than one context to access several servers.

### Parameters

| Parameter | Type | Required | Default value | Description |
| --------- | ---- | ---------| ------------- | ----------- |
| host | String | no | - | Name of the SSH host to connect to. If omitted, the code will be executed on the local host, in a separate Ruby process |
| use_ssh_config_file | String or Boolean | no | true | When boolean, specifies, whether to use ~/.ssh/config file for the initial set of parameters. When string, interpreted as a path to an SSH configuration file to use |
| ruby_executable | String | no | `ruby` | Absolute path to Ruby executable on the remote host, or executable name, reachable from $PATH |
| working_dir | String | no | '~' if running over SSH, or current dir, if running locally | Path to the directory where the script should be executed |
| use_cache | Boolean | no | `false` | Specifies if the cache should be used for execution of the block (if the cache is available). Refer to the [Caching](#caching) section to find out more about caching. |
| save_cache | Boolean | no | `false` | Specifies if the result of the block execution (i.e. output, error, and result streams) should be cached for the subsequent use. Refer to the [Caching](#caching) section to find out more about caching. |
| cache_ttl | Integer | no | 0 | Cache TTL in seconds. If RemoteRuby reads a cache file which is older than specified value, it will delete it and proceed as if it was not present |
| in_stream | Stream open for reading | no | `$stdin` | Source stream for server standard input |
| out_stream | Stream open for writing | no | `$stdout` | Redirection stream for server standard output |
| err_stream | Stream open for writing | no | `$stderr` | Redirection stream for server standard error|
| text_mode | Boolean or Hash | no | `false` | Specifies, if the connection should be run in text mode. See [Text Mode](#text-mode) section below to find out more about text mode. |
| dump_code | Boolean | no | `false` | When set to true, the compiled script that will be run on the remote server will be dumped to a local file for inspection. See [Configuration](#configuration) to configure where the code is written. |
| encrypt | Boolean | no | `true` | When true, the generated Ruby code will be encrypted before deploying. During execution, RemoteRuby passes the encryption key to the remote script as a command line paramter |

### SSH Parameters

In addition to the arguments above, you can fine-tune the SSH connection to the remote host, if SSH is used (that is, if the `host` argument is specified). The arguments for SSH configuration can be anything that is supported by [net-ssh gem](https://github.com/net-ssh/net-ssh). The complete list of parameters can be found in [the documentation for net-ssh](https://net-ssh.github.io/net-ssh/Net/SSH.html#method-c-start). Some of the parameters are in the table below.

If the SSH configuration file is used (see `ssh_config` parameter in the table above), the explicitly specified values **will override** those taken from SSH config.

| Parameter | Type |  Description |
| --------- | ---- |  ----------- |
| user | String | the user name to log in as |
| password | String  | the password to use to log in |
| keys | Array of strings | an array of file names of private keys to use for publickey and hostbased authentication |
| passphrase | String | the passphrase to use when loading a private key (default is `nil`, for no passphrase) |
| auth_methods | Array of strings | an array of authentication methods to try |

Example SSH configurations may look like:

```ruby
# Use ~/.ssh/config file, but override some parameters
ec1 = RemoteRuby::ExecutionContext.new(
  host: 'my_ssh_server',
  auth_methods: %w(password),
  user: 'jdoe',
  password: 'p@ssw0rd'
)

# Custom key file
ec2 = RemoteRuby::ExecutionContext.new(
  host: 'my_ssh_server',
  keys: '/home/jdoe/.ssh/custom_id_rsa'
)

# Ignore SSH configuration and provide everything explicitly
ec3 = RemoteRuby::ExecutionContext.new(
  host: 'my_ssh_server',
  use_ssh_config_file: false,
  auth_methods: %w(password),
  user: 'jdoe',
  password: 'p@ssw0rd'
)

```

### Output

Standard output and standard error streams from the remote process are captured, and then, depending on your parameters are either forwarded to local standard output/error or to the specified streams.

```ruby
execution_context.execute do
  puts 'This is an output'
  warn 'This is a warning'
end
```

### Input

Remote script can receive data from standard input. By default the input is captured from client's standard input, but this can be set to any readable stream using `in_stream` argument to the `ExecutionContext` initializer.

```ruby
name = execution_context.execute do
  puts "What is your name?"
  gets
end

puts "Hello locally, #{name}!"
```

### Local variables

When you call a remote block RemoteRuby will try to serialize all local variables from the calling context, and include them to the remote script.

If you do not want all local variables to be sent to the server, you can explicitly specify a set of local variables and their values.

```ruby
some_number = 3
name = 'Alice'

# Explicitly setting locals with ExecutionContext#execute method
execution_context = RemoteRuby::ExecutionContext.new(host: 'my_ssh_server')

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

execution_context.execute do
  puts file.read # undefined local variable or method `file'
end
```

Moreover, if such variables are assigned to in the remote block, their value **will not change** in the calling scope:

```ruby
file = File.open('some_file.txt', 'rb')

execution_context.execute do
  file = 3 # No exception here, as we are assigning
end

# Old value is retained
puts file == 3 # false
```

If the variable can be serialized, but the remote server context lacks the knowledge on how to deserialize it, the variable will be defined inside the remote block, but its value will be `nil`:

```ruby
# Something, that is not present on the remote server
special_thing = SomeSpecialGem::SpecialThing.new

execution_context.execute do
  puts defined?(special_thing) # => local-variable
  # special_thing is defined, but its value is nil
  puts special_thing.nil? # => true

  # but we can still reassign it:
  special_thing = 3
end

puts special_thing == 3 # => true
```

If RemoteRuby cannot deserialize variable on server side, it will print a warning to server's standard error.

It is possible to ignore certain types, so that RemoteRuby will never try to send variables of these types to the remote host. This can be done by adding configuration:

```ruby
RemoteRuby.configure do |c|
  c.ignore_types SomeSpecialGem::SpecialThing
end
```

If a type is ignored, the remote block will behave as if the local variable is not defined:

```ruby
RemoteRuby.configure do |c|
  c.ignore_types SomeSpecialGem::SpecialThing
end

special_thing = SomeSpecialGem::SpecialThing.new

execution_context.execute do
  puts defined?(special_thing) # => nil

  # special_thing is not defined
  puts special_thing.nil? # NameError undefined local variable or method `special_thing' for main:Object
end
```

RemoteRuby always ignores variables of type `RemoteRuby::ExecutionContext`.

### Return value and remote assignments

If remote block returns a value that cannot be deserialized on the client side, or if it assigns such a value to the local variable, the exception on the client side will be always raised:

```ruby
# Unsupported return value example

execution_context.execute do
  # this is not present in the client context
  server_specific_var = ServerSpecificClass.new
end

# undefined class/module ServerSpecificClass (ArgumentError)
```

```ruby
# Unsupported local value example

my_local = nil

execution_context.execute do
  # this is not present in the client context
  my_local = ServerSpecificClass.new
  nil
end

# undefined class/module ServerSpecificClass (ArgumentError)
```

To avoid these situations, do not assign/return values unsupported on the client side, or, if you don't need any return value, add `nil` at the end of your block:

```ruby
# No exception

execution_context.execute do
  # this is not present in the client context
  server_specific_var = ServerSpecificClass.new
  nil
end
```

### Error handling

If remote code raises an error, RemoteRuby intercepts it and raises a `RemoteRuby::RemoteError` on the local machine. Since remote code potentially can raise an exception of a type (or containing a type), that is not present in the local context, the exception itself is not wrapped. Instead, `RemoteRuby::RemoteError` will contain the class name, message and the stack trace of the causing remote error.

```ruby
a = 1
b = 2
res = 'unchanged'
begin
  execution_context =  RemoteRuby::ExecutionContext.new(host: 'my_ssh_server', dump_code: true)
  res = execution_context.execute do
    a = 10
    raise StandardError.new('remote error text')
    b = 20
    'changed'
  end
rescue RemoteRuby::RemoteError
  puts a
  puts b
  puts res

  raise
end
```

This will produce something like the following.

```
10
2
unchanged
/path/to/gemset/remote_ruby/lib/remote_ruby/execution_context.rb:36:in 'RemoteRuby::ExecutionContext#execute': Remote error: StandardError (RemoteRuby::RemoteError)
remote error text

from /tmp/remote_ruby.qwGUHP:71:in `block in <main>'
(See /home/jdoe/Work/remote_ruby_test/.remote_ruby/code/dcbb2493288b1d10be042a32a31bf8af43da660234f1731f03966aa67ac870e3.rb:71:in `block in <main>'
68:
69:      # Start of client code
70:      a = 10
71: >>   raise(StandardError.new("remote error text"))
72:      b = 20
73:      "changed"
74:      # End of client code
```

As you can see, the behaviour of remote error corresponds to the situation when an error is raised in normal block. Local variables that are assigned before the error have the new value. The result of block in case of an error is `nil`.

Note that when printed to console `RemoteError` displays the context of the error in the **remote script**. If `dump_code` is set to `true`, `RemoteError` will also print the location of the line in the local copy of the remote script. This may be very useful for debugging.


### Caching

RemoteRuby allows you to save the result of previous block excutions in the local cache on the client machine to save you time on subsequent script runs. To enable saving of the cache, set `save_cache: true` parameter. To turn reading from cache on, use `use_cache: true` parameter.

```ruby
# Caching example
# First time this script will take 60 seconds to run,
# but on subsequent runs it will return the result immediately

require 'remote_ruby'

execution_context =  RemoteRuby::ExecutionContext.new(host: 'my_ssh_server', save_cache: true, use_cache: true)

res = execution_context.execute do
  60.times do
    puts 'One second has passed'
    sleep 1
  end

  'Some result'
end

puts res # => Some result
```

You can specify where to put your cache files explicitly, by [configuring](#configuration) the `cache_dir` which is by default set to ".remote_ruby/cache" inside your current working directory.

RemoteRuby calculates the cache file to use, based on the code you pass to the remote block, as well as on `ExecutionContext` 'contextual' parameters (e. g. server or working directory) and serialized local variables. Therefore, if you change anything in your remote block, local variables (passed to the block), or in any of the 'contextual' parameters, RemoteRuby will use different cache file. However, if you revert all your changes back, the old file will be used again.

#### Cache cleanup and TTL

You can control cache expiration by passing a `cache_ttl` parameter (in seconds) to `ExecutionContext` initializer.

A `cache_ttl` of `0` (default) disables expiration checks; RemoteRuby will never remove old cache files.
When `cache_ttl` is a positive integer, RemoteRuby validates the timestamp of a matching cache entry. If the entry is older than the TTL, it is deleted and treated as a cache miss.

```ruby
execution_context = RemoteRuby::ExecutionContext.new(
  host: 'my_ssh_host',
  use_cache: true,
  save_cache: true,
  cache_ttl: 1800 # 30 minutes
)

# Executes remotely only if the previous cached result is older than 30 minutes
execution_context.execute do
  User.find(email: 'j.doe@example.com').last_login_date
end
```

**IMPORTANT** TTL only prevents RemoteRuby from *using* stale cache entries. It does **not** perform automatic cache cleanup. Expired files are removed only when the same code, locals, and execution context are evaluated again.

If you change any of those parameters, older cache files may remain indefinitely.

RemoteRuby will not delete cache files when:

* The script is never invoked again.
* Execution context (code, locals, parameters) changes and no longer matches prior entries.
* `cache_ttl` is `0`.

You are responsible for cleaning up cache files when they are no longer needed, especially if the cache may contain sensitive data.

### Text mode

Text mode allows to treat the output and/or the standard error of the remote process as text. If it is enabled, the server output is prefixed with some string, which makes it easier to distinguish local output, and the output coming from the remote code. Additionally, it may help distinguishing when the output is taken from cache.

The text mode is controlled by the `text_mode` parameter to the `RemoteRuby::ExecutionContext` initializer, and is `false` by default.

The easiest way to enable it is to set `text_mode` to `true`.

```ruby
execution_context = RemoteRuby::ExecutionContext.new(
  host: 'my_ssh_server',
  user: 'jdoe'
  text_mode: true,
)

execution_context.execute do
  puts "This is a greeting"
  warn "This is an error"
end
```

This will produce:

```
jdoe@my_ssh_server:~> This is a greeting
jdoe@my_ssh_server:~> This is a greeting
```

By default, the prefixes for standard output and standard error can be different when running over SSH and locally. Output prefix is marked with green italic, and error with red italic. If the cache is used, the default configuration will append a bold blue '[C]' prefix in front of each output line.


You can fine-tune the text mode to your needs by passing a hash as a value to `text_mode` parameter:

```ruby
execution_context = RemoteRuby::ExecutionContext.new(
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

It is reasonable to avoid text mode if you want to put binary data to the standard output:

```ruby
# copy_avatar.rb
# Reads a file from remote server and writes it to client's standard output.

execution_context =  RemoteRuby::ExecutionContext.new(host: 'my_ssh_server', text_mode: false)

execution_context.execute do
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

### Encryption

By default, RemoteRuby encrypts scripts using **AES-256-CBC** before deploying them to the remote host. If RemoteRuby crashes or exits without removing the temporary file, the file remains encrypted, preventing any extraction of its contents (including local variables). When executing the remote script, RemoteRuby passes a randomly generated encryption key via the command line. A new key is generated on every run, even when the script and execution context are unchanged.

You can disable encryption by passing `encrypt: false` to `RemoteRuby::ExecutionContext.new`.

**Note:** If you instruct RemoteRuby to dump the script locally (see [Error Handling](#error-handling)) by setting `dump_code: true`, the dumped file will **not** be encrypted.


### Plugins
RemoteRuby can be extended with plugins. Plugins are used to insert additional code to the script, which is executed in the remote context. There is also a built-in plugin that allows for automatically loading Rails environment.

#### Adding custom plugins

RemoteRuby plugin must be a class. Instances of a plugin class must respond to `#code_header` method without any parameters. Plugins are instantiated when the `ExecutionContext` is created.

You may inherit your class from `RemoteRuby::Plugin` class but that is not necessary.

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
  execution_context =  RemoteRuby::ExecutionContext.new(
    host: 'my_ssh_server',
    username_printer: { username: ENV['USER'] }
  )

  execution_context.execute do
    puts "Hello world!"
  end
```

This should print the following:

```
This code is run by jdoe
Hello world!
```


#### Rails plugin
RemoteRuby can load Rails environment for you, if you want to execute a script in a Rails context. To do this, simply add built-in Rails plugin by adding `rails` argument to your call:

```ruby
# Rails integration example

require 'remote_ruby'

remote_service = RemoteRuby::ExecutionContext.new(
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
