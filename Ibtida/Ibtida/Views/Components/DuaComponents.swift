//
//  DuaComponents.swift
//  Ibtida
//
//  UI components for Dua views
//

import SwiftUI

// MARK: - Daily Dua Card

struct DailyDuaCard: View {
    let dua: Dua
    let hasUserSaidAmeen: Bool
    let onAmeen: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.mutedGold)
                    Text("Dua of the Day")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                }
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.light()
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            
            // Dua text
            Text(dua.text)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(Color.warmText(colorScheme))
                .multilineTextAlignment(.leading)
                .lineSpacing(8)
            
            // Author
            Text("— \(dua.displayAuthorName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
            
            // Actions
            HStack {
                // Ameen button (toggle: tap to add, tap again to remove)
                AmeenButton(
                    dua: dua,
                    hasUserSaidAmeen: hasUserSaidAmeen,
                    onAmeen: onAmeen
                )
                
                Spacer()
                
                // Date
                Text(dua.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    // Solid opaque background - no transparency
                    colorScheme == .dark 
                        ? Color(red: 0.18, green: 0.16, blue: 0.14)  // Deep warm charcoal
                        : Color(red: 0.99, green: 0.97, blue: 0.94)  // Warm off-white cream
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient.goldAccent,
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.mutedGold.opacity(0.15), radius: 16, x: 0, y: 6)
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }
}

// MARK: - Dua of the Day Card (In-scroll section, with dismiss)

