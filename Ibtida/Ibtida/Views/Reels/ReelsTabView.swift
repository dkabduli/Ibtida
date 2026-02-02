//
//  ReelsTabView.swift
//  Ibtida
//
//  Reels tab: vertical full-screen swipeable Quran recitation videos.
//  Data-driven via Firestore; only reels with tags containing "quran" are shown.
//

import SwiftUI
import AVFoundation

struct ReelsTabView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @StateObject private var viewModel = ReelsFeedViewModel()
    @State private var currentIndex: Int = 0
    @State private var showOptionsSheet = false
    @State private var optionsReel: Reel?
    #if DEBUG
    @State private var pingMessage: String?
    @State private var showPingResult = false
    #endif
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                switch viewModel.loadState {
                case .idle, .loading:
                    loadingView
                case .offline:
                    offlineView
                case .empty:
                    emptyView
                case .error:
                    errorView
                case .success:
                    reelsFeed
                }
            }
            .navigationTitle("Reels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileToolbarButton()
                }
                #if DEBUG
                ToolbarItem(placement: .topBarLeading) {
                    Button("Ping") {
                        Task { await runFirestorePing() }
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                }
                #endif
            }
            .onAppear {
                configureAudioSession()
                Task { await viewModel.loadFirstPage(isOnline: networkMonitor.isOnline) }
            }
            .onChange(of: networkMonitor.isOnline) { _, isNowOnline in
                if isNowOnline {
                    Task { await viewModel.loadFirstPage(isOnline: true) }
                }
            }
            .onDisappear {
                viewModel.playerManager.releaseAll()
            }
            .sheet(isPresented: $showOptionsSheet) {
                if let reel = optionsReel {
                    reelOptionsSheet(reel: reel)
                }
            }
            #if DEBUG
            .overlay(pingOverlay)
            #endif
        }
    }
    
    #if DEBUG
    private var pingOverlay: some View {
        Group {
            if let msg = pingMessage, showPingResult {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Capsule().fill(Color.black.opacity(0.7)))
                    .padding(.top, 8)
                    .onTapGesture { pingMessage = nil; showPingResult = false }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(true)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showPingResult)
    }
    
    private func runFirestorePing() async {
        let result = await FirestorePingService.ping()
        await MainActor.run {
            switch result {
            case .reachable(exists: let exists):
                pingMessage = exists ? "Firestore: reachable (doc exists)" : "Firestore: reachable (doc missing)"
            case .failed(let msg):
                pingMessage = "Firestore: \(msg)"
            }
            showPingResult = true
        }
    }
    #endif
    
    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            Text("Loading reels…")
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var offlineView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 56))
                .foregroundColor(.white.opacity(0.7))
            Text("You're offline")
                .font(AppTypography.title3)
                .foregroundColor(.white)
            Text("Reels need internet. Connect and tap Retry.")
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, ContentLayout.horizontalPadding * 2)
            Button("Retry") {
                viewModel.retry(isOnline: networkMonitor.isOnline)
            }
            .font(AppTypography.bodyBold)
            .foregroundColor(.black)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.white, in: Capsule())
            .padding(.top, AppSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 56))
                .foregroundColor(.white.opacity(0.5))
            Text("No reels yet")
                .font(AppTypography.title3)
                .foregroundColor(.white)
            Text("Quran recitation reels will appear here when added.")
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, ContentLayout.horizontalPadding * 2)
            if networkMonitor.isOnline {
                Button("Try again") {
                    viewModel.retry(isOnline: true)
                }
                .font(AppTypography.bodyBold)
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, AppSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: AppSpacing.xl) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.7))
            Text("Couldn't load reels")
                .font(AppTypography.title3)
                .foregroundColor(.white)
            Text(viewModel.errorMessage ?? "Something went wrong.")
                .font(AppTypography.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, ContentLayout.horizontalPadding * 2)
            Button("Retry") {
                viewModel.retry(isOnline: networkMonitor.isOnline)
            }
            .font(AppTypography.bodyBold)
            .foregroundColor(.black)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.white, in: Capsule())
            .padding(.top, AppSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var reelsFeed: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            // TabView pages are laid out in (h, w) so that after -90° rotation they fill (w, h)
            TabView(selection: $currentIndex) {
                ForEach(Array(viewModel.reels.enumerated()), id: \.element.id) { index, reel in
                    ReelCellView(
                        reel: reel,
                        index: index,
                        viewModel: viewModel,
                        pageSize: CGSize(width: w, height: h),
                        onTap: { viewModel.playerManager.togglePlayPause() },
                        onLongPress: {
                            optionsReel = reel
                            showOptionsSheet = true
                        },
                        onMuteTap: {
                            viewModel.isMuted.toggle()
                            HapticFeedback.light()
                        }
                    )
                    .frame(width: h, height: w)
                    .rotationEffect(.degrees(90))
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .frame(width: h, height: w)
            .rotationEffect(.degrees(-90))
            .frame(width: w, height: h)
            .clipped()
            .onChange(of: currentIndex) { _, newIndex in
                viewModel.onVisibleIndexChanged(newIndex)
            }
            #if DEBUG
            if viewModel.playerManager.activePlayerCount > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Players: \(viewModel.playerManager.activePlayerCount)")
                            .font(AppTypography.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(8)
                            .background(Capsule().fill(Color.black.opacity(0.5)))
                            .padding(AppSpacing.md)
                    }
                }
                .allowsHitTesting(false)
            }
            #endif
        }
        .ignoresSafeArea(.container)
    }
    
    private func reelOptionsSheet(reel: Reel) -> some View {
        NavigationStack {
            List {
                Button("Report") {
                    // Stub
                    showOptionsSheet = false
                }
                Button("Not interested") {
                    // Stub
                    showOptionsSheet = false
                }
            }
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showOptionsSheet = false }
                }
            }
        }
    }
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            AppLog.error("ReelsTabView: audio session error \(error)")
        }
    }
}

