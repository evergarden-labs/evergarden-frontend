import SwiftUI
import SpriteKit
import PhotosUI

// MARK: - 1. API 명세서 기반 데이터 모델
enum ArchiveTheme: String, CaseIterable, Hashable {
    case album = "ALBUM"
    case polaroid = "POLAROID"
    case scrapbook = "SCRAPBOOK"
    
    var displayName: String {
        switch self {
        case .album: return "책장 (Albums)"
        case .polaroid: return "폴라로이드 (Polaroids)"
        case .scrapbook: return "스크랩북 (Scrapbooks)"
        }
    }
}

enum AlbumLayoutType: Int, CaseIterable, Hashable {
    case grid2x2 = 4
    case grid2x3 = 6
    
    var displayName: String {
        switch self {
        case .grid2x2: return "2x2 프레임 (4장)"
        case .grid2x3: return "2x3 프레임 (6장)"
        }
    }
}

enum CollaborationStatus: String, Hashable {
    case none = "NONE"
    case open = "OPEN"
    case closed = "CLOSED"
}

struct ArchiveSummary: Identifiable, Hashable {
    let id = UUID()
    let archiveId: Int64
    let title: String
    let theme: ArchiveTheme
    let primaryColor: String?
    let coverImageUrl: String?
    let startDate: String?
    let endDate: String?
    let itemCount: Int
    let collaborationStatus: CollaborationStatus
    let myRole: String
    var layoutType: AlbumLayoutType = .grid2x2
}

struct ArchiveLayout: Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var rotation: Double
}

struct ArchiveItem: Identifiable, Equatable {
    let id = UUID()
    let itemId: Int64
    var sortOrder: Int
    var pageIndex: Int = 0
    var layout: ArchiveLayout
    var caption: String?
    var isCover: Bool
    
    var imageData: Data?
    var uiImage: UIImage?
    let mockColor: Color = [Color.red, Color.blue, Color.green, Color.orange, Color.purple].randomElement()!
    
    static func == (lhs: ArchiveItem, rhs: ArchiveItem) -> Bool {
        lhs.itemId == rhs.itemId && lhs.sortOrder == rhs.sortOrder && lhs.pageIndex == rhs.pageIndex && lhs.layout == rhs.layout && lhs.caption == rhs.caption && lhs.isCover == rhs.isCover
    }
}

// MARK: - 🛡️ 보안 입력 필터
func sanitizeInput(_ input: String) -> String {
    let dangerousPatterns = ["'", "\"", ";", "--", "/*", "*/", "script", "SELECT", "INSERT", "UPDATE", "DELETE", "DROP", "UNION"]
    var cleanedString = input
    for pattern in dangerousPatterns {
        cleanedString = cleanedString.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
    }
    let allowedCharacterSet = CharacterSet.alphanumerics.union(CharacterSet.whitespaces).union(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ.,!?_"))
    let filteredScalars = cleanedString.unicodeScalars.filter { allowedCharacterSet.contains($0) }
    return String(String(filteredScalars).prefix(100))
}

// MARK: - 🌟 젤리 버튼 공통 배경
struct JellyButtonBackground: View {
    var mainColor: Color = .egFunctional
    var subColor: Color = .egSub
    
    var body: some View {
        ZStack {
            Capsule().fill(mainColor)
            Capsule().fill(subColor).padding(2.5)
            Capsule().fill(mainColor.opacity(0.5)).padding(2.5)
            Capsule().fill(subColor)
                .padding(.horizontal, 2.5).padding(.top, 2.5).padding(.bottom, 6.5)
            Capsule().stroke(
                LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.9), Color.white.opacity(0.1), Color.clear]), startPoint: .top, endPoint: .bottom),
                lineWidth: 1.5
            )
            .padding(.horizontal, 4).padding(.top, 4).padding(.bottom, 8)
        }
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
    }
}

// MARK: - 4. 메인 아카이브 뷰 (3단 서가)
struct ArchiveView: View {
    @State private var isShowingCreateAlbum = false
    @State private var selectedArchive: ArchiveSummary? = nil
    
