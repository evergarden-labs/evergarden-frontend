import SwiftUI
import SpriteKit

// MARK: - 1. API 명세서 기반 데이터 모델
enum ArchiveTheme: String, CaseIterable, Hashable {
    case polaroid = "POLAROID"
    case album = "ALBUM"
    case scrapbook = "SCRAPBOOK"
    
    var displayName: String {
        switch self {
        case .polaroid: return "폴라로이드"
        case .album: return "앨범"
        case .scrapbook: return "스크랩북"
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
}

struct ArchiveLayout: Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var rotation: Double
}

struct ArchiveItem: Identifiable {
    let id = UUID()
    let itemId: Int64
    var sortOrder: Int
    var layout: ArchiveLayout
    var caption: String?
    var isCover: Bool
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

// MARK: - 2. SpriteKit: 책장 목록 씬
class ArchiveShelfScene: SKScene {
    var archives: [ArchiveSummary] = []
    var onArchiveSelected: ((ArchiveSummary) -> Void)?
    
    let camNode = SKCameraNode()
    var previousTouchLocation: CGPoint?
    var contentHeight: CGFloat = 0
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(hex: "#8B6B4A")
        if camNode.parent == nil {
            self.camera = camNode
            addChild(camNode)
        }
        camNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        drawShelves()
    }
    
    func drawShelves() {
        guard size.width > 50 else { return } // 🌟 0초 로딩 시점의 렌더링 방지
        
        // 기존 선반 깔끔하게 지우기 (카메라 제외)
        children.forEach { if $0 != camNode { $0.removeFromParent() } }
        
        let shelfHeight: CGFloat = 180
        contentHeight = CGFloat(archives.count) * shelfHeight + 300
        var currentY: CGFloat = size.height - 100
        
        for archive in archives {
            let shelf = SKShapeNode(rectOf: CGSize(width: size.width, height: 15))
            shelf.fillColor = SKColor(hex: "#D9A05B")
            shelf.strokeColor = SKColor(hex: "#5C3A21")
            shelf.lineWidth = 2
            shelf.position = CGPoint(x: size.width / 2, y: currentY - 50)
            addChild(shelf)
            
            let albumNode = SKShapeNode(rectOf: CGSize(width: 80, height: 100), cornerRadius: 4)
            albumNode.fillColor = SKColor(hex: archive.primaryColor ?? "#E5C39C")
            albumNode.strokeColor = .white
            albumNode.lineWidth = 2
            albumNode.position = CGPoint(x: size.width / 2, y: currentY + 10)
            albumNode.name = "archive_\(archive.archiveId)"
            addChild(albumNode)
            
            let titleLabel = SKLabelNode(text: archive.title)
            titleLabel.fontName = "Courier-Bold"
            titleLabel.fontSize = 14
            titleLabel.fontColor = .white
            titleLabel.position = CGPoint(x: 0, y: -20)
            titleLabel.name = "archive_\(archive.archiveId)"
            albumNode.addChild(titleLabel)
            
            currentY -= shelfHeight
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let view = self.view else { return }
        previousTouchLocation = touch.location(in: view) // 🌟 씬 내부 좌표가 아닌 절대 화면 좌표 사용
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let view = self.view, let previousLocation = previousTouchLocation else { return }
        let currentLocation = touch.location(in: view)
        let dy = currentLocation.y - previousLocation.y
        camNode.position.y += dy
        previousTouchLocation = currentLocation
        
        // 🌟 카메라 무한 이탈(Infinity) 버그 완벽 방어!
        let minY = size.height / 2
        let maxY = max(minY, contentHeight - size.height / 2)
        if camNode.position.y > maxY { camNode.position.y = maxY }
        if camNode.position.y < minY { camNode.position.y = minY }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        for node in touchedNodes {
            if let name = node.name, name.hasPrefix("archive_") {
                let idString = name.replacingOccurrences(of: "archive_", with: "")
                if let id = Int64(idString), let selected = archives.first(where: { $0.archiveId == id }) {
                    onArchiveSelected?(selected)
                }
                break
            }
        }
        previousTouchLocation = nil
    }
}

// MARK: - 3. SpriteKit: 자유 배치 캔버스 씬
class ArchiveCanvasScene: SKScene {
    var items: [ArchiveItem] = []
    var onItemMoved: ((Int64, Double, Double) -> Void)?
    var getIsEditing: (() -> Bool)?
    var selectedNode: SKNode?
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(hex: "#F4E3C5")
        drawItems()
    }
    
