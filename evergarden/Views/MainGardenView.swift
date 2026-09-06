//
//  MainGardenView.swift
//  evergarden
//
//  Created by 유승진 on 6/16/26.
//
import SwiftUI

struct MainGardenView: View {
    // ContentView의 아카이브 데이터를 공유받아 사용하기 위해 @Binding 연결
    @Binding var currentArchiveCount: Int
    
    // 식물 배치 설계도
    let gardenLayout: [GardenElement] = [
        GardenElement(name: "첫 식물", imageName: "pixel_plant_1", position: CGPoint(x: 0.3, y: 0.65), requiredArchiveCount: 1),
        GardenElement(name: "두 번째 식물", imageName: "pixel_plant_2", position: CGPoint(x: 0.7, y: 0.7), requiredArchiveCount: 3),
        GardenElement(name: "메인 나무", imageName: "pixel_plant_3", position: CGPoint(x: 0.5, y: 0.55), requiredArchiveCount: 5)
    ]
    
    var body: some View {
        ZStack {
            // 1. 배경 이미지 (원본 비율 사수)
            Image("bg_empty")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.45, green: 0.65, blue: 0.85))
                .ignoresSafeArea()
            
            // 2. 식물 요소 배치 레이어
            GeometryReader { geometry in
                ZStack {
                    ForEach(gardenLayout) { element in
                        if currentArchiveCount >= element.requiredArchiveCount {
                            Image(element.imageName)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 70, height: 70)
                                .position(x: geometry.size.width * element.position.x,
                                          y: geometry.size.height * element.position.y)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            
            // 3. 테스트용 상단 아카이브 추가 버튼
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            currentArchiveCount += 1
                        }
                    }) {
                        Text("아카이브 추가 (현재: \(currentArchiveCount))")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                Spacer()
            }
        }
    }
}
