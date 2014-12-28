$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

ENV['RAILS_ENV'] = 'test'

require 'rails/all'
require 'test/unit'
require 'pothoven-attachment_fu'
include ActionDispatch::TestProcess

# Define the application and configuration
module RbConfig
  class Application < ::Rails::Application
    # configuration here if needed
    config.active_support.deprecation = :stderr
  end
end

# Initialize the application
RbConfig::Application.initialize!

# Setup database
load(File.dirname(__FILE__) + "/schema.rb")

FIXTURE_PATH = File.dirname(__FILE__) + "/fixtures"
$LOAD_PATH.unshift(FIXTURE_PATH)

class Test::Unit::TestCase #:nodoc:
  #  include ActionDispatch::TestProcess
  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(FIXTURE_PATH, table_names) { yield }
    else
      Fixtures.create_fixtures(FIXTURE_PATH, table_names)
    end
  end

  def setup
    Attachment.saves = 0
    DbFile.transaction { [Attachment, FileAttachment, OrphanAttachment, MinimalAttachment, DbFile].each { |klass| klass.delete_all } }
    attachment_model self.class.attachment_model
  end

  def teardown
    FileUtils.rm_rf File.join(File.dirname(__FILE__), 'files')
    # Files generated by random_tempfile_filename
    FileUtils.rm_rf Dir['[0-9]*.{png,jpg}']
  end

  #self.use_transactional_fixtures = true
  #self.use_instantiated_fixtures  = false

  def self.attachment_model(klass = nil)
    @attachment_model = klass if klass
    @attachment_model
  end

  def self.test_against_class(test_method, klass, subclass = false)
    define_method("#{test_method}_on_#{:sub if subclass}class") do
      klass = Class.new(klass) if subclass
      attachment_model klass
      send test_method, klass
    end
  end

  def self.test_against_subclass(test_method, klass)
    test_against_class test_method, klass, true
  end

  protected
    def upload_file(options = {})
      use_temp_file options[:filename] do |file|
puts options
        opts = { :uploaded_data => fixture_file_upload(file, options[:content_type] || 'image/png') }
        opts.update(options.reject { |k, v| ![:imageable_type, :imageable_id].include?(k) })
        att = attachment_model.create opts
        att.reload unless att.new_record?
        return att
      end
    end

    def upload_merb_file(options = {})
      use_temp_file options[:filename] do |file|
        att = attachment_model.create :uploaded_data => {"size" => file.size, "content_type" => options[:content_type] || 'image/png', "filename" => file, 'tempfile' => fixture_file_upload(file, options[:content_type] || 'image/png')}
        att.reload unless att.new_record?
        return att
      end
    end

    def use_temp_file(fixture_filename)
      temp_path = File.join('/tmp', File.basename(fixture_filename))
      temp_dir = File.join(FIXTURE_PATH, 'tmp')
      use_file = File.join(FIXTURE_PATH, temp_path)
      FileUtils.mkdir_p temp_dir
      FileUtils.cp File.join(FIXTURE_PATH, fixture_filename), use_file
      yield use_file
    ensure
      FileUtils.rm_rf temp_dir
    end

    def assert_created(num = 1)
      assert_difference attachment_model.base_class, :count, num do
        if attachment_model.included_modules.include? DbFile
          assert_difference DbFile, :count, num do
            yield
          end
        else
          yield
        end
      end
    end

    def assert_valid(record)
      assert record.valid?, record.errors.full_messages.join("\n")
    end

    def assert_file_jpeg_quality(model, thumbnail, expected)
      filename = if model.respond_to?(:full_filename)
        model.full_filename(thumbnail)
      else
        thumb = thumbnail ? model.thumbnails.find(:first, :conditions => { :thumbnail => thumbnail.to_s }, :include => :db_file) : model
        unless thumb && thumb.db_file && thumb.db_file.data && thumb.db_file.data.size > 0
          STDERR.puts "Cannot find DB file data for thumbnail #{thumbnail.inspect} -> Aborting JPEG quality check."
          return
        end
        result = Tempfile.new('dbfile_dump').path
        File.open(result, 'wb') { |f| f.write(thumb.db_file.data) }
        result
      end
      quality = %x(identify -format '%Q' "#{filename}" 2> /dev/null)
      if $?.success?
        assert_equal expected, quality.to_i, "Produced JPEG quality (thumbnail: #{thumbnail.inspect}) is incorrect."
      else
        STDERR.puts "ImageMagick's identify not found / not in PATH: can't quickly check produced image quality."
      end
    end

    def assert_not_created
      assert_created(0) { yield }
    end

    def should_reject_by_size_with(klass)
      attachment_model klass
      assert_not_created do
        attachment = upload_file :filename => '/files/rails.png'
        assert attachment.new_record?
        assert attachment.errors.on(:size)
        assert_nil attachment.db_file if attachment.respond_to?(:db_file)
      end
    end

    def assert_difference(object, method = nil, difference = 1)
      initial_value = object.send(method)
      yield
      assert_equal initial_value + difference, object.send(method)
    end

    def assert_no_difference(object, method, &block)
      assert_difference object, method, 0, &block
    end

    def attachment_model(klass = nil)
      @attachment_model = klass if klass
      @attachment_model
    end
end

require File.join(File.dirname(__FILE__), 'fixtures/attachment')
require File.join(File.dirname(__FILE__), 'base_attachment_tests')
