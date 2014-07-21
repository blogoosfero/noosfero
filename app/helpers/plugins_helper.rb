module PluginsHelper

  def plugins_article_toolbar_actions
    @plugins.dispatch(:article_toolbar_actions, @page).collect { |content| instance_eval(&content) }.join ""
  end

end
