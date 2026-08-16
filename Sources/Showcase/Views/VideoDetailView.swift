import ShowcaseCore
import ShowcaseUI
import SwiftUI
import SkipAV
#if canImport(AVFoundation)
import AVFoundation
#endif

struct VideoDetailView: View {
    let video: Video
    @Environment(ViewModel.self) var viewModel: ViewModel

    var body: some View {
        VStack {
            if let url = viewModel.videoURL(for: video) {
                #if os(macOS) && !SKIP
                Text("Видеоплеер (macOS)")
                    .frame(maxWidth: 800, maxHeight: 400)
                    .background(Color.black)
                    .foregroundStyle(.white)
                #else
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(maxWidth: 800, maxHeight: 400)
                #endif
            } else {
                EmptyStateView("Видео недоступно", systemImage: "video.slash")
            }

            Form {
                Section("Подробности") {
                    if let title = video.title {
                        LabeledRow(title: "Название", value: title)
                    }
                    if let duration = video.durationSec {
                        LabeledRow(title: "Длительность", value: "\(duration) сек.")
                    }
                    LabeledRow(title: "Порядок", value: "\(video.orderIndex)")
                    LabeledRow(title: "Статус", value: video.isActive ? "Активно" : "Неактивно")
                }
            }
        }
        .navigationTitle(video.title ?? "Видео")
    }
}