    @State private var archives: [ArchiveSummary] = [
        ArchiveSummary(archiveId: 1, title: "오사카 미식 탐험", theme: .album, primaryColor: "#5C3A21", coverImageUrl: nil, startDate: "2026-12-20", endDate: "2026-12-23", itemCount: 42, collaborationStatus: .open, myRole: "OWNER", layoutType: .grid2x3),
        ArchiveSummary(archiveId: 2, title: "도쿄 산책", theme: .album, primaryColor: "#3A5F7D", coverImageUrl: nil, startDate: "2026-05-10", endDate: "2026-05-14", itemCount: 30, collaborationStatus: .closed, myRole: "OWNER", layoutType: .grid2x2),
        ArchiveSummary(archiveId: 3, title: "제주도 드라이브", theme: .polaroid, primaryColor: "#87553A", coverImageUrl: nil, startDate: "2026-08-15", endDate: "2026-08-18", itemCount: 28, collaborationStatus: .closed, myRole: "EDITOR", layoutType: .grid2x2),
        ArchiveSummary(archiveId: 4, title: "해운대 노을", theme: .polaroid, primaryColor: "#E07A5F", coverImageUrl: nil, startDate: "2025-05-29", endDate: "2025-05-30", itemCount: 12, collaborationStatus: .none, myRole: "OWNER", layoutType: .grid2x2),
        ArchiveSummary(archiveId: 5, title: "나만의 스크랩북", theme: .scrapbook, primaryColor: "#B88F66", coverImageUrl: nil, startDate: nil, endDate: nil, itemCount: 0, collaborationStatus: .none, myRole: "OWNER", layoutType: .grid2x2)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#D2A679").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack(alignment: .bottom) {
                        Text("나의 아카이브")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(Color(hex: "#4A2E18"))
                        
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 22))
                            .offset(y: -4)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ShelfRowView(
                                title: "책장 (Albums)",
                                theme: .album,
                                archives: archives.filter { $0.theme == .album },
                                onSelect: { selectedArchive = $0 }
                            )
                            
                            ShelfRowView(
                                title: "폴라로이드 (Polaroids)",
                                theme: .polaroid,
                                archives: archives.filter { $0.theme == .polaroid },
                                onSelect: { selectedArchive = $0 }
                            )
                            
                            ShelfRowView(
                                title: "스크랩북 (Scrapbooks)",
                                theme: .scrapbook,
                                archives: archives.filter { $0.theme == .scrapbook },
                                onSelect: { selectedArchive = $0 }
                            )
                            
                            // 커스텀 탭바(80pt) + 버튼 높이 고려 여백
                            Spacer().frame(height: 160)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // 메인 추가 버튼: 커스텀 탭바(80pt) 바로 위에 안착
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { isShowingCreateAlbum = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .heavy))
                                Text("새 앨범 추가")
                                    .font(.system(size: 16, weight: .heavy))
                            }
                            .foregroundColor(Color(hex: "#4A2E18"))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(JellyButtonBackground(mainColor: Color(hex: "#E8A598"), subColor: Color(hex: "#F7C5BA")))
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 95)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedArchive) { archive in
                ArchiveDetailView(archive: archive, onDelete: {
                    if let index = archives.firstIndex(of: archive) {
                        archives.remove(at: index)
                    }
                    selectedArchive = nil
                })
            }
            .sheet(isPresented: $isShowingCreateAlbum) {
                CreateAlbumView { newTitle, newTheme, newColorHex, newLayoutType in
                    let safeTitle = sanitizeInput(newTitle)
                    let finalTitle = safeTitle.isEmpty ? "무제 앨범" : safeTitle
                    
                    let newArchive = ArchiveSummary(
                        archiveId: Int64(archives.count + 1),
                        title: finalTitle,
                        theme: newTheme,
                        primaryColor: newColorHex,
                        coverImageUrl: nil,
                        startDate: nil,
                        endDate: nil,
                        itemCount: 0,
                        collaborationStatus: .none,
                        myRole: "OWNER",
                        layoutType: newLayoutType
                    )
                    archives.append(newArchive)
                }
            }
        }
    }
}

