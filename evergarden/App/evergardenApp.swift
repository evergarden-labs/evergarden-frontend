import SwiftUI

// 1. 화면 방향을 세로(Portrait)로만 고정하도록 통제하는 클래스
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait // 세로 모드 고정!
        // (만약 가로로 하려면 .landscape, 다 되게 하려면 .all)
    }
}

@main
struct evergardenApp: App {
    // 2. 위에서 만든 설정을 앱 전체에 연결해 줍니다.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
