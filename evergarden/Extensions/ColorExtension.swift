import SwiftUI

// 🌟 에버가든 전용 색상 및 헥사코드 변환 기능
extension Color {
    init(hex: String) {
        // var를 let으로 변경하여 경고 해결!
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
    
    static let egBase = Color(hex: "#FDFBF7")
    static let egMain = Color(hex: "#62974F")
    static let egPoint = Color(hex: "#F197A9")
    static let egSub = Color(hex: "#D9A05B")
    static let egFunctional = Color(hex: "#432616")
}
