import SwiftUI

struct ScenarioGridView: View {
    enum LayoutStyle: String, CaseIterable {
        case grid = "Сетка"
        case list = "Список"
        case masonry = "Мозаика"
    }

    @Environment(ViewModel.self) var viewModel: ViewModel
    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    let animationNamespace: Namespace.ID
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
                        Color.clear.frame(height: 100)

                        VStack(spacing: isCompact ? 20 : 32) {
                            // Welcome Text
                            VStack(spacing: 12) {
                                Text("МЕЩЕРСКИЙ ПАРК")
                                    .font(.labelCaps)
                                    .tracking(4)
                                    .foregroundStyle(Color.terracotta)

                                Text("Выберите сценарий\nобраза жизни")
                                    .font(isCompact ? .displayMedium : .displayLarge)
                                    .foregroundStyle(.ink)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.top, 24)

                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
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
                                            case .masonry:
                                                masonryGrid
                                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                            }
                                        }
                                    }
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: layoutStyle)
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
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, isCompact ? 16 : 24)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .opacity(scrollOffset < -140 ? 0 : 1)
                                    )
                                }
                                .padding(.top, 44) // Account for the status bar area when pinned
                                .padding(.bottom, 20)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Rectangle()
                                        .fill(.ultraThinMaterial)
                                        .opacity(scrollOffset < -140 ? 1 : 0)
                                        .ignoresSafeArea(edges: .top)
                                )
                                .animation(.easeInOut, value: scrollOffset < -140)
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
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }

                // Moving Logo Overlay
                // headerLogo(width: outerGeo.size.width)
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

    // MARK: - Pyramid Grid (iPad: 3+2 centered rows)

    @ViewBuilder
    private var pyramidGrid: some View {
        let scenarios = viewModel.scenarios

        VStack(spacing: 32) {
            // Top row: up to 3 cards
            let topRow = Array(scenarios.prefix(3))
            HStack(spacing: 24) {
                ForEach(topRow) { scenario in
                    ScenarioCard(scenario: scenario, namespace: animationNamespace) {
                        HapticManager.shared.impact(style: .medium)
                        viewModel.selectScenario(scenario)
                    }
                }
            }

            // Bottom row: remaining cards, centered
            if scenarios.count > 3 {
                let bottomRow = Array(scenarios.dropFirst(3))
                HStack(spacing: 24) {
                    ForEach(bottomRow) { scenario in
                        ScenarioCard(scenario: scenario, namespace: animationNamespace) {
                            HapticManager.shared.impact(style: .medium)
                            viewModel.selectScenario(scenario)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 40)
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

    private var masonryColumnCount: Int {
        isCompact ? 2 : 2
    }

    private var masonryColumns: [[Scenario]] {
        let scenarios = viewModel.scenarios
        let columns = masonryColumnCount
        var cols: [[Scenario]] = Array(repeating: [], count: columns)

        // Simple masonry bucket allocation
        for (index, scenario) in scenarios.enumerated() {
            cols[index % columns].append(scenario)
        }
        return cols
    }

    @ViewBuilder
    private var masonryGrid: some View {
        let cols = masonryColumns
        let spacing: CGFloat = isCompact ? 12 : 20

        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<cols.count, id: \.self) { colIndex in
                VStack(spacing: spacing) {
                    ForEach(cols[colIndex]) { scenario in
                        ScenarioCard(scenario: scenario, namespace: animationNamespace) {
                            HapticManager.shared.impact(style: .medium)
                            viewModel.selectScenario(scenario)
                        }
                    }
                }
                // Offset the second column to create the masonry staggered look
                .padding(.top, colIndex == 1 ? (isCompact ? 24 : 40) : 0)
            }
        }
        .padding(.horizontal, isCompact ? 16 : 24)
    }

    /// Constrains the bottom row width to center it relative to the top row.
    private func cardWidth(for bottomCount: Int, total topCount: Int) -> CGFloat {
        // If fewer items in bottom, constrain to proportional width
        guard topCount > 0, bottomCount < topCount else { return .infinity }
        // This works as a rough heuristic; actual sizing is handled by flexible HStack
        return .infinity
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
