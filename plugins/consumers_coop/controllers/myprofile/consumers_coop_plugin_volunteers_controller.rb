class ConsumersCoopPluginVolunteersController < OrdersCyclePluginVolunteersController

  no_design_blocks
  include ConsumersCoopPlugin::TranslationHelper

  helper ConsumersCoopPlugin::TranslationHelper

  protected

  extend HMVC::ClassMethods
  hmvc ConsumersCoopPlugin

end
