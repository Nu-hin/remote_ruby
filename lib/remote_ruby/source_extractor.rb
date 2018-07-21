module RemoteRuby
  class SourceExtractor
     def extract(&block)
       parse_block(block.source)
     end

    # Quick and dirty solution
    # Will only work with well-formatted 'do' blocks now
    def parse_block(block_code)
      block_code.lines[1..-2].join
    end
  end
end
