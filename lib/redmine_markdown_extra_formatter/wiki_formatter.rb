# -*- coding: utf-8 -*-
require 'bluefeather'
require 'coderay'

module BlueFeather
  class Parser

    # derived from bluefeather.rb

    TOCRegexp = %r{
      ^\{    # bracket on line-head
      [ ]*    # optional inner space
      ([<>])?
      toc

      (?:
        (?:
          [:]    # colon
          |      # or
          [ ]+   # 1 or more space
        )
        (.+?)    # $1 = parameter
      )?

      [ ]*    # optional inner space
      \}     # closer
      [ ]*$   # optional space on line-foot
    }ix

    TOCStartLevelRegexp = %r{
      ^
      (?:              # optional start
        h
        ([1-6])        # $1 = start level
      )?

      (?:              # range symbol
        [.]{2,}|[-]    # .. or -
      )

      (?:              # optional end
        h?             # optional 'h'
        ([1-6])        # $2 = end level
      )?$
    }ix

    ### Transform any Markdown-style horizontal rules in a copy of the specified
    ### +str+ and return it.
    def transform_toc( str, rs )
      @log.debug " Transforming tables of contents"
      str.gsub(TOCRegexp){
        start_level = 1 # default
        end_level = 6

        param = $2
        if param then
          if param =~ TOCStartLevelRegexp then
            if !($1) and !($2) then
              rs.warnings << "illegal TOC parameter - #{param} (valid example: 'h2..h4')"
            else
              start_level = ($1 ? $1.to_i : 1)
              end_level = ($2 ? $2.to_i : 6)
            end
          else
            rs.warnings << "illegal TOC parameter - #{param} (valid example: 'h2..h4')"
          end
        end

        if rs.headers.first and rs.headers.first.level >= (start_level + 1) then
          rs.warnings << "illegal structure of headers - h#{start_level} should be set before h#{rs.headers.first.level}"
        end


        ul_text = "\n\n"
        div_class = 'toc'
        div_class << ' right' if $1 == '>'
        div_class << ' left' if $1 == '<'
        ul_text << "<ul class=\"#{div_class}\">"
        rs.headers.each do |header|
          if header.level >= start_level and header.level <= end_level then
            ul_text << "<li class=\"heading#{header.level}\"><a href=\"##{header.id}\">#{header.content_html}</a></li>\n"
          end
        end
        ul_text << "</ul>"
        ul_text << "\n"

        ul_text # output

      }
    end
  end
end

module RedmineMarkdownExtraFormatter
  class WikiFormatter
    def initialize(text)
      @text = text
    end

    def to_html(&block)
      @macros_runner = block
      parsedText = BlueFeather.parse(@text)
      parsedText = inline_macros(parsedText)
      parsedText = syntax_highlight(parsedText)
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

    PreCodeClassBlockRegexp = %r{^<pre><code\s+class="(\w+)">\s*\n(.+?)</code></pre>\n}m

    def syntax_highlight( str )
      str.gsub( PreCodeClassBlockRegexp ) {|block|
        syntax = $1.downcase
        "<pre><code class=\"#{syntax.downcase} CodeRay\">" +
        CodeRay.scan($2, syntax).html(:escape => true, :line_numbers => nil) +
        "</code></pre>"
      }
    end
  end
end
