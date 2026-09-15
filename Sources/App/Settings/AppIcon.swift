import Foundation
import Shared

/// Selectable app icons.
///
/// The 22 upstream Home Assistant community icons (colour line, pride flags, `classic`/`old-*`
/// legacy marks) were removed for Apporo: they are Home Assistant brand assets, and after the
/// rebrand every one of them was a byte-identical copy of the single Apporo mark, so the picker
/// offered 25 visually identical choices. What remains are the three Apporo build-channel icons,
/// which are the same sets `ASSETCATALOG_COMPILER_APPICON_NAME` selects per configuration.
enum AppIcon: String, CaseIterable {
    case Release = "release"
    case Beta = "beta"
    case Dev = "dev"

    var title: String {
        switch self {
        case .Release:
            return L10n.SettingsDetails.General.AppIcon.Enum.release
        case .Beta:
            return L10n.SettingsDetails.General.AppIcon.Enum.beta
        case .Dev:
            return L10n.SettingsDetails.General.AppIcon.Enum.dev
        }
    }

    var darkIcon: String {
        switch self {
        case .Release, .Beta:
            return "icon-dark-mode"
        default:
            return "icon-\(rawValue)"
        }
    }

    var isDefault: Bool {
        switch Current.appConfiguration {
        case .debug where self == .Dev: return true
        case .release where self == .Release: return true
        default: return false
        }
    }

    var iconName: String? {
        if isDefault {
            return nil
        } else {
            return rawValue
        }
    }
}
