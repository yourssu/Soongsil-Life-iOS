import SwiftUI

struct NotificationView: View {
    var body: some View {
        // TODO: 알림 요구사항과 서버 API가 준비되면 이 영역에 알림 화면을 구현합니다.제발 푸쉬 성공
        Color.soomsilBackground
            .ignoresSafeArea()
            .navigationTitle(L10n.Common.notifications)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Notification") {
    NavigationStack {
        NotificationView()
    }
}