// MARK: - 🪵 메인 서가 단일 행 컴포넌트
struct ShelfRowView: View {
    let title: String
    let theme: ArchiveTheme
    let archives: [ArchiveSummary]
    let onSelect: (ArchiveSummary) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "#4A2E18"))
                .padding(.horizontal, 4)
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#C6925B"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#7A4E29"), lineWidth: 2.5)
                    )
                
                Rectangle()
                    .fill(Color(hex: "#9E6B38"))
                    .frame(height: 14)
                    .overlay(
                        Rectangle()
                            .stroke(Color(hex: "#5C3A1E"), lineWidth: 1)
                    )
                    .cornerRadius(2)
                    .padding(.horizontal, 2)
                    .padding(.bottom, 2)
                
                if archives.isEmpty {
                    Text("비어있음")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 45)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: theme == .album ? 8 : 14) {
                            ForEach(archives) { archive in
                                Button(action: { onSelect(archive) }) {
                                    switch theme {
                                    case .album:
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color(hex: archive.primaryColor ?? "#5C3A21"))
                                                .frame(width: 38, height: 110)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                                )
                                                .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 1)
                                            
                                            Text(archive.title)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 90)
                                                .rotationEffect(.degrees(-90))
                                                .lineLimit(1)
                                        }
                                    case .polaroid:
                                        VStack(spacing: 4) {
                                            Rectangle()
                                                .fill(Color(hex: archive.primaryColor ?? "#E5C39C"))
                                                .frame(width: 65, height: 60)
                                                .cornerRadius(4)
                                            
                                            Text(archive.title)
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(.black.opacity(0.8))
                                                .lineLimit(1)
                                                .frame(width: 65)
                                        }
                                        .padding(6)
                                        .background(Color.white)
                                        .cornerRadius(6)
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                                        
                                    case .scrapbook:
                                        ZStack(alignment: .trailing) {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color(hex: archive.primaryColor ?? "#B88F66"))
                                                .frame(width: 85, height: 95)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(Color.black.opacity(0.2), lineWidth: 1.5)
                                                )
                                                .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                                            
                                            Rectangle()
                                                .fill(Color(hex: "#5C3A21"))
                                                .frame(width: 14, height: 26)
                                                .cornerRadius(2)
                                                .offset(x: -4)
                                            
                                            Text(archive.title)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                                .frame(width: 70)
                                                .offset(x: -8)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.bottom, 16)
                    }
                }
            }
            .frame(height: 150)
        }
    }
}

// MARK: - 5. 아카이브 상세 화면 (커스텀 탭바 침범 원천 차단)
struct ArchiveDetailView: View {
    let archive: ArchiveSummary
    var onDelete: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    @State private var initialItems: [ArchiveItem] = [
        ArchiveItem(itemId: 101, sortOrder: 1, pageIndex: 0, layout: ArchiveLayout(x: 0.35, y: 0.35, width: 0.4, height: 0.25, rotation: -5), caption: "추억의 시작", isCover: true),
        ArchiveItem(itemId: 102, sortOrder: 2, pageIndex: 0, layout: ArchiveLayout(x: 0.65, y: 0.65, width: 0.35, height: 0.22, rotation: 10), caption: "즐거운 한때", isCover: false)
    ]
    @State private var items: [ArchiveItem] = [
        ArchiveItem(itemId: 101, sortOrder: 1, pageIndex: 0, layout: ArchiveLayout(x: 0.35, y: 0.35, width: 0.4, height: 0.25, rotation: -5), caption: "추억의 시작", isCover: true),
        ArchiveItem(itemId: 102, sortOrder: 2, pageIndex: 0, layout: ArchiveLayout(x: 0.65, y: 0.65, width: 0.35, height: 0.22, rotation: 10), caption: "즐거운 한때", isCover: false),
        ArchiveItem(itemId: 103, sortOrder: 3, pageIndex: 0, layout: ArchiveLayout(x: 0.35, y: 0.35, width: 0.4, height: 0.25, rotation: 0), caption: "새 추억", isCover: false),
        ArchiveItem(itemId: 104, sortOrder: 4, pageIndex: 0, layout: ArchiveLayout(x: 0.65, y: 0.65, width: 0.4, height: 0.25, rotation: 0), caption: "새 추억", isCover: false),
        ArchiveItem(itemId: 105, sortOrder: 5, pageIndex: 0, layout: ArchiveLayout(x: 0.35, y: 0.35, width: 0.4, height: 0.25, rotation: 0), caption: "새 추억", isCover: false),
        ArchiveItem(itemId: 106, sortOrder: 6, pageIndex: 0, layout: ArchiveLayout(x: 0.65, y: 0.65, width: 0.4, height: 0.25, rotation: 0), caption: "새 추억", isCover: false)
    ]
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var showingUnsavedAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var enlargedItem: ArchiveItem? = nil
    
