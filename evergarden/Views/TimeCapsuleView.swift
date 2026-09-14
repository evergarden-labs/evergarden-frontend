import SwiftUI
import SpriteKit
import PhotosUI
import MapKit
import CoreLocation
import Combine

// MARK: - 0. SpriteKit / UIKit Hex Extension
extension SKColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
            let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
            let b = CGFloat(hexNumber & 0x0000ff) / 255
            self.init(red: r, green: g, blue: b, alpha: 1.0)
            return
        }
        self.init(white: 0.5, alpha: 1.0)
    }
}

// MARK: - 1. 데이터 모델

enum TimeCapsuleStatus: String, Codable, CaseIterable {
    case sealed = "SEALED"
    case unlockable = "UNLOCKABLE"
    case opened = "OPENED"
    
    var displayName: String {
        switch self {
        case .sealed: return "봉인됨"
        case .unlockable: return "열기 가능"
        case .opened: return "개봉됨"
        }
    }
}

enum UnlockType: String, Codable, CaseIterable {
    case date = "DATE"
    case location = "LOCATION"
    
    var displayName: String {
        switch self {
        case .date: return "날짜 해제"
        case .location: return "위치 해제"
        }
    }
}

struct UnlockCondition: Codable, Equatable {
    let type: UnlockType
    var satisfied: Bool
    var unlockDate: String?
    var lat: Double?
    var lng: Double?
    var radiusMeters: Int?
    var placeName: String?
}

struct TimeCapsuleSummary: Identifiable, Codable, Equatable {
    var id: Int64 { capsuleId }
    let capsuleId: Int64
    let title: String
    var status: TimeCapsuleStatus
    let unlockType: UnlockType
    let thumbnailUrl: String?
    let createdAt: String
    var openedAt: String?
    var unlockDate: String?
    var placeName: String?
    var lat: Double?
    var lng: Double?
}

struct TimeCapsuleDetail: Identifiable, Codable, Equatable {
    var id: Int64 { capsuleId }
    let capsuleId: Int64
    let title: String
    var status: TimeCapsuleStatus
    let unlockType: UnlockType
    let thumbnailUrl: String?
    let createdAt: String
    var openedAt: String?
    let unlockCondition: UnlockCondition
    var content: String?
}

// MARK: - 🌟 보안 및 UI 헬퍼
enum TimeCapsuleSecurityHelper {
    static func sanitize(_ input: String) -> String {
        let dangerousPatterns = ["'", "\"", ";", "--", "/*", "*/", "script", "SELECT", "INSERT", "UPDATE", "DELETE", "DROP", "UNION"]
        var cleanedString = input
        for pattern in dangerousPatterns {
            cleanedString = cleanedString.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        let allowedCharacterSet = CharacterSet.alphanumerics.union(CharacterSet.whitespaces).union(CharacterSet(charactersIn: "가-힣ㄱ-ㅎㅏ-ㅣ.,!?_"))
        let filteredScalars = cleanedString.unicodeScalars.filter { allowedCharacterSet.contains($0) }
        return String(String(filteredScalars).prefix(100))
    }
}

struct TimeCapsuleJellyBackground: View {
    var mainColor: Color = Color(hex: "#4A2E18")
    var subColor: Color = Color(hex: "#E8A598")
    
