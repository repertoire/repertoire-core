require File.dirname(__FILE__) + '/spec_helper'
require 'dm-core'

describe RepertoireCore do
  
  before(:all) do
    DataMapper.setup(:default, 'sqlite3::memory:')
  end 
  
end

describe "RepertoireCore (module)" do
  
  # Feel free to remove the specs below
  
  it "should be registered in Merb::Slices.slices" do
    Merb::Slices.slices.should include(RepertoireCore)
  end
  
  it "should have an :identifier property" do
    RepertoireCore.identifier.should == "repertoire_core"
  end
  
  it "should have an :identifier_sym property" do
    RepertoireCore.identifier_sym.should == :repertoire_core
  end
  
  it "should have a :root property" do
    RepertoireCore.root.should == current_slice_root
    RepertoireCore.root_path('app').should == current_slice_root / 'app'
  end
  
  it "should have metadata properties" do
  #  RepertoireCore.description.should == "RepertoireCore is a Merb slice that provides authentication"
  #  RepertoireCore.version.should == "0.1.0"
  #  RepertoireCore.author.should == "Merb Core"
  end
  
  it "should have a config property (Hash)" do
    RepertoireCore.config.should be_kind_of(Hash)
  end
  
  it "should have a :layout config option set" do
    RepertoireCore.config[:layout].should == :repertoire_core
  end
  
  it "should have a dir_for method" do
    app_path = RepertoireCore.dir_for(:application)
    app_path.should == current_slice_root / 'app'
    [:view, :model, :controller, :helper, :mailer, :part].each do |type|
      RepertoireCore.dir_for(type).should == app_path / "#{type}s"
    end
    public_path = RepertoireCore.dir_for(:public)
    public_path.should == current_slice_root / 'public'
    [:stylesheet, :javascript, :image].each do |type|
      RepertoireCore.dir_for(type).should == public_path / "#{type}s"
    end
  end
  
  it "should have a app_dir_for method" do
    root_path = RepertoireCore.app_dir_for(:root)
    root_path.should == Merb.root / 'slices' / 'repertoire_core'
    app_path = RepertoireCore.app_dir_for(:application)
    app_path.should == root_path / 'app'
    [:view, :model, :controller, :helper, :mailer, :part].each do |type|
      RepertoireCore.app_dir_for(type).should == app_path / "#{type}s"
    end
    public_path = RepertoireCore.app_dir_for(:public)
    public_path.should == Merb.dir_for(:public) / 'slices' / 'repertoire_core'
    [:stylesheet, :javascript, :image].each do |type|
      RepertoireCore.app_dir_for(type).should == public_path / "#{type}s"
    end
  end
  
  it "should have a public_dir_for method" do
    public_path = RepertoireCore.public_dir_for(:public)
    public_path.should == '/slices' / 'repertoire_core'
    [:stylesheet, :javascript, :image].each do |type|
      RepertoireCore.public_dir_for(type).should == public_path / "#{type}s"
    end
  end
  
  it "should keep a list of path component types to use when copying files" do
    (RepertoireCore.mirrored_components & RepertoireCore.slice_paths.keys).length.should == RepertoireCore.mirrored_components.length
  end
  
end