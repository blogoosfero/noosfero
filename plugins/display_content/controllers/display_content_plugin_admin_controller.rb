require File.dirname(__FILE__) + '/display_content_plugin_module'

class DisplayContentPluginAdminController < AdminController

  append_view_path File.join(File.dirname(__FILE__) + '/../views')

  include DisplayContentPluginController 

end
