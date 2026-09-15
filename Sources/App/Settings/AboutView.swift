import CPDAcknowledgements
import Shared
import SwiftUI

struct AboutView: View {
    @State private var showVersionAlert = false

    var body: some View {
        List {
            AppleLikeListTopRowHeader(
                image: nil,
                headerImageAlternativeView: AnyView(
                    Image(uiImage: Asset.logo.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                ),
                title: L10n.About.Logo.appTitle,
                subtitle: HomeAssistantAPI.clientVersionDescription
            )
            .onTapGesture {
                showVersionAlert = true
            }

            // The upstream screen also linked to the Home Assistant beta programme, its app-store
            // review page, Lokalise translation, the community forums and chat, the project's
            // Twitter/Facebook accounts and its GitHub repo + issue tracker. Those are Home
            // Assistant's channels, not Apporo's; shipping them under the Apporo brand would be
            // misleading and a trademark problem, so they are removed rather than re-pointed.
            Section {
                NavigationLink(destination: AcknowledgementsView()) {
                    Text(L10n.About.Acknowledgements.title)
                }
            }

            Section {
                Link(L10n.About.Website.title, destination: AppConstants.WebURLs.homeAssistant)

                Link(L10n.About.Documentation.title, destination: AppConstants.WebURLs.companionAppDocs)
            }
        }
        .navigationTitle(L10n.About.title)
        .alert(isPresented: $showVersionAlert) {
            Alert(
                title: Text(""),
                message: Text(HomeAssistantAPI.clientVersionDescription),
                primaryButton: .default(Text(L10n.copyLabel), action: {
                    UIPasteboard.general.string = HomeAssistantAPI.clientVersionDescription
                }),
                secondaryButton: .cancel(Text(L10n.cancelLabel))
            )
        }
    }
}

struct AcknowledgementsView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CPDAcknowledgementsViewController {
        var licenses = [CPDLibrary]()

        for fileName in [
            "Pods-iOS-App-metadata",
            "ManualPodLicenses",
        ] {
            if let file = Bundle.main.url(forResource: fileName, withExtension: "plist"),
               let dictionary = NSDictionary(contentsOf: file),
               let license = dictionary["specs"] as? [[String: Any]] {
                licenses += license.map { CPDLibrary(cocoaPodsMetadataPlistDictionary: $0) }
            }
        }

        licenses.sort(by: { $0.title < $1.title })

        return CPDAcknowledgementsViewController(style: nil, acknowledgements: licenses, contributions: nil)
    }

    func updateUIViewController(_ uiViewController: CPDAcknowledgementsViewController, context: Context) {}
}
