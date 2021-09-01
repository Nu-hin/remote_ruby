# frozen_string_literal: true

module RemoteRuby
  # Provides helper methods for working with Ruby AST
  class ASTHelper
    def self.rename_method(ast, new_name)
      raise 'Not a method' unless %i[defs def].include?(ast.type)

      Parser::AST::Node.new(:def, [
                              new_name,
                              *ast.children[-2..-1]
                            ])
    end

    def self.wrap_in_block(ast, result_name)
      Parser::AST::Node.new(:lvasgn, [
                              result_name,
                              Parser::AST::Node.new(:kwbegin, [ast])
                            ])
    end
  end
end
