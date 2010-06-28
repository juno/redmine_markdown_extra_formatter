# -*- coding: utf-8 -*-
require 'bluefeather'

module RedmineMarkdownExtraFormatter
  class WikiFormatter
    def initialize(text)
      @text = text
    end

    def to_html(&block)
      @macros_runner = block
      parsedText = BlueFeather.parse(@text)
      inline_macros(parsedText)
    rescue => e
      return("<pre>problem parsing wiki text: #{e.message}\n"+
             "original text: \n"+
             @text+
             "</pre>")
    end

    MACROS_RE = /
          (!)?                        # escaping
          (
          \{\{                        # opening tag
          ([\w]+)                     # macro name
          (\(([^\}]*)\))?             # optional arguments
          \}\}                        # closing tag
          )
        /x

    def inline_macros(text)
      text.gsub!(MACROS_RE) do
        esc, all, macro = $1, $2, $3.downcase
        args = ($5 || '').split(',').each(&:strip)
        if esc.nil?
          begin
            @macros_runner.call(macro, args)
          rescue => e
            "<div class=\"flash error\">Error executing the <strong>#{macro}</strong> macro (#{e})</div>"
          end || all
        else
          all
        end
      end
      text
    end
  end
end
