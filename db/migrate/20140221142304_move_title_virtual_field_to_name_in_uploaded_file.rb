class MoveTitleVirtualFieldToNameInUploadedFile < ActiveRecord::Migration
  def self.up
    i = Iconv.new 'UTF-8//IGNORE', 'UTF-8'
    UploadedFile.find_each do |uploaded_file|
      uploaded_file.name = i.iconv uploaded_file.setting.delete(:title)
      uploaded_file.send :update_without_callbacks
    end
  end

  def self.down
    say "this migration can't be reverted"
  end
end
