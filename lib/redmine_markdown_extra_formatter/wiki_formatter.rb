require 'bluefeather'

module RedmineMarkdownExtraFormatter
  class WikiFormatter
    def initialize(text)
      @text = text
    end

    def to_html(&block)
      BlueFeather.parse(@text)
    rescue => e
      return("<pre>problem parsing wiki text: #{e.message}\n"+
             "original text: \n"+
             @text+
             "</pre>")
    end
  end
end