    var body: some View {
        ZStack {
            Capsule().fill(mainColor)
            Capsule().fill(subColor).padding(2.5)
            Capsule().fill(mainColor.opacity(0.4)).padding(2.5)
            Capsule().fill(subColor)
                .padding(.horizontal, 2.5).padding(.top, 2.5).padding(.bottom, 6)
        }
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
    }
}

// MARK: - 2. API 통신 서비스 (인메모리 지속성 보장)

actor TimeCapsuleService {
    static let shared = TimeCapsuleService()
    
    private var inMemoryCapsules: [TimeCapsuleSummary] = [
        TimeCapsuleSummary(capsuleId: 1, title: "가을 단풍 소원", status: .sealed, unlockType: .date, thumbnailUrl: nil, createdAt: "2026-09-01T00:00:00Z", openedAt: nil, unlockDate: "2026.11.15", placeName: nil, lat: nil, lng: nil),
        TimeCapsuleSummary(capsuleId: 2, title: "광안리 바다 약속", status: .unlockable, unlockType: .location, thumbnailUrl: nil, createdAt: "2026-08-15T00:00:00Z", openedAt: nil, unlockDate: nil, placeName: "광안리 해수욕장", lat: 35.1532, lng: 129.1186),
        TimeCapsuleSummary(capsuleId: 3, title: "새봄 여행 일기", status: .sealed, unlockType: .date, thumbnailUrl: nil, createdAt: "2026-05-10T00:00:00Z", openedAt: nil, unlockDate: "2027.03.01", placeName: nil, lat: nil, lng: nil),
        TimeCapsuleSummary(capsuleId: 4, title: "한라산 백록담 추억", status: .sealed, unlockType: .location, thumbnailUrl: nil, createdAt: "2026-07-01T00:00:00Z", openedAt: nil, unlockDate: nil, placeName: "한라산 정상", lat: 33.3617, lng: 126.5332),
        TimeCapsuleSummary(capsuleId: 5, title: "새해 첫 다짐", status: .sealed, unlockType: .date, thumbnailUrl: nil, createdAt: "2026-01-01T00:00:00Z", openedAt: nil, unlockDate: "2028.01.05", placeName: nil, lat: nil, lng: nil)
    ]
    
    func fetchCapsules() async throws -> [TimeCapsuleSummary] {
        return inMemoryCapsules
    }
    
    func addCapsule(_ capsule: TimeCapsuleSummary) {
        inMemoryCapsules.append(capsule)
    }
    
    func deleteCapsule(id: Int64) {
        inMemoryCapsules.removeAll { $0.capsuleId == id }
    }
    
    func openCapsule(summary: TimeCapsuleSummary) async throws -> TimeCapsuleDetail {
        if let idx = inMemoryCapsules.firstIndex(where: { $0.capsuleId == summary.capsuleId }) {
            inMemoryCapsules[idx].status = .opened
            inMemoryCapsules[idx].openedAt = "2026-09-14T00:00:00Z"
        }
        return TimeCapsuleDetail(
            capsuleId: summary.capsuleId,
            title: summary.title,
            status: .opened,
            unlockType: summary.unlockType,
            thumbnailUrl: nil,
            createdAt: summary.createdAt,
            openedAt: "2026-09-14T00:00:00Z",
            unlockCondition: UnlockCondition(
                type: summary.unlockType,
                satisfied: true,
                unlockDate: summary.unlockDate,
                lat: summary.lat,
                lng: summary.lng,
                radiusMeters: 100,
                placeName: summary.placeName
            ),
            content: "오솔길을 따라 정성스럽게 묻어둔 소중한 기억이 마침내 열렸습니다."
        )
    }
}

// MARK: - 3. SpriteKit 오솔길 트레일 씬

final class TimeCapsuleTrailScene: SKScene {
    var capsules: [TimeCapsuleSummary] = []
    var onSelectCapsule: ((TimeCapsuleSummary) -> Void)?
    
    private let cameraNode = SKCameraNode()
    private let worldNode = SKNode()
    private var totalWorldHeight: CGFloat = 1200
    private var previousTouchY: CGFloat?
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: "#5B8C46")
        scaleMode = .resizeFill
        
