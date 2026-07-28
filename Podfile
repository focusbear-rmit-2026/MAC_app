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

  # Vendored NWWebSocket use-after-free fix (#2125). NWWebSocket 0.5.4 calls connection?.cancel()
  # without first niling the connection's update handlers, so a cancelled NWConnection can still deliver
  # a final state report into a handler whose captured context has been freed during reconnect churn —
  # the nw_connection_report_state → objc_retain crash the app hit on sleep / network loss. Upstream
  # fixed this in 0.5.10, but bumping to it regenerates the Pods project and breaks the Sentry pod build
  # under Xcode 26. So we vendor the exact fix into the pinned 0.5.4 and re-apply it here, since
  # `pod install` regenerates the source and would otherwise silently drop it.
  nwws = File.join(__dir__, 'Pods/NWWebSocket/Sources/NWWebSocket/Model/Client/NWWebSocket.swift')
  if File.exist?(nwws)
    src = File.read(nwws)
    unless src.include?('cancelConnectionSafely')
      src = src.gsub('connection?.cancel()', 'cancelConnectionSafely()')
      helper = <<~SWIFT

          // FOCUS BEAR VENDORED PATCH (#2125): nil the connection's update handlers before cancel() so a
          // cancelled NWConnection can't deliver a final state report into a freed handler. Upstream's
          // 0.5.10 fix, vendored into 0.5.4 (0.5.10 breaks the Sentry pod build under Xcode 26).
          private func cancelConnectionSafely() {
              connection?.stateUpdateHandler = nil
              connection?.betterPathUpdateHandler = nil
              connection?.viabilityUpdateHandler = nil
              connection?.cancel()
          }
      SWIFT
      src = src.sub(/\n(\s*)deinit \{/, "\n#{helper}\\1deinit {")
      File.write(nwws, src)
      Pod::UI.puts '[Focus Bear] Applied NWWebSocket use-after-free patch (#2125)'
    end
  end
end
