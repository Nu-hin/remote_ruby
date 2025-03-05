# Changelog

## [1.0](https://github.com/Nu-hin/remote_ruby/releases/tag/v1.0)

### Major changes

* Full [support of SSH features](README.md#ssh-parameters), including password authentication, private key passphrases, made possible by switching to [net-ssh](https://github.com/net-ssh/net-ssh) gem.
* Since RemoteRuby no longer uses system SSH client, use of MacOS Keychain (`UseKeychain` option in MacOS OpenSSH implementation, starting from MacOS Sierra) is no longer possible.
* Added [support for STDIN](README.md#input) redirection. It is now possible to make remote scripts interactive, or stream data from local host.
* The output and error streams are now automatically synchronized. There is no need to use `STDOUT.flush` in the remote script anymore to avoid delays.
* Output and Error streams now work in binary mode, instead of being read line-by-line. It is possible to stream binary data from the remote script.
* Added support for dumping compiled code for easier debugging (see [Parameters](README.md#parameters))
* Added proper [error handling](README.md#error-handling). Printing remote stack trace and code context on error for easier debugging.
* Added advanced, customizable [text mode](README.md#text-mode).
* Flavours are renamed to plugins. It is now possible to [add custom plugins in configuration](README.md#plugins).
* Added a possibility to ignore specified types globally. Variables of the ignored types won't be attempted for serialization.

### Minor changes

* Minimum supported Ruby version is now 2.7
* `.remotely` is not included to the global scope by default, and needs to be included [explicitly](README.md#basic-usage).
* Connection adapter is now automatically selected based on the presence of the `host` argument.
* Only two adapters are now available: SSH adapter, and local temp file adapter. All other adapters are deprecated.
* Cache directory is now a [global configuration option](README.md#configuration), rather than an argument to the ExecutionContext.
* The default cache location is now in the .remote_ruby/cache, relative to the working directory.
* Added [changelog](#CHANGELOG.md)

### Migration from v0.3

1. To have `.remotely` method in global scope, include the `RemoteRuby::Extensions` module
2. Rename `server` parameter to `host`.
3. Remove `adapter` parameter.
4. Remove `cache_dir` parameter and configure it globally instead.
5. Remove `bundler` parameter.
6. If you want stdout and stderr to be prefixed, enable Text Mode and configure it.
7. Change `key_file` parameter to `keys` and make it an array with one filename instead of single string.
8. Optionally remove `STDOUT.flush` from your scripts.

Here's an example configuration which should resemble the default behaviour of v0.3:

```ruby
RemoteRuby.configure do |c|
    c.cache_dir = File.join(Dir.pwd, 'cache')
end

include RemoteRuby::Extensions

ec = RemoteRuby::ExecutionContext.new(
    host: 'my_ssh_host',
    text_mode: true
)

ec.execute do
    # your code
end

# OR

remotely(host: 'my_ssh_host', text_mode: true) do
    # your code
end

```
