# frozen_string_literal: true

module RemoteRuby
  class TestAdapter < ConnectionAdapter
    attr_reader :input, :out, :err, :result

    def initialize(out: nil, err: nil, result: nil)
      super
      @out = out
      @err = err
      @result = result
    end

    def open(_code)
      input_io = StringIO.new
      input_io.close_write

      yield nil, StringIO.new(out), StringIO.new(err)

      @input = input_io.string
    end

    def with_result_stream
      yield StringIO.new(result)
    end
  end
end
