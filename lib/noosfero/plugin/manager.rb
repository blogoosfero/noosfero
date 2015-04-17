class Noosfero::Plugin::Manager

  include Noosfero::Plugin::HotSpot::Dispatchers

  attr_reader :environment
  attr_reader :context

  def initialize(environment, context)
    @environment = environment
    @context = context
  end

  delegate :each, :to => :enabled_plugins
  include Enumerable

  # Dispatches +event+ to each enabled plugin and collect the results.
  #
  # Returns an Array containing the objects returned by the event method in
  # each plugin. This array is compacted (i.e. nils are removed) and flattened
  # (i.e. elements of arrays are added to the resulting array). For example, if
  # the enabled plugins return 1, 0, nil, and [1,2,3], then this method will
  # return [1,0,1,2,3]
  #
  def dispatch(event, *args)
    flat_map{ |plugin| result_for plugin, event, *args }.compact
  end

  def fetch_plugins(event, *args)
    flat_map{ |plugin| plugin.class if result_for plugin, event, *args }.compact
  end

  def dispatch_without_flatten(event, *args)
    map { |plugin| result_for plugin, event, *args }.compact
  end

  alias :dispatch_scopes :dispatch_without_flatten

  def default_for event, *args
    Noosfero::Plugin.new.send event, *args
  end

  def result_for plugin, event, *args
    # check if defined to avoid crash, as there is hotspots using method_missing
    return unless plugin.respond_to? event
    method = plugin.method event
    method.call *args if method.owner != Noosfero::Plugin::HotSpot::Definitions
  end

  def dispatch_first(event, *args)
    each do |plugin|
      result = result_for plugin, event, *args
      return result if result.present?
    end
    default_for event, *args
  end

  def fetch_first_plugin(event, *args)
    each do |plugin|
      result = result_for plugin, event, *args
      return plugin.class if result.present?
    end
    nil
  end

  def pipeline(event, *args)
    each do |plugin|
      # result_for can't be used here and default must be returned to keep args
      result = plugin.send event, *args
      result = result.kind_of?(Array) ? result : [result]
      raise ArgumentError, "Pipeline broken by #{plugin.class.name} on #{event} with #{result.length} arguments instead of #{args.length}." if result.length != args.length
      args = result
    end
    args.length < 2 ? args.first : args
  end

  def filter(property, data)
    inject(data){ |data, plugin| data = plugin.send(property, data) }
  end

  def enabled_plugins
    @enabled_plugins ||= (Noosfero::Plugin.all & environment.enabled_plugins).map do |plugin|
      Noosfero::Plugin.load_plugin_identifier(plugin).new context
    end
  end
  alias_method :plugins, :enabled_plugins

  def default_macro
    @default_macro ||= Noosfero::Plugin::Macro.new(context)
  end

  def parse_macro(macro_name, macro, source = nil)
    macro_instance = enabled_macros[macro_name] || default_macro
    macro_instance.convert(macro, source)
  end

  def enabled_macros
    @enabled_macros ||= plugins_macros.inject({}) do |memo, macro|
      memo.merge!(macro.identifier => macro.new(context))
    end
  end

  def [](class_name)
    enabled_plugins.select do |plugin|
      plugin.kind_of?(class_name.constantize)
    end.first
  end

end
