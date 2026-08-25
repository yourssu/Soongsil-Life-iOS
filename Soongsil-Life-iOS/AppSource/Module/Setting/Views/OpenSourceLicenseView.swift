import SwiftUI

struct OpenSourceLicenseView: View {
    private let licenseText: String

    init(bundle: Bundle = .main) {
        licenseText = LicenseResource.load(from: bundle)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text(L10n.Settings.openSourceDescription)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.soomsilPrimaryText)
                    .lineSpacing(5)

                if let repositoryURL = LicenseResource.repositoryURL {
                    Link(destination: repositoryURL) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.Settings.openSourceRepository)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Color.soomsilPrimaryText)

                                Text(LicenseResource.repositoryURLString)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.soomsilSecondaryText)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.soomsilBlue600)
                        }
                        .padding(16)
                        .soomsilCard(cornerRadius: 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Settings.openSourceLicense)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.soomsilPrimaryText)

                    Text(licenseText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.soomsilSecondaryText)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 48)
        }
        .background(Color.soomsilBackground)
        .navigationTitle(L10n.Settings.openSource)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

private enum LicenseResource {
    static let repositoryURLString = AppConfig.lmsPackageURL
    static let repositoryURL = URL(string: repositoryURLString)

    static func load(from bundle: Bundle) -> String {
        guard
            let url = bundle.url(
                forResource: "LMS-API-LICENSE",
                withExtension: "txt"
            ),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            return L10n.Settings.openSourceLoadFailed
        }

        return text
    }
}

#Preview {
    NavigationStack {
        OpenSourceLicenseView()
    }
}
