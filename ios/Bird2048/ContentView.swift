import SwiftUI

struct ContentView: View {
    @State private var viewModel: GameViewModel

    init() {
        _viewModel = State(initialValue: GameViewModel(soundPlayer: .live))
    }

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = min(proxy.size.width - 46, 390)
            // The full-bleed background and the hosted SwiftUI content land in slightly different
            // horizontal coordinate spaces on the current iPhone simulator. Keep the playable
            // surface visually centered against the screenshot/background, not the shifted host area.
            let visualCenterCorrection: CGFloat = -17.5

            ZStack {
                GameTheme.background
                    .ignoresSafeArea()

                HStack(spacing: 0) {
                    Spacer(minLength: 0)

                    VStack(spacing: 16) {
                        Spacer(minLength: max(18, proxy.size.height * 0.065))

                        HeaderView(score: viewModel.score, highScore: viewModel.highScore)

                        ZStack {
                            GameBoardView(
                                board: viewModel.board,
                                sideLength: contentWidth,
                                animatedTileKeys: viewModel.animatedTileKeys,
                                animationTurn: viewModel.animationTurn,
                                isChoosingReviveTile: viewModel.isChoosingReviveTile,
                                selectTile: viewModel.selectReviveTile
                            )

                            if viewModel.isChoosingReviveTile {
                                VStack {
                                    Spacer()

                                    Button {
                                        _ = viewModel.cancelReviveMode()
                                    } label: {
                                        Label("取消复活", systemImage: "xmark")
                                    }
                                    .buttonStyle(PrimaryGameButtonStyle(tint: GameTheme.ink.opacity(0.78)))
                                    .padding(.bottom, 18)
                                }
                            }

                            if viewModel.showsStatusOverlay {
                                StatusOverlay(
                                    title: viewModel.statusTitle,
                                    score: viewModel.score,
                                    canContinueAfterWin: viewModel.hasWon && !viewModel.didContinueAfterWin,
                                    canRevive: viewModel.isGameOver && viewModel.remainingRevives > 0,
                                    remainingRevives: viewModel.remainingRevives,
                                    continueAfterWin: viewModel.continueAfterWin,
                                    revive: viewModel.activateReviveMode,
                                    restart: viewModel.restart
                                )
                            }
                        }

                        ControlBar(
                            canUndo: viewModel.canUndo,
                            isFeedbackEnabled: viewModel.isFeedbackEnabled,
                            statusText: viewModel.statusText,
                            restart: viewModel.restart,
                            undo: viewModel.undo,
                            setFeedbackEnabled: viewModel.setFeedbackEnabled
                        )

                        Spacer(minLength: max(34, proxy.size.height * 0.045))
                    }
                    .frame(width: contentWidth)
                    .overlay(alignment: .topTrailing) {
                        #if DEBUG
                        Button {
                            viewModel.loadDebugBirdPreviewBoard()
                        } label: {
                            Label("素材", systemImage: "photo.on.rectangle")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(DebugPreviewButtonStyle())
                        .padding(.top, max(18, proxy.size.height * 0.065) - 6)
                        #endif
                    }

                    Spacer(minLength: 0)
                }
                .offset(x: visualCenterCorrection)
            }
        }
        .ignoresSafeArea(.container, edges: .horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    viewModel.move(direction: Direction.fromDrag(value.translation))
                }
        )
    }
}

#if DEBUG
private struct DebugPreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background {
                Circle()
                    .fill(GameTheme.ink.opacity(configuration.isPressed ? 0.48 : 0.64))
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.74), lineWidth: 1)
                    }
                    .shadow(color: GameTheme.coolShadow, radius: 8, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}
#endif

