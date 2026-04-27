import SwiftUI

struct ScenarioGridView: View {
    enum LayoutStyle: String, CaseIterable {
        case grid = "Сетка"
        case list = "Список"
        case masonry = "Мозаика"
    }

    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var showVideoPlayer = false
    @State internal var isAnimating = false
    @State internal var layoutStyle: LayoutStyle = .grid

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Welcome Text & Layout Controls
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("МЕЩЕРСКИЙ ПАРК")
                            .font(.labelCaps)
                            .tracking(4)
                            .foregroundStyle(Color.terracotta)
                            .padding(.top, 20)

                        Text("Выберите сценарий\nобраза жизни")
                            .font(.displayLarge)
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
                    .frame(maxWidth: 320)
                    .padding(.top, 16)
                }
                .padding(.top, 32)
                .padding(.bottom, 16)

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
                            pyramidGrid
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
        .background(backgroundGradient)
        .refreshable {
            await viewModel.loadData()
        }
        #if !os(macOS)
        .fullScreenCover(isPresented: $showVideoPlayer) {
            VideoPlayerView()
                .environment(viewModel)
        }
        #else
        .sheet(isPresented: $showVideoPlayer) {
            VideoPlayerView()
                .environment(viewModel)
        }
        #endif
    }

    // MARK: - Pyramid Grid

    @ViewBuilder
    private var pyramidGrid: some View {
        let scenarios = viewModel.scenarios

        VStack(spacing: 20) {
            // Top row: up to 3 cards
            let topRow = Array(scenarios.prefix(3))
            HStack(spacing: 20) {
                ForEach(topRow) { scenario in
                    ScenarioCard(scenario: scenario) {
                        viewModel.selectScenario(scenario)
                        showVideoPlayer = true
                    }
                }
            }

            // Bottom row: remaining cards, centered
            if scenarios.count > 3 {
                let bottomRow = Array(scenarios.dropFirst(3))
                HStack(spacing: 20) {
                    ForEach(bottomRow) { scenario in
                        ScenarioCard(scenario: scenario) {
                            viewModel.selectScenario(scenario)
                            showVideoPlayer = true
                        }
                    }
                }
                .frame(maxWidth: cardWidth(for: bottomRow.count, total: min(topRow.count, 3)))
            }
        }
        .padding(.horizontal, 24)
    }
    // MARK: - List View

    @ViewBuilder
    private var listView: some View {
        VStack(spacing: 24) {
            ForEach(viewModel.scenarios) { scenario in
                ScenarioCard(scenario: scenario) {
                    viewModel.selectScenario(scenario)
                    showVideoPlayer = true
                }
                .frame(maxWidth: 600)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Masonry Grid

    private var masonryColumns: [[Scenario]] {
        let scenarios = viewModel.scenarios
        let columns = 2
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
        
        HStack(alignment: .top, spacing: 20) {
            ForEach(0..<cols.count, id: \.self) { colIndex in
                VStack(spacing: 20) {
                    ForEach(cols[colIndex]) { scenario in
                        ScenarioCard(scenario: scenario) {
                            viewModel.selectScenario(scenario)
                            showVideoPlayer = true
                        }
                    }
                }
                // Offset the second column to create the masonry staggered look
                .padding(.top, colIndex == 1 ? 40 : 0)
            }
        }
        .padding(.horizontal, 24)
    }
    /// Constrains the bottom row width to center it relative to the top row.
    private func cardWidth(for bottomCount: Int, total topCount: Int) -> CGFloat {
        // If fewer items in bottom, constrain to proportional width
        guard topCount > 0, bottomCount < topCount else { return .infinity }
        // This works as a rough heuristic; actual sizing is handled by flexible HStack
        return .infinity
    }

    // MARK: - Ambient Background

    private var backgroundGradient: some View {
        ZStack {
            Color.soft.ignoresSafeArea()

            // Subtle animated orbs
            Circle()
                .fill(Color.terracotta.opacity(0.04))
                .blur(radius: 80)
                .frame(width: 500, height: 500)
                .offset(x: isAnimating ? 150 : -100, y: isAnimating ? -150 : 50)

            Circle()
                .fill(Color.ochre.opacity(0.05))
                .blur(radius: 100)
                .frame(width: 600, height: 600)
                .offset(x: isAnimating ? -200 : 250, y: isAnimating ? 250 : -50)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
