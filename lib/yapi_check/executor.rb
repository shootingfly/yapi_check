module YapiCheck
  class Executor
    # 当前支持检查的YAPI请求参数类型
    YAPI_PARAMS_CLASS = {
      'string' => :String,
      'number' => :Float,
      'integer' => :Integer
    }.freeze

    # 获取YAPI参数
    def self.get_yapi_params(detail)
      yapi_params = []
      form_params = Array(detail['req_body_form'])
      form_params.each do |form|
        s = YapiParams.new
        s.name = form['name']
        s.example = form['example']
        s.desc = form['desc']
        s.required = form['required'].to_i
        s.category = 'form'
        yapi_params << s
      end
      query_params = Array(detail['req_query'])
      query_params.each do |query|
        s = YapiParams.new
        s.name = query['name']
        s.example = query['example']
        s.desc = query['desc']
        s.required = query['required'].to_i
        s.category = 'query'
        yapi_params << s
      end
      exist_key_arr = []
      begin
        json_data = JSON.parse(detail['req_body_other'] || '{}')
      rescue JSON::ParserError => e
        puts "=== 解析json_data JSON出错#{e.backtrace}"
        return yapi_params
      end
      # 先遍历必填项
      json_params = json_data['required'] || {}
      json_params.each do |param_name|
        s = YapiParams.new
        s.name = param_name
        s.required = 1
        s.type = json_data['properties'][param_name]['type']
        s.category = 'json'
        exist_key_arr << param_name
        yapi_params << s
      end
      if json_data['properties'].present?
        json_data['properties'].each do |k, v|
          next if exist_key_arr.include?(k)

          s = YapiParams.new
          s.name = k
          s.type = v['type']
          s.category = 'json'
          s.required = 0
          yapi_params << s
        end
      end
      yapi_params
    end

    # 获取响应参数
    def self.get_response_params(detail)
      yapi_params = []
      begin
        json_params = JSON.parse(detail['res_body'] || '{}')['properties']['data']['properties'] || {}
      rescue JSON::ParserError => e
        puts "=== 解析json_params JSON出错#{e.backtrace}"
        return []
      end
      json_params.each do |k, v|
        s = YapiParams.new
        s.name = k
        s.type = v['type']
        s.category = 'json'
        yapi_params << s
        properties = nil
        case v['type']
        when 'object'
          properties = v['properties']
        when 'array'
          properties = v['items']['properties']
        end
        next unless properties.present?

        properties.each do |sk, sv|
          s = YapiParams.new
          s.name = sk
          s.type = sv['type']
          s.category = 'json'
          yapi_params << s
        end
      end
      yapi_params
    end

    # 获取Rails控制器和动作
    def self.get_controller_and_action(endpoint, method)
      request_controller_and_action = Rails.application.routes.recognize_path(endpoint, method: method)
      controller = "#{request_controller_and_action[:controller]}_controller".classify.constantize
      action = request_controller_and_action[:action].to_sym
      [controller, action]
    rescue ActionController::RoutingError
      []
    end

    # 检查请求参数是否正确(json支持检查类型, query和form不支持)
    def self.check_request_params(_method, yapi_params, action_source)
      errors = []
      yapi_params.each do |yapi_param|
        # 必填性验证
        required_check = yapi_param.required == 1 ? "required(:#{yapi_param.name}" : "optional(:#{yapi_param.name}"
        errors << "#{yapi_param.name}必填性错误，期待#{required_check}" unless action_source.include?(required_check)
        # 类型验证
        if yapi_param.category == 'json'
          type_errors = get_must_not_in_strings(yapi_param).select { |x| action_source.include?(x) }
          errors << "#{yapi_param.name}类型错误, 期待#{required_check}, #{YAPI_PARAMS_CLASS[yapi_param.type]}}" unless type_errors.empty?
        end
      end

      errors
    end

    # 反向匹配参数类型
    def self.get_must_not_in_strings(yapi_param)
      name = yapi_param.name
      case yapi_param.type
      when 'string' then ["#{name}, :Integer)", "#{name}, :Float)"]
      when 'number' then ["#{name}, :String)", "#{name}, :Integer)"]
      when 'integer' then ["#{name}, :String)", "#{name}, :Float)"]
      else
        []
      end
    end

    # 检查接口名称是否一致
    def self.check_request_title(action_title, yapi_title)
      errors = []
      errors << action_title unless action_title == yapi_title
      errors
    end

    # 核对响应
    def self.check_response(response_params, jbuilder_source)
      errors = []
      response_params.each do |response_param|
        errors << response_param.name unless jbuilder_source =~ get_response_param_type(response_param.name, response_param.type)
      end
      errors
    end

    # 获取响应参数对应的类型(正则表达式)
    def self.get_response_param_type(name, type)
      case type
      when 'string' then /json\.#{name}\s.*\.to_s/
      when 'number' then /json\.#{name}\s.*\.to_f/
      when 'integer' then /json\.#{name}\s.*\.to_i/
      when 'array' then /json\.#{name}\s(.*\.to_a|.*\sdo)/
      when 'object' then /json\.#{name}\s(.*\.to_h|do\s)/
      else
        raise "Unknown parameter type: #{type}"
      end
    end

    # 检查单个接口
    def self.check_single_interface(interface_id, method_mapping, path_mapping)
      params = {
        token: YapiCheck::Config.yapi_project_token,
        id: interface_id
      }
      response = HTTP.get("#{YapiCheck::Config.yapi_project_domain}/api/interface/get", params: params)
      begin
        detail = JSON.parse(response.body)['data'].to_h
      rescue JSON::ParserError => e
        puts "=== 解析detail JSON出错#{e.backtrace}"
        return
      end
      endpoint = "#{YapiCheck::Config.yapi_api_prefix}#{path_mapping[interface_id]}"
      controller, action = get_controller_and_action(endpoint, method_mapping[interface_id])
      unless controller.respond_to?(:instance_method)
        puts "=== #{endpoint} 接口未实现"
        return
      end
      action_source = controller.instance_method(action).source
      error = {}
      response_params = get_response_params(detail)
      begin
        if response_params.present?
          jbuilder_source = expand_jbuilder_with_partial("#{YapiCheck::Config.yapi_api_prefix}#{path_mapping[interface_id]}.json.jbuilder")
          error[:response_error] = check_response(response_params, jbuilder_source)
        end
      rescue StandardError => e
        puts e
        puts "=== #{path_mapping[interface_id]} 接口所在目录中缺少的jbuilder文件, 请判断是否需要添加对应jbuilder文件 ==="
      end
      yapi_params = get_yapi_params(detail)
      endpoint_error = {}
      error[:request_params_error] = check_request_params(method_mapping[interface_id], yapi_params, action_source)
      endpoint_error["#{method_mapping[interface_id]} #{path_mapping[interface_id]}"] = error if error[:request_params_error].present? || error[:response_error].present?
      if endpoint_error.present?
        puts "接口: #{path_mapping[interface_id]} 对应文档中的请求参数或响应参数与当前代码存在不一致,"
        puts "请求参数不同之处: #{error[:request_params_error]}"
        puts "响应参数不同之处: #{error[:response_error]}"
      else
        puts "=== 请求类型: #{method_mapping[interface_id]}, 接口: #{path_mapping[interface_id]} 检查无误 ==="
      end
    end

    # 使用子视图展开jbuilder(递归)
    def self.expand_jbuilder_with_partial(jbuilder_file_name, parent_file_name = nil)
      parent_file_name ||= jbuilder_file_name # 若是相对路径需要知道父级的文件名
      jbuilder_source = []
      jbuilder_view_path = File.join('app/views', jbuilder_file_name)
      File.open(jbuilder_view_path) do |file|
        file.each_line(chomp: true) do |line|
          if line =~ %r{json\.partial! '([a-z0-9_/]+)'}
            partial_file_name = Regexp.last_match(1)
            partial_file_name_arr = partial_file_name.split('/')
            if partial_file_name_arr.size == 1
              # 相对路径 base_measurement => api/v1/measurements/_base_measurement
              partial_view_name = File.join(File.dirname(parent_file_name), "_#{partial_file_name}")
            else
              # 绝对路径 api/v1/measurements/base_measurement => api/v1/measurements/_base_measurement
              partial_file_name_arr[-1] = "_#{partial_file_name_arr[-1]}"
              partial_view_name = partial_file_name_arr.join('/')
            end
            jbuilder_source << expand_jbuilder_with_partial("#{partial_view_name}.json.jbuilder", parent_file_name)
          else
            jbuilder_source << line
          end
        end
      end

      jbuilder_source.join("\n")
    end
  end
end