    @State private var scrapbookPageCount: Int = 1
    @State private var currentScrapbookPage: Int = 0
    
    var hasUnsavedChanges: Bool {
        return items != initialItems
    }
    
    var body: some View {
        ZStack {
            Color(hex: archive.primaryColor ?? "#EFEFEF").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. 상단 네비게이션 헤더
                HStack {
                    Button(action: {
                        if hasUnsavedChanges {
                            showingUnsavedAlert = true
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("뒤로")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.egFunctional)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(JellyButtonBackground(mainColor: Color.gray.opacity(0.15), subColor: Color.white.opacity(0.9)))
                    }
                    .padding(.leading, 16)
                    
                    if isEditing {
                        Button(action: { showingDeleteAlert = true }) {
                            Text("앨범 삭제")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(JellyButtonBackground(mainColor: Color.red.opacity(0.15), subColor: Color.white.opacity(0.9)))
                        }
                        .padding(.leading, 8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if isEditing {
                            print("💾 ARCH-07 레이아웃 일괄 저장 통신 완료")
                            initialItems = items
                        }
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "완료" : "편집")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isEditing ? .egFunctional : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(JellyButtonBackground(mainColor: Color.gray.opacity(0.2), subColor: Color.white.opacity(0.95)))
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 12)
                .padding(.bottom, 6)
                
                // 2. 테마별 뷰 컨텐츠
                Group {
                    switch archive.theme {
                    case .polaroid:
                        PolaroidThemeView(items: $items, isEditing: $isEditing, enlargedItem: $enlargedItem) { clickedItem in
                            if !isEditing { enlargedItem = clickedItem }
                        } onDeleteItem: { itemId in
                            items.removeAll { $0.itemId == itemId }
                        }
                    case .album:
                        AlbumThemeView(
                            items: $items,
                            layoutType: archive.layoutType,
                            isEditing: $isEditing,
                            enlargedItem: $enlargedItem
                        ) { clickedItem in
                            if !isEditing { enlargedItem = clickedItem }
                        } onDeleteItem: { itemId in
                            items.removeAll { $0.itemId == itemId }
                        }
                    case .scrapbook:
                        ScrapbookThemeView(items: $items, isEditing: $isEditing, pageCount: $scrapbookPageCount, currentPage: $currentScrapbookPage, enlargedItem: $enlargedItem) { clickedItem in
                            if !isEditing { enlargedItem = clickedItem }
                        } onDeleteItem: { itemId in
                            items.removeAll { $0.itemId == itemId }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 3. 편집 모드 전용 액션 바
                if isEditing {
                    HStack(spacing: 12) {
                        Spacer()
                        
                        if archive.theme == .scrapbook {
                            Button(action: {
                                scrapbookPageCount += 1
                                currentScrapbookPage = scrapbookPageCount - 1
                            }) {
                                Text("+ 페이지 추가")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(JellyButtonBackground(mainColor: Color.egMain, subColor: Color.egFunctional))
                            }
                        }
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("+ 사진 추가")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.egFunctional)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(JellyButtonBackground())
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            guard let newItem = newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    let newItemEntity = ArchiveItem(
                                        itemId: Int64.random(in: 200...999),
                                        sortOrder: items.count + 1,
                                        pageIndex: currentScrapbookPage,
                                        layout: ArchiveLayout(x: 0.5, y: 0.5, width: 0.4, height: 0.25, rotation: 0),
                                        caption: "새 추억",
                                        isCover: false,
                                        imageData: data,
                                        uiImage: uiImage
                                    )
                                    items.append(newItemEntity)
                                    selectedPhotoItem = nil
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 6)
                }
                
                // 🌟 핵심: 커스텀 탭바(80pt) 높이만큼의 절대 침범 금지 영역 설정
                Spacer().frame(height: 80)
            }
            
            // 확대 모달
            if let targetItem = enlargedItem {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .background(.ultraThinMaterial)
                        .onTapGesture { enlargedItem = nil }
                    
                    VStack(spacing: 14) {
                        Group {
                            if let uiImage = targetItem.uiImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                Rectangle()
                                    .fill(targetItem.mockColor)
                                    .aspectRatio(contentMode: .fit)
                                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundColor(.white))
                            }
                        }
                        .frame(maxWidth: 320, maxHeight: 400)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.4), radius: 15, y: 5)
                        
                        if let caption = targetItem.caption, !caption.isEmpty {
                            Text(caption)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                        }
                    }
                    .padding(20)
                    .onTapGesture { enlargedItem = nil }
                }
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: enlargedItem != nil)
                .zIndex(999)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert("앨범 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) { onDelete() }
        } message: {
            Text("이 아카이브를 정말 삭제할까요?\n(이 작업은 되돌릴 수 없습니다.)")
        }
        .alert("저장되지 않은 변경 사항", isPresented: $showingUnsavedAlert) {
            Button("취소", role: .cancel) { }
            Button("저장하고 나가기", role: .none) { dismiss() }
            Button("저장하지 않고 나가기", role: .destructive) { dismiss() }
        } message: {
            Text("변경 사항이 아직 저장되지 않았습니다.\n저장하시겠습니까?")
        }
    }
}

