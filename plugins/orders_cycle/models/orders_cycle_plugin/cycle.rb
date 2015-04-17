class OrdersCyclePlugin::Cycle < ActiveRecord::Base

  attr_accessible :profile, :status, :name, :description, :opening_message

  attr_accessible :start, :finish, :delivery_start, :delivery_finish
  attr_accessible :start_date, :start_time, :finish_date, :finish_time, :delivery_start_date, :delivery_start_time, :delivery_finish_date, :delivery_finish_time,

  Statuses = %w[edition orders purchases receipts separation delivery closing]
  DbStatuses = %w[new] + Statuses
  UserStatuses = Statuses

  StatusActorMap = ActiveSupport::OrderedHash[
    'edition', :supplier,
    'orders', :supplier,
    'purchases', :consumer,
    'receipts', :consumer,
    'separation', :supplier,
    'delivery', :supplier,
    'closing', :supplier,
  ]
  OrderStatusMap = ActiveSupport::OrderedHash[
    'orders', :ordered,
    'purchases', :draft,
    'receipts', :ordered,
    'separation', :accepted,
    'delivery', :separated,
  ]

  belongs_to :profile

  has_many :delivery_options, class_name: 'DeliveryPlugin::Option', dependent: :destroy,
    as: :owner, conditions: ["delivery_plugin_options.owner_type = 'OrdersCyclePlugin::Cycle'"]
  has_many :delivery_methods, through: :delivery_options, source: :delivery_method

  has_many :cycle_orders, class_name: 'OrdersCyclePlugin::CycleOrder', foreign_key: :cycle_id, dependent: :destroy, order: 'id ASC'

  # cannot use :order because of months/years named_scope
  has_many :sales, through: :cycle_orders, source: :sale
  has_many :purchases, through: :cycle_orders, source: :purchase

  has_many :cycle_products, foreign_key: :cycle_id, class_name: 'OrdersCyclePlugin::CycleProduct', dependent: :destroy
  has_many :products, through: :cycle_products, order: 'products.name ASC',
    include: [{from_products: [:from_products, {sources_from_products: [{supplier: [{profile: [:domains]}]}]}]}, {profile: [:domains]}]

  has_many :consumers, through: :sales, source: :consumer, order: 'name ASC'
  has_many :suppliers, through: :products, order: 'suppliers_plugin_suppliers.name ASC', uniq: true
  has_many :orders_suppliers, through: :sales, source: :profile, order: 'name ASC'

  has_many :from_products, through: :products, order: 'name ASC', uniq: true
  has_many :product_categories, through: :products, order: 'name ASC', uniq: true

  has_many :orders_confirmed, through: :cycle_orders, source: :sale, order: 'id ASC',
    conditions: ['orders_plugin_orders.ordered_at IS NOT NULL']

  has_many :items_selled, through: :sales, source: :items
  has_many :items_purchased, through: :purchases, source: :items
  # DEPRECATED
  has_many :items, through: :orders_confirmed

  has_many :ordered_suppliers, through: :orders_confirmed, source: :suppliers

  has_many :ordered_offered_products, through: :orders_confirmed, source: :offered_products, uniq: true, include: [:suppliers]
  has_many :ordered_distributed_products, through: :orders_confirmed, source: :distributed_products, uniq: true, include: [:suppliers]
  has_many :ordered_supplier_products, through: :orders_confirmed, source: :supplier_products, uniq: true, include: [:suppliers]

  has_many :volunteers_periods, class_name: 'VolunteersPlugin::Period', as: :owner
  has_many :volunteers, through: :volunteers_periods, source: :profile
  attr_accessible :volunteers_periods_attributes
  accepts_nested_attributes_for :volunteers_periods, allow_destroy: true

  scope :has_volunteers_periods, -> {uniq.joins [:volunteers_periods]}

  extend CodeNumbering::ClassMethods
  code_numbering :code, scope: Proc.new { self.profile.orders_cycles }

  # status scopes
  scope :defuncts, conditions: ["status = 'new' AND created_at < ?", 2.days.ago]
  scope :not_new, conditions: ["status <> 'new'"]
  scope :on_orders, lambda {
    {conditions: ["status = 'orders' AND ( (start <= :now AND finish IS NULL) OR (start <= :now AND finish >= :now) )",
      {now: DateTime.now}]}
  }
  scope :not_on_orders, lambda {
    {conditions: ["NOT (status = 'orders' AND ( (start <= :now AND finish IS NULL) OR (start <= :now AND finish >= :now) ) )",
      {now: DateTime.now}]}
  }
  scope :opened, conditions: ["status <> 'new' AND status <> 'closing'"]
  scope :closing, conditions: ["status = 'closing'"]
  scope :by_status, lambda { |status| { conditions: {status: status} } }

  scope :months, select: 'DISTINCT(EXTRACT(months FROM start)) as month', order: 'month DESC'
  scope :years, select: 'DISTINCT(EXTRACT(YEAR FROM start)) as year', order: 'year DESC'

  scope :by_month, lambda { |month| {
    conditions: [ 'EXTRACT(month FROM start) <= :month AND EXTRACT(month FROM finish) >= :month', { month: month } ]}
  }
  scope :by_year, lambda { |year| {
    conditions: [ 'EXTRACT(year FROM start) <= :year AND EXTRACT(year FROM finish) >= :year', { year: year } ]}
  }
  scope :by_range, lambda { |range| {
    conditions: [ 'start BETWEEN :start AND :finish OR finish BETWEEN :start AND :finish',
      { start: range.first, finish: range.last }
    ]}
  }

  validates_presence_of :profile
  validates_presence_of :name, if: :not_new?
  validates_presence_of :start, if: :not_new?
  # FIXME: The user frequenqly forget about this, and this will crash the app in some places, so don't enable this
  #validates_presence_of :delivery_options, unless: :new_or_edition?
  validates_inclusion_of :status, in: DbStatuses, if: :not_new?
  validates_numericality_of :margin_percentage, allow_nil: true, if: :not_new?
  validate :validate_orders_dates, if: :not_new?
  validate :validate_delivery_dates, if: :not_new?

  before_validation :step_new
  before_validation :check_status
  before_save :add_products_on_edition_state
  after_create :delay_purge_profile_defuncts

  extend SplitDatetime::SplitMethods
  split_datetime :start
  split_datetime :finish
  split_datetime :delivery_start
  split_datetime :delivery_finish

  serialize :data, Hash

  def name_with_code
    I18n.t('orders_cycle_plugin.models.cycle.code_name') % {
      code: code, name: name
    }
  end
  def total_price_consumer_ordered
    self.items.sum :price_consumer_ordered
  end

  def status
    self['status'] = 'closing' if self['status'] == 'closed'
    self['status']
  end

  def step
    self.status = DbStatuses[DbStatuses.index(self.status)+1]
  end
  def step_back
    self.status = DbStatuses[DbStatuses.index(self.status)-1]
  end

  def passed_by? status
    DbStatuses.index(self.status) > DbStatuses.index(status) rescue false
  end

  def new?
    self.status == 'new'
  end
  def not_new?
    self.status != 'new'
  end
  def open?
    !self.closing?
  end
  def closing?
    self.status == 'closing'
  end
  def edition?
    self.status == 'edition'
  end
  def new_or_edition?
    self.status == 'new' or self.status == 'edition'
  end
  def orders?
    now = DateTime.now
    status == 'orders' && ( (self.start <= now && self.finish.nil?) || (self.start <= now && self.finish >= now) )
  end
  def delivery?
    now = DateTime.now
    status == 'delivery' && ( (self.delivery_start <= now && self.delivery_finish.nil?) || (self.delivery_start <= now && self.delivery_finish >= now) )
  end

  def products_for_order
    # FIXME name alias conflict
    #self.products.unarchived.with_price.order('products.name ASC')
    self.products.unarchived.with_price
  end

  def supplier_products_by_suppliers orders = self.sales.ordered
    OrdersCyclePlugin::Order.supplier_products_by_suppliers orders
  end

  def generate_purchases
    return self.purchases if self.purchases.present?

    self.ordered_offered_products.unarchived.group_by{ |p| p.supplier }.map do |supplier, products|
      next unless supplier_product = product.supplier_product

      # can't be created using self.purchases.create!, as if :cycle is set (needed for code numbering), then double CycleOrder will be created
      purchase = OrdersCyclePlugin::Purchase.create! cycle: self, consumer: self.profile, profile: supplier.profile
      products.each do |product|
        purchase.items.create! order: purchase, product: supplier_product,
          quantity_consumer_ordered: product.total_quantity_consumer_ordered, price_consumer_ordered: product.total_price_consumer_ordered
      end
    end

    self.purchases true
  end

  def add_distributed_products
    return if self.products.count > 0
    ActiveRecord::Base.transaction do
      self.profile.distributed_products.unarchived.available.find_each(batch_size: 20) do |product|
        OrdersCyclePlugin::OfferedProduct.create_from_distributed self, product
      end
    end
  end

  def can_order? user
    profile.members.include? user
  end

  def add_products_job
    @add_products_job ||= Delayed::Job.find_by_id self.data[:add_products_job_id]
  end

  protected

  def add_products_on_edition_state
    return unless self.status_was == 'new'
    job = self.delay.add_distributed_products
    self.data[:add_products_job_id] = job.id
  end

  def step_new
    return if new_record?
    self.step if self.new?
  end

  def check_status
    # done at #step_new
    return if self.new?

    # step orders to next_status on status change
    return if self.status_was.blank?
    return unless order_status = OrderStatusMap[self.status_was]
    actor_name = StatusActorMap[self.status_was]
    orders_method = if actor_name == :supplier then :sales else :purchases end
    orders = self.send(orders_method).where(status: order_status.to_s)
    orders.each{ |order| order.step! actor_name }
  end

  def validate_orders_dates
    return if self.new? or self.finish.nil?
    errors.add :base, (I18n.t('orders_cycle_plugin.models.cycle.invalid_orders_period')) unless self.start < self.finish
  end

  def validate_delivery_dates
    return if self.new? or delivery_start.nil? or delivery_finish.nil?
    errors.add :base, I18n.t('orders_cycle_plugin.models.cycle.invalid_delivery_peri') unless delivery_start < delivery_finish
    errors.add :base, I18n.t('orders_cycle_plugin.models.cycle.delivery_period_befor') unless finish <= delivery_start
  end

  def purge_profile_defuncts
    self.class.where(profile_id: self.profile_id).defuncts.destroy_all
  end

  def delay_purge_profile_defuncts
    self.delay.purge_profile_defuncts
  end

end
