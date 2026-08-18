import SwiftUI

struct ClipRowView: View {
    let item: ClipItem
    let palette: Palette
    let isCopied: Bool
    let onCopy: () -> Void
    let onTogglePin: () -> Void

    var body: some View {
        Button(action: onCopy) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 12))
                    .foregroundStyle(palette.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    if isCopied {
                        Text("Copied")
                            .font(.caption)
                            .foregroundStyle(palette.text)
                    } else {
                        Text(item.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(palette.dim)
                    }
                    Spacer()
                    Button(action: onTogglePin) {
                        Image(systemName: item.isPinned ? "pin.fill" : "pin")
                            .font(.caption)
                            .foregroundStyle(item.isPinned ? palette.text : palette.dim)
                    }
                    .buttonStyle(.plain)
                    .help(item.isPinned ? "Unpin" : "Pin")
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(palette.border)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("Copy to clipboard")
    }
}
