class CreateDistributionOrderSessions < ActiveRecord::Migration
  def self.up
    create_table  :distribution_order_sessions do |t|
      t.integer   :node_id
      t.string    :name
      t.text      :description 
      t.datetime  :start
      t.datetime  :finish
      t.datetime  :delivery_start
      t.datetime  :delivery_finish
      t.decimal   :margin_percentage
      t.decimal   :margin_fixed

      t.timestamps
    end
  end

  def self.down
    drop_table :distribution_order_sessions
  end
end
