require 'friendly/attribute'
require 'friendly/config'
require 'friendly/data_store'
require 'friendly/document'
require 'friendly/document_table'
require 'friendly/index'
require 'friendly/persister'
require 'friendly/finder'
require 'friendly/repository'
require 'friendly/storage_proxy'
require 'friendly/translator'

module Friendly
  class << self
    attr_accessor :datastore

    def configure
    end

    def config
      @config ||= Config.new
    end
  end

  class Error < RuntimeError; end
  class RecordNotFound < Error; end
  class MissingIndex < Error; end
end
