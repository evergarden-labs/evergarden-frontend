//
//  ColorExtension.swift
//  evergarden
//
//  Created by 유승진 on 6/16/26.
//

import SwiftUI

// Hex 코드를 편하게 쓰기 위한 확장 기능
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - EverGarden Official Colors
    
    /// 배경: 전체 앱 배경. 햇살을 머금은 흙이나 모래사장처럼 따뜻한 톤
    static let egBase = Color(hex: "#F9F5EB")
    
    /// 브랜드 컬러: 잔디와 나무의 색. 활성 상태 아이콘, 긍정적인 성장 지표
    static let egMain = Color(hex: "#91C483")
    
    /// 감성 컬러: 꽃 에셋, 기록 완료 버튼, 사랑스러운 추억 마커
    static let egSub = Color(hex: "#FFB7B2")
    
    /// 강조 컬러: 타임캡슐 알림, 새로운 보상, 반짝이는 별 효과
    static let egPoint = Color(hex: "#FFD97D")
    
    /// 가독성/보안: 모든 텍스트 컬러. 검정 대신 깊은 갈색을 써서 부드러움 유지
    static let egFunctional = Color(hex: "#52453A")
}