    func drawItems() {
        guard size.width > 50 else { return } // 🌟 크기 축소 버그 방어
        self.removeAllChildren()
        
        for item in items {
            let pixelX = CGFloat(item.layout.x) * size.width
            let pixelY = CGFloat(1.0 - item.layout.y) * size.height
            let pixelWidth = CGFloat(item.layout.width) * size.width
            let pixelHeight = CGFloat(item.layout.height) * size.width
            
            let photoNode = SKShapeNode(rectOf: CGSize(width: pixelWidth, height: pixelHeight), cornerRadius: 8)
            photoNode.fillColor = .white
            photoNode.strokeColor = SKColor(hex: "#CCCCCC")
            photoNode.lineWidth = 2
            
            photoNode.position = CGPoint(x: pixelX, y: pixelY)
            photoNode.zRotation = CGFloat(item.layout.rotation * .pi / 180)
            photoNode.zPosition = CGFloat(item.sortOrder)
            photoNode.name = "item_\(item.itemId)"
            
            let innerImage = SKShapeNode(rectOf: CGSize(width: pixelWidth - 10, height: pixelHeight - 30))
            innerImage.fillColor = SKColor(hex: "#A2C3E8")
            innerImage.strokeColor = .clear
            innerImage.position = CGPoint(x: 0, y: 10)
            innerImage.name = photoNode.name
            photoNode.addChild(innerImage)
            
            addChild(photoNode)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard getIsEditing?() == true, let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let touchedNodes = nodes(at: location).filter { $0.name?.hasPrefix("item_") == true }
        if let topNode = touchedNodes.max(by: { $0.zPosition < $1.zPosition }) {
            selectedNode = topNode.parent == self ? topNode : topNode.parent
            selectedNode?.run(SKAction.scale(to: 1.05, duration: 0.1))
            selectedNode?.zPosition = 999
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard getIsEditing?() == true, let touch = touches.first, let node = selectedNode else { return }
        node.position = touch.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard getIsEditing?() == true, let node = selectedNode else { return }
        node.run(SKAction.scale(to: 1.0, duration: 0.1))
        
        if let name = node.name {
            let idString = name.replacingOccurrences(of: "item_", with: "")
            if let id = Int64(idString) {
                let ratioX = Double(node.position.x / size.width)
                let ratioY = Double(1.0 - (node.position.y / size.height))
                onItemMoved?(id, ratioX, ratioY)
            }
        }
        selectedNode = nil
    }
}

// MARK: - 4. SwiftUI 래퍼 뷰
struct ArchiveView: View {
    @State private var isShowingCreateAlbum = false
    @State private var selectedArchive: ArchiveSummary? = nil
    
    @State private var archives: [ArchiveSummary] = [
        ArchiveSummary(archiveId: 1, title: "오사카 미식 탐험", theme: .album, primaryColor: "#F197A9", coverImageUrl: nil, startDate: "2026-12-20", endDate: "2026-12-23", itemCount: 42, collaborationStatus: .open, myRole: "OWNER"),
        ArchiveSummary(archiveId: 2, title: "제주도 드라이브", theme: .polaroid, primaryColor: "#87553A", coverImageUrl: nil, startDate: "2026-08-15", endDate: "2026-08-18", itemCount: 28, collaborationStatus: .closed, myRole: "EDITOR"),
        ArchiveSummary(archiveId: 3, title: "빈 스크랩북", theme: .scrapbook, primaryColor: "#B88F66", coverImageUrl: nil, startDate: nil, endDate: nil, itemCount: 0, collaborationStatus: .none, myRole: "OWNER")
    ]
    
    // 🌟 씬을 옵셔널로 선언하여 GeometryReader 안에서 크기가 확정되었을 때만 만듭니다!
    @State private var shelfScene: ArchiveShelfScene? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.egBase.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 상단 헤더 복구 완!
                    HStack(alignment: .bottom) {
                        Text("나의 아카이브")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.egFunctional)
                        
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.egMain)
                            .font(.system(size: 24))
                            .offset(y: -4)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 15)
                    
                    GeometryReader { geo in
                        // 🌟 화면 사이즈가 확실해졌을 때만 씬을 렌더링
                        if let scene = shelfScene {
                            SpriteView(scene: scene)
                                .ignoresSafeArea(edges: .bottom)
                        } else {
                            Color.clear.onAppear {
                                let newScene = ArchiveShelfScene(size: geo.size)
                                newScene.scaleMode = .resizeFill
                                newScene.archives = archives
                                newScene.onArchiveSelected = { archive in
                                    selectedArchive = archive
                                }
                                shelfScene = newScene
                            }
                        }
                    }
                    .onChange(of: archives) { _, newArchives in
                        shelfScene?.archives = newArchives
                        shelfScene?.drawShelves()
                    }
                }
                
