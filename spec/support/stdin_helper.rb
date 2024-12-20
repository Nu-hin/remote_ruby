module StdinHelper
  def with_stdin_redirect(input)
    old_stdin = $stdin
    $stdin = StringIO.new(input)
    yield
  ensure
    $stdin = old_stdin
  end
end
