import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettings

    let storageURL: URL
    let onClose: () -> Void
    let onLanguageChanged: () -> Void
    let onRunBackupNow: () -> Void

    @State private var selection: PreferencesSection = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                sidebarHeaderRow
                    .listRowInsets(EdgeInsets(top: 0, leading: -4, bottom: 15, trailing: 10))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                ForEach(PreferencesSection.allCases) { section in
                    sidebarRow(for: section)
                        .tag(section)
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
            .navigationSplitViewColumnWidth(min: 180, ideal: 205, max: 250)
        } detail: {
            detailView(for: selection)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(.ultraThinMaterial)
        }
        .frame(minWidth: 820, minHeight: 640)
        .onChange(of: settings.selectedLanguage) { _ in
            onLanguageChanged()
        }
    }

    @ViewBuilder
    private var sidebarHeaderRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .frame(width: 36, height: 36)
                .cornerRadius(3)

            VStack(alignment: .leading, spacing: 2) {
                Text("PKbrain")
                    .font(.headline.weight(.semibold))
                Text(localizedString("preferences"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func sidebarRow(for section: PreferencesSection) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(section.iconGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black.opacity(0.06))
                        .blendMode(.multiply)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.45),
                                    .white.opacity(0.08),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .blendMode(.screen)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 0.5)
                        .blendMode(.screen)
                }
                .overlay(
                    Image(systemName: section.systemImage)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .frame(width: 26, height: 26)

            Text(section.title)
                .font(.system(size: 13.5, weight: .regular))
        }
        .padding(.vertical, 1)
        .tag(section)
    }

    @ViewBuilder
    private func detailView(for section: PreferencesSection) -> some View {
        switch section {
        case .general:
            GeneralPreferencesView(
                settings: settings,
                storageURL: storageURL,
                onRestartRequested: onLanguageChanged,
                onRunBackupNow: onRunBackupNow
            )
        case .shortcuts:
            ShortcutsPreferencesView(settings: settings)
        case .about:
            AboutPreferencesView()
        }
    }
}

private enum PreferencesSection: Hashable, CaseIterable, Identifiable {
    case general
    case shortcuts
    case about

    var id: String {
        switch self {
        case .general: "general"
        case .shortcuts: "shortcuts"
        case .about: "about"
        }
    }

    var title: String {
        switch self {
        case .general: localizedString("general")
        case .shortcuts: localizedString("shortcuts")
        case .about: localizedString("about_section")
        }
    }

    var subtitle: String {
        switch self {
        case .general: localizedString("general_subtitle")
        case .shortcuts: localizedString("shortcuts_subtitle")
        case .about: localizedString("about_subtitle")
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape"
        case .shortcuts: "keyboard"
        case .about: "info.circle"
        }
    }

    var iconGradient: LinearGradient {
        switch self {
        case .general:
            return LinearGradient(colors: [Color(red: 0.42, green: 0.58, blue: 0.96), Color(red: 0.20, green: 0.34, blue: 0.78)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .shortcuts:
            return LinearGradient(colors: [Color(red: 0.54, green: 0.38, blue: 0.96), Color(red: 0.30, green: 0.20, blue: 0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .about:
            return LinearGradient(colors: [Color(red: 0.28, green: 0.72, blue: 0.76), Color(red: 0.13, green: 0.42, blue: 0.50)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
