import SwiftUI

struct CreateAlbumView: View {
    // 화면을 닫기 위한 환경 변수
    @Environment(\.dismiss) var dismiss
    
    // 사용자가 입력/선택한 데이터를 저장할 변수들
    @State private var albumName: String = ""
    @State private var selectedType: AlbumType = .albums
    @State private var selectedColor: Color = .egSub
    
    // 앨범 종류 선택지
    enum AlbumType: String, CaseIterable {
        case albums = "책장 (Albums)"
        case polaroids = "폴라로이드 (Polaroids)"
        case scrapbooks = "스크랩북 (Scrapbooks)"
    }
    
    // 앨범 색상 선택지 (ColorExtension에 있는 색상 + 2가지 추가 조합)
    let albumColors: [Color] = [
        .egSub, // 인디핑크
        .egMain, // 초록
        .egPoint, // 노랑
        Color(red: 0.45, green: 0.65, blue: 0.85), // 파랑 (하늘색)
        Color(red: 0.6, green: 0.5, blue: 0.7) // 보라색
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // 전체 배경색
                Color.egBase.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 35) {
                        
                        // 1. 앨범 이름 입력 칸
                        VStack(alignment: .leading, spacing: 10) {
                            Text("앨범 이름")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.egFunctional)
                            
                            TextField("어떤 추억을 기록할까요?", text: $albumName)
                                .font(.system(size: 16))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.egFunctional.opacity(0.4), lineWidth: 1.5)
                                )
                        }
                        
                        // 2. 앨범 종류 선택 칸
                        VStack(alignment: .leading, spacing: 10) {
                            Text("앨범 종류")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.egFunctional)
                            
                            VStack(spacing: 12) {
                                ForEach(AlbumType.allCases, id: \.self) { type in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedType = type
                                        }
                                    }) {
                                        HStack {
                                            Text(type.rawValue)
                                                .font(.system(size: 16, weight: .bold))
                                            Spacer()
                                            // 선택된 항목에 체크마크 표시
                                            if selectedType == type {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 20))
                                            } else {
                                                Image(systemName: "circle")
                                                    .font(.system(size: 20))
                                                    .opacity(0.3)
                                            }
                                        }
                                        .foregroundColor(selectedType == type ? .egBase : .egFunctional)
                                        .padding()
                                        .background(selectedType == type ? Color.egFunctional : Color.white)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.egFunctional, lineWidth: selectedType == type ? 0 : 1.5)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // 3. 앨범 색상 선택 칸
                        VStack(alignment: .leading, spacing: 10) {
                            Text("테마 색상")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.egFunctional)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(albumColors, id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 45, height: 45)
                                            // 선택된 색상일 경우 바깥에 굵은 테두리 추가
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.egFunctional, lineWidth: selectedColor == color ? 3 : 0)
                                                    .padding(-4) // 테두리를 바깥으로 띄움
                                            )
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                    selectedColor = color
                                                }
                                            }
                                            .padding(4) // 테두리가 잘리지 않도록 여백 추가
                                    }
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("새 앨범 추가")
            .navigationBarTitleDisplayMode(.inline)
            // 상단 취소/완료 버튼
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .foregroundColor(.egFunctional)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        // TODO: 여기에 새로운 앨범을 배열에 추가하는 로직이 들어갑니다.
                        print("\(albumName) / \(selectedType.rawValue) / 생성완료!")
                        dismiss() // 화면 닫기
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(albumName.isEmpty ? Color.gray : .egFunctional) // 이름이 비어있으면 회색처리
                    .disabled(albumName.isEmpty) // 이름이 비어있으면 터치 불가
                }
            }
        }
    }
}

#Preview {
    CreateAlbumView()
}
