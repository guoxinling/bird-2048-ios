import Foundation

enum RewardedGameAction: Equatable {
    case undo
    case revive
}

enum RewardedActionResult: Equatable {
    case performed
    case requiresAd(RewardedGameAction)
    case unavailable
}

@Observable
final class GameViewModel {
    static let highScoreStorageKey = "highScore"
    static let savedGameStorageKey = "savedGame"
    static let feedbackEnabledStorageKey = "feedbackEnabled"
    static let soundEnabledStorageKey = "soundEnabled"
    static let freeUndosPerGame = 1

    private let defaults: UserDefaults
    private let feedback: GameFeedback
    private let soundPlayer: SoundPlayer?
    private(set) var game: GameBoard
    private(set) var highScore: Int
    private(set) var remainingRevives = 3
    private(set) var remainingFreeUndos = freeUndosPerGame
    private(set) var isChoosingReviveTile = false
    private(set) var didContinueAfterWin = false
    private(set) var isFeedbackEnabled: Bool
    private(set) var isSoundEnabled: Bool
    private(set) var animatedTileKeys: Set<String> = []
    private(set) var animationTurn = 0
    private var undoSnapshot: GameSnapshot?

    init(
        game: GameBoard? = nil,
        defaults: UserDefaults = .standard,
        feedback: GameFeedback = .live,
        soundPlayer: SoundPlayer? = nil
    ) {
        self.defaults = defaults
        self.feedback = feedback
        self.soundPlayer = soundPlayer
        let savedGame = Self.loadSavedGame(defaults: defaults)
        self.game = game ?? savedGame?.game ?? GameBoard.newGame()
        highScore = defaults.integer(forKey: Self.highScoreStorageKey)
        remainingRevives = savedGame?.remainingRevives ?? 3
        remainingFreeUndos = savedGame?.remainingFreeUndos ?? Self.freeUndosPerGame
        didContinueAfterWin = savedGame?.didContinueAfterWin ?? false
        isFeedbackEnabled = defaults.object(forKey: Self.feedbackEnabledStorageKey) as? Bool ?? true
        isSoundEnabled = defaults.object(forKey: Self.soundEnabledStorageKey) as? Bool ?? true
    }

    var board: [[Int]] {
        game.cells
    }

    var score: Int {
        game.score
    }

    var hasWon: Bool {
        game.hasWon
    }

    var isGameOver: Bool {
        game.isGameOver
    }

    var canUndo: Bool {
        undoSnapshot != nil
    }

    var showsStatusOverlay: Bool {
        !isChoosingReviveTile && ((hasWon && !didContinueAfterWin) || isGameOver)
    }

    var statusTitle: String {
        if hasWon {
            return "Evolution Complete"
        }

        if isGameOver {
            return "Game Over"
        }

        return ""
    }

    var statusText: String {
        if isChoosingReviveTile {
            return "Choose one tile to remove"
        }

        if hasWon {
            return didContinueAfterWin ? "Keep Going" : "The Bird King Has Arrived"
        }

        if isGameOver {
            return "Game Over"
        }

        return "Swipe to merge birds"
    }

    func move(direction: Direction) {
        guard !isChoosingReviveTile, !isGameOver else {
            return
        }

        let snapshot = makeSnapshot()
        let previousBoard = game.cells
        let result = game.play(direction)
        if result.moved {
            undoSnapshot = snapshot
            playFeedback(.move)
            playSound(result.merged ? .merge : .move)
            markAnimatedTiles(changedFrom: previousBoard, to: game.cells)
            saveGame()
        }

        if game.score > highScore {
            highScore = game.score
            defaults.set(highScore, forKey: Self.highScoreStorageKey)
        }
    }

    func restart() {
        game = GameBoard.newGame()
        remainingRevives = 3
        remainingFreeUndos = Self.freeUndosPerGame
        isChoosingReviveTile = false
        didContinueAfterWin = false
        animatedTileKeys = []
        animationTurn += 1
        undoSnapshot = nil
        saveGame()
    }

#if DEBUG
    static let debugBirdPreviewBoard = GameBoard(cells: [
        [2, 4, 8, 16],
        [32, 64, 128, 256],
        [512, 1024, 2048, 0],
        [0, 0, 0, 0]
    ])

    func loadDebugBirdPreviewBoard() {
        game = Self.debugBirdPreviewBoard
        remainingRevives = 3
        remainingFreeUndos = Self.freeUndosPerGame
        isChoosingReviveTile = false
        didContinueAfterWin = true
        animatedTileKeys = []
        animationTurn += 1
        undoSnapshot = nil
        saveGame()
    }
#endif

    @discardableResult
    func continueAfterWin() -> Bool {
        guard hasWon, !didContinueAfterWin else {
            return false
        }

        didContinueAfterWin = true
        saveGame()
        return true
    }

    func setFeedbackEnabled(_ isEnabled: Bool) {
        isFeedbackEnabled = isEnabled
        defaults.set(isEnabled, forKey: Self.feedbackEnabledStorageKey)
    }

    func setSoundEnabled(_ isEnabled: Bool) {
        isSoundEnabled = isEnabled
        defaults.set(isEnabled, forKey: Self.soundEnabledStorageKey)
    }

    @discardableResult
    func activateReviveMode() -> Bool {
        guard isGameOver, remainingRevives > 0 else {
            return false
        }

        isChoosingReviveTile = true
        return true
    }

