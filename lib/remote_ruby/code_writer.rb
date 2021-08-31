# frozen_string_literal: true

require 'stringio'
require 'unparser'
require 'method_source'

require 'remote_ruby/ast_helper'

module RemoteRuby
  # A writer with specialized methods to write Ruby source code
  class CodeWriter < SimpleDelegator
    def initialize(io = nil)
      io ||= StringIO.new
      super(io)
    end

    def write_require(path)
      self.puts "require('#{path}')"
    end

    def write_comment(comment_text)
      self.puts "# #{comment_text}"
    end

    def write_section(name)
      write_comment("Begin #{name}")
      yield self
      write_comment("End #{name}")
      self.puts
    end

    def write_ast(ast)
      write(::Unparser.unparse(ast))
    end

    def write_method(method, new_name)
      ast = ::Parser::CurrentRuby.parse(method.source)
      ast = ::RemoteRuby::ASTHelper.rename_method(ast, new_name)
      write_ast(ast)
      puts
    end
  end
end
