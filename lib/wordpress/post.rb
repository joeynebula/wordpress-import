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

    # blog_slug is used to identify which blog this import is from
    def to_rails(blog_slug)

      user = ::RefineryAuthenticationDeviseUser.find_by_wp_username(creator)

      if user.nil?
        raise "User with wp_username #{creator} not found"
      end

      post = ::RefineryBlogPost.create({
        :wp_post_id => post_id, :slug => post_name,
        :user_id => user.id, :title => title,
        :created_at => post_date,
        :published_at => publish_date,
        :wp_link => link,
        :wp_blog => blog_slug,
        :translations_attributes => { "0" => {
            :locale => "en",
            :title => title,
            :body => content_formatted,
            # merge the translation's category list with the wordpress post's
            :category_list => categories.collect(&:name) | tags.collect(&:name)
          }}
        })

      if post.errors.blank?
        puts "Post #{post_name} imported."
        return post.reload
      else
        puts post.inspect
        raise post.errors.full_messages.to_s
      end
    end

  end
end
