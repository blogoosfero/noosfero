module UrlSupport

  protected

  extend ActiveSupport::Concern
  included do
    helper_method :url_for
  end

  mattr_accessor :controller_path_class
  self.controller_path_class = {}

  def url_for options = {}
    return super unless options.is_a? Hash
    # for action mailer
    return super unless respond_to? :params and respond_to? :controller_path

    ##
    # This has to implemented overiding #url_for due to 2 reasons:
    # 1) #default_url_options cannot be used to delete params
    # 2) #url_options is general and not specific to each options/url_for call
    #
    # This does:
    # 1) Remove :profile when not needed by the target controller
    # 2) Remove :profile when target profile has a custom domain
    # 3) Add :profile if target controller needs a profile and target profile doesn't use a custom domain
    #
    path              = (options[:controller] || self.controller_path).to_sym
    controller        = UrlSupport.controller_path_class[path] ||= "#{path}_controller".camelize.constantize
    profile_needed    = controller.profile_needed if controller.respond_to? :profile_needed, true
    use_custom_domain = @profile && @profile.identifier == options[:profile] && @profile.hostname
    if use_custom_domain
      options.delete :profile
    elsif not profile_needed and options[:profile].present?
      options.delete :profile
    elsif profile_needed and @profile
      options[:profile] ||= @profile.identifier
    end

    super options
  end

  def default_url_options
    options = super

    options[:override_user] = params[:override_user] if params[:override_user].present?

    options
  end
end