        if cameraNode.parent == nil {
            addChild(worldNode)
            addChild(cameraNode)
            camera = cameraNode
        }
        redrawWorld()
    }
    
    func updateData(_ newCapsules: [TimeCapsuleSummary]) {
        self.capsules = newCapsules
        redrawWorld()
    }
    
    func redrawWorld() {
        worldNode.removeAllChildren()
        guard size.width > 50, size.height > 50 else { return }
        
        let stepHeight: CGFloat = 190
        let count = max(capsules.count, 4)
        totalWorldHeight = CGFloat(count + 1) * stepHeight + size.height * 0.45
        
        drawWindingPath(stepHeight: stepHeight, count: count)
        drawSceneryDecorations(stepHeight: stepHeight, count: count)
        
        let sortedCapsules = capsules.sorted {
            if $0.status == .unlockable && $1.status != .unlockable { return true }
            if $0.status != .unlockable && $1.status == .unlockable { return false }
            return ($0.unlockDate ?? $0.createdAt) < ($1.unlockDate ?? $1.createdAt)
        }
        
        for (index, capsule) in sortedCapsules.enumerated() {
            let progress = CGFloat(index + 1) / CGFloat(count + 1)
            let yPos = totalWorldHeight - (progress * CGFloat(count) * stepHeight) - 80
            
            let centerX = size.width * 0.5 + sin(progress * .pi * 3.0) * (size.width * 0.22)
            let isLeft = index % 2 == 0
            
            let bottleX = isLeft ? centerX - 65 : centerX + 65
            createGlassBottleNode(capsule: capsule, position: CGPoint(x: bottleX, y: yPos))
            
            let signX = isLeft ? centerX + 75 : centerX - 75
            createWoodenSignNode(capsule: capsule, position: CGPoint(x: signX, y: yPos + 8))
        }
        
        let initialY = totalWorldHeight - size.height * 0.5
        cameraNode.position = CGPoint(x: size.width * 0.5, y: max(size.height * 0.5, initialY))
    }
    
    private func drawWindingPath(stepHeight: CGFloat, count: Int) {
        let path = CGMutablePath()
        let steps = 100
        let startY = totalWorldHeight
        let endY: CGFloat = 0
        
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let y = startY - t * (startY - endY)
            let progress = (totalWorldHeight - y) / (CGFloat(count) * stepHeight)
            let x = size.width * 0.5 + sin(progress * .pi * 3.0) * (size.width * 0.22)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        let trailBase = SKShapeNode(path: path)
        trailBase.lineWidth = 110
        trailBase.strokeColor = SKColor(hex: "#C69E6D")
        trailBase.lineCap = .round
        trailBase.lineJoin = .round
        worldNode.addChild(trailBase)
        
        let trailInner = SKShapeNode(path: path)
        trailInner.lineWidth = 85
        trailInner.strokeColor = SKColor(hex: "#B88E5B")
        trailInner.lineCap = .round
        trailInner.lineJoin = .round
        worldNode.addChild(trailInner)
    }
    
    private func drawSceneryDecorations(stepHeight: CGFloat, count: Int) {
        for i in 0...(count * 2) {
            let y = totalWorldHeight - CGFloat(i) * (stepHeight * 0.6) - 50
            let isLeft = i % 2 == 0
            let x = isLeft ? CGFloat.random(in: 20...50) : size.width - CGFloat.random(in: 20...50)
            
            let bush = SKShapeNode(circleOfRadius: CGFloat.random(in: 22...30))
            bush.fillColor = SKColor(hex: i % 3 == 0 ? "#3E6B2E" : "#4B7F36")
            bush.strokeColor = SKColor(hex: "#2F5220")
            bush.lineWidth = 2
            bush.position = CGPoint(x: x, y: y)
            worldNode.addChild(bush)
        }
    }
    
    private func createGlassBottleNode(capsule: TimeCapsuleSummary, position: CGPoint) {
        let node = SKNode()
        node.position = position
        node.name = "capsule_\(capsule.capsuleId)"
        
        let soil = SKShapeNode(ellipseOf: CGSize(width: 54, height: 24))
        soil.fillColor = SKColor(hex: "#6B4423")
        soil.strokeColor = SKColor(hex: "#4A2E18")
        soil.position = CGPoint(x: 0, y: -18)
        soil.name = node.name
        node.addChild(soil)
        
        let bottle = SKShapeNode(rectOf: CGSize(width: 44, height: 56), cornerRadius: 12)
        bottle.fillColor = SKColor(hex: "#E0F2FE").withAlphaComponent(0.85)
        bottle.strokeColor = SKColor(hex: "#94A3B8")
        bottle.lineWidth = 2
        bottle.name = node.name
        node.addChild(bottle)
        
        let cork = SKShapeNode(rectOf: CGSize(width: 22, height: 10), cornerRadius: 3)
        cork.fillColor = SKColor(hex: "#B07D4F")
        cork.strokeColor = SKColor(hex: "#784E29")
        cork.position = CGPoint(x: 0, y: 30)
        cork.name = node.name
        node.addChild(cork)
        
        // 🌟 개별 캡슐 상태에 따른 고유 아이콘 렌더링
        if capsule.status == .opened {
            let flower = SKLabelNode(text: "🌸")
            flower.fontSize = 24
            flower.position = CGPoint(x: 0, y: -10)
            flower.name = node.name
            node.addChild(flower)
        } else if capsule.status == .unlockable {
            let sprout = SKLabelNode(text: "🌱")
            sprout.fontSize = 22
            sprout.position = CGPoint(x: 0, y: -8)
            sprout.name = node.name
            node.addChild(sprout)
            
            let glow = SKShapeNode(circleOfRadius: 26)
            glow.fillColor = SKColor.yellow.withAlphaComponent(0.3)
            glow.strokeColor = .clear
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.25, duration: 0.6),
                SKAction.scale(to: 0.85, duration: 0.6)
            ])
            glow.run(SKAction.repeatForever(pulse))
            node.addChild(glow)
        } else {
            let seed = SKLabelNode(text: capsule.unlockType == .location ? "📍" : "🌰")
            seed.fontSize = 18
            seed.position = CGPoint(x: 0, y: -10)
            seed.name = node.name
            node.addChild(seed)
        }
        
        worldNode.addChild(node)
    }
    
    private func createWoodenSignNode(capsule: TimeCapsuleSummary, position: CGPoint) {
        let node = SKNode()
        node.position = position
        node.name = "capsule_\(capsule.capsuleId)"
        
        let pole = SKShapeNode(rectOf: CGSize(width: 8, height: 36))
        pole.fillColor = SKColor(hex: "#6B4423")
        pole.strokeColor = SKColor(hex: "#4A2E18")
        pole.position = CGPoint(x: 0, y: -10)
        pole.name = node.name
        node.addChild(pole)
        
        let board = SKShapeNode(rectOf: CGSize(width: 84, height: 28), cornerRadius: 6)
        board.fillColor = SKColor(hex: "#87553A")
        board.strokeColor = SKColor(hex: "#4A2E18")
        board.lineWidth = 2
        board.position = CGPoint(x: 0, y: 10)
        board.name = node.name
        node.addChild(board)
        
        let labelText = capsule.unlockType == .location ? (capsule.placeName ?? "지정 위치") : (capsule.unlockDate ?? String(capsule.createdAt.prefix(10)).replacingOccurrences(of: "-", with: "."))
        let textLabel = SKLabelNode(text: labelText)
        textLabel.fontName = "AppleSDGothicNeo-Bold"
        textLabel.fontSize = 10
        textLabel.fontColor = SKColor(hex: "#FDE68A")
        textLabel.position = CGPoint(x: 0, y: 6)
        textLabel.name = node.name
        node.addChild(textLabel)
        
        worldNode.addChild(node)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let view = view else { return }
        previousTouchY = touch.location(in: view).y
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let view = view, let prevY = previousTouchY else { return }
        let currentY = touch.location(in: view).y
        let dy = currentY - prevY
        
        cameraNode.position.y += dy
        previousTouchY = currentY
        
        let minY = size.height * 0.5
        let maxY = max(minY, totalWorldHeight - size.height * 0.5)
        if cameraNode.position.y < minY { cameraNode.position.y = minY }
        if cameraNode.position.y > maxY { cameraNode.position.y = maxY }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: worldNode)
        let hitNodes = worldNode.nodes(at: touchLocation)
        
        for node in hitNodes {
            if let name = node.name, name.hasPrefix("capsule_"),
               let id = Int64(name.replacingOccurrences(of: "capsule_", with: "")),
               let target = capsules.first(where: { $0.capsuleId == id }) {
                
                let bounce = SKAction.sequence([
                    SKAction.scale(to: 1.15, duration: 0.08),
                    SKAction.scale(to: 1.0, duration: 0.08)
                ])
                node.run(bounce) { [weak self] in
                    self?.onSelectCapsule?(target)
                }
                break
            }
        }
        previousTouchY = nil
    }
}

