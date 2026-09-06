import SwiftUI
import SpriteKit

// MARK: - 0. SpriteKit용 헥사코드 색상 확장
extension SKColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}

// 🚨 GrowthStage와 TimeCapsuleItem은 Models.swift에 있으므로 생략 🚨

// MARK: - 1. 하이퀄리티 SpriteKit 씬
class TimeCapsuleScene: SKScene {
    var capsules: [TimeCapsuleItem] = []
    let camNode = SKCameraNode()
    var previousTouchLocation: CGPoint?
    var contentHeight: CGFloat = 0
    
    override func didMove(to view: SKView) {
        self.backgroundColor = SKColor(hex: "#62974F")
        self.camera = camNode
        addChild(camNode)
        
        let spacing: CGFloat = 280
        contentHeight = CGFloat(capsules.count) * spacing + 500
        
        drawBackgroundBushes()
        drawDirtPath(spacing: spacing)
        
        let now = Date()
        var closestIndex = 0
        var minTimeDifference: TimeInterval = .greatestFiniteMagnitude
        
        // 과거(위)에서 미래(아래)로 배치
        for (index, capsule) in capsules.enumerated() {
            let yPos = (contentHeight / 2) - 300 - (CGFloat(index) * spacing)
            let xPos = sin(CGFloat(index) * 1.5) * 100
            
            let capsuleNode = createCapsuleNode(capsule: capsule)
            capsuleNode.position = CGPoint(x: xPos, y: yPos)
            if index % 2 == 0 { capsuleNode.zRotation = -0.05 }
            else { capsuleNode.zRotation = 0.05 }
            
            addChild(capsuleNode)
            
            let diff = abs(capsule.targetDate.timeIntervalSince(now))
            if diff < minTimeDifference {
                minTimeDifference = diff
                closestIndex = index
            }
        }
        
        let targetY = (contentHeight / 2) - 300 - (CGFloat(closestIndex) * spacing)
        
        let maxY = contentHeight / 2 - view.bounds.height / 2
        let minY = -contentHeight / 2 + view.bounds.height / 2
        
        var finalCameraY = targetY
        if finalCameraY > maxY { finalCameraY = maxY }
        if finalCameraY < minY { finalCameraY = minY }
        
        camNode.position = CGPoint(x: 0, y: finalCameraY)
    }
    
    // 배경 수풀 장식
    func drawBackgroundBushes() {
        for _ in 0...20 {
            let bush = SKShapeNode(circleOfRadius: CGFloat.random(in: 20...40))
            bush.fillColor = SKColor(hex: "#436F37")
            bush.strokeColor = .clear
            bush.position = CGPoint(
                x: CGFloat.random(in: -200...200),
                y: CGFloat.random(in: (-contentHeight/2)...(contentHeight/2))
            )
            bush.zPosition = -3
            addChild(bush)
        }
    }
    
    // 부드러운 오솔길
    func drawDirtPath(spacing: CGFloat) {
        let path = CGMutablePath()
        let startY = contentHeight / 2 + 200
        
        let startVirtualIndex = ((contentHeight / 2 - 300) - startY) / spacing
        let startX = sin(startVirtualIndex * 1.5) * 100
        path.move(to: CGPoint(x: startX, y: startY))
        
        let totalPathHeight = contentHeight + 400
        for i in 1...100 {
            let yPos = startY - CGFloat(i) * (totalPathHeight / 100)
            let virtualIndex = ((contentHeight / 2 - 300) - yPos) / spacing
            let xPos = sin(virtualIndex * 1.5) * 100
            path.addLine(to: CGPoint(x: xPos, y: yPos))
        }
        
        let pathBorder = SKShapeNode(path: path)
        pathBorder.strokeColor = SKColor(hex: "#886341")
        pathBorder.lineWidth = 150
        pathBorder.lineCap = .round
        pathBorder.lineJoin = .round
        pathBorder.zPosition = -2
        addChild(pathBorder)
        
        let pathInner = SKShapeNode(path: path)
        pathInner.strokeColor = SKColor(hex: "#B88F66")
        pathInner.lineWidth = 135
        pathInner.lineCap = .round
        pathInner.lineJoin = .round
        pathInner.zPosition = -1
        addChild(pathInner)
    }
    
