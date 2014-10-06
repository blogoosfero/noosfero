require 'nokogiri'

module WhiteListFilter

  def check_iframe_on_content(content, trusted_sites)
    if content.blank? || !content.include?('iframe')
      return content
    end
    doc = Nokogiri::HTML::DocumentFragment.parse content
    doc.css('iframe').each do |iframe|
      src = URI.parse iframe.attr('src') rescue nil
      iframe.remove unless src and trusted_sites.include? src.host
    end
    doc.to_html
  end

  module ClassMethods
    def filter_iframes(*opts)
      options = opts.pop
      white_list_method = options[:whitelist]
      opts.each do |field|
        before_validation do |obj|
          content = obj.send field
          content = obj.check_iframe_on_content content, obj.instance_eval(&white_list_method)
          obj[field.to_s] = content
        end
      end
    end
  end

  def self.included(c)
    c.send(:extend, WhiteListFilter::ClassMethods)
  end
end
