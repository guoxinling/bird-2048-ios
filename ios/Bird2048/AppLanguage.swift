import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chinese = "zh-Hans"

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .chinese:
            return "中文"
        }
    }
}

struct GameStrings {
    let language: AppLanguage

    var titleImageName: String {
        switch language {
        case .english:
            return "game_title_en"
        case .chinese:
            return "game_title"
        }
    }

    var titleAccessibilityLabel: String {
        switch language {
        case .english:
            return "Merge Bird"
        case .chinese:
            return "合合小鸟"
        }
    }

    var score: String {
        switch language {
        case .english:
            return "Score"
        case .chinese:
            return "分数"
        }
    }

    var bestScore: String {
        switch language {
        case .english:
            return "Best"
        case .chinese:
            return "最高分"
        }
    }

    var restart: String {
        switch language {
        case .english:
            return "Restart"
        case .chinese:
            return "重开"
        }
    }

    var undo: String {
        switch language {
        case .english:
            return "Undo"
        case .chinese:
            return "撤销"
        }
    }

    var settings: String {
        switch language {
        case .english:
            return "Settings"
        case .chinese:
            return "设置"
        }
    }

    var languageLabel: String {
        switch language {
        case .english:
            return "Language"
        case .chinese:
            return "语言"
        }
    }

    var haptics: String {
        switch language {
        case .english:
            return "Haptics"
        case .chinese:
            return "触感"
        }
    }

    var sound: String {
        switch language {
        case .english:
            return "Sound"
        case .chinese:
            return "音效"
        }
    }

    var done: String {
        switch language {
        case .english:
            return "Done"
        case .chinese:
            return "完成"
        }
    }

    var gameOverTitle: String {
        switch language {
        case .english:
            return "Game Over"
        case .chinese:
            return "游戏结束"
        }
    }

    var winTitle: String {
        switch language {
        case .english:
            return "Evolution Complete"
        case .chinese:
            return "进化完成"
        }
    }

    var continueChallenge: String {
        switch language {
        case .english:
            return "Keep Going"
        case .chinese:
            return "继续挑战"
        }
    }

    var birdKingBorn: String {
        switch language {
        case .english:
            return "The Bird King Has Arrived"
        case .chinese:
            return "小鸟之王诞生"
        }
    }

    var swipeHint: String {
        switch language {
        case .english:
            return "Swipe to merge birds"
        case .chinese:
            return "滑动合并小鸟"
        }
    }

    var reviveSelectionPrompt: String {
        switch language {
        case .english:
            return "Choose one tile to remove"
        case .chinese:
            return "选择一个方块消除并复活"
        }
    }

    var cancelRevive: String {
        switch language {
        case .english:
            return "Cancel revive"
        case .chinese:
            return "取消复活"
        }
    }

    var reviveInfo: String {
        switch language {
        case .english:
            return "Watch an ad to remove one tile and continue."
        case .chinese:
            return "观看广告后可消除一个方块并继续游戏。"
        }
    }

    var reviveButton: String {
        switch language {
        case .english:
            return "Remove a tile"
        case .chinese:
            return "看广告消除方块"
        }
    }

    var tryAgain: String {
        switch language {
        case .english:
            return "Try Again"
        case .chinese:
            return "再来一次"
        }
    }

    var adUnavailableTitle: String {
        switch language {
        case .english:
            return "Ad unavailable"
        case .chinese:
            return "广告暂不可用"
        }
    }

    var adUnavailableMessage: String {
        switch language {
        case .english:
            return "The ad has not finished loading. Please try again later."
        case .chinese:
            return "广告还没有加载完成，请稍后再试。"
        }
    }

    var ok: String {
        switch language {
        case .english:
            return "OK"
        case .chinese:
            return "好"
        }
    }

    var assetPreview: String {
        switch language {
        case .english:
            return "Assets"
        case .chinese:
            return "素材"
        }
    }

    func statusTitle(hasWon: Bool, isGameOver: Bool) -> String {
        if hasWon {
            return winTitle
        }

        if isGameOver {
            return gameOverTitle
        }

        return ""
    }

    func statusText(isChoosingReviveTile: Bool, hasWon: Bool, didContinueAfterWin: Bool, isGameOver: Bool) -> String {
        if isChoosingReviveTile {
            return reviveSelectionPrompt
        }

        if hasWon {
            return didContinueAfterWin ? continueChallenge : birdKingBorn
        }

        if isGameOver {
            return gameOverTitle
        }

        return swipeHint
    }
}