struct DuaOfTheDayCard: View {
    let dua: Dua
    let hasUserSaidAmeen: Bool
    let onAmeen: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with dismiss button
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.mutedGold)
                    Text("Dua of the Day")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.warmText(colorScheme))
                }
                
                Spacer()
                
                Button(action: {
                    HapticFeedback.light()
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Dua text
            Text(dua.text)
                .font(.system(size: 17, weight: .regular, design: .rounded))
                .foregroundColor(Color.warmText(colorScheme))
                .multilineTextAlignment(.leading)
                .lineSpacing(8)
            
            // Author
            Text("— \(dua.displayAuthorName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.warmSecondaryText(colorScheme))
            
            // Actions (spacing so Ameen and nav/toolbar never overlap)
            HStack(alignment: .center, spacing: 12) {
                AmeenButton(
                    dua: dua,
                    hasUserSaidAmeen: hasUserSaidAmeen,
                    onAmeen: onAmeen
                )
                
                Spacer(minLength: 8)
                
                Text(dua.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
            }
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    // Solid opaque background - no transparency
                    colorScheme == .dark 
                        ? Color.warmDarkCard  // Deep warm charcoal
                        : Color.white  // Pure white for clarity
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient.goldAccent,
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.mutedGold.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Dua Card

struct DuaCard: View {
    let dua: Dua
    let hasUserSaidAmeen: Bool
    let onAmeen: () -> Void
    let onReport: () -> Void
    
    @State private var showMenu = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Dua text
            Text(dua.text)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Color.warmText(colorScheme))
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
            
            // Tags
            if !dua.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(dua.tags.prefix(3), id: \.self) { tag in
                            TagChip(tag: tag, isSelected: false, action: {})
                        }
                    }
                }
            }
            
            // Footer
            HStack {
                // Author
                Text("— \(dua.displayAuthorName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.warmSecondaryText(colorScheme))
                
                Spacer()
                
                // Ameen button (toggle)
                AmeenButtonCompact(
                    dua: dua,
                    hasUserSaidAmeen: hasUserSaidAmeen,
                    onAmeen: onAmeen
                )
                
                // Menu
                Menu {
                    Button(action: onReport) {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(Color.warmSecondaryText(colorScheme))
                        .padding(8)
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                        .overlay(
                            Capsule()
                                .stroke(Color(.separator).opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag Chip

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("#\(tag)")
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .white : .accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dua Filter View (Sheet)

struct DuaFilterView: View {
    @Binding var selectedFilter: DuaFilter
    @Binding var selectedTag: String?
    let allTags: [String]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Filter Section
                Section("Filter By") {
                    ForEach(DuaFilter.allCases) { filter in
                        Button(action: {
                            selectedFilter = filter
                        }) {
                            HStack {
                                Text(filter.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedFilter == filter {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                // Tags Section
                if !allTags.isEmpty {
                    Section("Tags") {
                        Button(action: {
                            selectedTag = nil
                        }) {
                            HStack {
                                Text("All Tags")
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedTag == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        
                        ForEach(allTags, id: \.self) { tag in
                            Button(action: {
                                selectedTag = tag
                            }) {
                                HStack {
                                    Text("#\(tag)")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedTag == tag {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Duas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Submit Dua Sheet

struct SubmitDuaView: View {
    @ObservedObject var viewModel: DuaViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var duaText = ""
    @State private var isAnonymous = false
    @State private var selectedTags: [String] = []
    @State private var newTag = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $duaText)
                        .frame(minHeight: 150)
                } header: {
                    Text("Your Dua")
                }
                
                Section {
                    Toggle("Submit anonymously", isOn: $isAnonymous)
                } footer: {
                    Text("Your name won't be shown if anonymous")
                }
                
                Section("Tags (Optional)") {
                    // Selected tags
                    if !selectedTags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(selectedTags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                    Button(action: {
                                        selectedTags.removeAll { $0 == tag }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.1))
                                )
                            }
                        }
                    }
                    
                    // Add tag
                    HStack {
                        TextField("Add tag", text: $newTag)
                        Button("Add") {
                            let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !tag.isEmpty && !selectedTags.contains(tag) {
                                selectedTags.append(tag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Submit Dua")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitDua()
                    }
                    .disabled(duaText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    private func submitDua() {
        Task {
            isSubmitting = true
            errorMessage = nil
            
            do {
                try await viewModel.submitDua(
                    text: duaText,
                    isAnonymous: isAnonymous,
                    tags: selectedTags
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isSubmitting = false
        }
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Loading Skeleton

struct DuaSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 16)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 40)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(height: 16)
                .frame(maxWidth: .infinity)
                .padding(.trailing, 80)
            
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 12)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .redacted(reason: .placeholder)
        .shimmering()
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: -geo.size.width + phase * geo.size.width * 2)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: phase
                    )
                }
            )
            .clipped()
            .onAppear {
                phase = 1
            }
    }
}

// MARK: - Ameen Button Component (Full) — Toggle only; no Undo. Tap to add, tap again to remove.

struct AmeenButton: View {
    let dua: Dua
    let hasUserSaidAmeen: Bool
    let onAmeen: () -> Void
    
    @State private var isLocked = false
    @State private var animatedCount: Int
    @Environment(\.colorScheme) var colorScheme
    
    init(dua: Dua, hasUserSaidAmeen: Bool, onAmeen: @escaping () -> Void) {
        self.dua = dua
        self.hasUserSaidAmeen = hasUserSaidAmeen
        self.onAmeen = onAmeen
        _animatedCount = State(initialValue: dua.ameenCount)
    }
    
    var body: some View {
        Button(action: handleAmeenTap) {
            HStack(spacing: 8) {
                Image(systemName: hasUserSaidAmeen ? "hands.sparkles.fill" : "hands.sparkles")
                    .font(.system(size: 16, weight: .semibold))
                if hasUserSaidAmeen {
                    Text("You said Ameen")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                } else {
                    Text("\(animatedCount) Ameen")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
            .foregroundColor(hasUserSaidAmeen ? .white : .mutedGold)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(hasUserSaidAmeen ? AnyShapeStyle(LinearGradient.goldAccent) : AnyShapeStyle(Color.mutedGold.opacity(0.15)))
            )
        }
        .buttonStyle(SmoothButtonStyle())
        .disabled(isLocked)
        .opacity(isLocked ? 0.6 : 1.0)
        .accessibilityLabel(hasUserSaidAmeen ? "Ameen selected" : "Ameen not selected")
        .accessibilityHint(hasUserSaidAmeen ? "Double tap to remove Ameen" : "Double tap to say Ameen")
        .onChange(of: dua.ameenCount) { _, newCount in
            withAnimation(.easeOut(duration: 0.4)) {
                animatedCount = newCount
            }
        }
    }
    
    private func handleAmeenTap() {
        isLocked = true
        onAmeen()
        HapticFeedback.light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isLocked = false
        }
    }
}

// MARK: - Ameen Button Component (Compact for DuaCard)

struct AmeenButtonCompact: View {
    let dua: Dua
    let hasUserSaidAmeen: Bool
    let onAmeen: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isLocked = false
    @State private var animatedCount: Int
    
    init(dua: Dua, hasUserSaidAmeen: Bool, onAmeen: @escaping () -> Void) {
        self.dua = dua
        self.hasUserSaidAmeen = hasUserSaidAmeen
        self.onAmeen = onAmeen
        _animatedCount = State(initialValue: dua.ameenCount)
    }
    
    var body: some View {
        Button(action: handleAmeenTap) {
            HStack(spacing: 4) {
                Image(systemName: hasUserSaidAmeen ? "hands.sparkles.fill" : "hands.sparkles")
                    .font(.system(size: 14, weight: .semibold))
                Text("\(animatedCount)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(hasUserSaidAmeen ? .mutedGold : Color.warmSecondaryText(colorScheme))
        }
        .disabled(isLocked)
        .opacity(isLocked ? 0.6 : 1.0)
        .accessibilityLabel(hasUserSaidAmeen ? "Ameen selected" : "Ameen not selected")
        .accessibilityHint(hasUserSaidAmeen ? "Double tap to remove Ameen" : "Double tap to say Ameen")
        .onChange(of: dua.ameenCount) { _, newCount in
            withAnimation(.easeOut(duration: 0.4)) {
                animatedCount = newCount
            }
        }
    }
    
    private func handleAmeenTap() {
        isLocked = true
        onAmeen()
        HapticFeedback.light()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isLocked = false
        }
    }
}
