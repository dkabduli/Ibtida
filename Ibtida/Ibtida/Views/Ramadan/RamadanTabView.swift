//
//  RamadanTabView.swift
//  Ibtida
//
//  Ramadan fasting tracker. Tab visible only when server config enables Ramadan.
//  Uses same proportional system as Home (no clipping).
//

import SwiftUI
import FirebaseAuth

struct RamadanTabView: View {
    @StateObject private var viewModel = RamadanViewModel()
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedSheetItem: RamadanDaySheetItem?
    
    private let horizontalPadding: CGFloat = 20
    private let sectionSpacing: CGFloat = 16
    
    var body: some View {
        NavigationStack {
            ZStack {
                WarmBackgroundView()
                mainContent
            }
            .tabBarScrollClearance()
            .navigationTitle("Ramadan")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task { await viewModel.loadLogsIfNeeded() }
            }
            .refreshable {
                await CalendarConfigManager.shared.refresh()
                await viewModel.loadLogsIfNeeded()
            }
            .sheet(item: $selectedSheetItem) { item in
                if let date = DateUtils.date(from: item.dateString) {
                    RamadanDaySheet(
                        date: date,
                        dateString: item.dateString,
                        existingLog: viewModel.log(for: item.dateString),
                        isSister: viewModel.isSister,
                        onSave: { log in
                            Task { await viewModel.saveLog(log) }
                            selectedSheetItem = nil
                        },
                        onDismiss: { selectedSheetItem = nil }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if !authService.isLoggedIn {
            signInPrompt
        } else if !viewModel.config.hasValidRange {
            tbdView
        } else {
            scrollContent
        }
    }
    
    private var signInPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundColor(.mutedGold)
            Text("Sign in to track Ramadan")
                .font(AppTypography.subheadline)
                .foregroundColor(Color.warmSecondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
    
    private var tbdView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 44))
                .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.7))
            Text("Ramadan dates not confirmed yet.")
                .font(AppTypography.subheadline)
                .foregroundColor(Color.warmText(colorScheme))
                .multilineTextAlignment(.center)
            if viewModel.config.ramadanEnabled {
                Text("TBD")
                    .font(AppTypography.caption)
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
    
    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: sectionSpacing) {
                headerSection
                daysList
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let total = viewModel.ramadanTotalDays,
               let dayNum = viewModel.ramadanDayNumber(for: Date()) {
                Text("Day \(dayNum) of Ramadan")
                    .font(AppTypography.subheadline)
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            } else if viewModel.config.ramadanEnabled && viewModel.config.startDate != nil {
                Text("Starts tomorrow")
                    .font(AppTypography.caption)
                    .foregroundColor(.mutedGold)
            }
            Text(HijriCalendarService.hijriDisplayString(for: Date(), method: .ummAlQura))
                .font(AppTypography.caption)
                .foregroundColor(Color.warmSecondaryText(colorScheme).opacity(0.9))
        }
    }
    
    private var daysList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fasting log")
                .font(AppTypography.captionBold)
                .foregroundColor(Color.warmSecondaryText(colorScheme))
            
            ForEach(viewModel.ramadanDates, id: \.timeIntervalSince1970) { date in
                let dateString = DateUtils.dayId(for: date)
                let dayNum = viewModel.ramadanDayNumber(for: date)
                let status = viewModel.status(for: dateString)
                
                Button {
                    selectedSheetItem = RamadanDaySheetItem(dateString: dateString)
                } label: {
                    RamadanDayRow(
                        dayNumber: dayNum ?? 0,
                        date: date,
                        status: status,
                        isSister: viewModel.isSister
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Day Row

private struct RamadanDayRow: View {
    let dayNumber: Int
    let date: Date
    let status: RamadanFastingStatus?
    let isSister: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    private static var gregorianFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        f.timeZone = TimeZone.current
        return f
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(dayNumber)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color.warmText(colorScheme))
                .frame(width: 28, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.gregorianFormatter.string(from: date))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.warmText(colorScheme))
                Text(HijriCalendarService.hijriDisplayString(for: date, method: .ummAlQura))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
            
            Spacer(minLength: 0)
            
            Text(status?.displayLabel ?? "Unlogged")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(pillColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(pillColor.opacity(0.15)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.warmSurface(colorScheme)))
    }
    
    private var pillColor: Color {
        switch status {
        case .fasted: return .prayerOnTime
        case .notFasted: return Color.warmSecondaryText(colorScheme)
        case .sisterNotApplicable: return .gray
        case .none: return Color.warmSecondaryText(colorScheme).opacity(0.7)
        }
    }
}

// MARK: - Day Sheet (log fasting)

struct RamadanDaySheet: View {
    let date: Date
    let dateString: String
    let existingLog: RamadanLog?
    let isSister: Bool
    let onSave: (RamadanLog) -> Void
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    @State private var didFast: Bool? = nil
    @State private var sisterNotApplicable: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Did you fast on \(Self.dateFormatter.string(from: date))?")
                    .font(AppTypography.subheadline)
                    .foregroundColor(Color.warmText(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    if isSister {
                        Button {
                            sisterNotApplicable = true
                            didFast = nil
                        } label: {
                            HStack {
                                Text("Not applicable 🩸")
                                    .foregroundColor(Color.warmText(colorScheme))
                                Spacer()
                                if sisterNotApplicable {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.mutedGold)
                                }
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 10).fill(sisterNotApplicable ? Color.mutedGold.opacity(0.15) : Color.warmSurface(colorScheme)))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button {
                        sisterNotApplicable = false
                        didFast = true
                    } label: {
                        HStack {
                            Text("Yes")
                                .foregroundColor(Color.warmText(colorScheme))
                            Spacer()
                            if didFast == true {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.mutedGold)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(didFast == true ? Color.mutedGold.opacity(0.15) : Color.warmSurface(colorScheme)))
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        sisterNotApplicable = false
                        didFast = false
                    } label: {
                        HStack {
                            Text("No")
                                .foregroundColor(Color.warmText(colorScheme))
                            Spacer()
                            if didFast == false {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.mutedGold)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(didFast == false ? Color.mutedGold.opacity(0.15) : Color.warmSurface(colorScheme)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .navigationTitle("Log fasting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let log = RamadanLog(
                            dateString: dateString,
                            didFast: didFast,
                            sisterNotApplicable: isSister ? sisterNotApplicable : nil,
                            updatedAt: Date(),
                            timezone: TimeZone.current.identifier
                        )
                        onSave(log)
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.mutedGold)
                }
            }
            .onAppear {
                if let log = existingLog {
                    didFast = log.didFast
                    sisterNotApplicable = log.sisterNotApplicable ?? false
                }
            }
        }
    }
    
    private static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        f.timeZone = TimeZone.current
        return f
    }
}

// MARK: - Sheet item wrapper

private struct RamadanDaySheetItem: Identifiable {
    let dateString: String
    var id: String { dateString }
}

// MARK: - Preview

#Preview("Ramadan TBD") {
    RamadanTabView()
        .environmentObject(AuthService.shared)
}
