import SwiftUI
import MapKit
import Combine

// MARK: - 1. API 명세서 모델 (Planner Models)

enum PlanStatus: String, Codable, CaseIterable, Hashable {
    case planning = "PLANNING"     // 여행 계획 중
    case ongoing = "ONGOING"       // 여행 진행 중
    case completed = "COMPLETED"   // 여행 완료
    
    var displayName: String {
        switch self {
        case .planning: return "준비 중"
        case .ongoing: return "여행 중"
        case .completed: return "추억 보관"
        }
    }
    
    var color: Color {
        switch self {
        case .planning: return Color(hex: "#E07A5F")
        case .ongoing: return Color(hex: "#81B29A")
        case .completed: return Color(hex: "#8D99AE")
        }
    }
}

struct PlanPlaceItem: Identifiable, Codable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var placeName: String
    var roadAddress: String?
    var latitude: Double
    var longitude: Double
    var visitOrder: Int
    var estimatedCost: Int
    var memo: String
}

struct PlanDaySchedule: Identifiable, Codable, Equatable, Hashable {
    var id: String = UUID().uuidString
    var dayNumber: Int
    var dateString: String
    var places: [PlanPlaceItem]
}

struct TravelPlan: Identifiable, Codable, Equatable, Hashable {
    var id: Int64 { planId }
    let planId: Int64
    var title: String
    var destination: String
    var startDate: String
    var endDate: String
    var status: PlanStatus
    var totalBudget: Int
    var schedules: [PlanDaySchedule]
    let createdAt: String
}

// MARK: - 2. 인메모리 통신 서비스 (PlanService)

actor PlanService {
    static let shared = PlanService()
    
    private var plans: [TravelPlan] = [
        TravelPlan(
            planId: 101,
            title: "부산 바다 정원 힐링 여행",
            destination: "부산광역시",
            startDate: "2026-10-03",
            endDate: "2026-10-05",
            status: .planning,
            totalBudget: 450000,
            schedules: [
                PlanDaySchedule(
                    dayNumber: 1,
                    dateString: "2026-10-03",
                    places: [
                        PlanPlaceItem(placeName: "부산역", roadAddress: "부산 동구 중앙대로 206", latitude: 35.1152, longitude: 129.0422, visitOrder: 1, estimatedCost: 60000, memo: "KTX 도착 및 렌터카 수령"),
                        PlanPlaceItem(placeName: "광안리 해수욕장", roadAddress: "부산 수영구 광안해변로 219", latitude: 35.1532, longitude: 129.1186, visitOrder: 2, estimatedCost: 35000, memo: "오션뷰 카페 및 산책")
                    ]
                ),
                PlanDaySchedule(
                    dayNumber: 2,
                    dateString: "2026-10-04",
                    places: [
                        PlanPlaceItem(placeName: "해운대 블루라인파크", roadAddress: "부산 해운대구 청사포로 116", latitude: 35.1601, longitude: 129.1664, visitOrder: 1, estimatedCost: 30000, memo: "해변열차 탑승 예약 필수")
                    ]
                )
            ],
            createdAt: "2026-09-10T12:00:00Z"
        )
    ]
    
    func fetchPlans() async throws -> [TravelPlan] {
        return plans
    }
    
    func createPlan(_ plan: TravelPlan) {
        plans.insert(plan, at: 0)
    }
    
    func updatePlan(_ plan: TravelPlan) {
        if let idx = plans.firstIndex(where: { $0.planId == plan.planId }) {
            plans[idx] = plan
        }
    }
    
    func deletePlan(id: Int64) {
        plans.removeAll { $0.planId == id }
    }
}

// MARK: - 3. 플래너 메인 화면 (목록)

