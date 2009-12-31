require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'indexing attribute fields', :type => :indexer do
  it 'should correctly index a stored string attribute field' do
    session.index(post(:title => 'A Title'))
    connection.should have_add_with(:title_ss => 'A Title')
  end

  it 'should correctly index an integer attribute field' do
    session.index(post(:blog_id => 4))
    connection.should have_add_with(:blog_id_i => '4')
  end

  it 'should correctly index a float attribute field' do
    session.index(post(:ratings_average => 2.23))
    connection.should have_add_with(:average_rating_f => '2.23')
  end

  it 'should correctly index a trie integer attribute field' do
    session.index(Photo.new(:size => 104856))
    connection.should have_add_with(:size_it => '104856')
  end

  it 'should correctly index a trie float attribute field' do
    session.index(Photo.new(:average_rating => 2.23))
    connection.should have_add_with(:average_rating_ft => '2.23')
  end

  it 'should correctly index a trie time attribute field' do
    session.index(Photo.new(:created_at => Time.parse('2009-12-16 15:00:00 -0400')))
    connection.should have_add_with(:created_at_dt => '2009-12-16T19:00:00Z')
  end

  it 'should allow indexing by a multiple-value field' do
    session.index(post(:category_ids => [3, 14]))
    connection.should have_add_with(:category_ids_im => ['3', '14'])
  end

  it 'should not index a single-value field with newlines as multiple' do
    session.index(post(:title => "Multi\nLine"))
    connection.adds.last.first.field_by_name(:title_ss).value.should == "Multi\nLine"
  end

  it 'should correctly index a time field' do
    session.index(
      post(:published_at => Time.parse('1983-07-08 05:00:00 -0400'))
    )
    connection.should have_add_with(:published_at_d => '1983-07-08T09:00:00Z')
  end

  it 'should correctly index a date field' do
    session.index(post(:expire_date => Date.new(2009, 07, 13)))
    connection.should have_add_with(:expire_date_d => '2009-07-13T00:00:00Z')
  end

  it 'should correctly index a boolean field' do
    session.index(post(:featured => true))
    connection.should have_add_with(:featured_b => 'true')
  end

  it 'should correctly index a false boolean field' do
    session.index(post(:featured => false))
    connection.should have_add_with(:featured_b => 'false')
  end

  it 'should not index a nil boolean field' do
    session.index(post)
    connection.should_not have_add_with(:featured_b)
  end

  it 'should index latitude and longitude as a pair' do
    session.index(post(:coordinates => [40.7, -73.5]))
    connection.should have_add_with(:lat => 40.7, :long => -73.5)
  end

  [
    [:lat, :lng],
    [:lat, :lon],
    [:lat, :long],
    [:latitude, :longitude]
  ].each do |lat_attr, lng_attr|
    it "should index latitude and longitude from #{lat_attr.inspect}, #{lng_attr.inspect}" do
      session.index(post(
          :coordinates => OpenStruct.new(lat_attr => 40.7, lng_attr => -73.5)
      ))
      connection.should have_add_with(:lat => 40.7, :long => -73.5)
    end
  end

  it 'should index latitude and longitude from a block' do
    session.index(Photo.new(:lat => 30, :lng => -60))
    connection.should have_add_with(:lat => 30.0, :long => -60.0)
  end

  it 'should correctly index an attribute field with block access' do
    session.index(post(:title => 'The Blog Post'))
    connection.should have_add_with(:sort_title_s => 'blog post')
  end

  it 'should correctly index an attribute field with instance-external block access' do
    session.index(post(:category_ids => [1, 2, 3]))
    connection.should have_add_with(:primary_category_id_i => '1')
  end

  it 'should correctly index a field that is defined on a superclass' do
    Sunspot.setup(SuperClass) { string :author_name }
    session.index(post(:author_name => 'Mat Brown'))
    connection.should have_add_with(:author_name_s => 'Mat Brown')
  end

  it 'should throw a NoMethodError only if a nonexistent type is defined' do
    lambda { Sunspot.setup(Post) { string :author_name }}.should_not raise_error
    lambda { Sunspot.setup(Post) { bogus :journey }}.should raise_error(NoMethodError)
  end

  it 'should throw a NoMethodError if a nonexistent field argument is passed' do
    lambda { Sunspot.setup(Post) { string :author_name, :bogus => :argument }}.should raise_error(ArgumentError)
  end

  it 'should throw an ArgumentError if single-value field tries to index multiple values' do
    lambda do
      Sunspot.setup(Post) { string :author_name }
      session.index(post(:author_name => ['Mat Brown', 'Matthew Brown']))
    end.should raise_error(ArgumentError)
  end
end
