
module SolrPlugin::FacetsBrowse

  extend ActiveSupport::Concern
  included do
  end

  def facets_browse
    @asset = params[:asset_key].to_sym
    @asset_class = asset_class(@asset)

    @facets_only = true
    send @asset
    load_facets

    @facet = @asset_class.map_facets_for(environment).find { |facet| facet[:id] == params[:facet_id] }
    raise 'Facet not found' if @facet.nil?
  end

  protected

  include SolrPlugin::SearchHelper

end

