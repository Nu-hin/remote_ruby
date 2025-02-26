# frozen_string_literal: true

module RemoteRuby
  # Wraps three pairs of pipes for stdin, stdout, and stderr
  class Pipes
    attr_reader :in_r, :in_w, :out_r, :out_w, :err_r, :err_w, :res_r, :res_w

    def initialize
      @in_r, @in_w = IO.pipe
      @out_r, @out_w = IO.pipe
      @err_r, @err_w = IO.pipe
      @res_r, @res_w = IO.pipe
    end

    def close_r
      in_w.close
      out_r.close
      err_r.close
      res_r.close
    end

    def self.with_pipes
      pipes = new
      yield pipes
    ensure
      pipes.close_r
    end
  end
end
