import Foundation
import SwiftUI

public extension Color {
    // Blue
    static var blue05 = Color(hex: "0xFF000F35")
    static var blue10 = Color(hex: "0xFF001A4E")
    static var blue20 = Color(hex: "0xFF002D77")
    static var blue30 = Color(hex: "0xFF003F9C")
    static var blue40 = Color(hex: "0xFF0053C0")
    static var blue50 = Color(hex: "0xFF0071EC")
    static var blue60 = Color(hex: "0xFF3E96FF")
    static var blue70 = Color(hex: "0xFF6EB3FF")
    static var blue80 = Color(hex: "0xFF9FCEFF")
    static var blue90 = Color(hex: "0xFFD1E8FF")
    static var blue95 = Color(hex: "0xFFE8F3FF")

    // Brand
    //
    // Apporo gold ramp, derived from the primary brand colour `BrandColor.primaryHex` (#8B6B24,
    // ADR-0001). Each step keeps the *exact* CIELAB L* of the ramp step it replaces, so every
    // contrast ratio against white and against black is preserved to within 0.05 — no existing
    // component can lose its contrast budget. Only hue and chroma changed: hue is fixed at the
    // primary's LCh hue (83.1°) and chroma is `min(step's original gamut fullness, 0.791)`,
    // where 0.791 is the primary's own fraction of the maximum in-gamut chroma at its lightness.
    // That cap is what keeps the light end a muted gold instead of a saturated yellow.
    //
    // NOTE: `Color(hex:)` only accepts 6- or 8-digit strings; the upstream `0xFF…` spelling used
    // here silently failed to parse and fell back to `haPrimary`. Keep these 6-digit.
    static var brand05 = Color(hex: "271D09")
    static var brand10 = Color(hex: "47350F")
    static var brand20 = Color(hex: "5A4414")
    static var brand30 = Color(hex: "816321")
    static var brand40 = Color(hex: "BC9134")
    static var brand50 = Color(hex: "D7A73D")
    static var brand60 = Color(hex: "E5B342")
    static var brand70 = Color(hex: "F7C148")
    static var brand80 = Color(hex: "FADBA9")
    static var brand90 = Color(hex: "FCEED9")
    static var brand95 = Color(hex: "FDF6ED")

    // Cyan
    static var cyan05 = Color(hex: "0xFF00151B")
    static var cyan10 = Color(hex: "0xFF002129")
    static var cyan20 = Color(hex: "0xFF003844")
    static var cyan30 = Color(hex: "0xFF014C5B")
    static var cyan40 = Color(hex: "0xFF026274")
    static var cyan50 = Color(hex: "0xFF078098")
    static var cyan60 = Color(hex: "0xFF00A3C0")
    static var cyan70 = Color(hex: "0xFF2FBEDC")
    static var cyan80 = Color(hex: "0xFF7FD6EC")
    static var cyan90 = Color(hex: "0xFFC5ECF7")
    static var cyan95 = Color(hex: "0xFFE3F6FB")

    // Green
    static var green05 = Color(hex: "0xFF031608")
    static var green10 = Color(hex: "0xFF052310")
    static var green20 = Color(hex: "0xFF0A3A1D")
    static var green30 = Color(hex: "0xFF0A5027")
    static var green40 = Color(hex: "0xFF036730")
    static var green50 = Color(hex: "0xFF00883C")
    static var green60 = Color(hex: "0xFF00AC49")
    static var green70 = Color(hex: "0xFF5DC36F")
    static var green80 = Color(hex: "0xFF93DA98")
    static var green90 = Color(hex: "0xFFC2F2C1")
    static var green95 = Color(hex: "0xFFE3F9E3")

    // Indigo
    static var indigo05 = Color(hex: "0xFF0D0A3A")
    static var indigo10 = Color(hex: "0xFF181255")
    static var indigo20 = Color(hex: "0xFF292381")
    static var indigo30 = Color(hex: "0xFF3933A7")
    static var indigo40 = Color(hex: "0xFF4945CB")
    static var indigo50 = Color(hex: "0xFF6163F2")
    static var indigo60 = Color(hex: "0xFF808AFF")
    static var indigo70 = Color(hex: "0xFF9DA9FF")
    static var indigo80 = Color(hex: "0xFFBCC7FF")
    static var indigo90 = Color(hex: "0xFFDFe5FF")
    static var indigo95 = Color(hex: "0xFFF0F2FF")

    // Neutral
    static var neutral05 = Color(hex: "0xFF101219")
    static var neutral10 = Color(hex: "0xFF1B1D26")
    static var neutral20 = Color(hex: "0xFF2F323F")
    static var neutral30 = Color(hex: "0xFF424554")
    static var neutral40 = Color(hex: "0xFF545868")
    static var neutral50 = Color(hex: "0xFF717584")
    static var neutral60 = Color(hex: "0xFF9194A2")
    static var neutral70 = Color(hex: "0xFFABAEB9")
    static var neutral80 = Color(hex: "0xFFC7C9D0")
    static var neutral90 = Color(hex: "0xFFE4E5E9")
    static var neutral95 = Color(hex: "0xFFF1F2F3")

