# frozen_string_literal: true

module RemoteRuby
  # Serves to dynamically require the parser gem and configure it.
  # This is done in a separate module to have a possibility
  # to suppress parser gem warnings about Ruby compatibility.
  module ParserFactory
    def self.require_parser
      begin
        prev = $VERBOSE
        $VERBOSE = nil if RemoteRuby.suppress_parser_warnings
        require 'parser/current'
        require 'unparser'
      ensure
        $VERBOSE = prev
      end

      # Opt-in to most recent AST format
      Parser::Builders::Default.emit_lambda              = true
      Parser::Builders::Default.emit_procarg0            = true
      Parser::Builders::Default.emit_encoding            = true
      Parser::Builders::Default.emit_index               = true
      Parser::Builders::Default.emit_arg_inside_procarg0 = true
      Parser::Builders::Default.emit_forward_arg         = true
      Parser::Builders::Default.emit_kwargs              = true
      Parser::Builders::Default.emit_match_pattern       = true
    end
  end
end
