# frozen_string_literal: true

require 'method_source'

module RemoteRuby
  # Provides methods for extracting the client source code
  class CodeExtractor
    def self.extract_block_ast(&block)
      ast = Parser::CurrentRuby.parse(block.source)
      block_node = find_block(ast)

      return nil unless block_node

      block_node.children[2]
    end

    def self.find_block(node)
      return nil unless node.is_a? AST::Node
      return node if node.type == :block

      node.children.each do |child|
        res = find_block(child)
        return res if res
      end

      nil
    end
  end
end
