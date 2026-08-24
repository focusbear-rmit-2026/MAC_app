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

  # Vendored NWWebSocket teardown patch. NWWebSocket 0.5.4's connection teardown races with
  # Network.framework: cancelling an NWConnection is asynchronous, so after cancel() the OS may still
  # deliver a final state report on the connection's internal queue (nw_connection_report_state →
  # objc_retain). If the app has by then RELEASED the connection (connection = nil in tearDownConnection,
  # or reassigned in migrateConnection during reconnect / better-path churn on sleep / network loss),
  # that report retains a freed connection / handler block → EXC_BAD_ACCESS (Sentry
  # FOCUS-BEAR-MACOS-19G / 1B / Q8, recurred on 3.36+525).
  #
  # The earlier fix (#2125) nil'd the connection's update handlers before cancel() — that made it WORSE:
  # it suppressed the `.cancelled` teardown callback AND the nil raced with the internal queue retaining
  # the handler block. So we do NOT touch the handlers. Instead cancelConnectionSafely() cancels and then
  # keeps a strong reference to the cancelled connection for a grace period, so it (and its copied handler
  # block) outlives the report window before it's dropped. Strictly additive — only extends lifetime; the
  # held connections are static so the deinit path is covered too. Re-applied here because `pod install`
  # regenerates the source and would otherwise drop it. Durable upstream fix is NWWebSocket 0.5.10
  # (blocked: it regenerates the Pods project and breaks the Sentry pod build under Xcode 26).
  nwws = File.join(__dir__, 'Pods/NWWebSocket/Sources/NWWebSocket/Model/Client/NWWebSocket.swift')
  if File.exist?(nwws)
    src = File.read(nwws)
    unless src.include?('cancelConnectionSafely')
      src = src.gsub('connection?.cancel()', 'cancelConnectionSafely()')
      helper = <<~SWIFT

          // FOCUS BEAR VENDORED PATCH (Sentry FOCUS-BEAR-MACOS-19G / 1B / Q8): cancel() is async, so a
          // final state report can fire on the connection's internal queue AFTER the app has released the
          // connection during reconnect churn — objc_retain on a freed connection / handler block
          // (EXC_BAD_ACCESS on sleep / network loss). Rather than niling the [weak self] handlers (which
          // raced harder), keep a strong reference to the cancelled connection for a grace period so it
          // outlives the report window, then drop it. Static + locked so the deinit path is covered too.
          private static let fbCancelledConnectionsLock = NSLock()
          private static var fbCancelledConnections: [NWConnection] = []

          private func cancelConnectionSafely() {
              guard let conn = connection else { return }
              conn.cancel()
              NWWebSocket.fbCancelledConnectionsLock.lock()
              NWWebSocket.fbCancelledConnections.append(conn)
              NWWebSocket.fbCancelledConnectionsLock.unlock()
              DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                  NWWebSocket.fbCancelledConnectionsLock.lock()
                  NWWebSocket.fbCancelledConnections.removeAll { $0 === conn }
                  NWWebSocket.fbCancelledConnectionsLock.unlock()
              }
          }
      SWIFT
      src = src.sub(/\n(\s*)deinit \{/, "\n#{helper}\\1deinit {")
      File.write(nwws, src)
      Pod::UI.puts '[Focus Bear] Applied NWWebSocket teardown patch (hold cancelled connections)'
    end
  end
end
