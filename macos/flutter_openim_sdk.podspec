Pod::Spec.new do |s|
  s.name             = 'flutter_openim_sdk'
  s.version          = '0.0.1'
  s.summary          = 'OpenIM Flutter SDK macOS plugin.'
  s.description      = <<-DESC
OpenIM Flutter SDK macOS plugin. macOS 端通过本地 openim-sdk-core 动态库接入核心 IM 能力。
                       DESC
  s.homepage         = 'https://www.openim.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'OpenIM' => 'contact@openim.io' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.vendored_libraries = 'Libraries/libopenim_macos_bridge.dylib'
  s.resources = 'Libraries/libopenim_macos_bridge.dylib'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
