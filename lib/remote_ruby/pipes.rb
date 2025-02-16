module RemoteRuby
  # Wraps three pairs of pipes for stdin, stdout, and stderr
  class Pipes
    attr_reader :in_r, :in_w, :out_r, :out_w, :err_r, :err_w

    def initialize
      @in_r, @in_w = IO.pipe
      @out_r, @out_w = IO.pipe
      @err_r, @err_w = IO.pipe
    end

    def close_r
      in_w.close
      out_r.close
      err_r.close
    end

    def close_w
      in_r.close
      out_w.close
      err_w.close
    end

    def self.with_pipes
      pipes = new
      yield pipes
    ensure
      pipes.close_r
    end
  end
end
