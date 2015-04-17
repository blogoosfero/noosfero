require 'pp'

# locally-developed modules
require 'acts_as_filesystem'
require 'acts_as_having_settings'
require 'acts_as_having_boxes'
require 'acts_as_having_image'
require 'acts_as_having_posts'
require 'route_if'
require 'maybe_add_http'
require 'set_profile_region_from_city_state'
require 'authenticated_system'
require 'needs_profile'
require 'white_list_filter'

# ruby exts
require 'super_proxy'

# third-party libraries
require 'will_paginate'
require 'will_paginate/array'
require 'nokogiri'

require 'fast_blank' unless RUBY_ENGINE == 'jruby'
# THESE DON'T HELP!
#require 'escape_utils' #require 'escape_utils/html/rack' # to patch Rack::Utils
#require 'escape_utils/html/erb' # to patch ERB::Util
#require 'escape_utils/html/cgi' # to patch CGI
#require 'escape_utils/url/uri' # to patch URI
#require 'escape_utils/javascript/action_view' # to patch ActionView::Helpers::JavaScriptHelper

