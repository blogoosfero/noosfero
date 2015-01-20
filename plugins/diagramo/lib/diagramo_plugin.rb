class DiagramoPlugin < Noosfero::Plugin

  def self.plugin_name
    "Integração com o diagramo"
  end

  def self.plugin_description
    "Um novo conteúdo que integra o diagramo"
  end

  def content_types
    [DiagramoPlugin::Diagram]
  end

  def stylesheet?
    true
  end

end
