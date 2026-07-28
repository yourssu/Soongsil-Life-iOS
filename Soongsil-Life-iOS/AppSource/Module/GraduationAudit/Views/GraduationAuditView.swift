import SwiftUI

struct GraduationAuditView: View {
    var body: some View {
        // TODO: 졸업사정 데이터와 ViewModel이 준비되면 이 영역에 졸업사정표를 구현합니다.
        Color.soomsilBackground
            .ignoresSafeArea()
            .navigationTitle(L10n.Home.graduationAudit)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Graduation audit") {
    NavigationStack {
        GraduationAuditView()
    }
}