// MARK: - Reel Cell (single full-screen reel)

private struct ReelCellView: View {
    let reel: Reel
    let index: Int
    @ObservedObject var viewModel: ReelsFeedViewModel
    let pageSize: CGSize
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onMuteTap: () -> Void
    
    private var hasValidVideoURL: Bool {
        !reel.videoURL.isEmpty && (URL(string: reel.videoURL) != nil)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Video or placeholder (cell is (h,w) then rotated +90 so content fills screen)
            if hasValidVideoURL {
                VideoPlayerView(player: viewModel.playerManager.getOrCreatePlayer(for: index))
                    .frame(width: pageSize.height, height: pageSize.width)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap() }
                    .onLongPressGesture(minimumDuration: 0.5) { onLongPress() }
            } else {
                placeholderView
            }
            
            // Bottom overlay: title + subtitle (in cell coords bottom = screen bottom after rotation)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(reel.title)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .lineLimit(2)
                if let sub = reel.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(AppTypography.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
            }
            .padding(.horizontal, ContentLayout.horizontalPadding)
            .padding(.bottom, TabBarLayout.clearanceHeight + AppSpacing.lg)
            
            // Right-side overlay: mute, like, save, share (in cell coords topTrailing = screen right after +90)
            VStack(spacing: AppSpacing.lg) {
                Button(action: onMuteTap) {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel(viewModel.isMuted ? "Unmute" : "Mute")
                
                Button(action: {
                    viewModel.toggleLike(reelId: reel.id)
                }) {
                    Image(systemName: viewModel.isLiked(reelId: reel.id) ? "heart.fill" : "heart")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.isLiked(reelId: reel.id) ? .red : .white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel(viewModel.isLiked(reelId: reel.id) ? "Unlike" : "Like")
                
                Button(action: {
                    viewModel.toggleSave(reelId: reel.id)
                }) {
                    Image(systemName: viewModel.isSaved(reelId: reel.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.isSaved(reelId: reel.id) ? .yellow : .white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel(viewModel.isSaved(reelId: reel.id) ? "Unsave" : "Save")
                
                Button(action: { shareReel(reel) }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel("Share")
            }
            .padding(ContentLayout.horizontalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .frame(width: pageSize.height, height: pageSize.width)
    }
    
    private var placeholderView: some View {
        ZStack {
            Color.black.opacity(0.85)
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.6))
                Text(reel.title)
                    .font(AppTypography.bodyBold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)
                Text("Video loading")
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: pageSize.height, height: pageSize.width)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onLongPressGesture(minimumDuration: 0.5) { onLongPress() }
    }
    
    private func shareReel(_ reel: Reel) {
        HapticFeedback.light()
        let text = reel.title + (reel.subtitle.map { " · \($0)" } ?? "")
        let url = URL(string: reel.videoURL)
        var items: [Any] = [text]
        if let u = url { items.append(u) }
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(av, animated: true)
    }
}

// MARK: - Preview

#Preview {
    ReelsTabView()
        .environmentObject(AuthService.shared)
        .environmentObject(ThemeManager.shared)
        .environmentObject(NetworkMonitor())
}
