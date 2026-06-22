import ServiceManagement

/// Thin wrapper over `SMAppService` for the launch-at-login toggle.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Blip: login item toggle failed — \(error.localizedDescription)")
        }
    }
}
