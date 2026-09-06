import SwiftUI

// MARK: - 1. 커뮤니티 데이터 모델
struct CommunityPost: Identifiable {
    let id = UUID()
    let authorName: String
    let profileColor: Color
    let region: String
    let title: String
    let content: String
    let timeAgo: String
    var likes: Int
    var comments: Int
    var isLiked: Bool
    var isMine: Bool // 내가 쓴 글인지 여부 (수정/삭제 권한용)
}

// MARK: - 2. 커뮤니티 메인 화면
struct CommunityView: View {
    // 🌟 명세서 기능: 피드 조회 (최신순/인기순)
    @State private var selectedFilter = "최신순"
    let filters = ["최신순", "인기순", "내가 좋아요한 글"]
    
    // 🌟 명세서 기능: 지역별 피드 조회
    @State private var selectedRegion = "전체"
    let regions = ["전체", "서울", "제주", "도쿄", "오사카", "후쿠오카"]
    
    // 글쓰기 시트 제어
    @State private var isShowingWriteSheet = false
    
    // 더미 데이터 (관광/맛집 투어 컨셉)
    @State private var posts: [CommunityPost] = [
        CommunityPost(authorName: "해킹냥이", profileColor: .egMain, region: "도쿄", title: "도쿄 IT 보안 컨퍼런스 & 맛집 투어 💻🍣", content: "오전에 컨퍼런스 듣고 오후에 시부야 근처 라멘집 투어했습니다. 츠케멘 진짜 맛있네요! 다음엔 N2 따서 취업 설명회도 가볼 예정입니다.", timeAgo: "10분 전", likes: 24, comments: 5, isLiked: false, isMine: true),
        CommunityPost(authorName: "미식탐험가", profileColor: .egPoint, region: "제주", title: "제주도 로컬들만 아는 숨겨진 맛집 코스", content: "관광 데이터 기반으로 동선 최적화해서 다녀온 2박 3일 제주도 먹방 코스 아카이브 공유합니다. 동쪽 해안도로 강추해요!", timeAgo: "2시간 전", likes: 128, comments: 32, isLiked: true, isMine: false),
        CommunityPost(authorName: "초보여행자", profileColor: .egSub, region: "오사카", title: "오사카 3박 4일 첫 여행 코스 평가 부탁드려요", content: "유니버셜 스튜디오 하루 풀로 잡고, 도톤보리랑 난바 위주로 돌려고 하는데 코스 빡빡하지 않을까요?", timeAgo: "5시간 전", likes: 12, comments: 8, isLiked: false, isMine: false)
    ]
    
    var body: some View {
        ZStack {
            Color.egBase.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 상단 헤더
                HStack(alignment: .bottom) {
                    Text("커뮤니티")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.egFunctional)
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.egFunctional)
                        .padding(.trailing, 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 15)
                
                // 필터 & 지역 선택 바 (COMM-01, COMM-02)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 지역 선택 메뉴
                        Menu {
                            ForEach(regions, id: \.self) { region in
                                Button(region) { selectedRegion = region }
                            }
                        } label: {
                            HStack {
                                Text(selectedRegion)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .foregroundColor(.egFunctional)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.egFunctional.opacity(0.2), lineWidth: 1))
                        }
                        
                        Divider().frame(height: 20)
                        
                        // 정렬 필터
                        ForEach(filters, id: \.self) { filter in
                            Button(action: {
                                selectedFilter = filter
                            }) {
                                Text(filter)
                                    .font(.system(size: 14, weight: .bold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilter == filter ? Color.egFunctional : Color.clear)
                                    .foregroundColor(selectedFilter == filter ? .egBase : .egFunctional.opacity(0.6))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
                
                // 🌟 피드 리스트 (COMM-01)
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        // 지역 필터가 적용된 피드만 보여줌
                        let filteredPosts = selectedRegion == "전체" ? posts : posts.filter { $0.region == selectedRegion }
                        
                        ForEach($posts) { $post in
                            // 지역 필터링 통과한 것만 렌더링
                            if selectedRegion == "전체" || post.region == selectedRegion {
                                CommunityPostCell(post: $post)
                            }
                        }
                        
                        Spacer().frame(height: 120) // 하단 바 & 플로팅 버튼 여백
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            
            // 🌟 게시물 작성 버튼 (COMM-04) - 입체 젤리 버튼 적용!
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        isShowingWriteSheet = true
                    }) {
                        Text("✏️ 글쓰기")
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
        }
        // 게시물 작성 시트 연결
        .sheet(isPresented: $isShowingWriteSheet) {
            ZStack {
                Color.egBase.ignoresSafeArea()
                Text("나의 아카이브/코스 공유 화면 (게시물 작성)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.egFunctional)
            }
        }
    }
}

// MARK: - 3. 게시물 셀 디자인 (상세 조회, 좋아요, 수정/삭제/신고)
struct CommunityPostCell: View {
    @Binding var post: CommunityPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 프로필 & 닉네임 & 더보기 버튼
            HStack {
                Circle()
                    .fill(post.profileColor)
                    .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.egFunctional)
                    HStack(spacing: 6) {
                        Text(post.region)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.egMain)
                            .cornerRadius(4)
                        
                        Text(post.timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                
                // 🌟 명세서 기능: 게시물 수정/삭제(COMM-05,06) 및 신고(COMM-09)
                Menu {
                    if post.isMine {
                        Button("수정하기", action: { print("수정 화면으로 이동") })
                        Button("삭제하기", role: .destructive, action: { print("게시물 삭제") })
                    } else {
                        Button("이 게시물 신고하기", role: .destructive, action: { print("신고 처리") })
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            
            // 제목 & 내용 (터치 시 상세 조회 - COMM-03)
            Button(action: {
                print("\(post.title) 상세 조회 화면으로 이동")
                // TODO: NavigationLink로 연결하여 댓글(COMM-10~15) 기능 구현
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.egFunctional)
                        .lineLimit(1)
                    
                    Text(post.content)
                        .font(.system(size: 14))
                        .foregroundColor(.egFunctional.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // 첨부 이미지 (아카이브 공유 썸네일)
                    Rectangle()
                        .fill(Color.egPoint.opacity(0.2))
                        .frame(height: 140)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.egFunctional.opacity(0.3))
                        )
                }
            }
            .buttonStyle(PlainButtonStyle()) // 버튼 눌림 효과 제거
            
            // 🌟 하단 반응 버튼 (좋아요, 댓글 - COMM-07)
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        post.isLiked.toggle()
                        post.likes += post.isLiked ? 1 : -1
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .gray)
                        Text("\(post.likes)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(post.isLiked ? .red : .gray)
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.gray)
                    Text("\(post.comments)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.gray)
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
    CommunityView()
}
