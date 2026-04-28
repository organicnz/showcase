import SwiftUI

struct SettingsView: View {
    @Environment(ViewModel.self) var viewModel: ViewModel
    @AppStorage("appTheme") internal var appTheme: AppTheme = .system
    @State internal var showingReloadAlert = false
    @State internal var isConnected: Bool? = nil
    @State internal var systemHealth: SupabaseManager.SystemHealth? = nil
    @State internal var isSyncing = false

    var totalVideos: Int {
        viewModel.videos.values.flatMap { $0 }.count
    }

    var body: some View {
        Form {
            // MARK: - Appearance
            Section("Оформление") {
                Picker(selection: $appTheme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Label(theme.rawValue, systemImage: theme.iconName)
                            .tag(theme)
                    }
                } label: {
                    Label("Тема", systemImage: "paintbrush")
                }
            }

            // MARK: - App Information
            Section("О приложении") {
                LabeledRow(title: "Название", value: "Showcase Мещерский парк")
                LabeledRow(title: "Версия", value: "1.0.1")
                LabeledRow(title: "Сборка", value: "Swift 6.3.1 + SKIP")
                LabeledRow(title: "Платформа", value: platformName)
            }

            // MARK: - Content Statistics
            Section("Статистика контента") {
                LabeledRow(title: "Сценарии", value: "\(viewModel.scenarios.count)")
                LabeledRow(title: "Всего видео", value: "\(totalVideos)")

                if !viewModel.scenarios.isEmpty {
                    ForEach(viewModel.scenarios) { scenario in
                        HStack {
                            Image(systemName: viewModel.iconName(for: scenario))
                                .foregroundStyle(.terracotta)
                                .frame(width: 20)
                            Text(viewModel.scenarioTitle(for: scenario))
                            Spacer()
                            Text("\(viewModel.videosForScenario(scenario).count) видео")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }

            // MARK: - External Display
            Section("Внешний экран") {
                HStack {
                    Image(systemName: "airplayvideo")
                        .foregroundStyle(.blue)
                    Text("Статус AirPlay")
                    Spacer()
                    Text("Готов")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - System Health Dashboard
            Section("Здоровье системы") {
                if let health = systemHealth {
                    healthRow(title: "База данных", status: health.database, icon: "externaldrive")
                    healthRow(title: "Авторизация", status: health.auth, icon: "lock.shield")
                    healthRow(title: "Хранилище", status: health.storage, icon: "cloud")
                    
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.secondary)
                        Text("Задержка")
                        Spacer()
                        Text("\(health.latencyMs) ms")
                            .foregroundStyle(health.latencyMs < 200 ? .green : (health.latencyMs < 500 ? .orange : .red))
                            .monospacedDigit()
                    }
                } else {
                    HStack {
                        ProgressView()
                        Text("Проверка систем...")
                            .padding(.leading, 8)
                            .foregroundStyle(.secondary)
                    }
                }

                if let syncDate = viewModel.lastSyncDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text("Последняя синхр.")
                        Spacer()
                        Text(syncDate, style: .date)
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
                LabeledRow(title: "Дизайн", value: "Женя Миловидов")
                LabeledRow(title: "PM", value: "Женя Южакова")
                LabeledRow(title: "Клиент", value: "ООО «СПК-М»")
            }

            // MARK: - Account
            Section("Аккаунт") {
                if let email = viewModel.userEmail {
                    LabeledRow(title: "Email", value: email)
                }

                Button(role: .destructive, action: {
                    Task { await viewModel.logout() }
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Выйти из системы")
                    }
                }
            }

            // MARK: - About
            Section("О проекте") {
                Text("Премиальный плеер для отдела продаж жилого комплекса Мещерский парк в Москве.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        #if !os(macOS)
        .scrollContentBackground(.hidden)
        #endif
        .background(Color.soft.ignoresSafeArea())
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

    private func healthRow(title: String, status: Bool, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(status ? .green : .red)
                .frame(width: 24)
            Text(title)
            Spacer()
            Text(status ? "В норме" : "Ошибка")
                .foregroundStyle(status ? .green : .red)
                .font(.subheadline)
        }
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
        systemHealth = await SupabaseManager.shared.checkSystemHealth()
        isConnected = systemHealth?.isAllHealthy
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
