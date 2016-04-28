module SolrPlugin

  module ActsAsFaceted

    module ClassMethods
    end

    module ActsMethods
      # Example:
      #
      #acts_as_faceted fields: {
      #  f_type: {label: c_('Type'), proc: proc{|klass| f_type_proc(klass)}},
      #  f_published_at: {type: :date, label: _('Published date'), queries: {'[* TO NOW-1YEARS/DAY]' => _("Older than one year"),
      #    '[NOW-1YEARS TO NOW/DAY]' => _("Last year"), '[NOW-1MONTHS TO NOW/DAY]' => _("Last month"), '[NOW-7DAYS TO NOW/DAY]' => _("Last week"), '[NOW-1DAYS TO NOW/DAY]' => _("Last day")}},
      #  f_profile_type: {label: c_('Author'), proc: proc{|klass| f_profile_type_proc(klass)}},
      #  f_category: {label: c_('Categories')}},
      #  order: [:f_type, :f_published_at, :f_profile_type, :f_category]
      #
      #acts_as_searchable additional_fields: [ {name: {type: :string, as: :name_sort, boost: 5.0}} ],
      #  exclude_fields: [:setting],
      #  include: [:profile],
      #  facets: solr_facets_options,
      #  if: proc{|a| ! ['RssFeed'].include?(a.class.name)}
      def acts_as_faceted options
        extend ClassMethods
        extend ActsAsSolr::CommonMethods

        cattr_accessor :solr_facets
        cattr_accessor :solr_facets_order
        cattr_accessor :solr_facets_results_containers
        cattr_accessor :solr_facets_fields
        cattr_accessor :solr_facets_fields_names
        cattr_accessor :solr_facets_options
        cattr_accessor :solr_facet_category_query
        cattr_accessor :to_solr_facets_fields_names

        self.solr_facets = options[:fields]
        self.solr_facets_order = options[:order] || self.solr_facets.keys
        self.solr_facets_results_containers = {fields: 'facet_fields', queries: 'facet_queries', ranges: 'facet_ranges'}
        self.solr_facets_options = Hash[self.solr_facets.select{ |id,data| ! data.has_key?(:queries) }].keys
        self.solr_facets_fields = self.solr_facets.map{ |id,data| {id => data[:type] || :facet} }
        self.solr_facets_fields_names = self.solr_facets.map{ |id,data| id.to_s + '_' + get_solr_field_type(data[:type] || :facet) }
        self.solr_facet_category_query = options[:category_query]

        # A hash to retrieve the field key for the solr facet string returned
        # field_name: "field_name_facet"
        self.to_solr_facets_fields_names = Hash[self.solr_facets.keys.zip(solr_facets_fields_names)]

        def facet_by_id(id)
          {id: id}.merge(self.solr_facets[id]) if self.solr_facets[id]
        end

        def map_facets_for context
          self.solr_facets_order.map do |id|
            facet = facet_by_id id
            next unless facet
            next if criteria = facet[:context_criteria] and !context.instance_exec(&criteria)
            next if type_if = facet[:type_if] and !type_if.call(self.new)

            if facet[:multi]
              facet[:label].call(context.send(:environment)).map do |label_id, label|
                facet.merge({id: facet[:id].to_s+'_'+label_id.to_s, solr_field: facet[:id], label_id: label_id, label: label})
              end
            else
              facet.merge(id: facet[:id].to_s, solr_field: facet[:id])
            end
          end.compact.flatten
        end

        def map_facet_results facet, facet_params, facets_data, unfiltered_facets_data = {}, options = {}
          raise 'Use map_facets_for before this method' if facet[:solr_field].nil?
          facets_data = {} if facets_data.blank? # could be empty array
          solr_facet = to_solr_facets_fields_names[facet[:solr_field]]
          unfiltered_facets_data ||= {}

          if facet[:queries]
            container = facets_data[self.solr_facets_results_containers[:queries]]
            facet_data = (container.nil? or container.empty?) ? [] : container.select{ |k,v| k.starts_with? solr_facet }
            container = unfiltered_facets_data[self.solr_facets_results_containers[:queries]]
            unfiltered_facet_data = (container.nil? or container.empty?) ? [] : container.select{ |k,v| k.starts_with? solr_facet }
          else
            container = facets_data[self.solr_facets_results_containers[:fields]]
            facet_data = (container.nil? or container.empty?) ? [] : container[solr_facet] || []
            container = unfiltered_facets_data[self.solr_facets_results_containers[:fields]]
            unfiltered_facet_data = (container.nil? or container.empty?) ? [] : container[solr_facet] || []
          end

          if unfiltered_facets_data.present? and facet_params.present?
            f = Hash[Array(facet_data)]
            zeros = []
            facet_data = unfiltered_facet_data.map do |id, count|
              count = f[id]
              if count.nil?
                zeros.push [id, 0]
                nil
              else
                [id, count]
              end
            end.compact + zeros
          end

          facet_count = facet_data.length

          if facet[:queries]
            result = facet_data.map do |id, count|
              q = id[id.index(':')+1, id.length]
              label = gettext(facet[:queries][q])
              [q, label, count] if count > 0
            end.compact
            result = facet[:queries_order].map{ |id| result.detect{ |rid, label, count| rid == id } }.compact if facet[:queries_order]
          elsif facet[:proc]
            if facet[:label_id]
              result = facet_result_proc(facet, facet_data)
              facet_count = result.length
              result = result.first(options[:limit]) if options[:limit]
            else
              facet_data = facet_data.first(options[:limit]) if options[:limit]
              result = facet_result_proc(facet, facet_data)
            end
          else
            facet_data = facet_data.first(options[:limit]) if options[:limit]
            result = facet_data.map{ |id, count| [id, id, count] }
          end

          sorted = facet_result_sort(facet, result, options[:sort])

          # length can't be used if limit option is given;
          # total_entries comes to help
          sorted.class.send(:define_method, :total_entries, proc { facet_count })

          sorted
        end

        def facet_result_sort(facet, facets_data, sort_by = nil)
          if facet[:queries_order]
            facets_data
          elsif sort_by == :alphabetically
            facets_data.sort{ |a,b| Array(a[1])[0] <=> Array(b[1])[0] }
          elsif sort_by == :count
            facets_data.sort{ |a,b| -1*(a[2] <=> b[2]) }
          else
            facets_data
          end
        end

        def facet_result_proc(facet, data)
          if facet[:multi]
            facet[:label_id] ||= 0
            facet[:proc].call(facet, data)
          else
            gettext(facet[:proc].call(facet, data))
          end
        end

        def facet_result_name(facet, data)
          if facet[:queries]
            gettext(facet[:queries][facet])
          elsif facet[:proc]
            facet_result_proc(facet, data).first[1]
          else
            data
          end
        end

        def facet_label(facet)
          return nil unless facet
          _(facet[:label])
        end

        def solr_facets_find_options facets_selected = {}, options = {}
          browses = []
          facets_selected ||= {}
          facets_selected.map do |id, value|
            next unless self.solr_facets[id.to_sym]
            if value.kind_of?(Hash)
              value.map do |label_id, value|
                value.to_a.each do |value|
                  browses << id.to_s + ':' + (self.solr_facets[id.to_sym][:queries] ? value : '"'+value.to_s+'"')
                end
              end
            else
              browses << id.to_s + ':' + (self.solr_facets[id.to_sym][:queries] ? value : '"'+value.to_s+'"')
            end
          end.flatten

          {
            facets: {
              zeros: false, sort: :count,
              fields: solr_facets_options,
              browse: browses,
              query: self.solr_facets.map { |f, options| options[:queries].keys.map { |q| f.to_s + ':' + q } if options[:queries] }.compact.flatten,
            }
          }
        end
      end
    end

  end

  ApplicationRecord.extend ActsAsFaceted::ActsMethods

end