// MARK: - 4. 타임캡슐 메인 뷰

struct TimeCapsuleView: View {
    @State private var capsules: [TimeCapsuleSummary] = []
    @State private var selectedCapsule: TimeCapsuleSummary? = nil
    @State private var isShowingCreateSheet = false
    @State private var scene = TimeCapsuleTrailScene()
    @State private var hasLoadedInitialData = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { screenGeo in
                let availableWidth = screenGeo.size.width
                
                ZStack {
                    SpriteView(scene: scene)
                        .id(capsules.count)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("타임캡슐 오솔길")
                                    .font(.system(size: availableWidth * 0.065, weight: .heavy))
                                    .foregroundColor(Color(hex: "#4A2E18"))
                                Text("기다림의 시간과 장소를 따라 싹을 틔웁니다")
                                    .font(.system(size: availableWidth * 0.032, weight: .bold))
                                    .foregroundColor(Color(hex: "#5C3A21"))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, availableWidth * 0.05)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FDE68A").opacity(0.85), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Button(action: { isShowingCreateSheet = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 15, weight: .heavy))
                                    Text("캡슐 묻기")
                                        .font(.system(size: 15, weight: .heavy))
                                }
                                .foregroundColor(Color(hex: "#4A2E18"))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(TimeCapsuleJellyBackground(mainColor: Color(hex: "#87553A"), subColor: Color(hex: "#FDE68A")))
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 95)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedCapsule) { capsule in
                TimeCapsuleDetailModal(capsuleSummary: capsule, onOpened: { updated in
                    // 🌟 선택한 특정 ID만 정확히 개봉 상태로 업데이트
                    if let index = capsules.firstIndex(where: { $0.capsuleId == updated.capsuleId }) {
                        capsules[index].status = .opened
                        capsules[index].openedAt = updated.openedAt
                        scene.updateData(capsules)
                    }
                }, onDeleted: { deletedId in
                    Task {
                        await TimeCapsuleService.shared.deleteCapsule(id: deletedId)
                    }
                    capsules.removeAll { $0.capsuleId == deletedId }
                    scene.updateData(capsules)
                })
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                CreateTimeCapsuleView { newCapsule in
                    Task {
                        await TimeCapsuleService.shared.addCapsule(newCapsule)
                    }
                    capsules.append(newCapsule)
                    scene.updateData(capsules)
                }
            }
            .onAppear {
                if !hasLoadedInitialData {
                    hasLoadedInitialData = true
                    loadInitialData()
                }
            }
        }
    }
    
    private func loadInitialData() {
        Task {
            let loaded = try? await TimeCapsuleService.shared.fetchCapsules()
            await MainActor.run {
                self.capsules = loaded ?? []
                self.scene.updateData(self.capsules)
                self.scene.onSelectCapsule = { selected in
                    self.selectedCapsule = selected
                }
            }
        }
    }
}

