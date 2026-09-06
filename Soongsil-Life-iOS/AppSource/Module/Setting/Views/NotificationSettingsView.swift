import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("gradeAnnouncementNotificationEnabled")
    private var isGradeNotificationEnabled = true

    @AppStorage("chapelNotificationEnabled")
    private var isChapelNotificationEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.Settings.notifications)
                .font(.pretendard(20, weight: .semibold))
                .foregroundStyle(.black000)
                .padding(.horizontal, 20)
                .frame(height: 48)

            NotificationToggleRow(
                title: L10n.Settings.gradeNotifications,
                isOn: $isGradeNotificationEnabled
            )

            Rectangle()
                .fill(.serviceGray200)
                .frame(height: 1)
                .padding(.horizontal, 20)

            NotificationToggleRow(
                title: L10n.Settings.chapelNotifications,
                isOn: $isChapelNotificationEnabled
            )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white000)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.white000, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(.black000)
    }
}

private struct NotificationToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Text(title)
                .font(.pretendard(20, weight: .semibold))
                .foregroundStyle(.black000)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.serviceBlue600)
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
    }
}

#Preview {
    NotificationSettingsView()
}