private struct HeaderView: View {
    let score: Int
    let highScore: Int

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            Image("game_title")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 318, maxHeight: 106)
                .accessibilityLabel("合合小鸟")

            HStack(spacing: 10) {
                ScorePill(title: "分数", value: score)
                ScorePill(title: "最高分", value: highScore)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatusOverlay: View {
    let title: String
    let score: Int
    let canContinueAfterWin: Bool
    let canRevive: Bool
    let remainingRevives: Int
    let continueAfterWin: () -> Bool
    let revive: () -> Bool
    let restart: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 25, weight: .heavy, design: .rounded))
            Text("分数 \(score.formatted())")
                .font(.subheadline)

            if canContinueAfterWin {
                Button {
                    _ = continueAfterWin()
                } label: {
                    Label("继续挑战", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryGameButtonStyle(tint: GameTheme.accent))
            }

            if canRevive {
                Button {
                    _ = revive()
                } label: {
                    Label("移除方块复活 \(remainingRevives)", systemImage: "heart.fill")
                }
                .buttonStyle(PrimaryGameButtonStyle(tint: GameTheme.green))
            }

            Button(action: restart) {
                Label("再来一次", systemImage: "arrow.clockwise")
            }
            .buttonStyle(SecondaryGameButtonStyle())
        }
        .padding(20)
        .foregroundStyle(GameTheme.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GameTheme.glassPanel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        }
    }
}

private struct ScorePill: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(GameTheme.steel)
            Text(value.formatted())
                .font(.system(size: 30, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.58)
                .monospacedDigit()
                .foregroundStyle(GameTheme.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.horizontal, 12)
        .background(GameTheme.glassCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.82), lineWidth: 1.2)
        }
        .shadow(color: GameTheme.coolShadow, radius: 15, y: 8)
    }
}

private struct ControlBar: View {
    let canUndo: Bool
    let isFeedbackEnabled: Bool
    let statusText: String
    let restart: () -> Void
    let undo: () -> Bool
    let setFeedbackEnabled: (Bool) -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Button(action: restart) {
                    Label("重开", systemImage: "arrow.clockwise")
                }
                .buttonStyle(PrimaryGameButtonStyle(tint: GameTheme.accent))

                Button {
                    _ = undo()
                } label: {
                    Label("撤销", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(SecondaryGameButtonStyle())
                .disabled(!canUndo)

                Toggle("触感", isOn: Binding(
                    get: { isFeedbackEnabled },
                    set: { setFeedbackEnabled($0) }
                ))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(GameTheme.ink.opacity(0.82))
                .toggleStyle(.switch)
                .fixedSize()
                .padding(.horizontal, 12)
                .frame(height: 50)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.82))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.82), lineWidth: 1)
                        }
                        .shadow(color: GameTheme.coolShadow, radius: 8, y: 4)
                }
            }
            .frame(maxWidth: .infinity)

            Text(statusText)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(GameTheme.tipText)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct GameBoardView: View {
    let board: [[Int]]
    let sideLength: CGFloat
    let animatedTileKeys: Set<String>
    let animationTurn: Int
    let isChoosingReviveTile: Bool
    let selectTile: (Int, Int) -> Bool

    var body: some View {
        let boardPadding: CGFloat = 13
        let gridSpacing: CGFloat = 10
        let gridSide = sideLength - boardPadding * 2

        LazyVGrid(columns: columns, spacing: gridSpacing) {
            ForEach(0..<16, id: \.self) { index in
                let row = index / 4
                let column = index % 4

                TileView(
                    value: board[row][column],
                    animationTrigger: animatedTileKeys.contains(GameViewModel.tileKey(row: row, column: column)) ? animationTurn : 0,
                    isSelectable: isChoosingReviveTile && board[row][column] != 0
                )
                .onTapGesture {
                    _ = selectTile(row, column)
                }
            }
        }
        .frame(width: gridSide, height: gridSide)
        .padding(boardPadding)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(GameTheme.boardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.white.opacity(0.76), lineWidth: 1.3)
                }
                .shadow(color: GameTheme.warmShadow, radius: 18, y: 10)
        }
        .frame(width: sideLength, height: sideLength)
    }

    private var columns: [GridItem] {
        let boardPadding: CGFloat = 13
        let gridSpacing: CGFloat = 10
        let gridSide = sideLength - boardPadding * 2
        let tileSide = (gridSide - gridSpacing * 3) / 4

        return Array(repeating: GridItem(.fixed(tileSide), spacing: gridSpacing), count: 4)
    }
}