struct PlannerView: View {
    @State private var plans: [TravelPlan] = []
    @State private var isShowingCreateSheet = false
    @State private var selectedPlan: TravelPlan?
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F4F1DE").ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("여행 플래너")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(Color(hex: "#3D405B"))
                            Text("설레는 여정과 장소를 차곡차곡 정리하세요")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#3D405B").opacity(0.7))
                        }
                        Spacer()
                        
                        Button(action: { isShowingCreateSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .heavy))
                                Text("새 계획")
                                    .font(.system(size: 13, weight: .heavy))
                            }
                            .foregroundColor(Color(hex: "#3D405B"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(TimeCapsuleJellyBackground(mainColor: Color(hex: "#87553A"), subColor: Color(hex: "#FDE68A")))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if plans.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Text("🗺️")
                                .font(.system(size: 48))
                            Text("아직 등록된 여행 일정이 없습니다.")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "#3D405B"))
                            Text("새로운 계획을 세우고 오솔길처럼 여정을 걸어보세요!")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#3D405B").opacity(0.6))
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(plans) { plan in
                                    PlanCardView(plan: plan)
                                        .onTapGesture {
                                            selectedPlan = plan
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 95) // 하단 탭바 여백 확보
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan) { updated in
                    if let idx = plans.firstIndex(where: { $0.planId == updated.planId }) {
                        plans[idx] = updated
                        Task { await PlanService.shared.updatePlan(updated) }
                    }
                } onDeleted: { deletedId in
                    plans.removeAll { $0.planId == deletedId }
                    Task { await PlanService.shared.deletePlan(id: deletedId) }
                }
            }
            .sheet(isPresented: $isShowingCreateSheet) {
                CreatePlanSheetView { newPlan in
                    plans.insert(newPlan, at: 0)
                    Task { await PlanService.shared.createPlan(newPlan) }
                }
            }
            .onAppear(perform: loadPlans)
        }
    }
    
    private func loadPlans() {
        Task {
            let loaded = (try? await PlanService.shared.fetchPlans()) ?? []
            await MainActor.run {
                self.plans = loaded
                self.isLoading = false
            }
        }
    }
}

// MARK: - 4. 계획 카드 뷰

