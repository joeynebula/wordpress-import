module WordPressImport
  class Dump
    attr_reader :doc

    def initialize(file_name)
      begin
        file_name = File.expand_path(file_name)
        raise "error" unless File.file?(file_name) && File.readable?(file_name)
      rescue
        raise "Given file '#{file_name}' is not a file or not readable. Rake tasks take filename arguments like this: rake wordpress:full_import['/path/to/my_file']"
      end
      
      file = File.open(file_name)
      
      if file.size >= 10485760 # 10MB
        puts "WARNING: LibXML by default supports 10MB max file size. On some systems your file will be silently truncated; on others, an error will be raised. Consider splitting your file into smaller chunks and running rake tasks individually (authors, then blog/pages, then media), and double-check the import results."
      end

      @doc = Nokogiri::XML(file.read().gsub("\u0004", "")) # get rid of all EOT characters
    end

    def authors
      doc.xpath("//wp:author").collect do |author|
        Author.new(author)
      end
    end

    def pages(only_published=false)
      pages = doc.xpath("//item[wp:post_type = 'page']").collect do |page|
        Page.new(page)
      end

      pages = pages.select(&:published?) if only_published
      pages
    end

    def posts(only_published=false)
      posts = doc.xpath("//item[wp:post_type = 'post']").collect do |post|
        Post.new(post)
      end
      posts = posts.select(&:published?) if only_published
      posts
    end

    def tags
      doc.xpath("//wp:tag/wp:tag_slug").collect do |tag|
        Tag.new(tag.text)
      end
    end

    def categories
      doc.xpath("//wp:category/wp:cat_name").collect do |category|
        Category.new(category.text)
      end
    end

    def attachments
      doc.xpath("//item[wp:post_type = 'attachment']").collect do |attachment|
        Attachment.new(attachment)
      end
    end
  end
end