    @discardableResult
    func requestReviveMode() -> RewardedActionResult {
        guard isGameOver, remainingRevives > 0 else {
            return .unavailable
        }

        return .requiresAd(.revive)
    }

    @discardableResult
    func performRewardedRevive() -> Bool {
        activateReviveMode()
    }

    @discardableResult
    func cancelReviveMode() -> Bool {
        guard isChoosingReviveTile else {
            return false
        }

        isChoosingReviveTile = false
        return true
    }

    @discardableResult
    func selectReviveTile(row: Int, column: Int) -> Bool {
        guard isChoosingReviveTile, remainingRevives > 0 else {
            return false
        }

        let snapshot = makeSnapshot()
        guard game.removeTile(row: row, column: column) else {
            return false
        }

        undoSnapshot = snapshot
        remainingRevives -= 1
        isChoosingReviveTile = false
        animatedTileKeys = []
        animationTurn += 1
        playFeedback(.revive)
        saveGame()
        return true
    }

    @discardableResult
    func requestUndo() -> RewardedActionResult {
        guard canUndo else {
            return .unavailable
        }

        guard remainingFreeUndos > 0 else {
            return .requiresAd(.undo)
        }

        let remainingAfterUndo = remainingFreeUndos - 1
        guard undo() else {
            return .unavailable
        }

        remainingFreeUndos = remainingAfterUndo
        saveGame()
        return .performed
    }

    @discardableResult
    func performRewardedUndo() -> Bool {
        undo()
    }

    @discardableResult
    func undo() -> Bool {
        guard let snapshot = undoSnapshot else {
            return false
        }

        game = snapshot.game
        remainingRevives = snapshot.remainingRevives
        remainingFreeUndos = snapshot.remainingFreeUndos
        isChoosingReviveTile = snapshot.isChoosingReviveTile
        didContinueAfterWin = snapshot.didContinueAfterWin
        animatedTileKeys = []
        animationTurn += 1
        undoSnapshot = nil
        saveGame()
        return true
    }

    static func saveGameForTesting(
        game: GameBoard,
        remainingRevives: Int,
        remainingFreeUndos: Int = GameViewModel.freeUndosPerGame,
        didContinueAfterWin: Bool = false,
        defaults: UserDefaults
    ) throws {
        let savedGame = SavedGame(
            game: game,
            remainingRevives: remainingRevives,
            remainingFreeUndos: remainingFreeUndos,
            didContinueAfterWin: didContinueAfterWin
        )
        let data = try JSONEncoder().encode(savedGame)
        defaults.set(data, forKey: Self.savedGameStorageKey)
    }

    private func saveGame() {
        try? Self.saveGameForTesting(
            game: game,
            remainingRevives: remainingRevives,
            remainingFreeUndos: remainingFreeUndos,
            didContinueAfterWin: didContinueAfterWin,
            defaults: defaults
        )
    }

    private func makeSnapshot() -> GameSnapshot {
        GameSnapshot(
            game: game,
            remainingRevives: remainingRevives,
            remainingFreeUndos: remainingFreeUndos,
            isChoosingReviveTile: isChoosingReviveTile,
            didContinueAfterWin: didContinueAfterWin
        )
    }

    private func playFeedback(_ event: GameFeedback.Event) {
        guard isFeedbackEnabled else {
            return
        }

        feedback.play(event)
    }

    private func playSound(_ effect: SoundPlayer.Effect) {
        guard isSoundEnabled else {
            return
        }

        soundPlayer?.play(effect)
    }

    private func markAnimatedTiles(changedFrom previousBoard: [[Int]], to currentBoard: [[Int]]) {
        var keys: Set<String> = []
        for row in 0..<4 {
            for column in 0..<4 where currentBoard[row][column] != 0 && currentBoard[row][column] != previousBoard[row][column] {
                keys.insert(Self.tileKey(row: row, column: column))
            }
        }

        animatedTileKeys = keys
        animationTurn += 1
    }

    static func tileKey(row: Int, column: Int) -> String {
        "\(row)-\(column)"
    }

    private static func loadSavedGame(defaults: UserDefaults) -> SavedGame? {
        guard let data = defaults.data(forKey: savedGameStorageKey) else {
            return nil
        }

        return try? JSONDecoder().decode(SavedGame.self, from: data)
    }
}

private struct GameSnapshot {
    let game: GameBoard
    let remainingRevives: Int
    let remainingFreeUndos: Int
    let isChoosingReviveTile: Bool
    let didContinueAfterWin: Bool
}

private struct SavedGame: Codable {
    let game: GameBoard
    let remainingRevives: Int
    let remainingFreeUndos: Int
    let didContinueAfterWin: Bool

    init(game: GameBoard, remainingRevives: Int, remainingFreeUndos: Int, didContinueAfterWin: Bool) {
        self.game = game
        self.remainingRevives = remainingRevives
        self.remainingFreeUndos = remainingFreeUndos
        self.didContinueAfterWin = didContinueAfterWin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        game = try container.decode(GameBoard.self, forKey: .game)
        remainingRevives = try container.decode(Int.self, forKey: .remainingRevives)
        remainingFreeUndos = try container.decodeIfPresent(Int.self, forKey: .remainingFreeUndos) ?? GameViewModel.freeUndosPerGame
        didContinueAfterWin = try container.decodeIfPresent(Bool.self, forKey: .didContinueAfterWin) ?? false
    }
}
