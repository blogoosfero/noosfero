class CreateIndexesForSearch < ActiveRecord::Migration

  Searchables = %w[ article comment qualifier national_region certifier profile license scrap category ]
  Klasses = Searchables.map {|searchable| searchable.camelize.constantize }

  def self.up
    Klasses.each do |klass|
      fields = klass.pg_search_plugin_fields
      execute "create index pg_search_plugin_#{klass.name.singularize.downcase} on #{klass.table_name} using gin(to_tsvector('simple', #{fields}))"
    end
  end

  def self.down
    Klasses.each do |klass|
      execute "drop index pg_search_plugin_#{klass.name.singularize.downcase}"
    end
  end
end
