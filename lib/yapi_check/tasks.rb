require_relative '../yapi_check'

desc 'YAPI检查'
namespace :yapi do
  task :check, %i[uri version] => :environment do |_task, args|
    raise '请设置YAPI_PROJECT_TOKEN环境变量 ' if YapiCheck::Config.yapi_project_token.nil?
    raise '请设置YAPI_PROJECT_DOMAIN环境变量 ' if YapiCheck::Config.yapi_project_domain.nil?

    puts "\n=== 开启YAPI接口检查(注意: 接口若使用非json参数, 则无法核对参数类型) ===\n"
    # 获取接口列表
    params = {
      token: YapiCheck::Config.yapi_project_token,
      page: 1,
      limit: 1000
    }
    response = HTTP.get("#{YapiCheck::Config.yapi_project_domain}/api/interface/list", params: params)
    interfaces = Array(JSON.parse(response.body).dig('data', 'list'))
    interface_mapping = {}
    method_mapping = {}
    tag_mapping = {}
    path_mapping = {}
    interfaces.each do |interface|
      interface_id = interface['_id']
      method = interface['method']
      path = interface['path']
      tags = interface['tag']
      method_mapping[interface_id] = method
      path_mapping[interface_id] = path
      interface_mapping[path] = interface_id
      # 根据访问路径check某个API
      if args[:uri].present?
        if interface_mapping[args[:uri]].nil?
          next
        else
          YapiCheck::Executor.check_single_interface(interface_mapping[args[:uri]], method_mapping, path_mapping)
          puts "\n"
        end

        break
      end
      tags.each do |tag|
        if tag_mapping.key?(tag)
          tag_mapping[tag] << interface_id
        else
          tag_mapping[tag] = [interface_id]
        end
      end
      # 版本号和URI均不传，检查除[接口说明]内容外的所有接口
      if args[:version].blank? && args[:uri].blank?
        if interface['title'].start_with?('[接口说明]')
          next
        else
          YapiCheck::Executor.check_single_interface(interface_id, method_mapping, path_mapping)
          puts "\n"
        end
      end
    end
    # 根据版本check某些API
    if args[:version].present? && !tag_mapping[args[:version]].nil?
      interface_ids = tag_mapping[args[:version]]
      interface_ids.each do |interface_id|
        YapiCheck::Executor.check_single_interface(interface_id, method_mapping, path_mapping)
        puts "\n"
      end
    end
  end
end
