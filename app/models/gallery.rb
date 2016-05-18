class Gallery < Folder

  has_many :images, -> { where(is_image: true).order('updated_at DESC') },
    class_name: 'Article', foreign_key: :parent_id

  def self.type_name
    _('Gallery')
  end

  def self.short_description
    _('Gallery')
  end

  def self.description
    _('A gallery, inside which you can put images.')
  end

  include ActionView::Helpers::TagHelper
  def to_html(options={})
    article = self
    proc do
      render file: 'content_viewer/image_gallery', locals: {article: article}
    end
  end

  def gallery?
    true
  end

  def self.icon_name(article = nil)
    'gallery'
  end

end
