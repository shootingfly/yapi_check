module YapiCheck
  class Config
    # YAPI项目令牌
    def self.yapi_project_token
      ENV.fetch('YAPI_PROJECT_TOKEN', nil)
    end

    # YAPI项目开放API访问域名
    def self.yapi_project_domain
      ENV.fetch('YAPI_PROJECT_DOMAIN', nil)
    end

    # 接口统一前缀, 默认为/api/v1
    def self.yapi_api_prefix
      ENV.fetch('YAPI_API_PREFIX', '/api/v1')
    end
  end
end
