@testable import HomeAssistant
@testable import Shared
import Testing

struct AppIconTests {
    @Test func testAllIconsHaveLocalizedTitles() async throws {
        // Three Apporo build-channel icons; the 22 upstream Home Assistant community icons were removed.
        #expect(AppIcon.allCases.count == 3)

        for icon in AppIcon.allCases {
            #expect(icon.title.isEmpty == false, "\(icon.rawValue) should have a localized title")
        }
    }

    @Test func testEveryIconHasABackingAlternateIconSet() async throws {
        // Guards against an enum case surviving the removal of its `AlternateIcons/*.appiconset`,
        // which would make `setAlternateIconName` fail silently at runtime.
        #expect(Set(AppIcon.allCases.map(\.rawValue)) == ["release", "beta", "dev"])
    }

    @Test func testDarkIconUsesSharedDarkModeAssetForSupportedIcons() async throws {
        #expect(AppIcon.Release.darkIcon == "icon-dark-mode")
        #expect(AppIcon.Beta.darkIcon == "icon-dark-mode")
    }

    @Test func testDarkIconUsesPerIconAssetForNonDefaultDarkModeIcons() async throws {
        #expect(AppIcon.Dev.darkIcon == "icon-dev")
    }

    @Test func testDebugConfigurationSelectsDevAsDefaultIcon() async throws {
        #expect(Current.appConfiguration == .debug)
        #expect(AppIcon.Dev.isDefault)
        #expect(AppIcon.Dev.iconName == nil)

        #expect(AppIcon.Release.isDefault == false)
        #expect(AppIcon.Release.iconName == AppIcon.Release.rawValue)
    }
}
