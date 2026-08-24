import Testing
@testable import Bird2048

struct BirdLevelTests {
    @Test
    func mapsTileValuesToBirdLevels() {
        #expect(BirdLevel(value: 2)?.imageName == "bird_level_2")
        #expect(BirdLevel(value: 2)?.displayName == "小萌蛋")
        #expect(BirdLevel(value: 2048)?.imageName == "bird_level_2048")
        #expect(BirdLevel(value: 2048)?.displayName == "小鸟之王")
        #expect(BirdLevel(value: 2048)?.isFinalLevel == true)
    }

    @Test
    func rejectsEmptyAndUnsupportedTileValues() {
        #expect(BirdLevel(value: 0) == nil)
        #expect(BirdLevel(value: 3) == nil)
        #expect(BirdLevel(value: 4096) == nil)
    }
}