private struct PrimaryGameButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tint)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.72), lineWidth: 1.2)
                    }
                    .shadow(color: tint.opacity(0.30), radius: 10, y: 5)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private struct SecondaryGameButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .heavy, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .foregroundStyle(GameTheme.ink.opacity(configuration.isPressed ? 0.55 : 0.78))
            .padding(.horizontal, 18)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(configuration.isPressed ? 0.54 : 0.76))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.82), lineWidth: 1)
                    }
                    .shadow(color: GameTheme.coolShadow, radius: 8, y: 4)
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct TileView: View {
    let value: Int
    let animationTrigger: Int
    let isSelectable: Bool
    @State private var popScale = 1.0

    var body: some View {
        let birdLevel = BirdLevel(value: value)

        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tileBackground(for: birdLevel))
                .shadow(color: value > 0 ? GameTheme.warmShadow.opacity(0.72) : GameTheme.warmShadow.opacity(0.45), radius: 7, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.42), lineWidth: 1)

                    if isSelectable {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GameTheme.green, lineWidth: 3)
                    }
                }

            if let birdLevel {
                Image(birdLevel.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 0)
                    .padding(.top, 7)
                    .padding(.bottom, 17)
                    .offset(y: 5)

                VStack {
                    Spacer(minLength: 0)
                    TileValueBadge(value: value, isFinalLevel: birdLevel.isFinalLevel)
                        .padding(.horizontal, 7)
                        .padding(.bottom, 1)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .scaleEffect(popScale)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onChange(of: animationTrigger) { _, newValue in
            guard newValue > 0 else {
                return
            }

            popScale = 0.78
            withAnimation(.spring(response: 0.28, dampingFraction: 0.56)) {
                popScale = 1
            }
        }
    }

    private func tileBackground(for birdLevel: BirdLevel?) -> Color {
        birdLevel?.backgroundColor ?? GameTheme.emptyTile
    }
}

private struct TileValueBadge: View {
    let value: Int
    let isFinalLevel: Bool

    var body: some View {
        Text("\(value)")
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .monospacedDigit()
            .foregroundStyle(isFinalLevel ? GameTheme.accent : GameTheme.steel)
            .frame(maxWidth: .infinity, minHeight: 20)
            .shadow(color: .white.opacity(0.95), radius: 0, x: 0, y: 1)
            .shadow(color: .white.opacity(0.85), radius: 0, x: 1, y: 0)
            .shadow(color: .white.opacity(0.85), radius: 0, x: -1, y: 0)
            .shadow(color: .white.opacity(0.52), radius: 4, x: 0, y: 2)
    }

    private var digitCount: Int {
        String(value).count
    }

    private var fontSize: CGFloat {
        digitCount >= 4 ? 12 : 13
    }
}

private enum GameTheme {
    static let ink = Color(red: 0.12, green: 0.19, blue: 0.30)
    static let steel = Color(red: 0.32, green: 0.38, blue: 0.49)
    static let accent = Color(red: 1.0, green: 0.55, blue: 0.24)
    static let green = Color(red: 0.23, green: 0.72, blue: 0.54)
    static let glassCard = Color.white.opacity(0.66)
    static let glassPanel = Color.white.opacity(0.72)
    static let boardBackground = Color(red: 0.90, green: 0.86, blue: 0.76).opacity(0.78)
    static let emptyTile = Color(red: 1.0, green: 0.98, blue: 0.93).opacity(0.90)
    static let tipText = Color(red: 0.55, green: 0.59, blue: 0.66)
    static let coolShadow = Color(red: 0.20, green: 0.31, blue: 0.40).opacity(0.10)
    static let warmShadow = Color(red: 0.30, green: 0.25, blue: 0.16).opacity(0.12)

    static var background: some View {
        Image("bg_main")
            .resizable()
            .scaledToFill()
    }
}

extension Direction {
    static func fromDrag(_ translation: CGSize) -> Direction {
        if abs(translation.width) > abs(translation.height) {
            return translation.width > 0 ? .right : .left
        }

        return translation.height > 0 ? .down : .up
    }
}

#Preview {
    ContentView()
}
