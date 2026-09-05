import SwiftUI

struct BirdLevel: Equatable {
    let value: Int
    let displayName: String
    let chineseDisplayName: String
    let imageName: String
    let backgroundColor: Color
    let isFinalLevel: Bool

    init?(value: Int) {
        guard let definition = Self.definitions[value] else {
            return nil
        }

        self.value = value
        displayName = definition.displayName
        chineseDisplayName = definition.chineseDisplayName
        imageName = "bird_level_\(value)"
        backgroundColor = definition.backgroundColor
        isFinalLevel = value == 2048
    }

    func displayName(language: AppLanguage) -> String {
        switch language {
        case .english:
            return displayName
        case .chinese:
            return chineseDisplayName
        }
    }

    private static let definitions: [Int: Definition] = [
        2: Definition(displayName: "Tiny Egg", chineseDisplayName: "小萌蛋", backgroundColor: Color(red: 1.0, green: 0.93, blue: 0.78)),
        4: Definition(displayName: "Shy Chick", chineseDisplayName: "羞羞仔", backgroundColor: Color(red: 1.0, green: 0.88, blue: 0.72)),
        8: Definition(displayName: "Curious Chick", chineseDisplayName: "好奇雏", backgroundColor: Color(red: 0.93, green: 0.95, blue: 0.70)),
        16: Definition(displayName: "Happy Bird", chineseDisplayName: "开心鸟", backgroundColor: Color(red: 0.78, green: 0.93, blue: 0.96)),
        32: Definition(displayName: "Bright Blue", chineseDisplayName: "活力蓝", backgroundColor: Color(red: 0.72, green: 0.90, blue: 0.97)),
        64: Definition(displayName: "Clever Chirp", chineseDisplayName: "聪明啾", backgroundColor: Color(red: 0.88, green: 0.80, blue: 0.68)),
        128: Definition(displayName: "Bold Blue", chineseDisplayName: "自信蓝", backgroundColor: Color(red: 0.78, green: 0.86, blue: 0.98)),
        256: Definition(displayName: "Spark Blue", chineseDisplayName: "闪耀蓝", backgroundColor: Color(red: 0.82, green: 0.91, blue: 1.0)),
        512: Definition(displayName: "Fancy Feather", chineseDisplayName: "华丽羽", backgroundColor: Color(red: 0.87, green: 0.84, blue: 0.98)),
        1024: Definition(displayName: "Crowned Blue", chineseDisplayName: "皇冠蓝", backgroundColor: Color(red: 0.96, green: 0.85, blue: 0.94)),
        2048: Definition(displayName: "Bird King", chineseDisplayName: "小鸟之王", backgroundColor: Color(red: 1.0, green: 0.87, blue: 0.58))
    ]

    private struct Definition {
        let displayName: String
        let chineseDisplayName: String
        let backgroundColor: Color
    }
}
