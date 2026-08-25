import SwiftUI

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(document.effectiveDate)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.soomsilBlue600)

                    Text(document.introduction)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.soomsilPrimaryText)
                        .lineSpacing(5)
                }

                ForEach(document.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section.title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.soomsilPrimaryText)

                        Text(section.body)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.soomsilSecondaryText)
                            .lineSpacing(5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 48)
        }
        .background(Color.soomsilBackground)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

#Preview("Terms") {
    NavigationStack {
        LegalDocumentView(document: LegalDocumentKind.terms.document)
    }
}

#Preview("Privacy") {
    NavigationStack {
        LegalDocumentView(document: LegalDocumentKind.privacy.document)
    }
}
