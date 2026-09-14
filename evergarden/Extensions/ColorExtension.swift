import SwiftUI

// 🌟 에버가든 전용 색상 및 헥사코드 변환 기능만 남깁니다!
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
    
    // 에버가든 테마 색상 (기존에 정의해두셨던 색상들을 유지합니다)
    static let egBase = Color(hex: "#FDFBF7")
    static let egMain = Color(hex: "#62974F")
    static let egPoint = Color(hex: "#F197A9")
    static let egSub = Color(hex: "#D9A05B")
    static let egFunctional = Color(hex: "#432616")
}
