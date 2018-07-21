require 'parser/current'
require 'unparser'

module RemoteRuby
  class SourceExtractor
     def extract(&block)
       ast = Parser::CurrentRuby.parse(block.source)
       block_node = find_block(ast)

       return '' unless block_node

       arguments, body = parse(block_node)
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
       return [args, body]
     end
  end
end
