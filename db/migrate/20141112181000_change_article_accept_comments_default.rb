class ChangeArticleAcceptCommentsDefault < ActiveRecord::Migration
  def self.up
    change_column :articles, :accept_comments, :boolean, :default => false
  end

  def self.down
    change_column :articles, :accept_comments, :boolean, :default => true
  end
end
