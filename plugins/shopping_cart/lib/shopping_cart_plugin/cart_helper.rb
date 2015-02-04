require 'pp'

module ShoppingCartPlugin::CartHelper

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TagHelper

  PaymentMethods = {
    money: proc{ _("Money") },
    check: proc{ s_('shopping_cart|Check') },
    credit_card: proc{ _('Credit card') },
    bank_transfer: proc{ _('Bank transfer') },
  }

  def add_to_cart_button item, options = {}
  	label = if options[:with_text].nil? or options[:with_text] then _('Add to basket') else '' end
  	button_to_function 'cart', label, "Cart.addItem(#{item.id}, this)", class: 'cart-add-item', type: 'primary'
  end

  def cart_applet
    button_to_function 'cart', '&nbsp;<span class="cart-qtty"></span>', "cart.toggle()", class: 'cart-applet-indicator', type: 'primary'
  end

  def cart_minimized
    @catalog_bar
  end

  def repeat_checkout_order_button order
    button_to_function 'check', t('views.public.repeat.checkout'), 'cart.repeatCheckout(event, this)', 'data-order-id' => order.id, :class => 'repeat-checkout-order'
  end

  def repeat_choose_order_button order
    button_to_function 'edit', t('views.public.repeat.choose'), 'cart.repeatChoose(event, this)', 'data-order-id' => order.id, :class => 'repeat-choose-order'
  end

  def sell_price(product)
    return 0 if product.price.nil?
    product.discount ? product.price_with_discount : product.price
  end

  def get_price product, environment, quantity=1, options = {}
    float_to_currency_cart price_with_quantity(product,quantity), environment, options
  end

  def price_with_quantity(product, quantity=1)
    quantity = 1 if !quantity.kind_of?(Numeric)
    sell_price(product)*quantity
  end

  def get_total(items)
    items.map { |id, quantity| price_with_quantity(Product.find(id),quantity)}.sum
  end

  def get_total_on_currency(items, environment)
    float_to_currency_cart(get_total(items), environment)
  end

  def build_order items, delivery_method = nil
    @order = profile.sales.build
    items.each do |product_id, quantity|
      @order.items.build product_id: product_id, quantity_consumer_ordered: quantity
    end
    @order.supplier_delivery = delivery_method
    @order
  end

  def items_table(items, profile, delivery_method = nil, by_mail = false)
    # partial key needed in mailer context
    render partial: 'shopping_cart_plugin/items', locals: {order: build_order(items, delivery_method), by_mail: by_mail}
  end

  def float_to_currency_cart value, environment, _options = {}
    options = {:unit => environment.currency_unit, :separator => environment.currency_separator, :delimiter => environment.currency_delimiter, :precision => 2, :format => "%u%n"}
    options.merge! _options
    number_to_currency value, options
  end

  def supplier_delivery_options selected=nil
    options = profile.delivery_methods.map do |method|
      [method.id, method.name, float_to_currency_cart(method.fixed_cost, environment), method == selected]
    end
    options << [nil, _('Delivery'), float_to_currency_cart(0, environment), true] if options.empty?

    options.map do |id, name, cost, selected|
      content_tag :option, "#{name} (#{cost})", value: id, data: {label: name}, selected: if selected then 'selected' else nil end
    end.join
  end

  def options_for_payment
    options_for_select PaymentMethods.map{ |key, text| [text.call, key] }
  end

end