    // 캡슐 노드
    func createCapsuleNode(capsule: TimeCapsuleItem) -> SKNode {
        let groupNode = SKNode()
        
        let signBoard = SKShapeNode(rectOf: CGSize(width: 130, height: 45), cornerRadius: 8)
        signBoard.fillColor = SKColor(hex: "#87553A")
        signBoard.strokeColor = SKColor(hex: "#432616")
        signBoard.lineWidth = 4
        signBoard.position = CGPoint(x: 70, y: 70)
        signBoard.zPosition = 10
        
        let signText = SKLabelNode(text: capsule.openDateString)
        signText.fontName = "Courier-Bold"
        signText.fontSize = 16
        signText.fontColor = SKColor(hex: "#E5C39C")
        signText.verticalAlignmentMode = .center
        signBoard.addChild(signText)
        
        let signPole = SKShapeNode(rectOf: CGSize(width: 14, height: 40))
        signPole.fillColor = SKColor(hex: "#87553A")
        signPole.strokeColor = SKColor(hex: "#432616")
        signPole.lineWidth = 4
        signPole.position = CGPoint(x: 70, y: 35)
        signPole.zPosition = 9
        
        groupNode.addChild(signBoard)
        groupNode.addChild(signPole)
        
        let dirt = SKShapeNode(ellipseOf: CGSize(width: 70, height: 25))
        dirt.fillColor = SKColor(hex: "#4E311F")
        dirt.strokeColor = .clear
        dirt.position = CGPoint(x: -20, y: 0)
        dirt.zPosition = 1
        groupNode.addChild(dirt)
        
        let plantNode = createPlantNode(stage: capsule.currentStage)
        plantNode.position = CGPoint(x: -20, y: 10)
        plantNode.zPosition = 2
        groupNode.addChild(plantNode)
        
        if capsule.currentStage != .bloomed {
            let bottleGroup = SKNode()
            bottleGroup.position = CGPoint(x: -20, y: 40)
            bottleGroup.zPosition = 5
            
            let glass = SKShapeNode(rectOf: CGSize(width: 54, height: 70), cornerRadius: 20)
            glass.fillColor = SKColor(white: 1.0, alpha: 0.15)
            glass.strokeColor = SKColor(white: 1.0, alpha: 0.6)
            glass.lineWidth = 2.5
            bottleGroup.addChild(glass)
            
            let highlightLine = SKShapeNode(rectOf: CGSize(width: 4, height: 35), cornerRadius: 2)
            highlightLine.fillColor = SKColor(white: 1.0, alpha: 0.8)
            highlightLine.strokeColor = .clear
            highlightLine.position = CGPoint(x: -18, y: 0)
            bottleGroup.addChild(highlightLine)
            
            let highlightDot = SKShapeNode(circleOfRadius: 2)
            highlightDot.fillColor = SKColor(white: 1.0, alpha: 0.8)
            highlightDot.strokeColor = .clear
            highlightDot.position = CGPoint(x: -18, y: 25)
            bottleGroup.addChild(highlightDot)
            
            let cork = SKShapeNode(rectOf: CGSize(width: 24, height: 16), cornerRadius: 3)
            cork.fillColor = SKColor(hex: "#9C6D44")
            cork.strokeColor = SKColor(hex: "#432616")
            cork.lineWidth = 2
            cork.position = CGPoint(x: 0, y: 40)
            bottleGroup.addChild(cork)
            
            groupNode.addChild(bottleGroup)
        }
        
        return groupNode
    }
    
