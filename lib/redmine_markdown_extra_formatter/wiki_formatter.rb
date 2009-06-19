# -*- coding: utf-8 -*-
require 'bluefeather'

module RedmineMarkdownExtraFormatter
  class WikiFormatter
    def initialize(text)
      @text = text
    end

    def to_html(&block)
      BlueFeather.parse(@text.gsub(/\[(.+)\]\((https?:\/\/.+)\)/, '[\1](/redirect/\2)'))
#      BlueFeather.parse(@text).gsub(/href=(["'])(.+)(["'])/i, 'href=\1/redirect/\2\3')
    rescue => e
      return("<pre>problem parsing wiki text: #{e.message}\n"+
             "original text: \n"+
             @text+
             "</pre>")
    end
  end
end
