require 'test_helper'

class UrlHelperTest < ActionDispatch::IntegrationTest

  extend MiniTest::Expectations
  extend MiniTest::Spec::DSL
  prepend UrlHelper

  let(:params){ {} }

  describe 'override user' do
    it 'preserve override_user if present' do
      params[:override_user] = 1
      assert_equal default_url_options[:override_user], params[:override_user]
    end
  end

  describe '#url_for' do
    let(:controller_path) { 'content_viewer' }

    before do
      @profile = create_user.person
    end

    describe 'profile option is present' do

      describe 'target controller needs profile' do
        describe 'to profile with custom domain' do
          before do
            @profile.domains.create name: 'example.com'
          end

          it 'removes the :profile param when target' do
            @profile.hostname.must_equal 'example.com'
            options = url_for profile: @profile.identifier, controller: :profile
            options[:profile].wont_equal @profile.identifier
          end
        end

        describe 'profile page without custom domain' do
          it 'removes the :profile param when target' do
            options = url_for profile: @profile.identifier, controller: :profile
            options[:profile].must_equal @profile.identifier
          end
        end
      end

      describe 'target controller doesnt need profile' do
        it 'removes the :profile param when target' do
          options = url_for profile: @profile.identifier, controller: :account
          options[:profile].wont_equal @profile.identifier
        end
      end

    end

    describe 'profile option isnt present' do
      describe 'target controller needs profile' do
        describe 'to profile without custom domain' do
          it 'add the :profile param' do
            @profile.hostname.must_be_nil
            options = url_for controller: :content_viewer
            options[:profile].must_equal @profile.identifier
          end
        end
      end
    end
  end

  protected

  ##
  # simpler super method
  #
  def url_for options
    options
  end

end
