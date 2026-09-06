//
//  CustomBottombar.swift
//  evergarden
//
//  Created by 유승진 on 6/16/26.
//
import SwiftUI

struct CustomBottomBar: View {
    @Binding var selectedTab: GardenTab
    
    var body: some View {
        ZStack {
            // 1. 어두운 배경 패널
            Rectangle()
                .fill(Color.egFunctional)
                .frame(height: 90)
                .clipShape(.rect(topLeadingRadius: 12, topTrailingRadius: 12))
            
            // 2. 6개의 탭 아이콘 배치
            HStack(spacing: 0) {
                ForEach(GardenTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(tab.imageName)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 32, height: 32)
                                .scaledToFit()
                            
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .opacity(selectedTab == tab ? 1.0 : 0.6)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 15) // 아이폰 하단 홈 바 영역 여백
        }
    }
}