                // 플로팅 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { isShowingCreateAlbum = true }) {
                            Text("+ 새 앨범 추가")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.egFunctional)
                                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1.5)
                                .padding(.horizontal, 26)
                                .padding(.vertical, 14)
                                .offset(y: -2)
                                .background(JellyButtonBackground())
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 60)
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
                CreateAlbumView { newTitle, newTheme, newColorHex in
                    let newArchive = ArchiveSummary(archiveId: Int64(archives.count + 1), title: newTitle, theme: newTheme, primaryColor: newColorHex, coverImageUrl: nil, startDate: nil, endDate: nil, itemCount: 0, collaborationStatus: .none, myRole: "OWNER")
                    archives.append(newArchive)
                }
            }
        }
    }
}

// MARK: - 5. 상세 화면 래퍼
struct ArchiveDetailView: View {
    let archive: ArchiveSummary
    var onDelete: () -> Void
    
    @State private var items: [ArchiveItem] = [
        ArchiveItem(itemId: 101, sortOrder: 1, layout: ArchiveLayout(x: 0.3, y: 0.3, width: 0.4, height: 0.25, rotation: -5), caption: nil, isCover: true),
        ArchiveItem(itemId: 102, sortOrder: 2, layout: ArchiveLayout(x: 0.7, y: 0.5, width: 0.4, height: 0.25, rotation: 8), caption: nil, isCover: false)
    ]
    
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    // 🌟 상세 씬도 마찬가지로 크기가 확정된 후에만 만듭니다!
    @State private var canvasScene: ArchiveCanvasScene? = nil
    
    var body: some View {
        ZStack {
            Color(hex: archive.primaryColor ?? "#EFEFEF").ignoresSafeArea()
            
            GeometryReader { geo in
                if let scene = canvasScene {
                    SpriteView(scene: scene)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(16)
                        .padding()
                } else {
                    Color.clear.onAppear {
                        let newScene = ArchiveCanvasScene(size: geo.size)
                        newScene.scaleMode = .resizeFill
                        newScene.items = items
                        newScene.getIsEditing = { isEditing }
                        newScene.onItemMoved = { id, newX, newY in
                            if let index = items.firstIndex(where: { $0.itemId == id }) {
                                items[index].layout.x = newX
                                items[index].layout.y = newY
                            }
                        }
                        canvasScene = newScene
                    }
                }
            }
            .onChange(of: isEditing) { _, editing in
                canvasScene?.getIsEditing = { editing }
            }
            .onChange(of: items.count) { _, _ in
                canvasScene?.items = items
                canvasScene?.drawItems()
            }
            
            // 🌟 앨범 조작 패널 오버레이
            VStack {
                HStack {
                    if isEditing {
                        Button(action: { showingDeleteAlert = true }) {
                            Text("앨범 삭제")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .offset(y: -1)
                                .background(JellyButtonBackground(mainColor: Color.red.opacity(0.15), subColor: Color.white.opacity(0.9)))
                        }
                        .padding(.leading, 24)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if isEditing {
                            self.items = canvasScene?.items ?? items
                            print("💾 배치 저장 완료!")
                        }
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "완료" : "편집")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isEditing ? .egFunctional : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .offset(y: -1)
                            .background(JellyButtonBackground(mainColor: Color.gray.opacity(0.2), subColor: Color.white.opacity(0.95)))
                    }
                    .padding(.trailing, 24)
                }
                .padding(.top, 20)
                
                Spacer()
                
                if isEditing {
                    HStack {
                        Button(action: {
                            let newItem = ArchiveItem(
                                itemId: Int64.random(in: 200...999),
                                sortOrder: items.count + 1,
                                layout: ArchiveLayout(x: 0.5, y: 0.5, width: 0.4, height: 0.25, rotation: Double.random(in: -10...10)),
                                caption: "새 사진",
                                isCover: false
                            )
                            items.append(newItem)
                        }) {
                            Text("+ 사진 추가")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.egFunctional)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .offset(y: -1)
                                .background(JellyButtonBackground())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationTitle(archive.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("앨범 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("이 아카이브를 정말 삭제할까요?\n(이 작업은 되돌릴 수 없습니다.)")
        }
    }
}

// MARK: - 6. 아카이브 생성 폼
struct CreateAlbumView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var selectedTheme: ArchiveTheme = .album
    @State private var selectedColor: Color = .egMain
    var onAdd: (String, ArchiveTheme, String) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.egBase.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("아카이브 이름")
                            .font(.system(size: 16, weight: .bold))
                        TextField("어떤 추억을 담을까요?", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("테마 선택")
                            .font(.system(size: 16, weight: .bold))
                        Picker("테마", selection: $selectedTheme) {
                            ForEach(ArchiveTheme.allCases, id: \.self) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("대표 색상 (Primary Color)")
                            .font(.system(size: 16, weight: .bold))
                        ColorPicker("아카이브 배경에 쓰일 색상을 골라주세요", selection: $selectedColor)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("새 앨범 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) { Text("취소").foregroundColor(.gray) }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let hexString = colorToHex(selectedColor)
                        onAdd(title, selectedTheme, hexString)
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
