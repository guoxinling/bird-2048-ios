import SwiftUI

struct BirdLevel: Equatable {
    let value: Int
    let displayName: String
    let imageName: String
    let backgroundColor: Color
    let isFinalLevel: Bool

    init?(value: Int) {
        guard let definition = Self.definitions[value] else {
            return nil
        }

        self.value = value
        displayName = definition.displayName
        imageName = "bird_level_\(value)"
        backgroundColor = definition.backgroundColor
        isFinalLevel = value == 2048
    }

    private static let definitions: [Int: Definition] = [
        2: Definition(displayName: "小萌蛋", backgroundColor: Color(red: 1.0, green: 0.93, blue: 0.78)),
        4: Definition(displayName: "羞羞仔", backgroundColor: Color(red: 1.0, green: 0.88, blue: 0.72)),
        8: Definition(displayName: "好奇雏", backgroundColor: Color(red: 0.93, green: 0.95, blue: 0.70)),
        16: Definition(displayName: "开心鸟", backgroundColor: Color(red: 0.78, green: 0.93, blue: 0.96)),
        32: Definition(displayName: "活力蓝", backgroundColor: Color(red: 0.72, green: 0.90, blue: 0.97)),
        64: Definition(displayName: "聪明啾", backgroundColor: Color(red: 0.88, green: 0.80, blue: 0.68)),
        128: Definition(displayName: "自信蓝", backgroundColor: Color(red: 0.78, green: 0.86, blue: 0.98)),
        256: Definition(displayName: "闪耀蓝", backgroundColor: Color(red: 0.82, green: 0.91, blue: 1.0)),
        512: Definition(displayName: "华丽羽", backgroundColor: Color(red: 0.87, green: 0.84, blue: 0.98)),
        1024: Definition(displayName: "皇冠蓝", backgroundColor: Color(red: 0.96, green: 0.85, blue: 0.94)),
        2048: Definition(displayName: "小鸟之王", backgroundColor: Color(red: 1.0, green: 0.87, blue: 0.58))
    ]

    private struct Definition {
        let displayName: String
        let backgroundColor: Color
    }
}
