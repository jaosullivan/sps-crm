import SwiftUI

struct ErrorBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(Color(hex: 0x991B1B))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(hex: 0xFEF2F2))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct StatusChip: View {
    let text: String
    var tint: Color = SPSTheme.primary

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

extension MemberStatus {
    var chipColor: Color {
        switch self {
        case .active: SPSTheme.primary
        case .lapsed: SPSTheme.muted
        case .complimentary: SPSTheme.orange
        }
    }
}

extension DealStage {
    var chipColor: Color {
        switch self {
        case .lead: SPSTheme.muted
        case .contacted: SPSTheme.bodyGreen
        case .proposal: SPSTheme.orange
        case .won: SPSTheme.primary
        case .lost: SPSTheme.danger
        }
    }
}

struct EmptyStateView: View {
    var title: String
    var description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SPSTheme.greenLight)
                    .frame(width: 56, height: 56)
                    .overlay(Circle().stroke(SPSTheme.pale, lineWidth: 1))
                ShamrockMark(size: 28, color: SPSTheme.orange)
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SPSTheme.ink)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(SPSTheme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(SPSTheme.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct StatCard: View {
    var label: String
    var value: String
    var subtitle: String
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SPSTheme.muted)
                Spacer()
                Image(systemName: systemImage)
                    .foregroundStyle(SPSTheme.primary)
            }
            Text(value)
                .font(.title.bold())
                .foregroundStyle(SPSTheme.ink)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(SPSTheme.muted)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SPSTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(SPSTheme.border, lineWidth: 1)
        )
    }
}

struct DetailRow: View {
    var label: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SPSTheme.muted)
                .textCase(.uppercase)
            Text(value)
                .font(.body)
                .foregroundStyle(SPSTheme.ink)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct OptionalDateField: View {
    var title: String
    @Binding var isoDate: String?

    var body: some View {
        Toggle(isOn: Binding(
            get: { isoDate != nil },
            set: { on in
                if on {
                    isoDate = Self.iso(from: Date())
                } else {
                    isoDate = nil
                }
            }
        )) {
            Text(title)
        }
        if isoDate != nil {
            DatePicker(
                title,
                selection: Binding(
                    get: { Self.date(from: isoDate) ?? Date() },
                    set: { isoDate = Self.iso(from: $0) }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
        }
    }

    private static func date(from iso: String?) -> Date? {
        guard let iso, iso.count >= 10 else { return nil }
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: String(iso.prefix(10)))
    }

    private static func iso(from date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
