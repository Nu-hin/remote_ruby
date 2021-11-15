# frozen_string_literal: true

require 'method_source'
require 'parser/current'
require 'unparser'

# Opt-in to most recent AST format
Parser::Builders::Default.emit_lambda              = true
Parser::Builders::Default.emit_procarg0            = true
Parser::Builders::Default.emit_encoding            = true
Parser::Builders::Default.emit_index               = true
Parser::Builders::Default.emit_arg_inside_procarg0 = true
Parser::Builders::Default.emit_forward_arg         = true
Parser::Builders::Default.emit_kwargs              = true
Parser::Builders::Default.emit_match_pattern       = true

module RemoteRuby
  # Receives a block and extracts Ruby code (as a string) with this block's
  # source
  class SourceExtractor
    def extract(&block)
      ast = Parser::CurrentRuby.parse(block.source)
      block_node = find_block(ast)

      return '' unless block_node

      _, body = parse(block_node)
      Unparser.unparse(body)
    end

    private

    def find_block(node)
      return nil unless node.is_a? AST::Node
      return node if node.type == :block

      node.children.each do |child|
        res = find_block(child)
        return res if res
      end

      nil
    end

    def parse(node)
      args = node.children[1].children
      body = node.children[2]
      [args, body]
    end
  end
end
