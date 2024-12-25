module StreamHelper
  def with_stdin_redirect(input)
    old_stdin = $stdin
    $stdin = StringIO.new(input)
    yield
  ensure
    $stdin = old_stdin
  end

  def with_capture
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
    [$stdout.string, $stderr.string]
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end
