import SwiftUI

struct ContentView: View {
    @State private var selectedTab: GardenTab = .garden
    @State private var currentArchiveCount = 0 // 앱의 핵심 데이터를 상위에서 통제
    
    var body: some View {
        ZStack {
            // 1. 하단 바 탭 선택에 따라 메인 알맹이 화면 갈아끼우기 (라우팅)
            Group {
                switch selectedTab {
                case .garden:
                    // 메인 정원 화면을 불러오고 데이터를 넘겨줌
                    MainGardenView(currentArchiveCount: $currentArchiveCount)
                    
                case .archive:
                    // 🌟 방금 만든 아카이브 화면 연결!
                    ArchiveView()
                    
                case .planner:
                    Text("플래너 (지도 코스) 화면이 들어올 자리입니다.")
                        .foregroundColor(.egFunctional)
                    
                case .timeCapsule:
                    Text("타임캡슐 화면이 들어올 자리입니다.")
                        .foregroundColor(.egFunctional)
                    
                case .community:
                    Text("커뮤니티 화면이 들어올 자리입니다.")
                        .foregroundColor(.egFunctional)
                    
                case .myMenu:
                    Text("마이 메뉴 화면이 들어올 자리입니다.")
                        .foregroundColor(.egFunctional)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 2. 커스텀 하단 바는 어떤 화면에서든 항상 맨 위에 고정
            VStack {
                Spacer()
                CustomBottomBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom) // 하단 바를 기기 맨 밑바닥까지 밀착
        }
        // 화면 전환 시 뜨는 빈 여백을 기본 바닐라 크림 색상으로 지정
        .background(Color.egBase.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
