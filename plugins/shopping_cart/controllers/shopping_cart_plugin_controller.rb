require 'base64'

class ShoppingCartPluginController < OrdersPluginController

  include ShoppingCartPlugin::CartHelper
  helper ShoppingCartPlugin::CartHelper

  def get
    config =
      if cart.nil?
        { :profile_id => params[:profile_id],
          :has_products => false,
          :visible => false,
          :products => []}
      else
        {
        	:profile_id => cart[:profile_id],
          :profile_short_name => cart_profile.short_name,
          :has_products => (cart[:items].keys.size > 0),
          :visible => visible?,
          :products => products,
        }
      end
    config[:has_previous_orders] = if cart_profile then previous_orders.first.present? else false end
    render :text => config.to_json
  end

  def add
    product = find_product(params[:id])
    if product && (profile = validate_same_profile(product))
        self.cart = { :profile_id => profile.id, :items => {} } if self.cart.nil?
        self.cart[:items][product.id] = 0 if self.cart[:items][product.id].nil?
        self.cart[:items][product.id] += 1
        render :text => {
          :ok => true,
          :error => {:code => 0},
          :products => [{
            :id => product.id,
            :name => product.name,
            :price => get_price(product, profile.environment),
            :description => product.description,
            :picture => product.default_image(:minor),
            :quantity => self.cart[:items][product.id]
          }]
        }.to_json
    end
  end

  def remove
    id = params[:id].to_i
    if validate_cart_presence && validate_cart_has_product(id)
      self.cart[:items].delete(id)
      self.cart = nil if self.cart[:items].empty?
      render :text => {
        :ok => true,
        :error => {:code => 0},
        :product_id => id
      }.to_json
    end
  end

  def list
    if validate_cart_presence
      render :text => {
        :ok => true,
        :error => {:code => 0},
        :products => products
      }.to_json
    end
  end

  def update_quantity
    quantity = params[:quantity].to_i
    id = params[:id].to_i
    if validate_cart_presence && validate_cart_has_product(id) && validate_item_quantity(quantity)
      product = Product.find(id)
      self.cart[:items][product.id] = quantity
      render :text => {
        :ok => true,
        :error => {:code => 0},
        :product_id => id,
        :quantity => quantity
      }.to_json
    end
  end

  def clean
    self.cart = nil
    render :text => {
      :ok => true,
      :error => {:code => 0}
    }.to_json
  end

  def repeat
    unless params[:id].present?
      @orders = previous_orders.last(5).reverse
      @orders.each{ |o| o.enable_product_diff }
    else
      @order = cart_profile.orders.find params[:id]
      self.cart = { profile_id: cart_profile.id, items: {} }
      @order.items.each do |item|
        next unless item.product.available
        self.cart[:items][item.product_id] = item.quantity_consumer_ordered.to_i
      end

      render json: {
        products: products,
      }
    end
  end

  def buy
    @customer = user || Person.new
    if validate_cart_presence
      @cart = cart
      @profile = cart_profile
      @settings = cart_profile.shopping_cart_settings
      render :layout => false
    end
  end

  def send_request
    register_order(params[:customer], self.cart[:items])
    begin
      profile = cart_profile
      ShoppingCartPlugin::Mailer.customer_notification(params[:customer], profile, self.cart[:items], params[:delivery_option]).deliver
      ShoppingCartPlugin::Mailer.supplier_notification(params[:customer], profile, self.cart[:items], params[:delivery_option]).deliver
      self.cart = nil
      render :text => {
        :ok => true,
        :message => _('Your order has been sent successfully! You will receive a confirmation e-mail shortly.'),
        :error => {:code => 0}
      }.to_json
    rescue ActiveRecord::ActiveRecordError
      render :text => {
        :ok => false,
        :error => {
          :code => 6,
          :message => exception.message
        }
      }.to_json
    end
  end

  def visibility
    render :text => visible?.to_json
  end

  def show
    begin
      self.cart[:visibility] = true
      render :text => {
        :ok => true,
        :message => _('Basket displayed.'),
        :error => {:code => 0}
      }.to_json
    rescue Exception => exception
      render :text => {
        :ok => false,
        :error => {
          :code => 7,
          :message => exception.message
        }
      }.to_json
    end
  end

  def hide
    begin
      self.cart[:visibility] = false
      render :text => {
        :ok => true,
        :message => _('Basket hidden.'),
        :error => {:code => 0}
      }.to_json
    rescue Exception => exception
      render :text => {
        :ok => false,
        :error => {
          :code => 8,
          :message => exception.message
        }
      }.to_json
    end
  end

  def update_delivery_option
    profile = cart_profile
    settings = profile.shopping_cart_settings
    delivery_price = settings.delivery_options[params[:delivery_option]]
    delivery = Product.new(:name => params[:delivery_option], :price => delivery_price)
    delivery.save run_callbacks: false, validate: false
    items = self.cart[:items].clone
    items[delivery.id] = 1
    total_price = get_total_on_currency(items, environment)
    delivery.destroy
    render :text => {
      :ok => true,
      :delivery_price => float_to_currency_cart(delivery_price, environment),
      :total_price => total_price,
      :message => _('Delivery option updated.'),
      :error => {:code => 0}
    }.to_json
  end

  private

  def validate_same_profile(product)
    if self.cart && self.cart[:profile_id] && product.profile_id != self.cart[:profile_id]
      render :text => {
        :ok => false,
        :error => {
          :code => 1,
          :message => _("Your basket contains items from '%{profile_name}'. Please empty the basket or checkout before adding items from here.") % {profile_name: cart_profile.short_name}
        }
      }.to_json
      return nil
    end
    product.profile
  end

  def validate_cart_presence
    if self.cart.nil?
      render :text => {
        :ok => false,
        :error => {
        :code => 2,
        :message => _("There is no basket.")
      }
      }.to_json
      return false
    end
    true
  end

  def find_product(id)
    begin
      product = Product.find(id)
    rescue ActiveRecord::RecordNotFound
      render :text => {
        :ok => false,
        :error => {
        :code => 3,
        :message => _("This enterprise doesn't have this product.")
      }
      }.to_json
      return nil
    end
    product
  end

  def validate_cart_has_product(id)
    if !self.cart[:items].has_key?(id)
      render :text => {
        :ok => false,
        :error => {
        :code => 4,
        :message => _("The basket doesn't have this product.")
      }
      }.to_json
      return false
    end
    true
  end

  def validate_item_quantity(quantity)
    if quantity.to_i < 1
      render :text => {
        :ok => false,
        :error => {
        :code => 5,
        :message => _("Invalid quantity.")
      }
      }.to_json
      return false
    end
    true
  end

  def register_order(custumer, items)
    products_list = {}; items.each do |id, quantity|
      product = Product.find(id)
      price = product.price || 0
      products_list[id] = {:quantity => quantity, :price => price, :name => product.name}
    end

    order = OrdersPlugin::Sale.new
    order.profile = environment.profiles.find(cart[:profile_id])
    order.session_id = session_id unless user
    order.consumer = user
    order.source = 'shopping_cart_plugin'
    order.status = 'ordered'
    order.products_list = products_list
    order.consumer_data = {
      :name => params[:customer][:name], :email => params[:customer][:email], :contact_phone => params[:customer][:contact_phone],
    }
    order.payment_data = {
      :method => params[:customer][:payment], :change => params[:customer][:change],
    }
    order.consumer_delivery_data = {
      :name => params[:customer][:delivery_option],
      :address_line1 => params[:customer][:address],
      :address_line2 => params[:customer][:address_line2],
      :reference => params[:customer][:address_reference],
      :district => params[:customer][:district],
      :city => params[:customer][:city],
      :state => params[:customer][:state],
      :postal_code => params[:customer][:zip_code],
    }
    order.save!
  end

  # must be public
  def profile
    cart_profile
  end

  protected

  def cart
    @cart ||=
      begin
        cookies[cookie_key] && YAML.load(Base64.decode64(cookies[cookie_key])) || nil
      end
    # migrate from old attribute
    @cart[:profile_id] ||= @cart.delete(:enterprise_id) if @cart and @cart[:enterprise_id].present?
    @cart
  end

  def cart_profile
    profile_id = if params[:profile_id].present? then params[:profile_id] elsif cart then cart[:profile_id] end
    @cart_profile ||= environment.profiles.find profile_id rescue nil
  end

  # from OrdersPluginController
  def supplier
    cart_profile
  end

  def cart=(data)
    @cart = data
  end

  after_filter :save_cookie
  def save_cookie
    if @cart.nil?
      cookies.delete(cookie_key, :path => '/plugin/shopping_cart')
    else
      cookies[cookie_key] = {
        :value => Base64.encode64(@cart.to_yaml),
        :path => "/plugin/shopping_cart"
      }
    end
  end

  def cookie_key
    :_noosfero_plugin_shopping_cart
  end

  def visible?
    !self.cart.has_key?(:visibility) || self.cart[:visibility]
  end

  def products
    self.cart[:items].collect do |id, quantity|
      product = Product.find_by_id(id)
      if product
        { :id => product.id,
          :name => product.name,
          :price => get_price(product, product.profile.environment),
          :description => product.description,
          :picture => product.default_image(:minor),
          :quantity => quantity
        }
      else
        { :id => id,
          :name => _('Undefined product'),
          :price => 0,
          :description => _('Wrong product id'),
          :picture => '',
          :quantity => quantity
        }
      end
    end
  end

end
