class AddAdmissionToForm < ActiveRecord::Migration
  def self.up
    change_table :custom_forms_plugin_forms do |t|
      t.boolean :for_admission, :default => false
    end

    CustomFormsPlugin::Form.find_each do |f|
      f.for_admission = false
      f.send :update_without_callbacks
    end
  end

  def self.down
    change_table :custom_forms_plugin_forms do |t|
      t.remove :for_admission
    end
  end
end
