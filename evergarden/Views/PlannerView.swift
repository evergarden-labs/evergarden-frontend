import SwiftUI

// MARK: - 1. 플래너 데이터 모델
struct TravelPlan: Identifiable {
    let id = UUID()
    let title: String
    let destination: String
    let startDate: String
    let endDate: String
    let isAIGenerated: Bool // PLAN-09: AI가 짜준 코스인지 여부
    let placesCount: Int
}

// MARK: - 2. 플래너 메인 화면
struct PlannerView: View {
    // 🌟 명세서 기능: 일정 목록 조회 (PLAN-11)
    @State private var plans: [TravelPlan] = [
        TravelPlan(title: "오사카 3박 4일 미식 투어 🐙", destination: "일본 오사카", startDate: "2026.12.20", endDate: "2026.12.23", isAIGenerated: true, placesCount: 15),
        TravelPlan(title: "도쿄 IT 보안 박람회 출장 💻", destination: "일본 도쿄", startDate: "2027.02.10", endDate: "2027.02.14", isAIGenerated: false, placesCount: 8),
        TravelPlan(title: "제주도 해안도로 드라이브 🌴", destination: "한국 제주", startDate: "2026.08.15", endDate: "2026.08.18", isAIGenerated: true, placesCount: 12)
    ]
    
    @State private var isShowingCreateSheet = false
    
    var body: some View {
        ZStack {
            Color.egBase.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 헤더
                HStack(alignment: .bottom) {
                    Text("여행 플래너")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.egFunctional)
                    Spacer()
                    
                    // 🌟 명세서 기능: 타인의 코스 가져오기 (PLAN-12)
                    Button(action: { print("공유 코드 입력 창 띄우기") }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 22))
                            .foregroundColor(.egFunctional)
                    }
                    .padding(.trailing, 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // 🌟 명세서 기능: 일정 목록 조회 (PLAN-11)
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(plans) { plan in
                            PlanCardView(plan: plan)
                        }
                        Spacer().frame(height: 120) // 하단 바 여백
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // ----------------------------------------------------
            // 🌟 명세서 기능: 일정 생성 버튼 (PLAN-01) - 젤리 버튼 적용
            // ----------------------------------------------------
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isShowingCreateSheet = true
                    }) {
                        Text("+ 새 일정 만들기")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.egFunctional)
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1.5)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 14)
                            .offset(y: -2)
                            .background(
                                ZStack {
                                    Capsule().fill(Color.egFunctional)
                                    Capsule().fill(Color.egSub).padding(2.5)
                                    Capsule().fill(Color.egFunctional.opacity(0.2)).padding(2.5)
                                    Capsule().fill(Color.egSub).padding(.horizontal, 2.5).padding(.top, 2.5).padding(.bottom, 6.5)
                                    Capsule().stroke(
                                        LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.1), Color.clear]), startPoint: .top, endPoint: .bottom),
                                        lineWidth: 1.5
                                    )
                                    .padding(.horizontal, 4).padding(.top, 4).padding(.bottom, 8)
                                }
                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 110)
                }
            }
            .zIndex(1)
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            ZStack {
                Color.egBase.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("어떤 일정을 만드시겠어요?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.egFunctional)
                    
                    // 🌟 명세서 기능: AI 자동 생성 (PLAN-09)
                    Button("✨ AI 자동 생성 (추천 코스)") { print("AI 일정 생성") }
                        .padding()
                        .background(Color.egPoint)
                        .foregroundColor(.egFunctional)
                        .cornerRadius(12)
                    
                    // 🌟 명세서 기능: 직접 생성 (PLAN-02, 06)
                    Button("🗺️ 내가 직접 장소 검색해서 짜기") { print("수동 일정 생성") }
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.egFunctional)
                        .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - 3. 플래너 카드 뷰 (일정 상세 조회 진입점 - PLAN-03)
struct PlanCardView: View {
    let plan: TravelPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.destination)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.egMain)
                    .cornerRadius(6)
                
                // 🌟 명세서 기능: AI 자동 생성 뱃지 (PLAN-09)
                if plan.isAIGenerated {
                    Text("✨ AI 추천 코스")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.egFunctional)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.egPoint)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                // 🌟 명세서 기능: 일정 수정/삭제 (PLAN-04, 05)
                Menu {
                    Button("일정 수정", action: { print("수정") })
                    Button("일정 삭제", role: .destructive, action: { print("삭제") })
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(4)
                }
            }
            
            Text(plan.title)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.egFunctional)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                Text("\(plan.startDate) ~ \(plan.endDate)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Divider().padding(.vertical, 4)
            
            HStack {
                Text("총 \(plan.placesCount)개의 장소 방문 예정")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.egFunctional.opacity(0.8))
                
                Spacer()
                
                // 🌟 명세서 기능: 코스 시각화 (PLAN-10)
                Button(action: {
                    print("지도에 코스 동선 시각화 띄우기")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "map.fill")
                        Text("지도 보기")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.egBase)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.egFunctional)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
    }
}

#Preview {
    PlannerView()
}
