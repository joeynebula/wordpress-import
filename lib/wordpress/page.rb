module WordPressImport
  class Page
    include ::ActionView::Helpers::TagHelper
    include ::ActionView::Helpers::TextHelper

    attr_reader :node

    def initialize(node)
      @node = node
    end

    def inspect
      "WordPress::Page(#{post_id}): #{title}"     
    end

    def link
      node.xpath("link").text
    end

    def title
      node.xpath("title").text
    end

    def content
      node.xpath("content:encoded").text
    end

    def content_formatted
      formatted = format_shortcodes(format_syntax_highlighter(format_paragraphs(content)))

      # remove all tags inside <pre> that simple_format created
      # TODO: replace format_paragraphs with a method, that ignores pre-tags
      formatted.gsub!(/(<pre.*?>)(.+?)(<\/pre>)/m) do |match| 
        "#{$1}#{strip_tags($2)}#{$3}"
      end
        
      formatted
    end

    def creator
      node.xpath("dc:creator").text
    end

    def post_date
      Time.parse node.xpath("wp:post_date").text
    end

    def publish_date
      Time.parse node.xpath("pubDate").text
    end

    def post_name
      node.xpath("wp:post_name").text
    end

    def post_id
      node.xpath("wp:post_id").text.to_i
    end

    def parent_id
      dump_id = node.xpath("wp:post_parent").text.to_i
      dump_id == 0 ? nil : dump_id
    end

    def status
      node.xpath("wp:status").text
    end

    def draft?
      status != 'publish'
    end

    def published?
      ! draft?
    end

    def ==(other)
      post_id == other.post_id
    end

    #NEED:
    # creator ->  "user_id"
    # wp:post_name ->   "slug"
    # pubDate -> "published_at"
    #OK:
    # title      ->  "title"
    # content:encoded ->     "body"
    # wp:post_date_gmt -> "created_at"

    def to_rails
      # :user_id => creator
      page = ::Page.create!(:id => post_id, :title => title, 
        :created_at => post_date, :slug => post_name, 
        :published_at => publish_date, :body => content_formatted)
    end

    private 

    def format_paragraphs(text, html_options={})
      # WordPress doesn't export <p>-Tags, so let's run a simple_format over
      # the content. As we trust ourselves, no sanatize. This code is heavily
      # inspired by the simple_format rails helper
      text = ''.html_safe if text.nil?
      start_tag = tag('p', html_options, true)
      
      text.gsub!(/\n\n+/, "</p>#{start_tag}")  # 2+ newline  -> paragraph
      text.gsub!(/\r?\n/, "<br/>\n")               # \r\n and \n -> line break (must be after the paragraph detection to avoid <br/><br/>)
      text.insert 0, start_tag

      text.html_safe.safe_concat("</p>")
    end

    def format_syntax_highlighter(text)
      # Support for SyntaxHighlighter (http://alexgorbatchev.com/SyntaxHighlighter/):
      # In WordPress you can (via a plugin) enclose code in [lang][/lang]
      # blocks, which are converted to a <pre>-tag with a class corresponding
      # to the language.
      # 
      # Example:
      # [ruby]p "Hello World"[/ruby] 
      # -> <pre class="brush: ruby">p "Hello world"</pre> 
      text.gsub(/\[(\w+)\](.+?)\[\/\1\]/m, '<pre class="brush: \1">\2</pre>')
    end

    # Replace Wordpress shortcodes with formatted HTML (see shortcode gem and support/templates folder)
    def format_shortcodes(text)
      Shortcode.setup do |config|
        # the template parser to use
        config.template_parser = :haml # :erb or :haml supported, :haml is default

         # location of the template files
        config.template_path = ::File.join(::File.dirname(__FILE__), "..", "..","support/templates/haml")

        # a list of block tags to support e.g. [quote]Hello World[/quote]
        config.block_tags = [:caption, :column]

        # a list of self closing tags to support e.g. [youtube id="12345"]
        config.self_closing_tags = [:end_columns, "google-map-v3"]
      end

      Shortcode.process(text)
    end
  end
end