// MARK: - 5. 상세 확인 및 개봉 모달 (TC-03, TC-05, TC-06, TC-07)

struct TimeCapsuleDetailModal: View {
    let capsuleSummary: TimeCapsuleSummary
    var onOpened: (TimeCapsuleDetail) -> Void
    var onDeleted: (Int64) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var detail: TimeCapsuleDetail? = nil
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#D2A679").ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                } else if let detail = detail {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text(detail.status == .sealed ? "🌰" : (detail.status == .unlockable ? "🌱" : "🌸"))
                                .font(.system(size: 55))
                            
                            Text(detail.title)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(Color(hex: "#4A2E18"))
                            
                            let subtitle = detail.unlockType == .date ? "개봉 예정일: \(capsuleSummary.unlockDate ?? String(detail.createdAt.prefix(10)))" : "지정 위치: \(capsuleSummary.placeName ?? "설정 위치")"
                            Text(subtitle)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#7A4E29"))
                        }
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("해제 조건 상태")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#4A2E18"))
                            
                            HStack {
                                Image(systemName: detail.unlockType == .date ? "calendar" : "mappin.and.ellipse")
                                Text(detail.status == .opened ? "이미 활짝 개봉되었습니다" : (detail.status == .unlockable ? "조건이 충족되어 열 수 있습니다!" : (detail.unlockType == .date ? "지정 날짜까지 봉인 상태입니다" : "지정 위치에 도착해야 열립니다")))
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text(detail.status.displayName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color(hex: detail.status == .opened ? "#81B29A" : (detail.status == .unlockable ? "#E07A5F" : "#7A5C43"))))
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(12)
                        
                        if detail.status == .opened {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("타임캡슐 속 메시지")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: "#4A2E18"))
                                    
                                    Text(detail.content ?? "내용이 없습니다.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.black.opacity(0.85))
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                }
                            }
                        } else {
                            VStack(spacing: 8) {
                                Spacer()
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(hex: "#7A4E29"))
                                Text(detail.unlockType == .date ? "개봉일이 도래하면\n이야기와 사진이 활짝 열립니다." : "설정된 장소 부근에 방문하면\n타임캡슐이 열릴 수 있습니다.")
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(hex: "#7A4E29"))
                                Spacer()
                            }
                        }
                        
                        Spacer()
                        
                        if detail.status == .unlockable {
                            Button(action: openCapsule) {
                                Text("타임캡슐 개봉하기")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(TimeCapsuleJellyBackground(mainColor: Color(hex: "#E07A5F"), subColor: Color(hex: "#F28482")))
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("타임캡슐 확인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(Color(hex: "#4A2E18"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("타임캡슐 삭제", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    onDeleted(capsuleSummary.capsuleId)
                    dismiss()
                }
            } message: {
                Text("타임캡슐을 오솔길에서 파내어 영구히 삭제하시겠습니까?")
            }
            .onAppear(perform: loadDetail)
        }
    }
    
    private func loadDetail() {
        Task {
            let res = try? await TimeCapsuleService.shared.openCapsule(summary: capsuleSummary)
            await MainActor.run {
                self.detail = res
                self.detail?.status = capsuleSummary.status
                self.isLoading = false
            }
        }
    }
    
    private func openCapsule() {
        guard var current = detail else { return }
        current.status = .opened
        current.openedAt = "2026-09-14T00:00:00Z"
        self.detail = current
        onOpened(current)
    }
}

