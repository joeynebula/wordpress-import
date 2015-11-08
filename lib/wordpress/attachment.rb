module WordPressImport
  class Attachment
    attr_reader :node
    attr_reader :paperclip_image
    attr_reader :paperclip_file

    def initialize(node)
      @node = node
    end

    def title
      node.xpath("title").text
    end

    def description
      node.xpath("description").text
    end

    def file_name
      url.split('/').last
    end

    def post_date
      DateTime.parse node.xpath("wp:post_date").text
    end

    def url
      node.xpath("wp:attachment_url").text
    end

    def url_pattern
      url_parts = url.split('.')
      extension = url_parts.pop
      url_without_extension = url_parts.join('.')

      /#{url_without_extension}(-\d+x\d+)?\.#{extension}/
    end

    def image?
      url.match /\.(png|jpg|jpeg|gif)$/
    end

    def to_rails
      begin
        if image?
          to_image
        else
          to_file
        end
      rescue StandardError => ex
        message = "ERROR saving attachment #{url} -- #{ex.message}"
        p message
        $ATTACHMENT_EXCEPTIONS = [] if $ATTACHMENT_EXCEPTIONS.blank?
        $ATTACHMENT_EXCEPTIONS << message
        return nil
      end
    end

    def replace_url
      begin
        @occurrance_count = 0
        if image?
          replace_image_url
        else
          replace_resource_url
        end
        p "Replaced #{@occurrance_count} occurrances of #{url}"
      rescue StandardError => ex
        message = "ERROR replacing URL #{url} -- #{ex.message}"
        p message
        $REPLACEMENT_EXCEPTIONS = [] if $REPLACEMENT_EXCEPTIONS.blank?
        $REPLACEMENT_EXCEPTIONS << message
        return nil
      end
    end

    private

    def rich_file_clean_file_name(full_file_name)
      extension = File.extname(full_file_name).gsub(/^\.+/, '')
      filename = full_file_name.gsub(/\.#{extension}$/, '')

      filename = CGI::unescape(filename)
      filename = CGI::unescape(filename)

      extension = extension.downcase
      filename = filename.downcase.gsub(/[^a-z0-9]+/i, '-')

      "#{filename}.#{extension}"
    end

    def to_image
      # avoid duplicates; use our storage system's filename cleaner for lookup
      image = ::Rich::RichFile.find_or_initialize_by(rich_file_file_name: rich_file_clean_file_name(file_name))

      if image.rich_file.instance.id.blank?
        p "Importing image #{file_name}"
        image.simplified_type = "image"
        image.created_at = post_date
        image.rich_file = URI.parse(url)
        image.save!
      else
        p "image #{file_name} already exists..."
      end

      @paperclip_image = image
      image
    end

    def to_file
      # avoid duplicates; use our storage system's filename cleaner for lookup
      file = ::Rich::RichFile.find_or_initialize_by(rich_file_file_name: rich_file_clean_file_name(file_name))

      if file.rich_file.instance.id.blank?
        p "Importing file #{file_name}"
        file.created_at = post_date
        file.rich_file = URI.parse(url) if file.rich_file.blank?
        file.save!
      else
        p "file #{file_name} already exists..."
      end

      @paperclip_file = file
      file
    end


    def replace_image_url
      replace_image_url_in_blog_posts
      replace_image_url_in_pages
    end

    def replace_resource_url
      replace_resource_url_in_blog_posts
      replace_resource_url_in_pages
    end

    def replace_image_url_in_blog_posts
      replace_url_in_blog_posts(paperclip_image.rich_file.url)
    end

    def replace_image_url_in_pages
      replace_url_in_pages(paperclip_image.rich_file.url)
    end

    def replace_resource_url_in_blog_posts
      replace_url_in_blog_posts(paperclip_file.rich_file.url)
    end

    def replace_resource_url_in_pages
      replace_url_in_pages(paperclip_file.rich_file.url)
    end

    def replace_url_in_blog_posts(new_url)
      Refinery::Post.all.each do |post|
        if (! post.body.empty?) && post.body.include?(url)
          @occurrance_count += 1
          post.body = post.body.gsub(url_pattern, new_url)
          post.save!
        end
      end
    end

    def replace_url_in_pages(new_url)
      Refinery::Page.all.each do |page|
        page.translations.each do |translation|
          translation.parts.each do |part|
            if (! part.content.to_s.blank?) && part.content.include?(url)
              @occurrance_count += 1
              part.content = part.content.gsub(url_pattern, new_url)
              part.save!
            end
          end
        end
      end
    end

  end
end
