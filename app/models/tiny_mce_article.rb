class TinyMceArticle < TextArticle

  def self.short_description
    _('Article')
  end

  def self.description
    _('Add a new text article.')
  end
  
  xss_terminate :only => [  ]

  xss_terminate :only => [ :name, :abstract, :body ], :with => 'white_list', :on => 'validation'

  include WhiteListFilter
  filter_iframes :abstract, :body, :whitelist => lambda { profile && profile.environment && profile.environment.trusted_sites_for_iframe }

  def notifiable?
    true
  end

  def tiny_mce?
    true
  end

end