// MARK: - 6. 타임캡슐 생성 뷰

struct CreateTimeCapsuleView: View {
    @Environment(\.dismiss) var dismiss
    var onCreated: (TimeCapsuleSummary) -> Void
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var unlockType: UnlockType = .date
    @State private var unlockDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    )
    @State private var currentCenterCoordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    @State private var exactAddress: String = "서울특별시 중구 세종대로 110"
    @State private var searchQuery: String = ""
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @State private var isSearching = false
    @State private var geocodeWorkItem: DispatchWorkItem?
    
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#D2A679").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("캡슐 이름 *")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#4A2E18"))
                            TextField("어떤 기억을 묻어둘까요?", text: $title)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("해제 방식 선택")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#4A2E18"))
                            Picker("해제 조건", selection: $unlockType) {
                                ForEach(UnlockType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        if unlockType == .date {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("개봉 예정일 선택")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#4A2E18"))
                                DatePicker("개봉 날짜", selection: $unlockDate, in: Date()..., displayedComponents: .date)
                                    .datePickerStyle(.graphical)
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(10)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("개봉 장소 검색 및 핀 설정")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#4A2E18"))
                                
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    TextField("장소나 주소 검색 (예: 해운대, 광화문)", text: $searchQuery)
                                        .onChange(of: searchQuery) { _, query in
                                            searchCompleter.search(query: query)
                                            isSearching = !query.isEmpty
                                        }
                                    if !searchQuery.isEmpty {
                                        Button(action: {
                                            searchQuery = ""
                                            isSearching = false
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(8)
                                
                                if isSearching && !searchCompleter.results.isEmpty {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(searchCompleter.results.prefix(4), id: \.self) { result in
                                            Button(action: {
                                                selectSearchResult(result)
                                            }) {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.title)
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(Color(hex: "#4A2E18"))
                                                    Text(result.subtitle)
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 10)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            Divider()
                                        }
                                    }
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                                }
                                
                                ZStack {
                                    Map(position: $cameraPosition)
                                        .frame(height: 200)
                                        .cornerRadius(12)
                                        .onMapCameraChange(frequency: .onEnd) { context in
                                            self.currentCenterCoordinate = context.camera.centerCoordinate
                                            scheduleReverseGeocoding(for: context.camera.centerCoordinate)
                                        }
                                    
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(.red)
                                        .offset(y: -14)
                                        .shadow(radius: 3)
                                }
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                    Text(exactAddress)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color(hex: "#4A2E18"))
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.85))
                                .cornerRadius(8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("남겨둘 이야기 *")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#4A2E18"))
                            TextEditor(text: $content)
                                .frame(height: 110)
                                .padding(6)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("오솔길에 캡슐 묻기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(Color(hex: "#4A2E18"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("묻기") {
                        submitCapsule()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#4A2E18"))
                }
            }
            .alert("입력 확인", isPresented: $showValidationAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private func submitCapsule() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanTitle.isEmpty {
            validationMessage = "캡슐 이름을 입력해 주세요."
            showValidationAlert = true
            return
        }
        
        if cleanContent.isEmpty {
            validationMessage = "남겨둘 이야기를 작성해 주세요."
            showValidationAlert = true
            return
        }
        
        let safeTitle = TimeCapsuleSecurityHelper.sanitize(cleanTitle)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        
        let isTodayOrPast = unlockType == .date && formatter.string(from: unlockDate) <= formatter.string(from: Date())
        let initialStatus: TimeCapsuleStatus = isTodayOrPast ? .unlockable : .sealed
        
        let newEntity = TimeCapsuleSummary(
            capsuleId: Int64.random(in: 100...999),
            title: safeTitle,
            status: initialStatus,
            unlockType: unlockType,
            thumbnailUrl: nil,
            createdAt: formatter.string(from: Date()),
            openedAt: nil,
            unlockDate: unlockType == .date ? formatter.string(from: unlockDate) : nil,
            placeName: unlockType == .location ? exactAddress : nil,
            lat: unlockType == .location ? currentCenterCoordinate.latitude : nil,
            lng: unlockType == .location ? currentCenterCoordinate.longitude : nil
        )
        onCreated(newEntity)
        dismiss()
    }
    
    private func selectSearchResult(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first, error == nil else { return }
            let coord = mapItem.location.coordinate
            self.currentCenterCoordinate = coord
            self.cameraPosition = .region(MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)))
            self.exactAddress = "\(completion.title) (\(completion.subtitle))"
            self.isSearching = false
            self.searchQuery = ""
        }
    }
    
    private func scheduleReverseGeocoding(for coordinate: CLLocationCoordinate2D) {
        geocodeWorkItem?.cancel()
        let work = DispatchWorkItem {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "\(coordinate.latitude), \(coordinate.longitude)"
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let mapItem = response?.mapItems.first, error == nil else {
                    self.exactAddress = String(format: "위도: %.4f, 경도: %.4f", coordinate.latitude, coordinate.longitude)
                    return
                }
                if let name = mapItem.name, !name.isEmpty {
                    self.exactAddress = name
                } else {
                    self.exactAddress = String(format: "위도: %.4f, 경도: %.4f", coordinate.latitude, coordinate.longitude)
                }
            }
        }
        geocodeWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }
}

// MARK: - 7. LocationSearchCompleter

final class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    func search(query: String) {
        if query.isEmpty {
            results = []
        } else {
            completer.queryFragment = query
        }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.results = []
    }
}
