require 'pathname'

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_openim_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  plugin_root = File.realpath(File.expand_path('..', __dir__))
  default_local_openim_xcframework = File.expand_path('../../build/openim_spm_artifacts/OpenIMCore.xcframework', plugin_root)
  local_openim_xcframework = ENV['OPENIM_IOS_XCFRAMEWORK_PATH']
  if (!local_openim_xcframework || local_openim_xcframework.empty?) && File.directory?(default_local_openim_xcframework)
    local_openim_xcframework = default_local_openim_xcframework
  end
  pod_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  user_xcconfig = {}

  s.name             = 'flutter_openim_sdk'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  s.library = 'resolv'
  s.static_framework = true

  if local_openim_xcframework && File.directory?(local_openim_xcframework)
    relative_xcframework_path = Pathname(local_openim_xcframework).relative_path_from(Pathname(plugin_root)).to_s
    s.vendored_frameworks = relative_xcframework_path
    pod_xcconfig['FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]'] =
      "\"#{local_openim_xcframework}/ios-arm64\" $(inherited)"
    pod_xcconfig['FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]'] =
      "\"#{local_openim_xcframework}/ios-arm64_x86_64-simulator\" $(inherited)"
    pod_xcconfig['OTHER_LDFLAGS'] = '$(inherited) -framework OpenIMCore'
    user_xcconfig['FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]'] =
      "\"#{local_openim_xcframework}/ios-arm64\" $(inherited)"
    user_xcconfig['FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]'] =
      "\"#{local_openim_xcframework}/ios-arm64_x86_64-simulator\" $(inherited)"
    user_xcconfig['OTHER_LDFLAGS'] = '$(inherited) -framework OpenIMCore'
  else
    s.dependency 'OpenIMSDKCore','3.8.3-hotfix.12'
  end

  # s.vendored_frameworks = 'Framework/*.xcframework'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = pod_xcconfig
  s.user_target_xcconfig = user_xcconfig unless user_xcconfig.empty?
  s.swift_version = '5.0'

  s.resource_bundles = {'flutter_openim_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
