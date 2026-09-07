import SwiftUI

// MARK: - 1. 마이페이지 메인 화면 (MY-01)
struct MyPageView: View {
    // 사용자 데이터 (나중에 실제 DB 데이터로 교체될 부분)
    @State private var nickname: String = "보안냥이"
    @State private var bio: String = "내년 오사카 맛집 투어를 위해 JLPT N2 열공 중! 📚"
    
    // 기록 현황 더미 데이터
    @State private var totalAlbums = 12
    @State private var totalTimeCapsules = 5
    @State private var totalPosts = 3
    
    // 프로필 수정 시트 제어 변수
    @State private var isShowingEditProfile = false
    
    var body: some View {
        ZStack {
            Color.egBase.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 상단 헤더
                HStack {
                    Text("마이 메뉴")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.egFunctional)
                    Spacer()
                    
                    // 설정 버튼 (추후 확장용)
                    Button(action: { print("설정 이동") }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.egFunctional)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 🌟 프로필 카드 영역 (MY-01)
                VStack(spacing: 16) {
                    // 프로필 이미지
                    Circle()
                        .fill(Color.egPoint)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: "cat.fill")
                                .font(.system(size: 45))
                                .foregroundColor(.white)
                                .offset(y: 5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    
                    VStack(spacing: 6) {
                        Text(nickname)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.egFunctional)
                        
                        Text(bio)
                            .font(.system(size: 14))
                            .foregroundColor(.egFunctional.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // 🌟 프로필 수정 버튼 (MY-02 진입점)
                    Button(action: {
                        isShowingEditProfile = true
                    }) {
                        Text("프로필 수정")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.egBase)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.egFunctional)
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                .padding(.horizontal, 20)
                
                // 🌟 내 기록 현황 영역 (MY-01)
                HStack(spacing: 0) {
                    StatBox(title: "내 앨범", count: "\(totalAlbums)")
                    Divider().frame(height: 40)
                    StatBox(title: "타임캡슐", count: "\(totalTimeCapsules)")
                    Divider().frame(height: 40)
                    StatBox(title: "커뮤니티 글", count: "\(totalPosts)")
                }
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 3)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        // 🌟 프로필 수정 모달 띄우기
        .sheet(isPresented: $isShowingEditProfile) {
            EditProfileView(
                currentNickname: $nickname,
                currentBio: $bio
            )
        }
    }
}

// 기록 현황용 작은 컴포넌트
struct StatBox: View {
    let title: String
    let count: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
            Text(count)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.egFunctional)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 2. 프로필 수정 화면 (MY-02)
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var currentNickname: String
    @Binding var currentBio: String
    
    // 편집용 임시 변수
    @State private var tempNickname: String = ""
    @State private var tempBio: String = ""
    
    // 🌟 중복 검사용 에러 메시지 상태
    @State private var errorMessage: String = ""
    
    // 이미 사용 중인 닉네임 목록 (DB 검사 시뮬레이션)
    let existingNicknames = ["여행자", "에버가든", "admin", "해킹냥이"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.egBase.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 프로필 이미지 수정 버튼 (UI만)
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(Color.egPoint)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "cat.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .offset(y: 5)
                            )
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.egFunctional)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            .offset(x: -5, y: -5)
                    }
                    .padding(.top, 20)
                    
                    // 닉네임 입력 및 중복 검사 (MY-02)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("닉네임")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.egFunctional)
                        
                        TextField("닉네임을 입력해주세요", text: $tempNickname)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(errorMessage.isEmpty ? Color.egFunctional.opacity(0.3) : Color.red, lineWidth: 1.5)
                            )
                            // 🌟 글씨를 입력할 때마다 중복 검사 실행
                            .onChange(of: tempNickname) { newValue in
                                validateNickname(newValue)
                            }
                        
                        // 에러 메시지 출력 영역
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.red)
                        } else {
                            Text("사용 가능한 닉네임입니다.")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.egMain)
                                .opacity(tempNickname.isEmpty || tempNickname == currentNickname ? 0 : 1)
                        }
                    }
                    
                    // 상태 메시지 입력
                    VStack(alignment: .leading, spacing: 10) {
                        Text("상태 메시지")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.egFunctional)
                        
                        TextField("나를 표현하는 한 마디를 적어보세요!", text: $tempBio)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.egFunctional.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(.egFunctional)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        // 실제 데이터에 반영 후 닫기
                        currentNickname = tempNickname
                        currentBio = tempBio
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    // 에러가 있거나 이름이 비어있으면 완료 버튼 비활성화
                    .foregroundColor(errorMessage.isEmpty && !tempNickname.isEmpty ? .egFunctional : .gray)
                    .disabled(!errorMessage.isEmpty || tempNickname.isEmpty)
                }
            }
            // 뷰가 나타날 때 현재 데이터를 임시 변수에 세팅
            .onAppear {
                tempNickname = currentNickname
                tempBio = currentBio
            }
        }
    }
    
    // 🌟 중복 검사 로직 (MY-02)
    private func validateNickname(_ name: String) {
        if name.isEmpty {
            errorMessage = "닉네임을 입력해주세요."
        } else if name == currentNickname {
            errorMessage = "" // 기존 닉네임과 같으면 통과
        } else if existingNicknames.contains(name) {
            errorMessage = "이미 사용 중인 닉네임입니다. 다른 닉네임을 입력해주세요."
        } else {
            errorMessage = ""
        }
    }
}

#Preview {
    MyPageView()
}
