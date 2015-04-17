module CurrencyHelper

  extend ActionView::Helpers::NumberHelper

  def self.parse_localized_number number
    return 0 if number.blank?
    number = number.to_s
    number.gsub(I18n.t("number.currency.format.unit"), '')
      .gsub(I18n.t("number.currency.format.delimiter"), '')
      .gsub(I18n.t("number.currency.format.separator"), '.')
      .to_f
  end

  def self.parse_currency currency
    self.parse_localized_number currency
  end

  def self.localized_number number
    number_with_delimiter number.to_f
  end

  def self.number_as_currency_number number
    string = number_to_currency number, unit: ''
    string.gsub! ' ', '' if string
    string
  end

  def self.number_as_currency number
    number_to_currency number
  end

  module ClassMethods

    def has_number_with_locale attr
      # Rails doesn't define getters and setters for attributes
      define_method attr do
        self[attr]
      end if attr.to_s.in? self.column_names and not method_defined? attr
      define_method "#{attr}=" do |value|
        self[attr] = value
      end if attr.to_s.in? self.column_names and not method_defined? "#{attr}="

      if method_defined? "#{attr}="
        define_method "#{attr}_with_locale=" do |value|
          value = CurrencyHelper.parse_localized_number value if value.is_a? String
          self.send "#{attr}_without_locale=", value
        end
        alias_method_chain "#{attr}=", :locale
      end

      define_method "#{attr}_localized" do |*args, &block|
        number = self.send attr, *args, &block
        CurrencyHelper.localized_number number
      end
    end

    def has_currency attr
      self.has_number_with_locale attr

      define_method "#{attr}_as_currency" do |*args, &block|
        number = self.send attr, *args, &block
        CurrencyHelper.number_as_currency number
      end
      define_method "#{attr}_as_currency_number" do |*args, &block|
        number = self.send attr, *args, &block
        CurrencyHelper.number_as_currency_number number
      end
    end

  end

  module InstanceMethods

  end

end
