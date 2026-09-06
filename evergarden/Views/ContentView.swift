import SwiftUI

struct ContentView: View {
    @State private var selectedTab: GardenTab = .garden
    @State private var currentArchiveCount = 0 // 앱의 핵심 데이터를 상위에서 통제
    
    var body: some View {
        ZStack {
            // 1. 하단 바 탭 선택에 따라 메인 알맹이 화면 갈아끼우기
            Group {
                switch selectedTab {
                case .garden:
                    MainGardenView(currentArchiveCount: $currentArchiveCount)
                    
                case .archive:
                    ArchiveView()
                    
                case .planner:
                    // 🌟 플래너 화면 완벽 연결!
                    PlannerView()
                        
                case .timeCapsule:
                    TimeCapsuleView()
                    
                case .community:
                    CommunityView()
                    
                case .myMenu:
                    Text("마이 메뉴 화면이 들어올 자리입니다.")
                        .foregroundColor(.egFunctional)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 2. 커스텀 하단 바
            VStack {
                Spacer()
                CustomBottomBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        // 화면 전환 시 뜨는 빈 여백을 기본 바닐라 크림 색상으로 지정
        .background(Color.egBase.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
