import SwiftUI

struct ScenarioGridView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var showVideoPlayer = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Welcome Text
                VStack(spacing: 8) {
                    Text("Мещерский парк")
                        .font(.displayMedium)
                        .foregroundStyle(.ink)

                    Text("Выберите сценарий образа жизни")
                        .font(.bodyLarge)
                        .foregroundStyle(.mid)
                }
                .padding(.top, 24)

                // Scenario Grid — Pyramid Layout (3 top, 2 bottom centered)
                if viewModel.scenarios.isEmpty {
                    EmptyStateView(
                        "Нет доступных сценариев",
                        systemImage: "square.grid.2x2",
                        description: "Сценарии появятся здесь после добавления"
                    )
                    .padding(.top, 60)
                } else {
                    pyramidGrid
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.soft.ignoresSafeArea())
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

    /// Constrains the bottom row width to center it relative to the top row.
    private func cardWidth(for bottomCount: Int, total topCount: Int) -> CGFloat {
        // If fewer items in bottom, constrain to proportional width
        guard topCount > 0, bottomCount < topCount else { return .infinity }
        // This works as a rough heuristic; actual sizing is handled by flexible HStack
        return .infinity
    }
}
