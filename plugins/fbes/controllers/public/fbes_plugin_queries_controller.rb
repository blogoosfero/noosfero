class FbesPluginQueriesController < PublicController

  before_filter :login_required
  protect 'view_environment_admin_panel', :environment
  no_design_blocks

  FbesPlugin::Queries::Hash.each do |name, query|
    define_method name do
      @fbes_plugin_page = (params[:page] || 1).to_i
      @fbes_plugin_per_page = if params[:per_page] == 'all' then nil else (params[:per_page] || 20).to_i end
      format = params[:format]
      request.format = format.to_sym if format.present?

      query_with_pagination = if not @fbes_plugin_per_page then query else "#{query} offset #{(@fbes_plugin_page-1)*@fbes_plugin_per_page} limit #{@fbes_plugin_per_page}" end
      result = ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute query_with_pagination
      end

      @fbes_plugin_result = result
      @fbes_plugin_result_full_count = result.first['full_count']
      @fbes_plugin_result_pages = (@fbes_plugin_per_page) ? (@fbes_plugin_result_full_count.to_f / @fbes_plugin_per_page.to_f).ceil : 1

      respond_to do |format|
        format.json do
          render :json => result.to_json
        end
        format.csv do
          csv = CSV.generate do |csv|
            csv << result.first.keys
            result.each{ |r| csv << r.values }
          end
          send_csv csv
        end
        format.html do
          render 'show_html'
        end
      end
    end
  end

  protected

  def send_csv csv
    send_data csv, :type => 'text/csv; charset=utf-8; header=present', :disposition => "attachment; filename=#{params[:action]}.csv"
  end

end
