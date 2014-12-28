require_dependency 'product'

# FIXME: The lines bellow should be on the core
class Product

  extend CurrencyHelper::ClassMethods
  has_currency :price
  has_currency :discount

  scope :available, conditions: {available: true}
  scope :unavailable, conditions: ['products.available <> true']
  scope :archived, conditions: {archived: true}
  scope :unarchived, conditions: ['products.archived <> true']

  scope :with_available, lambda { |available| where available: available }
  scope :with_price, conditions: 'products.price > 0'
  scope :with_product_category_id, lambda { |id| { conditions: {product_category_id: id} } }

  # FIXME: transliterate input and name column
  scope :name_like, lambda { |name| { conditions: ["LOWER(products.name) LIKE ?", "%#{name}%"] } }

  scope :by_profile, lambda { |profile| { conditions: {profile_id: profile.id} } }
  scope :by_profile_id, lambda { |profile_id| { conditions: {profile_id: profile_id} } }

  def self.product_categories_of products
    ProductCategory.find products.collect(&:product_category_id).compact.select{ |id| not id.zero? }
  end

end

class Product

  attr_accessible :from_products, :supplier_id, :supplier

  has_many :sources_from_products, foreign_key: :to_product_id, class_name: 'SuppliersPlugin::SourceProduct', dependent: :destroy
  has_many :sources_to_products, foreign_key: :from_product_id, class_name: 'SuppliersPlugin::SourceProduct', dependent: :destroy
  has_many :to_products, through: :sources_to_products, order: 'id ASC'
  has_many :from_products, through: :sources_from_products, order: 'id ASC'
  def from_product
    self.from_products.first
  end

  has_many :sources_from_2x_products, through: :sources_from_products, source: :sources_from_products
  has_many :sources_to_2x_products, through: :sources_to_product, source: :sources_to_products
  has_many :from_2x_products, through: :sources_from_2x_products, source: :from_product
  has_many :to_2x_products, through: :sources_to_2x_products, source: :to_product

  has_many :suppliers, through: :sources_from_products, uniq: true, order: 'id ASC'
  has_many :consumers, through: :to_products, source: :profile, uniq: true, order: 'id ASC'

  # prefer distributed_products has_many to use DistributedProduct scopes and eager loading
  scope :distributed, conditions: ["products.type = 'SuppliersPlugin::DistributedProduct'"]
  scope :own, conditions: ["products.type = 'Product'"]

  scope :from_supplier, lambda { |supplier| { conditions: ['suppliers_plugin_suppliers.id = ?', supplier.id] } }
  scope :from_supplier_id, lambda { |supplier_id| { conditions: ['suppliers_plugin_suppliers.id = ?', supplier_id] } }

  after_create :distribute_to_consumers
  after_destroy :destroy_dependent

  def own?
    self.class == Product
  end
  def distributed?
    self.class == SuppliersPlugin::DistributedProduct
  end

  # Redefine these two methods on
  def sources_supplier_products
    self.sources_from_products
  end
  def supplier_products
    self.from_products
  end

  def sources_supplier_product
    self.sources_supplier_products.first
  end
  def supplier_product
    self.supplier_products.first
  end

  def supplier
    # FIXME: use self.suppliers when rails support for nested preload comes
    @supplier ||= self.sources_supplier_product.supplier rescue nil
    @supplier ||= self.profile.self_supplier rescue nil
  end
  def supplier= value
    @supplier = value
  end
  def supplier_id
    self.supplier.id
  end
  def supplier_id= id
    @supplier = profile.environment.profiles.find id
  end

  def supplier_dummy?
    self.supplier ? self.supplier.dummy? : self.profile.dummy?
  end

  def distribute_to_consumer consumer
    SuppliersPlugin::DistributedProduct.create! profile: consumer, from_products: [self]
  end

  protected

  def distribute_to_consumers
    # shopping_cart creates products without a profile...
    return unless self.profile

    self.profile.consumers.except_people.except_self.each do |consumer|
      self.distribute_to_consumer consumer.profile
    end
  end

  # to_products doesn't work when triggered from supplier.destroy. delay workaround that
  def destroy_dependent
    self.to_products.each do |to_product|
      to_product.destroy if to_product.dependent?
    end
  end
  handle_asynchronously :destroy_dependent

end
