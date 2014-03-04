require 'spec_helper'

describe WordPressImport::Category, :type => :model do
  let(:category) { WordPressImport::Category.new('Rant') }

  describe "#name" do
    specify { category.name.should == 'Rant' }
  end

  describe "#==" do
    specify { category.should == WordPressImport::Category.new('Rant') }
    specify { category.should_not == WordPressImport::Category.new('Tutorials') }
  end

  describe "#to_refinery" do
    before do 
      @category = category.to_refinery
    end

    it "should create a BlogCategory" do
      BlogCategory.should have(1).record
    end

    it "should copy the name over to the BlogCategory object" do
      @category.title.should == category.name
    end
  end

end