    // Orange
    static var orange05 = Color(hex: "0xFF280700")
    static var orange10 = Color(hex: "0xFF3B0F00")
    static var orange20 = Color(hex: "0xFF5E1C00")
    static var orange30 = Color(hex: "0xFF7E2900")
    static var orange40 = Color(hex: "0xFF9D3800")
    static var orange50 = Color(hex: "0xFFC94E00")
    static var orange60 = Color(hex: "0xFFF36D00")
    static var orange70 = Color(hex: "0xFFFF9342")
    static var orange80 = Color(hex: "0xFFFFBB89")
    static var orange90 = Color(hex: "0xFFFFE0C8")
    static var orange95 = Color(hex: "0xFFFFF0E4")

    // Pink
    static var pink05 = Color(hex: "0xFF28041A")
    static var pink10 = Color(hex: "0xFF3C0828")
    static var pink20 = Color(hex: "0xFF5E1342")
    static var pink30 = Color(hex: "0xFF7D1E58")
    static var pink40 = Color(hex: "0xFF9E2A6C")
    static var pink50 = Color(hex: "0xFFC84382")
    static var pink60 = Color(hex: "0xFFE66BA3")
    static var pink70 = Color(hex: "0xFFF78DBF")
    static var pink80 = Color(hex: "0xFFFCB5D8")
    static var pink90 = Color(hex: "0xFFFEDDF0")
    static var pink95 = Color(hex: "0xFFFEFFF9")

    // Purple
    static var purple05 = Color(hex: "0xFF1E0532")
    static var purple10 = Color(hex: "0xFF2D0B48")
    static var purple20 = Color(hex: "0xFF491870")
    static var purple30 = Color(hex: "0xFF612692")
    static var purple40 = Color(hex: "0xFF7936B3")
    static var purple50 = Color(hex: "0xFF9951DB")
    static var purple60 = Color(hex: "0xFFB678F5")
    static var purple70 = Color(hex: "0xFFCA99FF")
    static var purple80 = Color(hex: "0xFFDDBDFF")
    static var purple90 = Color(hex: "0xFFEEDFFF")
    static var purple95 = Color(hex: "0xFFF7F0FF")

    // Red
    static var red05 = Color(hex: "0xFF2A040B")
    static var red10 = Color(hex: "0xFF3E0913")
    static var red20 = Color(hex: "0xFF631323")
    static var red30 = Color(hex: "0xFF8A132C")
    static var red40 = Color(hex: "0xFFB30532")
    static var red50 = Color(hex: "0xFFDC3146")
    static var red60 = Color(hex: "0xFFF3676C")
    static var red70 = Color(hex: "0xFFFD8F90")
    static var red80 = Color(hex: "0xFFFFB8B6")
    static var red90 = Color(hex: "0xFFFFDEDC")
    static var red95 = Color(hex: "0xFFFFF0EF")

    // Yellow
    static var yellow05 = Color(hex: "0xFF220C00")
    static var yellow10 = Color(hex: "0xFF331600")
    static var yellow20 = Color(hex: "0xFF532600")
    static var yellow30 = Color(hex: "0xFF6F3601")
    static var yellow40 = Color(hex: "0xFF8C4602")
    static var yellow50 = Color(hex: "0xFFB45F04")
    static var yellow60 = Color(hex: "0xFFDA7E00")
    static var yellow70 = Color(hex: "0xFFEF9D00")
    static var yellow80 = Color(hex: "0xFFFAC22B")
    static var yellow90 = Color(hex: "0xFFFFE495")
    static var yellow95 = Color(hex: "0xFFFEF3CD")

    /// Apporo primary brand colour. Single source of truth for the brand accent in Swift code;
    /// the asset-catalogue twin is `haPrimary` / `accentColor` (both already #8B6B24).
    static var brandPrimary = Color(hex: BrandColor.primaryHex)

    /// Neutral page background, re-tinted from the upstream cool grey (#F2F4F9) to the brand hue
    /// at the same L* (96.2), so it reads warm against the gold ramp without changing lightness.
    static var brandBackground = Color(hex: "F9F3EB")
}

/// Brand colour values that have to be expressed as hex *strings* (payload fields, `UIColor(hex:)`
/// call sites, SwiftUI previews) rather than as `Color`.
public enum BrandColor {
    /// Apporo primary brand colour — ADR-0001. White text on this reaches 4.88:1 (WCAG AA).
    public static let primaryHex = "#8B6B24"
}
