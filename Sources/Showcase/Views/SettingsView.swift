import SwiftUI

struct SettingsView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @State internal var showingReloadAlert = false
    @State internal var isConnected: Bool? = nil
    @State internal var isSyncing = false

    var totalVideos: Int {
        viewModel.videos.values.flatMap { $0 }.count
    }

    var body: some View {
        Form {
            // MARK: - App Information
            Section("О приложении") {
                LabeledRow(title: "Название", value: "Showcase Мещерский парк")
                LabeledRow(title: "Версия", value: "0.0.1")
                LabeledRow(title: "Сборка", value: "Swift 6.3 + SKIP")
                LabeledRow(title: "Платформа", value: platformName)
            }

            // MARK: - Content Statistics
            Section("Статистика контента") {
                LabeledRow(title: "Сценарии", value: "\(viewModel.scenarios.count)")
                LabeledRow(title: "Всего видео", value: "\(totalVideos)")

                if !viewModel.scenarios.isEmpty {
                    ForEach(viewModel.scenarios) { scenario in
                        HStack {
                            Image(systemName: viewModel.iconName(for: scenario.slug))
                                .foregroundStyle(.terracotta)
                                .frame(width: 20)
                            Text(scenario.title)
                            Spacer()
                            Text("\(viewModel.videosForScenario(scenario).count) видео")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }

            // MARK: - Connection Status
            Section("Подключение") {
                HStack {
                    Image(systemName: "airplayvideo")
                        .foregroundStyle(.blue)
                    Text("Внешний дисплей")
                    Spacer()
                    Text("Готов")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Image(systemName: connectionIcon)
                        .foregroundStyle(connectionColor)
                    Text("Supabase")
                    Spacer()
                    if let connected = isConnected {
                        Text(connected ? "Подключен" : "Не в сети")
                            .foregroundStyle(connected ? .green : .red)
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if let syncDate = viewModel.lastSyncDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text("Последняя синхр.")
                        Spacer()
                        Text(syncDate, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - Data Management
            Section("Управление данными") {
                Button(action: {
                    showingReloadAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Перезагрузить контент")
                    }
                }

                Button(action: {
                    syncFromServer()
                }) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.down")
                        Text("Синхронизация с сервером")
                        Spacer()
                        if isSyncing {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(isSyncing)
            }

            // MARK: - Support
            Section("Поддержка") {
                Link(destination: URL(string: "https://supabase.com/dashboard/project/smyfjmdjzfwdehynwfep")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("Панель управления Supabase")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledRow(title: "Разработчик", value: "Тарлан Исаев")
                LabeledRow(title: "Клиент", value: "ООО «СПК-М»")
            }

            // MARK: - About
            Section("О проекте") {
                Text("Премиальный плеер для отдела продаж жилого комплекса Мещерский парк в Москве.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .alert("Перезагрузить контент", isPresented: $showingReloadAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Перезагрузить") {
                syncFromServer()
            }
        } message: {
            Text("Это перезагрузит все сценарии и видео с сервера.")
        }
        .task {
            await checkConnection()
        }
    }

    // MARK: - Helpers

    private var connectionIcon: String {
        guard let connected = isConnected else { return "wifi" }
        return connected ? "wifi" : "wifi.exclamationmark"
    }

    private var connectionColor: Color {
        guard let connected = isConnected else { return .secondary }
        return connected ? .green : .red
    }

    private var platformName: String {
        #if os(iOS)
        return "iOS / iPadOS"
        #elseif os(macOS)
        return "macOS"
        #else
        return "Другое"
        #endif
    }

    private func checkConnection() async {
        isConnected = await SupabaseManager.shared.healthCheck()
    }

    private func syncFromServer() {
        isSyncing = true
        Task {
            await viewModel.loadData()
            await checkConnection()
            isSyncing = false
        }
    }
}
