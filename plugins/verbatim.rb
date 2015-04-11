# Input:
#   {% verbatim tag:p %}
#   $$a_1, a_2, a_3, \ldots$$
#   {% endverbatim %}
#
# Output:
#   <p>$$a_1, a_2, a_3, \ldots$$</p>
#
# Author: Hiroshi Yuki.
# Description: The content between {% verbatim %} and {% endverbatim %} would be rendered 'as is'.
# You can use 'tag' option to wrap the content.
# Purpose: To protect LaTeX (MathJax) content from markdown converter.

require './plugins/raw'

module Jekyll

  class VerbatimBlock < Liquid::Block
    include TemplateWrapper
    def initialize(tag_name, markup, tokens)
      @tag = nil
      if markup =~ /\s*tag:(\S+)/i
        @tag = $1
        markup = markup.sub(/\s*tag:(\S+)/i,'')
      end
      super
    end
    
    def safe_wrap(input)
    "<div class='bogus-wrapper'><notextile>#{input}</notextile></div>"
    end

    def render(context)
      output = super
      content = "<#{@tag}>" if @tag
      content += safe_wrap(output)
      content += "</#{@tag}>" if @tag
      return content
    end
  end
end

Liquid::Template.register_tag('verbatim', Jekyll::VerbatimBlock)