require "carrierwave-aliyun"
require "base64"

module Backup
  module Storage
    class Aliyun < Base
      attr_accessor :bucket,:access_key_id,:access_key_secret,:aliyun_internal, :area, :path

      def initialize(model, storage_id = nil, &block)
        super(model, storage_id)

        @path ||= 'backups'

        instance_eval(&block) if block_given?
      end

      private

      def connection
        return @connection if @connection

        CarrierWave.configure do |config|
          config.storage = :aliyun
          config.aliyun_access_id = self.access_key_id
          config.aliyun_access_key = self.access_key_secret
          config.aliyun_bucket = self.bucket
          config.aliyun_area = self.area || "cn-hangzhou"
          config.aliyun_internal = self.aliyun_internal || false
        end

        @uploader = CarrierWave::Uploader::Base.new
        @connection = CarrierWave::Storage::Aliyun::Connection.new(@uploader)
      end

      def transfer!
        remote_path = remote_path_for(@package)

        @package.filenames.each do |filename|
          src = File.join(Config.tmp_path, filename)
          dest = File.join(remote_path, filename)
          Logger.info "#{storage_name} uploading '#{ dest }'..."
          connection.put(dest, File.open(src))
        end
      end

      def remove!(package)
        remote_path = remote_path_for(package)
        Logger.info "#{storage_name} removing '#{remote_path}'..."
        connection.delete(remote_path)
      end
    end
  end
end
