require 'spec_helper'

describe WordPressImport::Tag, :type => :model do
  let(:tag) { WordPressImport::Tag.new('ruby') }

  describe "#name" do
    specify { tag.name.should == 'ruby' }
  end

  describe "#==" do
    specify { tag.should == WordPressImport::Tag.new('ruby') }
    specify { tag.should_not == WordPressImport::Tag.new('php') }
  end

  describe "#to_refinery" do
    before do 
      @tag = tag.to_refinery
    end

    it "should create a ActsAsTaggableOn::Tag" do
      ::ActsAsTaggableOn::Tag.should have(1).record
    end
    
    it "should copy the name over to the Tag object" do
      @tag.name.should == tag.name
    end
  end

end