// MARK: - 📖 앨범 테마 뷰 (1:1 정사각형 사진 + 유동 프레임)
struct AlbumThemeView: View {
    @Binding var items: [ArchiveItem]
    let layoutType: AlbumLayoutType
    @Binding var isEditing: Bool
    @Binding var enlargedItem: ArchiveItem?
    var onCardTapped: (ArchiveItem) -> Void
    var onDeleteItem: (Int64) -> Void
    
    var pageChunks: [[ArchiveItem]] {
        let pageSize = layoutType.rawValue
        var chunks: [[ArchiveItem]] = []
        for index in stride(from: 0, to: items.count, by: pageSize) {
            let chunk = Array(items[index..<min(index + pageSize, items.count)])
            chunks.append(chunk)
        }
        return chunks.isEmpty ? [[]] : chunks
    }
    
    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let totalHeight = geo.size.height
            let isGrid2x3 = (layoutType == .grid2x3)
            let numRows = isGrid2x3 ? 3 : 2
            
            // 여백 계산
            let sideMargin: CGFloat = 20
            let spacingH: CGFloat = 16
            let availableWidth = totalWidth - (sideMargin * 2) - spacingH
            let cardWidth = availableWidth / 2
            
            let spacingV: CGFloat = isGrid2x3 ? 10 : 16
            let captionHeight: CGFloat = isGrid2x3 ? 24 : 30
            let cardVerticalPadding: CGFloat = 18
            
            // 세로 가용 높이를 넘지 않는 최대 1:1 사진 사이즈 산출
            let availableHeightForRows = totalHeight - 20 - (spacingV * CGFloat(numRows - 1))
            let maxPhotoHeight = (availableHeightForRows / CGFloat(numRows)) - captionHeight - cardVerticalPadding
            let maxPhotoWidth = cardWidth - 16
            let photoDimension = max(60, min(maxPhotoWidth, maxPhotoHeight))
            
            let finalCardWidth = photoDimension + 16
            let finalCardHeight = photoDimension + captionHeight + cardVerticalPadding
            
