class CustomFormsPlugin::SelectField < CustomFormsPlugin::Field
  set_table_name :custom_forms_plugin_fields

  validates_inclusion_of :show_as, :in => %w(radio check_box select multiple_select)
  validates_length_of :alternatives, :minimum => 1, :message => 'can\'t be empty'

  def show_as
    self['show_as'] || 'radio'
  end
end
