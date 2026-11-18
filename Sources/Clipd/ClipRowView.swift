import SwiftUI

struct ClipRowView: View {
    let item: ClipItem
    let palette: Palette
    let isCopied: Bool
    let isSelected: Bool
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
                    // The keyboard selection: palette.border is too faint
                    // against surface to read as a highlight in either palette.
                    .strokeBorder(isSelected ? palette.dim : palette.border, lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("Copy to clipboard")
    }
}
