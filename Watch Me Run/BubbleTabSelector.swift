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
                GeometryReader { proxy in
                    let height = proxy.size.height
                    let cornerRadius = height / 2
                    let laneCount = 6
                    let laneSpacing: CGFloat = 2
                    let laneLineWidth: CGFloat = 1

                    ZStack {
                        ForEach(0..<laneCount, id: \.self) { lane in
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .inset(by: CGFloat(lane) * (laneSpacing + laneLineWidth))
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.6),
                                            Color.white.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: laneLineWidth
                                )
                                .opacity(0.9 - Double(lane) * 0.12)
                        }
                    }
                }
            }

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? Color.wmrTextPrimary : Color.wmrTextSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
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
