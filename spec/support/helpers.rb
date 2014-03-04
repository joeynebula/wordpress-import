module WordPressImport::SpecHelpers
  def test_dump
    file_name = File.expand_path(File.join(File.dirname(__FILE__), '../fixtures/wordpress_dump.xml'))
    WordPressImport::Dump.new(file_name) 
  end
end

RSpec.configure do |config|
  config.include WordPressImport::SpecHelpers
end

