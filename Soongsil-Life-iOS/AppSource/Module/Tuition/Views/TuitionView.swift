import SwiftUI

struct TuitionView: View {
    var body: some View {
        // TODO: 등록금·장학금 데이터와 ViewModel이 준비되면 이 영역에 상세 화면을 구현합니다.
        Color.soomsilBackground
            .ignoresSafeArea()
            .navigationTitle(L10n.Home.tuitionScholarship)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Tuition") {
    NavigationStack {
        TuitionView()
    }
}
