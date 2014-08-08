namespace :noosfero do
  namespace :translations do

    desc 'Update all translation files'
    task :update => ['updatepo', 'noosfero:doc:rebuild']

    desc 'Compiles all translations'
    task :compile => ['makemo', 'environment', 'noosfero:doc:translate']

  end
end
