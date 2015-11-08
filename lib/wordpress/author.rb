module WordPressImport
  class Author
    attr_reader :author_node

    def initialize(author_node)
      @author_node = author_node
    end

    def name
      name = author_node.xpath("wp:author_display_name").text
      name = author_node.xpath("wp:author_first_name").text + " " + author_node.xpath("wp:author_first_name").text if name.blank?
      name
    end

    def login
      author_node.xpath("wp:author_login").text
    end

    def email
      author_node.xpath("wp:author_email").text
    end

    def ==(other)
      login == other.login
    end

    def inspect
      "WordPress::Author: #{login} <#{email}>"
    end

    def to_rails
      user = Refinery::User.find_or_initialize_by_email(email)
      user.wp_username = login

      unless user.persisted?
        user.name = name
        user.password = 'password'
        user.password_confirmation = 'password'
      end
      user.save

      puts "User #{login} imported."

      user
    end
  end
end
