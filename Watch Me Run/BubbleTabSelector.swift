import SwiftUI

struct BubbleTabSelector: View {
    @Binding var selectedTab: RootTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(RootTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        selectedTab = tab
                    }
                } label: {
                    TrackTab(title: tab.rawValue, isSelected: selectedTab == tab)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct TrackTab: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            if isSelected {
                // Liquid glass pill for the active tab
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        // Subtle light border to give the glass edge definition
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.7),
                                        Color.white.opacity(0.15)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
                    .overlay(
                        // Soft inner highlight near the top to sell the "liquid" feel
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            .blur(radius: 2)
                            .offset(y: -3)
                            .mask(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .padding(.bottom, 10)
                            )
                    )
            } else {
                // Subtle pill for inactive tabs so the whole control feels cohesive
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }

            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundColor(isSelected ? Color.wmrTextPrimary : Color.wmrTextSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .frame(height: 32)
        .padding(.horizontal, 4)
    }
}

struct BubbleTabSelector_Previews: PreviewProvider {
    @State static var tab: RootTab = .results

    static var previews: some View {
        BubbleTabSelector(selectedTab: $tab)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