            ZStack {
                TabView {
                    if items.isEmpty {
                        VStack {
                            Text("앨범에 담긴 추억이 없어요!")
                                .foregroundColor(.gray)
                        }
                    } else {
                        ForEach(0..<pageChunks.count, id: \.self) { pageIndex in
                            VStack(spacing: spacingV) {
                                Spacer(minLength: 0)
                                
                                ForEach(0..<numRows, id: \.self) { rowIndex in
                                    let startIndex = rowIndex * 2
                                    let pageItems = pageChunks[pageIndex]
                                    
                                    HStack(spacing: spacingH) {
                                        if startIndex < pageItems.count {
                                            let itemBinding = Binding(
                                                get: { pageItems[startIndex] },
                                                set: { updated in
                                                    if let idx = items.firstIndex(where: { $0.itemId == updated.itemId }) {
                                                        items[idx] = updated
                                                    }
                                                }
                                            )
                                            AlbumCellView(
                                                item: itemBinding,
                                                cardWidth: finalCardWidth,
                                                cardHeight: finalCardHeight,
                                                photoDimension: photoDimension,
                                                isEditing: isEditing,
                                                onTap: { onCardTapped(pageItems[startIndex]) },
                                                onDelete: { onDeleteItem(pageItems[startIndex].itemId) }
                                            )
                                        } else {
                                            Spacer().frame(width: finalCardWidth, height: finalCardHeight)
                                        }
                                        
                                        if startIndex + 1 < pageItems.count {
                                            let itemBinding = Binding(
                                                get: { pageItems[startIndex + 1] },
                                                set: { updated in
                                                    if let idx = items.firstIndex(where: { $0.itemId == updated.itemId }) {
                                                        items[idx] = updated
                                                    }
                                                }
                                            )
                                            AlbumCellView(
                                                item: itemBinding,
                                                cardWidth: finalCardWidth,
                                                cardHeight: finalCardHeight,
                                                photoDimension: photoDimension,
                                                isEditing: isEditing,
                                                onTap: { onCardTapped(pageItems[startIndex + 1]) },
                                                onDelete: { onDeleteItem(pageItems[startIndex + 1].itemId) }
                                            )
                                        } else {
                                            Spacer().frame(width: finalCardWidth, height: finalCardHeight)
                                        }
                                    }
                                }
                                
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.bottom, 20)
                            .tag(pageIndex)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .disabled(enlargedItem != nil)
            }
        }
    }
}

struct AlbumCellView: View {
    @Binding var item: ArchiveItem
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let photoDimension: CGFloat
    let isEditing: Bool
    var onTap: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                // 🌟 완벽한 1:1 정사각형 사진 영역
                Group {
                    if let uiImage = item.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(item.mockColor.opacity(0.85))
                            .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.7)))
                    }
                }
                .frame(width: photoDimension, height: photoDimension)
                .cornerRadius(6)
                .clipped()
                
                // 하단 텍스트 필드/라벨
                if isEditing {
                    TextField("문구", text: Binding(
                        get: { item.caption ?? "" },
                        set: { item.caption = sanitizeInput($0) }
                    ))
                    .font(.system(size: 10, weight: .bold))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: photoDimension, height: 22)
                } else {
                    if let caption = item.caption, !caption.isEmpty {
                        Text(caption)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black.opacity(0.85))
                            .lineLimit(1)
                            .frame(width: photoDimension, height: 20)
                    } else {
                        Spacer().frame(height: 20)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
            .frame(width: cardWidth, height: cardHeight)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
            .onTapGesture { onTap() }
            
            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .background(Color.white.clipShape(Circle()))
                }
                .offset(x: 5, y: -5)
            }
        }
    }
}

// MARK: - ✂️ 스크랩북 테마 뷰
struct ScrapbookThemeView: View {
    @Binding var items: [ArchiveItem]
    @Binding var isEditing: Bool
    @Binding var pageCount: Int
    @Binding var currentPage: Int
    @Binding var enlargedItem: ArchiveItem?
    var onCardTapped: (ArchiveItem) -> Void
    var onDeleteItem: (Int64) -> Void
    
    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pageCount, id: \.self) { pageIndex in
                    ScrapbookPageView(
                        items: $items,
                        pageIndex: pageIndex,
                        isEditing: isEditing,
                        onCardTapped: onCardTapped,
                        onDeleteItem: onDeleteItem
                    )
                    .tag(pageIndex)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .disabled(enlargedItem != nil)
        }
    }
}

struct ScrapbookPageView: View {
    @Binding var items: [ArchiveItem]
    let pageIndex: Int
    let isEditing: Bool
    var onCardTapped: (ArchiveItem) -> Void
    var onDeleteItem: (Int64) -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.opacity(0.3)
                    .cornerRadius(16)
                    .padding(10)
                
