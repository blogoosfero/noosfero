class OrdersCyclePluginProductController < SuppliersPluginProductController

  no_design_blocks

  # FIXME: remove me when styles move from consumers_coop plugin
  include ConsumersCoopPlugin::ControllerHelper
  include OrdersCyclePlugin::TranslationHelper

  helper OrdersCyclePlugin::TranslationHelper
  helper OrdersCyclePlugin::OrdersCycleDisplayHelper

  def edit
    super
    @units = environment.units.all
  end

  def remove_from_order
    @offered_product = OrdersCyclePlugin::OfferedProduct.find params[:id]
    @order = OrdersPlugin::Sale.find params[:order_id]
    @item = @order.items.find_by_product_id @offered_product.id
    @item.destroy rescue render :nothing => true
  end

  def cycle_edit
    @product = OrdersCyclePlugin::OfferedProduct.find params[:id]
    if request.xhr?
      @product.update_attributes! params[:product]
      respond_to do |format|
        format.js
      end
    end
  end

  def cycle_destroy
    @product = OrdersCyclePlugin::OfferedProduct.find params[:id]
    @product.destroy
    flash[:notice] = t('controllers.myprofile.product_controller.product_removed_from_')
  end

  protected

  extend ControllerInheritance::ClassMethods
  hmvc OrdersCyclePlugin

end
