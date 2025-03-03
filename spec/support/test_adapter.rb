# frozen_string_literal: true

# A test adapter for testing purposes
class TestAdapter < RemoteRuby::ConnectionAdapter
  attr_reader :out, :err, :result

  def initialize(out: nil, err: nil, result: nil)
    super
    @out = out
    @err = err
    @result = result
  end

  def open(_code, _, stdout, stderr)
    stdout.write(out)
    stderr.write(err)
    result
  end
end
