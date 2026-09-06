//
//  Models.swift
//  evergarden
//
//  Created by 유승진 on 6/16/26.
//
import Foundation
import SwiftUI

// 1. 하단 바 탭 구분을 위한 열거형
enum GardenTab: String, CaseIterable {
    case garden = "GARDEN"
    case archive = "ARCHIVE"
    case planner = "PLANNER"
    case timeCapsule = "TIME CAPSULE"
    case community = "COMMUNITY"
    case myMenu = "MY MENU"
    
    var imageName: String {
        switch self {
        case .garden: return "pixel_icon_garden"
        case .archive: return "pixel_icon_archive"
        case .planner: return "pixel_icon_planner"
        case .timeCapsule: return "pixel_icon_timecapsule"
        case .community: return "pixel_icon_community"
        case .myMenu: return "pixel_icon_mymenu"
        }
    }
}

// 2. 정원에 배치될 식물 데이터 모델
struct GardenElement: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    let position: CGPoint // 화면 내 배치될 상대적 좌표 (x: 0.0~1.0, y: 0.0~1.0)
    let requiredArchiveCount: Int // 이 식물이 나타나기 위한 최소 아카이브 수
}


// 1. 타임캡슐의 식물 성장 단계
enum GrowthStage {
    case seed       // 씨앗 (아주 먼 미래)
    case sprout     // 작은 새싹 (조금 가까워짐)
    case growing    // 자라나는 중 (곧 열림)
    case bloomed    // 활짝 핀 꽃 (오픈 날짜 지남 - 병 열림!)
}

// 2. 타임캡슐 데이터 그릇
struct TimeCapsuleItem: Identifiable {
    let id = UUID()
    let openDateString: String // 팻말에 적힐 날짜 (예: "2027.08.12")
    let targetDate: Date       // 실제 오픈 날짜 (성장 계산용)
    
    // 현재 시간과 목표 시간을 비교해서 식물의 성장 단계를 자동으로 계산해 주는 똑똑한 변수!
    var currentStage: GrowthStage {
        let now = Date()
        let timeRemaining = targetDate.timeIntervalSince(now)
        let daysRemaining = timeRemaining / (60 * 60 * 24)
        
        if daysRemaining <= 0 {
            return .bloomed // 날짜가 지났으면 꽃이 핌!
        } else if daysRemaining <= 60 {
            return .growing // 2달 안남았으면 꽤 자람
        } else if daysRemaining <= 180 {
            return .sprout  // 6달 안남았으면 새싹
        } else {
            return .seed    // 그 이상은 씨앗
        }
    }
}
