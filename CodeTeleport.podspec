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
  s.source = { :git => 'https://github.com/zlit/CodeTeleport.git', :branch => "podspec_test" }
  s.frameworks = 'Foundation'
  s.requires_arc = true
  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/CodeTeleport' }
  s.vendored_frameworks = 'Output/CTClient.framework'
  s.prepare_command = 'bash Output/CTClient.framework/CocoapodsPrepareCommand.sh'

end
