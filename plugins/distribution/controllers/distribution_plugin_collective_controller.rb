class DistributionPluginDeliveryMethodController < ApplicationController
  append_view_path File.join(File.dirname(__FILE__) + '/../views')

  def index
  end

  def new
    if request.post?
      if params[:session_id]
        @for_session = true
        @session = DistributionPluginSession.find(params[:session_id])
        @delivery_method = DistributionPluginDeliveryMethod.create!(params[:delivery_method].merge({:node_id => @session.node_id}))
        @delivery_option = DistributionPluginDeliveryOption.create!(:session => @session, :delivery_method => @delivery_method)
      else
        @delivery_method = DistributionPluginDeliveryMethod.create!(params[:delivery_method])
      end
    else
      @delivery_method = DistributionPluginDeliveryMethod.new(:node => params[:node_id])
    end
  end

  def edit
    @delivery_method = DistributionPluginDeliveryMethod.find_by_id(params[:id])
  end

  def destroy
    dm = DistributionPluginDeliveryMethod.find_by_id(params[:id])
    @delivery_method_id = dm.id
    dm.destroy if dm
    flash[:notice] = _('Delivery method removed from session')
  end
end
