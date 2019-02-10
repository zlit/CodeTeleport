PACKAGE = "com.zhaoleili.CodeTeleport"

Pod::Spec.new do |s|

  s.name         = "CodeTeleport"
  s.version      = "0.0.1"
  s.summary      = "CodeTeleport"

  s.description  = <<-DESC
                   * a ios-platform hot reload tool.
                   DESC

  s.homepage     = "https://github.com/zlit/CodeTeleport"
  s.license      = 'Apache-2.0'
  s.author       = { "joesense" => "zhaoleili@icloud.com" }
  s.platform     = :ios, '8.0'
  s.ios.deployment_target = '8.0'

  s.source = { :https => 'https://github.com/zlit/CodeTeleport/tree/beta_1.0/Output', :branch => "beta_1.0" }
  s.frameworks = 'Foundation'
  s.requires_arc = true
  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/CodeTeleport' }
  s.prepare_command = 'bash CocoapodsPrepareCommand.sh'

end