                ForEach($items.filter { $0.wrappedValue.pageIndex == pageIndex }) { $item in
                    ScrapbookItemView(item: $item, canvasSize: geo.size, isEditing: isEditing, onTap: {
                        onCardTapped($item.wrappedValue)
                    }, onDelete: {
                        onDeleteItem($item.wrappedValue.itemId)
                    })
                }
            }
        }
    }
}

struct ScrapbookItemView: View {
    @Binding var item: ArchiveItem
    let canvasSize: CGSize
    let isEditing: Bool
    var onTap: () -> Void
    var onDelete: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var magnificationScale: CGFloat = 1.0
    @State private var rotationAngle: Angle = .zero
    
    var body: some View {
        let safeCanvasWidth = canvasSize.width > 0 ? canvasSize.width : 300
        let safeCanvasHeight = canvasSize.height > 0 ? canvasSize.height : 500
        
        let baseWidth: CGFloat = safeCanvasWidth * 0.4
        let currentWidth = baseWidth * CGFloat(item.layout.width) * magnificationScale
        
        return ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Group {
                    if let uiImage = item.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Rectangle()
                            .fill(item.mockColor.opacity(0.8))
                            .frame(width: currentWidth, height: currentWidth * 0.75)
                            .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.6)))
                    }
                }
                .frame(width: currentWidth)
                .cornerRadius(8)
                .clipped()
                
                if isEditing {
                    TextField("문구", text: Binding(
                        get: { item.caption ?? "" },
                        set: { item.caption = sanitizeInput($0) }
                    ))
                    .font(.system(size: 10, weight: .bold))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: currentWidth)
                } else if let caption = item.caption, !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(6)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            
            if isEditing {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .background(Color.white.clipShape(Circle()))
                }
                .offset(x: 5, y: -5)
            }
        }
        .rotationEffect(.degrees(item.layout.rotation) + rotationAngle)
        .position(
            x: (safeCanvasWidth * CGFloat(item.layout.x)).isFinite ? (safeCanvasWidth * CGFloat(item.layout.x)) + dragOffset.width : 150,
            y: (safeCanvasHeight * CGFloat(item.layout.y)).isFinite ? (safeCanvasHeight * CGFloat(item.layout.y)) + dragOffset.height : 250
        )
        .onTapGesture { onTap() }
        .simultaneousGesture(
            isEditing ?
            DragGesture().onChanged { value in
                dragOffset = value.translation
            }.onEnded { value in
                let newX = (safeCanvasWidth * CGFloat(item.layout.x) + value.translation.width) / safeCanvasWidth
                let newY = (safeCanvasHeight * CGFloat(item.layout.y) + value.translation.height) / safeCanvasHeight
                if newX.isFinite && newY.isFinite {
                    item.layout.x = Double(newX)
                    item.layout.y = Double(newY)
                }
                dragOffset = .zero
            } : nil
        )
        .simultaneousGesture(
            isEditing ?
            MagnificationGesture().onChanged { scale in
                magnificationScale = scale
            }.onEnded { scale in
                let newWidth = Double(item.layout.width) * Double(scale)
                if newWidth.isFinite {
                    item.layout.width = min(max(0.15, newWidth), 1.5)
                }
                magnificationScale = 1.0
            } : nil
        )
        .simultaneousGesture(
            isEditing ?
            RotationGesture().onChanged { angle in
                rotationAngle = angle
            }.onEnded { angle in
                if angle.degrees.isFinite {
                    item.layout.rotation += angle.degrees
                }
                rotationAngle = .zero
            } : nil
        )
    }
}

// MARK: - 📸 폴라로이드 테마 뷰
struct PolaroidThemeView: View {
    @Binding var items: [ArchiveItem]
    @Binding var isEditing: Bool
    @Binding var enlargedItem: ArchiveItem?
    var onCardTapped: (ArchiveItem) -> Void
    var onDeleteItem: (Int64) -> Void
    
