module Camlistore
  Configuration.namespace :camlistore
  Configuration.keys :host
  Configuration.env ENV

  class Client
    attr_reader :config, :blobroot, :searchroot
    include API

    def initialize options = {}
      @config = Configuration.new(options, host: 'http://localhost:3179/')
      raise ArgumentError, "You must supply blobstore host." unless config.host.present?
      remote_configuration = JSON.parse(Faraday.get(@config.host, {}, :accept => 'text/x-camli-configuration').body)
      @blobroot = remote_configuration['blobRoot']
      @searchroot = remote_configuration['searchRoot']
    end

    api_method :enumerate_blobs, 'bs/camli/enumerate-blobs'

    def each_blob &block
      data = enumerate_blobs
      blobs = data.blobs

      while blobs.any?
        blobs.each &block

        blobs = if data.continueAfter.present?
          data = enumerate_blobs(after: data.continueAfter)
          data.blobs
        else
          []
        end
      end
    end

    def get sha
      api_call('bs/camli/' + sha)
    end
  end

end
