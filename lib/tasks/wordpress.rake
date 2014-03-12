require 'wordpress'

namespace :wordpress do
  desc "Reset the blog relevant tables for a clean import"
  task :reset_blog do
    Rake::Task["environment"].invoke

    %w(posts post_translations taggings tags).each do |table_name|
      p "Truncating #{table_name} ..."
      ActiveRecord::Base.connection.execute "DELETE FROM #{table_name}"
    end

  end

  desc "import blog data from a WordPressImport XML dump"
  task :import_blog, :file_name, :blog_slug do |task, params|
    Rake::Task["environment"].invoke
    p "Loading XML from #{params[:file_name]} (using blog #{params[:blog_slug]}) ..."
    dump = WordPressImport::Dump.new(params[:file_name])

    p "Importing #{dump.authors.count} authors ..."
    dump.authors.each(&:to_rails)
    
    # by default, import all; unless $ONLY_PUBLISHED = "true"
    only_published = ENV['ONLY_PUBLISHED'] == 'true' ? true : false
    p "Importing #{dump.posts(only_published).count} posts ..."
    
    if only_published
      p "(only published posts)" 
    else
      p "(export ONLY_PUBLISHED=true to import only published posts)"
    end

    dump.posts(only_published).each{|p| p.to_rails(params[:blog_slug]) }
  end

  desc "reset blog tables and then import blog data from a WordPressImport XML dump"
  task :reset_and_import_blog, :file_name, :blog_slug do |task, params|
    Rake::Task["environment"].invoke
    Rake::Task["wordpress:reset_blog"].invoke
    Rake::Task["wordpress:import_blog"].invoke(params[:file_name], params[:blog_slug])
  end


  desc "download images in posts to public folder"
  task :download_post_images, :host_match do |task, params|
    raise "Error: you must specify a host to match for this download (i.e. rake wordpress:download_post_images['mywebsite']" if params[:host_match].blank?

    Rake::Task["environment"].invoke
    
    # scrape images
    ::Post.all.each do |post|
      doc = Nokogiri::HTML(post.body)
      doc.css("img").each do |img|
        # find remote file path
        remote_file = img.attributes["src"].text
        # load uri
        begin
          remote_uri = URI(remote_file)

          # only download if the image is a LFA-hosted image
          if remote_uri.host.match(params[:host_match]) != nil
            # find a local path for it
            local_file = File.expand_path(File.join(Rails.public_path,remote_uri.path))
            # only download if not already there
            unless File.exists?(local_file)
              # create local folders if necessary
              dirname = File.dirname(local_file)
              unless File.directory?(dirname)
                FileUtils.mkdir_p(dirname)
              end
              # save remote file to local
              begin
                File.open(local_file,'wb'){ |f| f.write(open(remote_file).read) }
                puts "Saved file #{remote_file}: #{local_file}"
              rescue OpenURI::HTTPError => error
                puts "Error saving file #{remote_file}: #{error.message}"
              end
            end
          end

        rescue => error
          puts "Error loading #{remote_file}: #{error.message}"
        end

      end
    end
  end

  # desc "Reset the cms relevant tables for a clean import"
  # task :reset_pages do
  #   Rake::Task["environment"].invoke

  #   %w(page_part_translations page_translations page_parts pages).each do |table_name|
  #     p "Truncating #{table_name} ..."
  #     ActiveRecord::Base.connection.execute "DELETE FROM #{table_name}"
  #   end
  # end

  # desc "import cms data from a WordPress XML dump"
  # task :import_pages, :file_name do |task, params|
  #   Rake::Task["environment"].invoke
  #   dump = WordPressImport::Dump.new(params[:file_name])

  #   only_published = ENV['ONLY_PUBLISHED'] == 'true' ? true : false
  #   dump.pages(only_published).each(&:to_rails)

  #   # After all pages are persisted we can now create the parent - child
  #   # relationships. This is necessary, as WordPress doesn't dump the pages in
  #   # a correct order. 
  #   dump.pages(only_published).each do |dump_page|
  #     page = ::Page.find(dump_page.post_id)
  #     page.parent_id = dump_page.parent_id
  #     page.save!
  #   end

  #   WordPressImport::Post.create_blog_page_if_necessary
        
  #   ENV["MODEL"] = 'Page'
  #   Rake::Task["friendly_id:redo_slugs"].invoke
  #   ENV.delete("MODEL")
  # end
  
  # desc "reset cms tables and then import cms data from a WordPress XML dump"
  # task :reset_and_import_pages, :file_name do |task, params|
  #   Rake::Task["environment"].invoke
  #   Rake::Task["wordpress:reset_pages"].invoke
  #   Rake::Task["wordpress:import_pages"].invoke(params[:file_name])
  # end


  desc "Reset the media relevant tables for a clean import"
  task :reset_media do
    Rake::Task["environment"].invoke

    %w(rich_rich_files).each do |table_name|
      p "Truncating #{table_name} ..."
      ActiveRecord::Base.connection.execute "DELETE FROM #{table_name}"
    end
  end

  desc "import media data (images and files) from a WordPress XML dump and replace target URLs in pages and posts"
  task :import_and_replace_media, :file_name do |task, params|
    Rake::Task["environment"].invoke
    dump = WordPressImport::Dump.new(params[:file_name])
    
    p "Importing #{dump.attachments.each_slice(200).first.count} attachments ..."
    attachments = dump.attachments.each_slice(200).first.each(&:to_rails)
    unless $ATTACHMENT_EXCEPTIONS.blank?
      p "----------------------------------------------------------"
      p "ERRORS WERE ENCOUNTERED IMPORTING ATTACHMENTS:" 
      $ATTACHMENT_EXCEPTIONS.each{|exception| puts exception}
      p "----------------------------------------------------------"
    end
    
    # parse all created Post and Page bodys and replace the old wordpress media urls 
    # with the newly created ones
    p "Replacing attachment URLs found in posts/pages ..."
    attachments.each(&:replace_url)

    unless $REPLACEMENT_EXCEPTIONS.blank?
      p "----------------------------------------------------------"
      p "ERRORS WERE ENCOUNTERED REPLACING ATTACHMENTS:" 
      $REPLACEMENT_EXCEPTIONS.each{|exception| puts exception}
      p "----------------------------------------------------------"
    end
  end

  desc "reset media tables and then import media data from a WordPress XML dump"
  task :reset_import_and_replace_media, :file_name do |task, params|
    Rake::Task["environment"].invoke
    Rake::Task["wordpress:reset_media"].invoke
    Rake::Task["wordpress:import_and_replace_media"].invoke(params[:file_name])
  end

  desc "reset and import all data (see the other tasks)"
  task :full_import, :file_name, :blog_slug do |task, params|
    Rake::Task["environment"].invoke
    Rake::Task["wordpress:reset_and_import_blog"].invoke(params[:file_name],params[:blog_slug])
    #Rake::Task["wordpress:reset_and_import_pages"].invoke(params[:file_name])
    #Rake::Task["wordpress:reset_import_and_replace_media"].invoke(params[:file_name])
    Rake::Task["wordpress:import_and_replace_media"].invoke(params[:file_name])
  end

end
