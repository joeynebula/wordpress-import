module WordPressImport
  class Post < Page
    def tags
      # xml dump has "post_tag" for wordpress 3.1 and "tag" for 3.0
      path = if node.xpath("category[@domain='post_tag']").count > 0
        "category[@domain='post_tag']"
      else
        "category[@domain='tag']"
      end

      node.xpath(path).collect do |tag_node| 
        Tag.new(tag_node.text)
      end
    end

    def tag_list
      tags.collect(&:name).join(',')
    end

    def categories
      node.xpath("category[@domain='category']").collect do |cat|
        Category.new(cat.text)
      end
    end

    def comments
      node.xpath("wp:comment").collect do |comment_node|
        Comment.new(comment_node)
      end
    end

    def to_rails

      user = ::User.find_by_wp_username(creator)

      if user.nil? 
        raise "User with wp_username #{creator} not found"
      end

      post = ::Post.find_or_initialize_by(:id => post_id, :slug => post_name)

      post.assign_attributes( 
        :user_id => user.id, :title => title, 
        :created_at => post_date, 
        :published_at => publish_date)
      # :body => content_formatted taken care of by translation below

      if post.translations.blank?
        translation = post.translations.build
      else
        translation = post.translations.first
      end
      
      translation.locale = "en"
      translation.title = title
      translation.body = content_formatted
      translation.save
      
      post.save

      if post.errors.blank?
        return post.reload
      else
        puts post.inspect
        raise post.errors.full_messages.to_s
      end
    end

  end
end
