require_dependency 'certifier'

class Certifier

  after_save_reindex [:products], with: :delayed_job

  acts_as_searchable fields: SEARCHABLE_FIELDS.map{ |field, options|
    {field => {boost: options[:weight]}}
  }

end

