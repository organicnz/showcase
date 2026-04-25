import SwiftUI

struct ScenarioGridView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LogoView()
                    .padding(.vertical)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.scenarios) { scenario in
                        ScenarioCard(scenario: scenario) {
                            viewModel.selectScenario(scenario)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