    var chunkedItems: [[ArchiveItem]] {
        var chunks: [[ArchiveItem]] = []
        for index in stride(from: 0, to: items.count, by: 3) {
            let chunk = Array(items[index..<min(index + 3, items.count)])
            chunks.append(chunk)
        }
        return chunks
    }
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 35) {
                    Spacer().frame(height: 25)
                    
                    if items.isEmpty {
                        Text("아직 걸려있는 사진이 없어요!")
                            .foregroundColor(.gray)
                            .padding(.top, 100)
                    } else {
                        ForEach(0..<chunkedItems.count, id: \.self) { rowIndex in
                            ZStack(alignment: .top) {
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 15))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: 15))
                                }
                                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                
                                HStack(spacing: 14) {
                                    ForEach($items.filter { item in
                                        chunkedItems[rowIndex].contains(where: { $0.id == item.id })
                                    }) { $item in
                                        HangingPolaroidCard(item: $item, isEditing: isEditing, onTap: {
                                            onCardTapped($item.wrappedValue)
                                        }, onDelete: {
                                            onDeleteItem($item.wrappedValue.itemId)
                                        })
                                    }
                                    
                                    if chunkedItems[rowIndex].count < 3 {
                                        ForEach(0..<(3 - chunkedItems[rowIndex].count), id: \.self) { _ in
                                            Spacer().frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    Spacer().frame(height: 30)
                }
            }
            .disabled(enlargedItem != nil)
        }
    }
}

struct HangingPolaroidCard: View {
    @Binding var item: ArchiveItem
    let isEditing: Bool
    var onTap: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        GeometryReader { cardGeo in
            let cardWidth = cardGeo.size.width
            
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(hex: "#C19A6B"))
                        .frame(width: 12, height: 18)
                        .cornerRadius(2)
                        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                        .zIndex(1)
                        .offset(y: 8)
                    
                    VStack(spacing: 5) {
                        Group {
                            if let uiImage = item.uiImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Rectangle()
                                    .fill(item.mockColor.opacity(0.8))
                                    .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.6)))
                            }
                        }
                        .frame(width: cardWidth - 14, height: cardWidth - 14)
                        .clipped()
                        
                        if isEditing {
                            TextField("문구", text: Binding(
                                get: { item.caption ?? "" },
                                set: { item.caption = sanitizeInput($0) }
                            ))
                            .font(.system(size: 9, weight: .bold))
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(height: 16)
                        } else {
                            if let caption = item.caption, !caption.isEmpty {
                                Text(caption)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.black.opacity(0.8))
                                    .lineLimit(1)
                                    .frame(height: 16)
                            } else {
                                Spacer().frame(height: 16)
                            }
                        }
                    }
                    .padding(6)
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                    .rotationEffect(.degrees(item.layout.rotation > 0 ? 3 : -3))
                    .onTapGesture { onTap() }
                }
                
                if isEditing {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .background(Color.white.clipShape(Circle()))
                    }
                    .offset(x: 4, y: 8)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 6. 아카이브 생성 폼
struct CreateAlbumView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var selectedTheme: ArchiveTheme = .album
    @State private var selectedColor: Color = .egMain
    @State private var selectedLayoutType: AlbumLayoutType = .grid2x2
    var onAdd: (String, ArchiveTheme, String, AlbumLayoutType) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.egBase.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("아카이브 이름")
                            .font(.system(size: 15, weight: .bold))
                        TextField("어떤 추억을 담을까요?", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("테마 선택")
                            .font(.system(size: 15, weight: .bold))
                        Picker("테마", selection: $selectedTheme) {
                            ForEach(ArchiveTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    if selectedTheme == .album {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("앨범 프레임 규격")
                                .font(.system(size: 15, weight: .bold))
                            Picker("프레임 규격", selection: $selectedLayoutType) {
                                ForEach(AlbumLayoutType.allCases, id: \.self) { layout in
                                    Text(layout.displayName).tag(layout)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("대표 색상")
                            .font(.system(size: 15, weight: .bold))
                        ColorPicker("아카이브 배경에 쓰일 색상을 골라주세요", selection: $selectedColor)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("새 앨범 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) { Text("취소").foregroundColor(.gray) }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let safeTitle = sanitizeInput(title)
                        let finalTitle = safeTitle.isEmpty ? "무제 앨범" : safeTitle
                        let hexString = colorToHex(selectedColor)
                        onAdd(finalTitle, selectedTheme, hexString, selectedLayoutType)
                        dismiss()
                    }) {
                        Text("만들기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(title.isEmpty ? .gray : .egFunctional)
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func colorToHex(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
