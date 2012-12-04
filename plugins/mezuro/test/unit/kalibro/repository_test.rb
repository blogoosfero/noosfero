require "test_helper"

require "#{RAILS_ROOT}/plugins/mezuro/test/fixtures/repository_fixtures"

class RepositoryTest < ActiveSupport::TestCase

  def setup
    @hash = RepositoryFixtures.repository_hash
    @repository = RepositoryFixtures.repository
    @created_repository = RepositoryFixtures.created_repository
  end

  should 'new repository from hash' do
    assert_equal @repository.type, Kalibro::Repository.new(@hash).type
  end

  should 'convert repository to hash' do
    assert_equal @hash, @repository.to_hash
  end

  should 'get supported repository types' do
    types = ['BAZAAR', 'GIT', 'SUBVERSION']
    Kalibro::Repository.expects(:request).with(:supported_repository_types).returns({:supported_type => types})
    assert_equal types, Kalibro::Repository.repository_types
  end

  should 'get repository of a precessing' do
    id = 31
    Kalibro::Repository.expects(:request).with(:repository_of, {:processing_id => id}).returns({:repository => @hash})
    assert_equal @hash[:name], Kalibro::Repository.repository_of(id).name
  end

  should 'get repositories of a project' do
    project_id = 31
    Kalibro::Repository.expects(:request).with(:repositories_of, {:project_id => project_id}).returns({:repository => [@hash]})
    assert_equal @hash[:name], Kalibro::Repository.repositories_of(project_id).first.name
  end

  should 'return true when repository is saved successfully' do
    id_from_kalibro = 1
    project_id = 56
    Kalibro::Repository.expects(:request).with(:save_repository, {:repository => @created_repository.to_hash, :project_id => project_id}).returns(:repository_id => id_from_kalibro)
    Kalibro::Repository.expects(:request).with(:process_repository, :repository_id => id_from_kalibro).returns(:repository_id => id_from_kalibro)
    assert @created_repository.save(project_id)
    assert_equal id_from_kalibro, @created_repository.id
  end

  should 'return false when repository is not saved successfully' do
    project_id = 56
    Kalibro::Repository.expects(:request).with(:save_repository, {:repository => @created_repository.to_hash, :project_id => project_id}).raises(Exception.new)
    assert !(@created_repository.save(project_id))
    assert_nil @created_repository.id
  end

  should 'destroy repository by id' do
    Kalibro::Repository.expects(:request).with(:delete_repository, {:repository_id => @repository.id})
    @repository.destroy
  end

  should 'process repository' do
    Kalibro::Repository.expects(:request).with(:process_repository, {:repository_id => @repository.id});
    @repository.process_repository
  end

  should 'cancel processing of a repository' do
    Kalibro::Repository.expects(:request).with(:cancel_processing_of_repository, {:repository_id => @repository.id});
    @repository.cancel_processing_of_repository
  end

end