struct PlanCardView: View {
    let plan: TravelPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.status.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(plan.status.color))
                
                Spacer()
                
                Text("\(plan.startDate) ~ \(plan.endDate)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#3D405B").opacity(0.7))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Color(hex: "#3D405B"))
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#E07A5F"))
                    Text(plan.destination)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#3D405B").opacity(0.8))
                }
            }
            
            Divider()
            
            HStack {
                let placeCount = plan.schedules.flatMap { $0.places }.count
                Text("총 \(plan.schedules.count)일 일정 · 방문지 \(placeCount)곳")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#3D405B").opacity(0.7))
                
                Spacer()
                
                let costSum = plan.schedules.flatMap { $0.places }.map { $0.estimatedCost }.reduce(0, +)
                Text("예상 \(costSum.formatted())원")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#3D405B"))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

// MARK: - 5. 여행 일정 상세 및 동선 편집 뷰 (PlanDetailView - 버튼 가림 완벽 해결)

struct PlanDetailView: View {
    @State var plan: TravelPlan
    var onUpdate: (TravelPlan) -> Void
    var onDeleted: (Int64) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedDayIndex = 0
    @State private var isShowingAddPlace = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "#F4F1DE").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 일자 선택 탭 (Day 1, Day 2 ...)
                if !plan.schedules.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(plan.schedules.indices, id: \.self) { idx in
                                let isSelected = selectedDayIndex == idx
                                Button(action: { selectedDayIndex = idx }) {
                                    VStack(spacing: 2) {
                                        Text("Day \(plan.schedules[idx].dayNumber)")
                                            .font(.system(size: 13, weight: .heavy))
                                        Text(plan.schedules[idx].dateString.suffix(5))
                                            .font(.system(size: 10))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .foregroundColor(isSelected ? .white : Color(hex: "#3D405B"))
                                    .background(
                                        isSelected ? Capsule().fill(Color(hex: "#3D405B")) : Capsule().fill(Color.white)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .background(Color.white.opacity(0.6))
                }
                
                // 해당 Day의 방문지 동선 리스트
                if plan.schedules.indices.contains(selectedDayIndex) {
                    let currentSchedule = plan.schedules[selectedDayIndex]
                    
                    if currentSchedule.places.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "map.badge.plus")
                                .font(.system(size: 44))
                                .foregroundColor(Color(hex: "#3D405B").opacity(0.4))
                            Text("아직 추가된 방문지가 없습니다.")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(hex: "#3D405B"))
                            Text("아래 버튼을 눌러 첫 번째 방문지를 등록해 보세요!")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#3D405B").opacity(0.6))
                        }
                        Spacer()
                            .frame(height: 140) // 하단 버튼 공간 확보
                    } else {
                        List {
                            ForEach(currentSchedule.places) { place in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(place.visitOrder)")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Color(hex: "#E07A5F")))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(place.placeName)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(Color(hex: "#3D405B"))
                                        
                                        if let addr = place.roadAddress, !addr.isEmpty {
                                            Text(addr)
                                                .font(.system(size: 11))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        
                                        if !place.memo.isEmpty {
                                            Text(place.memo)
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(hex: "#3D405B").opacity(0.8))
                                                .padding(6)
                                                .background(Color(hex: "#F4F1DE"))
                                                .cornerRadius(6)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if place.estimatedCost > 0 {
                                        Text("\(place.estimatedCost.formatted())원")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color(hex: "#81B29A"))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onDelete(perform: deletePlace)
                            .onMove(perform: movePlace)
                            
                            // 마지막 셀 아래 여백(버튼에 가려지지 않게)
                            Color.clear
                                .frame(height: 120)
                                .listRowBackground(Color.clear)
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            
            // 🌟 하단 플로팅 버튼: 탭바(약 70~80pt) 위로 완벽하게 올라오도록 bottom 패딩 80 적용
            VStack(spacing: 0) {
                Button(action: { isShowingAddPlace = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("Day \(selectedDayIndex + 1) 장소 추가")
                            .font(.system(size: 15, weight: .heavy))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "#3D405B"))
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80) // 🌟 탭바 위로 넉넉하게 띄움
            }
            .background(
                LinearGradient(
                    colors: [Color(hex: "#F4F1DE").opacity(0.0), Color(hex: "#F4F1DE").opacity(0.95), Color(hex: "#F4F1DE")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar) // 🌟 시스템 탭바 사용 시 숨김 처리
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("일정 삭제", isPresented: $showDeleteConfirm) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                onDeleted(plan.planId)
                dismiss()
            }
        } message: {
            Text("이 여행 일정을 전체 삭제하시겠습니까?")
        }
        .sheet(isPresented: $isShowingAddPlace) {
            AddPlaceSheetView { newPlace in
                var updatedPlaces = plan.schedules[selectedDayIndex].places
                var placeToAdd = newPlace
                placeToAdd.visitOrder = updatedPlaces.count + 1
                updatedPlaces.append(placeToAdd)
                plan.schedules[selectedDayIndex].places = updatedPlaces
                onUpdate(plan)
            }
        }
    }
    
    private func deletePlace(at offsets: IndexSet) {
        plan.schedules[selectedDayIndex].places.remove(atOffsets: offsets)
        for i in 0..<plan.schedules[selectedDayIndex].places.count {
            plan.schedules[selectedDayIndex].places[i].visitOrder = i + 1
        }
        onUpdate(plan)
    }
    
    private func movePlace(from source: IndexSet, to destination: Int) {
        plan.schedules[selectedDayIndex].places.move(fromOffsets: source, toOffset: destination)
        for i in 0..<plan.schedules[selectedDayIndex].places.count {
            plan.schedules[selectedDayIndex].places[i].visitOrder = i + 1
        }
        onUpdate(plan)
    }
}

// MARK: - 6. 신규 여행 플랜 생성 뷰 (CreatePlanSheetView)

struct CreatePlanSheetView: View {
    @Environment(\.dismiss) var dismiss
    var onCreated: (TravelPlan) -> Void
    
    @State private var title = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var validationError = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F4F1DE").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("여행 제목 *")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#3D405B"))
                            TextField("예: 제주도 올레길 힐링 투어", text: $title)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("여행지 *")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#3D405B"))
                            TextField("예: 제주도, 강릉, 도쿄 등", text: $destination)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("여행 기간 설정 *")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#3D405B"))
                            
                            DatePicker("출발일", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                            
                            DatePicker("도착일", selection: $endDate, in: startDate..., displayedComponents: .date)
                                .datePickerStyle(.compact)
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("새 여행 계획")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(Color(hex: "#3D405B"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("생성") {
                        submitPlan()
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#3D405B"))
                }
            }
            .alert("입력 오류", isPresented: $showAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(validationError)
            }
        }
    }
    
    private func submitPlan() {
        let cleanTitle = TimeCapsuleSecurityHelper.sanitize(title.trimmingCharacters(in: .whitespacesAndNewlines))
        let cleanDest = TimeCapsuleSecurityHelper.sanitize(destination.trimmingCharacters(in: .whitespacesAndNewlines))
        
        if cleanTitle.isEmpty {
            validationError = "여행 제목을 입력해 주세요."
            showAlert = true
            return
        }
        if cleanDest.isEmpty {
            validationError = "여행지를 입력해 주세요."
            showAlert = true
            return
        }
        if endDate < startDate {
            validationError = "도착일은 출발일보다 빠를 수 없습니다."
            showAlert = true
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var schedules: [PlanDaySchedule] = []
        var currentDate = startDate
        var dayNum = 1
        
        while currentDate <= endDate {
            schedules.append(
                PlanDaySchedule(
                    dayNumber: dayNum,
                    dateString: formatter.string(from: currentDate),
                    places: []
                )
            )
            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
            dayNum += 1
        }
        
        let newPlan = TravelPlan(
            planId: Int64.random(in: 1000...9999),
            title: cleanTitle,
            destination: cleanDest,
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate),
            status: .planning,
            totalBudget: 0,
            schedules: schedules,
            createdAt: formatter.string(from: Date())
        )
        
        onCreated(newPlan)
        dismiss()
    }
}

