require File.dirname(__FILE__) + '/../test_helper'
require 'home_controller'

# Re-raise errors caught by the controller.
class HomeController; def rescue_action(e) raise e end; end

class HomeControllerTest < Test::Unit::TestCase

  fixtures :profiles, :environments, :domains

  def setup
    @controller = HomeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_detection_of_environment_by_host
    uses_host 'www.colivre.net'
    get :index
    assert_template 'index'

    assert_kind_of Environment, assigns(:environment)

    assert_kind_of Domain, assigns(:domain)
    assert_equal 'colivre.net', assigns(:domain).name

    assert_nil assigns(:profile)
  end

  def test_detect_profile_by_host
    uses_host 'www.jrh.net'
    get :index
    assert_template 'index'

    assert_kind_of Environment, assigns(:environment)

    assert_kind_of Domain, assigns(:domain)
    assert_equal 'jrh.net', assigns(:domain).name

    assert_kind_of Profile, assigns(:profile)
  end

  def test_unknown_domain_falls_back_to_default_environment
    uses_host 'veryunprobabledomain.com'

    get :index
    assert_template 'index'

    assert_kind_of Environment, assigns(:environment)
    assert assigns(:environment).is_default?

  end

end
