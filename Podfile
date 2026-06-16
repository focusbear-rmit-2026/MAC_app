# Uncomment the next line to define a global platform for your project
 platform :macos, '10.15'

target 'Focus Bear' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '8.48.0'
  pod 'TrueTime'
  pod 'PusherSwift'

  # Pods for Focus Bear

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Xcode 26's explicit Swift modules can't resolve some pods' C module
      # dependencies (e.g. CTweetNacl for PusherSwift), which breaks the build with
      # "Unable to find module dependency: 'CTweetNacl'". Disabling explicit modules
      # for the pod targets restores a working build. See README "Running locally".
      config.build_settings['SWIFT_ENABLE_EXPLICIT_MODULES'] = 'NO'
    end
  end
end
