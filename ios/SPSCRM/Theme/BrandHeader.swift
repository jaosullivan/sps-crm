import SwiftUI
import UIKit

/// Brand lockup aligned with web `07afe90` / `fc654b7`.
/// Login uses the favicon tile; in-app chrome uses the same Wix CDN header logo.
enum SPSBrandAssets {
    static let headerLogoURL = URL(string:
        "https://static.wixstatic.com/media/ef9572_9049fdb0d6484286a126e71bad334748~mv2.png/v1/fill/w_378,h_194,al_c,q_85,usm_0.66_1.00_0.01,enc_avif,quality_auto/stpatslogo.png"
    )!

    static let societyEyebrow = "St. Patrick's Society HK"
    static let productName = "SPS CRM"
}

/// Login mark — same treatment as web `img.favicon.svg` on `bg-black` (`fc654b7`).
struct SPSFaviconMark: View {
    var size: CGFloat = 56

    var body: some View {
        Group {
            if UIImage(named: "SPSFavicon") != nil {
                Image("SPSFavicon")
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.19, style: .continuous)
                        .fill(SPSTheme.ink)
                    ShamrockShape()
                        .fill(SPSTheme.orange)
                        .padding(size * 0.16)
                    ShamrockStem()
                        .fill(SPSTheme.primary)
                        .padding(size * 0.16)
                }
            }
        }
        .frame(width: size, height: size)
        .background(SPSTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.19, style: .continuous))
        .accessibilityLabel("SPS Hong Kong logo")
    }
}

/// Stem only (favicon uses `#025C23` for the stalk).
private struct ShamrockStem: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 32
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * s, y: rect.minY + y * s)
        }
        path.move(to: p(15.2, 18.5))
        path.addCurve(to: p(16.0, 24.0), control1: p(15.4, 20.3), control2: p(15.7, 22.1))
        path.addCurve(to: p(16.8, 18.5), control1: p(16.3, 22.1), control2: p(16.6, 20.3))
        path.addCurve(to: p(15.2, 18.5), control1: p(16.3, 18.4), control2: p(15.7, 18.4))
        path.closeSubpath()
        return path
    }
}

/// Header logo: same CDN URL as web `AppLayout`, black plate, local asset fallback.
struct SPSHeaderLogo: View {
    var height: CGFloat = 40

    var body: some View {
        AsyncImage(url: SPSBrandAssets.headerLogoURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            default:
                Group {
                    if UIImage(named: "SPSHeaderLogo") != nil {
                        Image("SPSHeaderLogo")
                            .resizable()
                            .scaledToFit()
                    } else {
                        SPSFaviconMark(size: height)
                    }
                }
            }
        }
        .frame(height: height)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(SPSTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .accessibilityLabel("St. Patrick's Society Hong Kong")
    }
}

enum SPSBrandMarkStyle {
    /// Login / apple-touch treatment (`favicon.svg` on black).
    case favicon
    /// Sidebar / in-app chrome (CDN header logo on black).
    case header
}

struct SPSBrandLockup: View {
    var style: SPSBrandMarkStyle = .header
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            switch style {
            case .favicon:
                SPSFaviconMark(size: compact ? 40 : 56)
            case .header:
                SPSHeaderLogo(height: compact ? 32 : 40)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(SPSBrandAssets.societyEyebrow.uppercased())
                    .font(.system(size: compact ? 9 : 10, weight: .semibold))
                    .tracking(compact ? 1.2 : 1.4)
                    .foregroundStyle(SPSTheme.orange)
                    .lineLimit(1)
                Text(SPSBrandAssets.productName)
                    .font(compact ? .subheadline.weight(.semibold) : .title3.weight(.semibold))
                    .tracking(0.4)
                    .foregroundStyle(SPSTheme.primary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
