# encoding: utf-8

require 'mongo_mapper'
require 'carrierwave'
require 'carrierwave/validations/active_model'

module CarrierWave
  module MongoMapper
    include CarrierWave::Mount
    ##
    # See +CarrierWave::Mount#mount_uploader+ for documentation
    #
    def mount_uploader(column, uploader, options={}, &block)
      options[:mount_on] ||= "#{column}_filename"
      key options[:mount_on]

      super

      alias_method :read_uploader, :read_attribute
      alias_method :write_uploader, :write_attribute

      include CarrierWave::Validations::ActiveModel

      validates_integrity_of  column if uploader_option(column.to_sym, :validate_integrity)
      validates_processing_of column if uploader_option(column.to_sym, :validate_processing)

      after_save "store_#{column}!".to_sym
      before_save "write_#{column}_identifier".to_sym
      after_destroy "remove_#{column}!".to_sym
    end
  end
end

MongoMapper::Plugins::Rails::ClassMethods.send(:include, CarrierWave::MongoMapper)

CarrierWave::Storage.autoload :GridFS, 'carrierwave/storage/grid_fs'

class CarrierWave::Uploader::Base
  add_config :grid_fs_connection
  add_config :grid_fs_database
  add_config :grid_fs_host
  add_config :grid_fs_port
  add_config :grid_fs_username
  add_config :grid_fs_password
  add_config :grid_fs_access_url

  configure do |config|
    config.storage_engines[:grid_fs] = "CarrierWave::Storage::GridFS"
    config.grid_fs_database = "carrierwave"
    config.grid_fs_host = "localhost"
    config.grid_fs_port = 27017
  end
end