    // 식물 그리기
    func createPlantNode(stage: GrowthStage) -> SKNode {
        let node = SKNode()
        switch stage {
        case .seed:
            let seed = SKShapeNode(ellipseOf: CGSize(width: 10, height: 6))
            seed.fillColor = SKColor(hex: "#F9D673")
            seed.strokeColor = SKColor(hex: "#C68532")
            seed.lineWidth = 1
            node.addChild(seed)
            
        case .sprout:
            let leaf1 = SKShapeNode(ellipseOf: CGSize(width: 8, height: 14))
            leaf1.fillColor = SKColor(hex: "#7BC156")
            leaf1.strokeColor = .clear
            leaf1.zRotation = 0.5
            leaf1.position = CGPoint(x: 4, y: 6)
            
            let leaf2 = SKShapeNode(ellipseOf: CGSize(width: 8, height: 14))
            leaf2.fillColor = SKColor(hex: "#7BC156")
            leaf2.strokeColor = .clear
            leaf2.zRotation = -0.5
            leaf2.position = CGPoint(x: -4, y: 6)
            
            node.addChild(leaf1)
            node.addChild(leaf2)
            
        case .growing:
            let stem = SKShapeNode(rectOf: CGSize(width: 4, height: 20))
            stem.fillColor = SKColor(hex: "#7BC156")
            stem.strokeColor = .clear
            stem.position = CGPoint(x: 0, y: 10)
            
            let leaf1 = SKShapeNode(ellipseOf: CGSize(width: 10, height: 16))
            leaf1.fillColor = SKColor(hex: "#7BC156")
            leaf1.strokeColor = .clear
            leaf1.zRotation = 0.8
            leaf1.position = CGPoint(x: 8, y: 15)
            
            node.addChild(stem)
            node.addChild(leaf1)
            
        case .bloomed:
            let stem = SKShapeNode(rectOf: CGSize(width: 6, height: 45))
            stem.fillColor = SKColor(hex: "#436F37")
            stem.strokeColor = .clear
            stem.position = CGPoint(x: 0, y: 20)
            node.addChild(stem)
            
            for i in 0..<5 {
                let angle = CGFloat(i) * (2 * .pi / 5)
                let petal = SKShapeNode(circleOfRadius: 10)
                petal.fillColor = SKColor(hex: "#F197A9")
                petal.strokeColor = SKColor(hex: "#C6556B")
                petal.lineWidth = 2
                petal.position = CGPoint(x: cos(angle) * 12, y: sin(angle) * 12 + 45)
                node.addChild(petal)
            }
            
            let center = SKShapeNode(circleOfRadius: 8)
            center.fillColor = SKColor(hex: "#F9D673")
            center.strokeColor = SKColor(hex: "#C68532")
            center.lineWidth = 2
            center.position = CGPoint(x: 0, y: 45)
            node.addChild(center)
        }
        return node
    }
    
    // 화면 스크롤 로직
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        previousTouchLocation = touch.location(in: self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let previousLocation = previousTouchLocation else { return }
        let currentLocation = touch.location(in: self)
        let dy = currentLocation.y - previousLocation.y
        camNode.position.y -= dy
        
        let maxY = contentHeight / 2 - (view?.bounds.height ?? 0) / 2
        let minY = -contentHeight / 2 + (view?.bounds.height ?? 0) / 2
        
        if camNode.position.y > maxY { camNode.position.y = maxY }
        if camNode.position.y < minY { camNode.position.y = minY }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousTouchLocation = nil
    }
}

// MARK: - 3. SwiftUI 래퍼 뷰
struct TimeCapsuleView: View {
    @State private var isShowingCreateCapsule = false
    
    @State private var mockCapsules: [TimeCapsuleItem] = [
        TimeCapsuleItem(openDateString: "2024.06.10", targetDate: Calendar.current.date(byAdding: .day, value: -800, to: Date())!),
        TimeCapsuleItem(openDateString: "2026.11.15", targetDate: Calendar.current.date(byAdding: .day, value: 50, to: Date())!),
        TimeCapsuleItem(openDateString: "2027.03.01", targetDate: Calendar.current.date(byAdding: .day, value: 170, to: Date())!),
        TimeCapsuleItem(openDateString: "2027.08.12", targetDate: Calendar.current.date(byAdding: .day, value: 340, to: Date())!),
        TimeCapsuleItem(openDateString: "2028.01.05", targetDate: Calendar.current.date(byAdding: .day, value: 500, to: Date())!)
    ].sorted { $0.targetDate < $1.targetDate }
    
    func makeScene(size: CGSize) -> SKScene {
        let scene = TimeCapsuleScene()
        scene.capsules = mockCapsules
        scene.size = size
        scene.scaleMode = .resizeFill
        return scene
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.egBase.ignoresSafeArea()
                
                // 🌟 하단 여백 문제 해결!
                SpriteView(scene: makeScene(size: geo.size))
                    .ignoresSafeArea()
                
                // 타임캡슐 생성 버튼
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isShowingCreateCapsule = true
                        }) {
                            Text("+ 타임캡슐 생성")
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
                                        Capsule().fill(Color.egSub)
                                            .padding(.horizontal, 2.5).padding(.top, 2.5).padding(.bottom, 6.5)
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
        }
        .sheet(isPresented: $isShowingCreateCapsule) {
            ZStack {
                Color.egBase.ignoresSafeArea()
                Text("타임캡슐 생성 화면 준비 중! 🚧")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.egFunctional)
            }
        }
    }
}

#Preview {
    TimeCapsuleView()
}
