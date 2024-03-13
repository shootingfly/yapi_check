# YapiCheck

[en](./README.md) | [zh-CN](./README.zh-CN.md)

> YAPI是一款非常棒的接口文档管理工具, 但保持接口文档与代码一致性是一个难题, 与其通过人眼识别, 不如让工具自动化帮你处理

这是一款用于核对YAPI接口文档与代码的工具, 具有强一致性与规范性.

## 主要功能
### 1. 请求参数检查
+ 通过扫描action的源代码,并捕获action的lucky_param参数,与YAPI文档的入参元数据进行匹配
  + 支持必填性与非必填性验证
  + 其中JSON参数支持类型验证, 支持判断String, Float, Integer三种类型
  + 参数检测要求每个字段都单独成行, 如
    ```ruby
      required(:name, :String) # 姓名
      required(:phone, :Integer) # 手机号
      required(:height, :Float) # 身高
      optional(:email, :Email) # 邮箱
      optional(:tags, :ArrayJSON) # 标签
    ```
### 2. 响应参数检查
+ 通过扫描jbuilder源码,与YAPI文档的出参元数据进行匹配
  + 支持子视图
  + 支持使用相对根目录或相对当前文件目录的路径
  + action名称必须与jbuilder文件名保持一致
  + 出参要求每个返回的字段都单独成行
  + 出参要求强制类型转化:
    + 字符串: 使用to_s识别, json.attr_name ... to_s识别
    + 整型: 使用to_i识别, json.attr_name ... to_i识别
    + 浮点数: 使用to_f识别, json.attr_name ... to_f识别
    + 数组: 使用to_a识别或do识别, json.attr_name ... each do识别
    + 字典: 使用to_h识别或do识别, json.attr_name each do识别
  ```ruby
  json.user do
    json.name   user.name.to_s
    json.phone  user.phone.to_i
    json.height user.height.to_f
    json.email  user.email.to_s
    json.tags   user.tags.to_a
  end
  ```
  + 不支持布尔型, 请用整型代替
  + 属性必须包含在data对象中,如:{"code":200, "data":{}}
### 3. 批量检查
+ 支持检查单个项目的所有接口
+ 支持仅检查单个接口
+ 支持仅检查单个标签下的接口

## 使用说明

1. 添加本行在Rails项目的Gemfile中

```ruby
gem 'yapi_check'
```

2. 执行bundle install
```shell
$ bundle install
```

3. 在项目的Rakefile中间插入如下代码
```ruby
require 'yapi_check/tasks'
ENV['YAPI_PROJECT_TOKEN'] = 'THE_TOKEN_FROM_YOUR_YAPI_PROJECT' # YAPI项目唯一标识(必填), 建议配置在项目里. 该配置可进入YAPI项目查看并拷贝, 功能路径: 设置 -> token配置
ENV['YAPI_PROJECT_DOMAIN'] = 'http://YOUR_YAPI_WEBSITE' # YAPI项目域名, 建议配置在个人电脑里, 避免变更 ~/.bashrc or ~/.zshrc
ENV['YAPI_API_PREFIX'] = '' # YAPI项目接口前缀, 可设置为'', 不设置默认为/api/v1
```

4. 执行YAPI检查
注: 若使用zsh, 请于~/.zshrc中安装rake插件以支持特殊语法 plugins=(... rake)

```shell
# 完整检查
$ bundle exec rake yapi:check
# or
$ rails yapi:check

# 单个接口检查
$ bundle exec rake yapi:check[/healthy_lives/exit_healthy_life]
# or
$ noglob rails yapi:check[/healthy_lives/exit_healthy_life]
# or
$ rails 'yapi:check[/healthy_lives/exit_healthy_life]'

# 单个标签检查
$ bundle exec rake yapi:check[,3.3.0]
# or
$ noglob rails yapi:check[,3.3.0]
# or
$ rails 'yapi:check[,3.3.0]'
```

## 注意事项
本工具仅限Rails项目使用, 请求参数检查强依赖[lucky_param](https://github.com/shootingfly/lucky_param), 响应参数检查强依赖[jbuilder](https://github.com/rails/jbuilder)

## 贡献

1. Fork它 ( https://github.com/shootingfly/yapi_check/fork )
2. 创建一个新的功能分支 (git checkout -b my-new-feature)
3. 进行你的更改
4. 运行 `ruby test/yapi_check_test.rb` 来运行测试
5. 提交你的更改 (git commit -am 'Add some feature')
6. 推送到分支 (git push origin my-new-feature)
7. 创建一个新的Pull请求

## 许可证

该Gem以[MIT许可证](https://opensource.org/licenses/MIT)的形式提供。
