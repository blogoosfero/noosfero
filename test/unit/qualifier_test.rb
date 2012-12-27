# encoding: UTF-8
require File.dirname(__FILE__) + '/../test_helper'

class QualifierTest < ActiveSupport::TestCase

  should 'environment is mandatory' do
    qualifier = Qualifier.new(:name => 'Qualifier without environment')
    assert !qualifier.valid?

    qualifier.environment = fast_create(Environment)
    assert qualifier.valid?
  end

  should 'belongs to environment' do
    env_one = fast_create(Environment)
    qualifier_from_env_one = Qualifier.create(:name => 'Qualifier from environment one', :environment => env_one)

    env_two = fast_create(Environment)
    qualifier_from_env_two = Qualifier.create(:name => 'Qualifier from environment two', :environment => env_two)

    assert_includes env_one.qualifiers, qualifier_from_env_one
    assert_not_includes env_one.qualifiers, qualifier_from_env_two
  end

  should 'name is mandatory' do
    env_one = fast_create(Environment)
    qualifier = Qualifier.new(:environment => env_one)
    assert !qualifier.valid?

    qualifier.name = 'Qualifier name'
    assert qualifier.valid?
  end

  should 'sort by name' do
    last = fast_create(Qualifier, :name => "Zumm")
    first = fast_create(Qualifier, :name => "Atum")
    assert_equal [first, last], Qualifier.all.sort
  end

  should 'sorting is not case sensitive' do
    first = fast_create(Qualifier, :name => "Aaaa")
    second = fast_create(Qualifier, :name => "abbb")
    last = fast_create(Qualifier, :name => "Accc")
    assert_equal [first, second, last], Qualifier.all.sort
  end

  should 'discard non-ascii char when sorting' do
    first = fast_create(Qualifier, :name => "Áaaa")
    last = fast_create(Qualifier, :name => "Aáab")
    assert_equal [first, last], Qualifier.all.sort
  end

  should 'clean all ProductQualifier when destroy a Qualifier' do
    product1 = fast_create(Product)
    product2 = fast_create(Product)
    qualifier = fast_create(Qualifier, :name => 'Free Software')
    certifier = fast_create(Certifier, :name => 'FSF')
    ProductQualifier.create!(:product => product1, :qualifier => qualifier, :certifier => certifier)
    ProductQualifier.create!(:product => product2, :qualifier => qualifier, :certifier => certifier)
    assert_equal [['Free Software', 'FSF']], product1.product_qualifiers.map{|i| [i.qualifier.name, i.certifier.name]}
    Qualifier.destroy_all
    assert_equal [], product1.product_qualifiers(true)
  end

  should 'reindex products after saving' do
    product = mock
    Qualifier.any_instance.stubs(:products).returns([product])
    Qualifier.expects(:solr_batch_add).with(includes(product))
    qual = fast_create(Qualifier)
    qual.save!
  end
end
