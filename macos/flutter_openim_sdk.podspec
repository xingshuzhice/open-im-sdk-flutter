require 'pathname'

Pod::Spec.new do |s|
  plugin_root = File.realpath(File.expand_path('..', __dir__))
  default_local_openim_xcframework = File.expand_path('../../build/openim_spm_artifacts/OpenIMMacBridge.xcframework', plugin_root)
  local_openim_xcframework = ENV['OPENIM_MACOS_XCFRAMEWORK_PATH']
  if (!local_openim_xcframework || local_openim_xcframework.empty?) && File.directory?(default_local_openim_xcframework)
    local_openim_xcframework = default_local_openim_xcframework
  end

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
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  if local_openim_xcframework && File.directory?(local_openim_xcframework)
    s.vendored_frameworks = Pathname(local_openim_xcframework).relative_path_from(Pathname(plugin_root)).to_s
  else
    s.vendored_libraries = 'Libraries/libopenim_macos_bridge.dylib'
    s.resources = 'Libraries/libopenim_macos_bridge.dylib'
  end
end
