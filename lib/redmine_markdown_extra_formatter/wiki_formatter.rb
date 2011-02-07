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
    include ActionView::Helpers::TagHelper

    def initialize(text)
      @text = text
    end

    # Taken from
    # https://github.com/github/github-flavored-markdown/blob/gh-pages/code.rb,
    # with modifications.
    def gfm(text)
      # Extract pre blocks
      extractions = {}
      text.gsub!(%r{<pre>.*?</pre>|(?:(?:    |\t)[^\n]*\n)+}m) do |match|
        md5 = Digest::MD5.hexdigest(match)
        extractions[md5] = match
        "{gfm-extraction-#{md5}}"
      end

      # escape underline characters that aren't on a word boundary
      text.gsub!(%r{([^\s_]+\w+[^\s_]+)}) { |x| x.gsub('_', '\_') }

      # in very clear cases, let newlines become <br /> tags
      text.gsub!(/(\A|^$\n)(^\w[^\n]*\n)(^\w[^\n]*$)+/m) do |x|
        x.gsub(/^(.+)$/, "\\1  ")
      end

      # Insert pre block extractions
      text.gsub!(/\{gfm-extraction-([0-9a-f]{32})\}/) do
        extractions[$1]
      end


      puts "\n\n\n#{text.inspect}\n\n\n"

      text
    end

    def to_html(&block)
      @macros_runner = block
      parsedText = @text.dup
      parsedText.gsub!("\r\n", "\n")
      parsedText = gfm(parsedText)
      parsedText = BlueFeather.parse(parsedText)
      parsedText = inline_auto_link(parsedText)
      parsedText = inline_auto_mailto(parsedText)
      parsedText = syntax_highlight(parsedText)
    rescue => e
      return("<pre>problem parsing wiki text: #{e.message}\n"+
             "original text: \n"+
             @text+
             "</pre>")
    end

    PreCodeClassBlockRegexp = %r{^<pre><code\s+class="(\w+)">\s*\n*(.+?)</code></pre>}m

    def syntax_highlight(str)
      str.gsub(PreCodeClassBlockRegexp) {|block|
        syntax = $1.downcase
        "<pre><code class=\"#{syntax.downcase} syntaxhl\">" +
        CodeRay.scan($2, syntax).html(:escape => true, :line_numbers => nil) +
        "</code></pre>"
      }
    end

    AUTO_LINK_RE = %r{
                    (                          # leading text
                      <\w+.*?>|                # leading HTML tag, or
                      [^=<>!:'"/]|             # leading punctuation, or 
                      ^                        # beginning of line
                    )
                    (
                      (?:https?://)|           # protocol spec, or
                      (?:s?ftps?://)|
                      (?:www\.)                # www.*
                    )
                    (
                      (\S+?)                   # url
                      (\/)?                    # slash
                    )
                    ((?:&gt;)?|[^\w\=\/;\(\)]*?)               # post
                    (?=<|\s|$)
                   }x unless const_defined?(:AUTO_LINK_RE)

    # Turns all urls into clickable links (code from Rails).
    def inline_auto_link(text)
      text.gsub!(AUTO_LINK_RE) do
        all, leading, proto, url, post = $&, $1, $2, $3, $6
        if leading =~ /<a\s/i || leading =~ /![<>=]?/
          # don't replace URL's that are already linked
          # and URL's prefixed with ! !> !< != (textile images)
          all
        else
          # Idea below : an URL with unbalanced parethesis and
          # ending by ')' is put into external parenthesis
          if ( url[-1]==?) and ((url.count("(") - url.count(")")) < 0 ) )
            url=url[0..-2] # discard closing parenth from url
            post = ")"+post # add closing parenth to post
          end
          tag = content_tag('a', proto + url, :href => "#{proto=="www."?"http://www.":proto}#{url}", :class => 'external')
              %(#{leading}#{tag}#{post})
        end
      end
      text
    end

    # Turns all email addresses into clickable links (code from Rails).
    def inline_auto_mailto(text)
      text.gsub!(/([\w\.!#\$%\-+.]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+)/) do
        mail = $1
        if text.match(/<a\b[^>]*>(.*)(#{Regexp.escape(mail)})(.*)<\/a>/)
          mail
        else
          content_tag('a', mail, :href => "mailto:#{mail}", :class => "email")
        end
      end
      text
    end
  end
end
