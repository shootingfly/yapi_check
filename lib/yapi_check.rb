require 'method_source'
require 'http'

require_relative 'yapi_check/executor'
require_relative 'yapi_check/config'
require_relative 'yapi_check/version'
require_relative 'yapi_check/yapi_params'

module YapiCheck
  class Error < StandardError
  end
end