// MARK: - 7. 방문지 검색 및 추가 시트 (AddPlaceSheetView)

struct AddPlaceSheetView: View {
    @Environment(\.dismiss) var dismiss
    var onAdd: (PlanPlaceItem) -> Void
    
    @State private var searchQuery = ""
    @State private var placeName = ""
    @State private var roadAddress = ""
    @State private var latitude: Double = 37.5665
    @State private var longitude: Double = 126.9780
    @State private var memo = ""
    @State private var costString = ""
    
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#F4F1DE").ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("장소 검색")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#3D405B"))
                            
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("방문할 곳 검색 (예: 성산일출봉, 카페)", text: $searchQuery)
                                    .onChange(of: searchQuery) { _, q in
                                        searchCompleter.search(query: q)
                                        isSearching = !q.isEmpty
                                    }
                            }
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(8)
                            
                            if isSearching && !searchCompleter.results.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(searchCompleter.results.prefix(4), id: \.self) { res in
                                        Button(action: { selectSearchPlace(res) }) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(res.title)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(Color(hex: "#3D405B"))
                                                Text(res.subtitle)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        Divider()
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("장소명 *")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#3D405B"))
                            TextField("선택된 장소 이름", text: $placeName)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("예상 지출 금액 (원)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#3D405B"))
                            TextField("예: 15000", text: $costString)
                                .keyboardType(.numberPad)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("메모 / 예약 정보")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "#3D405B"))
                            TextField("예: 14시 네이버 예약 완료, 시그니처 메뉴 주문", text: $memo)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("방문지 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                        .foregroundColor(Color(hex: "#3D405B"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("추가") {
                        savePlace()
                    }
                    .disabled(placeName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#3D405B"))
                }
            }
        }
    }
    
    private func selectSearchPlace(_ completion: MKLocalSearchCompletion) {
        let req = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: req)
        search.start { resp, err in
            guard let item = resp?.mapItems.first, err == nil else { return }
            self.placeName = completion.title
            self.roadAddress = completion.subtitle
            self.latitude = item.location.coordinate.latitude
            self.longitude = item.location.coordinate.longitude
            self.isSearching = false
            self.searchQuery = ""
        }
    }
    
    private func savePlace() {
        let cost = Int(costString) ?? 0
        let item = PlanPlaceItem(
            placeName: TimeCapsuleSecurityHelper.sanitize(placeName),
            roadAddress: roadAddress,
            latitude: latitude,
            longitude: longitude,
            visitOrder: 1,
            estimatedCost: cost,
            memo: TimeCapsuleSecurityHelper.sanitize(memo)
        )
        onAdd(item)
        dismiss()
    }
}
