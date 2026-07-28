import SwiftUI

struct TimetableView: View {
    var body: some View {
        // TODO: 시간표 API와 ViewModel이 준비되면 이 영역에 시간표 화면을 구현합니다.
        Color.soomsilBackground
            .ignoresSafeArea()
            .navigationTitle(L10n.Common.timetable)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Timetable") {
    NavigationStack {
        TimetableView()
    }
}
