import ShowcaseCore
import ShowcaseUI
import SwiftUI

struct ScenarioGridView: View {
    enum LayoutStyle: String, CaseIterable {
        case grid = "Сетка"
        case list = "Список"
    }

    @Environment(ViewModel.self) var viewModel: ViewModel
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    let animationNamespace: NamespaceID
    @State internal var isAnimating = false
    @State internal var layoutStyle: LayoutStyle = .grid

    /// Whether the current device has a compact width (iPhone portrait, etc.)
    private var isCompact: Bool {
        #if os(macOS)
        return false
        #else
        return horizontalSizeClass == .compact
        #endif
    }

    @State internal var scrollOffset: CGFloat = 0

    var body: some View {
        GeometryReader { outerGeo in
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer for the status bar + navbar area
                        Color.clear.frame(height: 80)

                        VStack(spacing: isCompact ? 16 : 24) {
                            // Welcome Text
                            VStack(spacing: 8) {
                                Text("МЕЩЕРСКИЙ ПАРК")
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(3)
                                    .foregroundStyle(Color.terracotta)

                                Text("Выберите сценарий\nобраза жизни")
                                    .font(isCompact ? .displayMedium : .displayMedium)
                                    .foregroundStyle(.ink)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                        }
                        .padding(.top, 16)

                        LazyVStack(spacing: 0) {
                            Section {
                                VStack(spacing: isCompact ? 20 : 32) {
                                    // Scenario Layouts
                                    Group {
                                        if viewModel.scenarios.isEmpty {
                                            EmptyStateView(
                                                "Нет доступных сценариев",
                                                systemImage: "square.grid.2x2",
                                                description: "Сценарии появятся здесь после добавления"
                                            )
                                            .padding(.top, 60)
                                        } else {
                                            switch layoutStyle {
                                            case .grid:
                                                gridLayout
                                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                            case .list:
                                                listView
                                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                            }
                                        }
                                    }
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: layoutStyle)
                                }
                                .padding(.bottom, 40)
                                .frame(maxWidth: .infinity)
                            } header: {
                                // Sticky Layout Tabs (Liquid Glass style)
                                VStack(spacing: 0) {
                                    Picker("Вид", selection: $layoutStyle) {
                                        ForEach(LayoutStyle.allCases, id: \.self) { style in
                                            Text(style.rawValue).tag(style)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(maxWidth: isCompact ? .infinity : 320)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, isCompact ? 16 : 24)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .opacity(scrollOffset < -100 ? 0 : 1)
                                    )
                                }
                                .padding(.top, 12)
                                .padding(.bottom, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Rectangle()
                                        .fill(.ultraThinMaterial)
                                        .opacity(scrollOffset < -100 ? 1 : 0)
                                        .ignoresSafeArea(edges: .top)
                                )
                                .animation(.easeInOut, value: scrollOffset < -100)
                            }
                        }
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .named("scroll")).minY)
                        }
                    )
                }
                    #if !os(Android)
                    .coordinateSpace(name: "scroll")
                    #endif
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }

            }
            .ignoresSafeArea(edges: .top)
            .background(AmbientBackgroundView())
#if !os(macOS)
            .scrollContentBackground(.hidden)
#endif
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    private func headerLogo(width: CGFloat) -> some View {
        let progress = min(1, max(0, -scrollOffset / 140))
        let size: CGFloat = 80 - (progress * 48) // 80 -> 32
        
        // Horizontal: move from center to leading edge
        let leadingTarget = (isCompact ? 16 : 24) + (size / 2)
        let currentCenter = width / 2
        let targetX = leadingTarget - currentCenter
        let currentX = progress * targetX
        
        // Vertical: Move from content area into the navbar center
        // Standard navbar height is 44. Status bar is ~47. Center Y = 69.
        let startPadding: CGFloat = 80
        let endPadding: CGFloat = 53 
        let currentPadding = startPadding + (progress * (endPadding - startPadding))
        
        return LogoView(size: size)
            .padding(.top, currentPadding)
            .offset(x: currentX)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.85), value: scrollOffset)
    }

    // MARK: - Grid Layout (adaptive)

    @ViewBuilder
    private var gridLayout: some View {
        if isCompact {
            compactGrid
        } else {
            pyramidGrid
        }
    }

    // MARK: - Compact Grid (iPhone: 2 columns via LazyVGrid)

    @ViewBuilder
    private var compactGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.scenarios) { scenario in
                ScenarioCard(scenario: scenario, namespace: animationNamespace) {
                    HapticManager.shared.impact(style: .medium)
                    viewModel.selectScenario(scenario)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Pyramid Grid (iPad: 3-column LazyVGrid)

    @ViewBuilder
    private var pyramidGrid: some View {
        let scenarios = viewModel.scenarios
        let columns = isCompact 
            ? [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            : [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)]

        LazyVGrid(columns: columns, spacing: isCompact ? 20 : 24) {
            ForEach(scenarios) { scenario in
                ScenarioCard(scenario: scenario, namespace: animationNamespace) {
                    HapticManager.shared.impact(style: .medium)
                    viewModel.selectScenario(scenario)
                }
            }
        }
        .padding(.horizontal, isCompact ? 16 : 40)
    }

    // MARK: - List View

    @ViewBuilder
    private var listView: some View {
        VStack(spacing: isCompact ? 16 : 24) {
            ForEach(viewModel.scenarios) { scenario in
                ScenarioCard(scenario: scenario, namespace: animationNamespace) {
                    HapticManager.shared.impact(style: .medium)
                    viewModel.selectScenario(scenario)
                }
                .frame(maxWidth: 600)
            }
        }
        .padding(.horizontal, isCompact ? 16 : 24)
    }

    // MARK: - Masonry Grid

}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
