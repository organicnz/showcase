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

    var body: some View {
        ScrollView {
            VStack(spacing: isCompact ? 20 : 32) {
                // Welcome Text & Layout Controls
                VStack(spacing: isCompact ? 16 : 24) {
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

                    Picker("Вид", selection: $layoutStyle) {
                        ForEach(LayoutStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: isCompact ? .infinity : 320)
                    .padding(.horizontal, isCompact ? 16 : 0)
                    .padding(.top, isCompact ? 8 : 16)
                }
                .padding(.top, isCompact ? 16 : 32)
                .padding(.bottom, isCompact ? 8 : 16)

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
        }
        .background(AmbientBackgroundView())
        #if !os(macOS)
        .scrollContentBackground(.hidden)
        #endif
        .refreshable {
            await viewModel.loadData()
        }
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

