import SwiftUI

struct ArchiveView: View {
    // 🌟 화면을 띄울지 말지 결정하는 상태 스위치 추가
    @State private var isShowingCreateAlbum = false
    // 따뜻한 원목 책장 색상 유지
    let woodFrame = Color(red: 0.88, green: 0.72, blue: 0.54)
    let woodBackground = Color(red: 0.72, green: 0.53, blue: 0.40)
    let woodShelf = Color(red: 0.85, green: 0.67, blue: 0.48)
    
    var body: some View {
        ZStack {
            Color.egBase.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 헤더
                HStack(alignment: .bottom) {
                    Text("나의 아카이브")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.egFunctional)
                    
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.egMain)
                        .font(.system(size: 24))
                        .offset(y: -4)
                }
                .padding(.top, 20)
                .padding(.bottom, 15)
                
                // 책장 영역
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ArchiveShelf(title: "책장 (Albums)", bg: woodBackground, shelf: woodShelf) {
                            HStack(spacing: 4) {
                                ForEach(0..<10) { index in
                                    Rectangle()
                                        .fill(Color.egPoint.opacity(Double(index) * 0.1 + 0.3))
                                        .frame(width: 25, height: CGFloat.random(in: 100...120))
                                        .border(Color.egFunctional.opacity(0.3), width: 1)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        ArchiveShelf(title: "폴라로이드 (Polaroids)", bg: woodBackground, shelf: woodShelf) {
                            HStack(spacing: -15) {
                                ForEach(0..<4) { index in
                                    PolaroidMockup(title: "2023-05-29")
                                        .rotationEffect(.degrees(index % 2 == 0 ? -4 : 5))
                                        .offset(y: index % 2 == 0 ? 5 : 0)
                                }
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 5)
                        }
                        
                        ArchiveShelf(title: "스크랩북 (Scrapbooks)", bg: woodBackground, shelf: woodShelf) {
                            HStack(spacing: 10) {
                                ForEach(0..<3) { index in
                                    Rectangle()
                                        .fill(Color.egMain.opacity(Double(index) * 0.2 + 0.4))
                                        .frame(width: 130, height: 110)
                                        .cornerRadius(4)
                                        .overlay(
                                            HStack {
                                                Rectangle().fill(Color.black.opacity(0.2)).frame(width: 20)
                                                Spacer()
                                            }
                                        )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Rectangle()
                            .fill(woodBackground)
                            .frame(height: 180)
                    }
                    .background(woodFrame)
                    .border(woodFrame.opacity(0.8), width: 8)
                }
            }
            
            // ----------------------------------------------------
            // 🌟 새 앨범 추가 버튼 (내부 그림자 투명도 완벽 해결!)
            // ----------------------------------------------------
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        // 🌟 버튼을 누르면 스위치를 On으로 켬!
                        isShowingCreateAlbum = true
                        // 새 앨범 추가 액션
                    }) {
                        Text("+ 새 앨범 추가")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.egFunctional)
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1.5)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 14)
                            .offset(y: -2)
                            .background(
                                ZStack {
                                    // 1. 전체 외곽선 (가장 밑바닥)
                                    Capsule()
                                        .fill(Color.egFunctional)
                                    
                                    // 2. 밑색 차단용 배경 (외곽선 안쪽을 핑크색으로 일단 다 덮음)
                                    Capsule()
                                        .fill(Color.egSub)
                                        .padding(2.5)
                                    
                                    // 3. 🌟 진짜 내부 그림자!
                                    // 바탕이 핑크색이기 때문에 이제 opacity를 조절하는 대로 부드럽게 연해집니다.
                                    // 더 연하게 하고 싶으시면 0.2를 0.1로, 진하게 하려면 0.4로 바꾸시면 됩니다.
                                    Capsule()
                                        .fill(Color.egFunctional.opacity(0.5))
                                        .padding(2.5)
                                    
                                    // 4. 핑크색 윗면 (버튼이 위로 솟아오른 효과)
                                    Capsule()
                                        .fill(Color.egSub)
                                        .padding(.horizontal, 2.5)
                                        .padding(.top, 2.5)
                                        .padding(.bottom, 6.5)
                                    
                                    // 5. 상단 하이라이트 (빛 반사)
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.1), Color.clear]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 1.5
                                        )
                                        .padding(.horizontal, 4)
                                        .padding(.top, 4)
                                        .padding(.bottom, 8)
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
        // 🌟 ZStack 바깥에 시트 띄우기 설정 추가
                .sheet(isPresented: $isShowingCreateAlbum) {
                    CreateAlbumView()
                }
    }
}

// MARK: - 반복되는 선반(Shelf) 컴포넌트
struct ArchiveShelf<Content: View>: View {
    let title: String
    let bg: Color
    let shelf: Color
    let content: Content
    
    init(title: String, bg: Color, shelf: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.bg = bg
        self.shelf = shelf
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.05))
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 24, height: 24)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .padding(.bottom, 10)
            .background(shelf)
            
            ZStack(alignment: .bottom) {
                bg.frame(height: 160)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    content
                }
                
                Rectangle()
                    .fill(shelf)
                    .frame(height: 12)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: -2)
            }
        }
    }
}

// MARK: - 임시 폴라로이드
struct PolaroidMockup: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
            
            Text(title)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.black)
        }
        .padding(10)
        .background(Color.white)
        .shadow(color: .black.opacity(0.2), radius: 3, x: 1, y: 2)
    }
}

#Preview {
    ArchiveView()
}
