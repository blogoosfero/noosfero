module FindByContents

  protected

  def autocomplete asset, scope, query, paginate_options={:page => 1}, options={:field => 'name'}
    plugins.dispatch_first(:autocomplete, asset, scope, query, paginate_options, options) ||
    fallback_autocomplete(asset, scope, query, paginate_options, options)
  end

  def fallback_autocomplete asset, scope, query, paginate_options, options
    field = options[:field]
    query = query.downcase
    scope.where([
      "LOWER(#{field}) ILIKE ? OR #{field}) ILIKE ?", "#{query}%", "% #{query}%"
    ])
    {:results => scope.paginate(paginate_options)}
  end

  def find_by_contents(asset, context, scope, query, paginate_options={:page => 1}, options={})
    scope = scope.with_templates(options[:template_id]) unless options[:template_id].blank?
    search = plugins.dispatch_first(:find_by_contents, asset, scope, query, paginate_options, options)
    register_search_term(query, scope.count, search[:results].count, context, asset)
    search
  end

end

