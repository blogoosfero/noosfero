module LayoutHelper

  def body_classes
    # Identify the current controller and action for the CSS:
    (logged_in? ? " logged-in" : "") +
    "#{" responsive" if theme_option :responsive}" +
    " controller-#{controller.controller_name}" +
    " action-#{controller.controller_name}-#{controller.action_name}" +
    " template-#{@layout_template || if profile.blank? then 'default' else profile.layout_template end}" +
    (!profile.nil? && profile.is_on_homepage?(request.path,@page) ? " profile-homepage" : "")
  end

  def html_tag_classes
    [
      body_classes, (
        profile.blank? ? nil : [
          'profile-type-is-' + profile.class.name.downcase,
          'profile-name-is-' + profile.identifier,
        ]
      ), 'theme-' + current_theme,
      @plugins.dispatch(:html_tag_classes).map do |content|
        if content.respond_to?(:call)
          instance_exec(&content)
        else
          content.html_safe
        end
      end
    ].flatten.compact.join(' ')
  end

  def noosfero_javascript
    plugins_javascripts = @plugins.flat_map{ |plugin| Array.wrap(plugin.js_files).map{ |js| plugin.class.public_path(js, true) } }

    output = ''
    output += render 'layouts/javascript'
    unless plugins_javascripts.empty?
      output += javascript_include_tag *plugins_javascripts
    end
    output += theme_javascript_ng.to_s
    output += javascript_tag 'render_all_jquery_ui_widgets()'

    output += template_javascript_ng.to_s

    output
  end

  def noosfero_stylesheets
    plugins_stylesheets = @plugins.select(&:stylesheet?).map { |plugin|
      plugin.class.public_path('style.css', true)
    }
    global_css_pub = "/designs/themes/#{environment.theme}/global.css"
    global_css_at_fs = Rails.root.join 'public' + global_css_pub

    output = []
    output << stylesheet_link_tag('application')
    output << stylesheet_link_tag(template_stylesheet_path)
    output << stylesheet_link_tag(*icon_theme_stylesheet_path)
    output << stylesheet_link_tag(jquery_ui_theme_stylesheet_path)
    unless plugins_stylesheets.empty?
      # FIXME: caching does not work with asset pipeline
      #cacheid = "cache/plugins-#{Digest::MD5.hexdigest plugins_stylesheets.to_s}"
      output << stylesheet_link_tag(*plugins_stylesheets)
    end
    if File.exists? global_css_at_fs
      output << stylesheet_link_tag(global_css_pub)
    end
    output << stylesheet_link_tag(theme_stylesheet_path)
    output.join "\n"
  end

  def noosfero_layout_features
    render :file => 'shared/noosfero_layout_features'
  end

  def template_stylesheet_path
    File.join template_path, "/stylesheets/style.css"
  end


  def icon_theme_stylesheet_path
    icon_themes = []
    theme_icon_themes = theme_option(:icon_theme) || []
    for icon_theme in theme_icon_themes do
      theme_path = "designs/icons/#{icon_theme}/style.css"
      if File.exists?(Rails.root.join('public', theme_path))
        icon_themes << theme_path
      end
    end
    icon_themes
  end

  def jquery_ui_theme_stylesheet_path
    "https://code.jquery.com/ui/1.10.4/themes/#{jquery_theme}/jquery-ui.css"
  end

  def theme_stylesheet_path
    "#{theme_path[1..-1]}/style.css"
  end

  def layout_template
    if profile then profile.layout_template else environment.layout_template end
  end

  def addthis_javascript
    if NOOSFERO_CONF['addthis_enabled']
      "<script src='//s7.addthis.com/js/300/addthis_widget.js#pubid=#{NOOSFERO_CONF['addthis_pub']}'></script>"
    end
  end

end

