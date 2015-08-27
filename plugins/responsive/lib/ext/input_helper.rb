module InputHelper

  protected

  def input_group_addon addon, options = {}, &block
    content_tag :div, class: 'input-group' do
      content_tag(:span, addon, class: 'input-group-addon') + capture(&block)
    end
  end

end

module ApplicationHelper

  include InputHelper

end

