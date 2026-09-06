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
