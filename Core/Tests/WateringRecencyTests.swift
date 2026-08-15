import Foundation
import Testing
@testable import TerrariumCore

@Suite("水やりからの経過時間")
struct WateringRecencyTests {
    private let wateredAt = Date(timeIntervalSince1970: 1_000_000)

    @Test("水やり前は未実施と表示する")
    func neverWatered() {
        #expect(WateringRecency.label(lastWateredAt: nil, relativeTo: wateredAt) == "まだ水やりしていません")
    }

    @Test(arguments: [
        (0, "たった今、水やり"),
        (3_599, "たった今、水やり"),
        (3_600, "1時間前に水やり"),
        (10_800, "3時間前に水やり"),
        (86_400, "1日前に水やり"),
        (172_800, "2日前に水やり")
    ])
    func labels(elapsed: TimeInterval, expected: String) {
        #expect(
            WateringRecency.label(
                lastWateredAt: wateredAt,
                relativeTo: wateredAt.addingTimeInterval(elapsed)
            ) == expected
        )
    }

    @Test("最初の1日は毎時、その後は毎日更新する")
    func timelineBoundaries() {
        let boundaries = WateringRecency.timelineBoundaries(
            lastWateredAt: wateredAt,
            after: wateredAt.addingTimeInterval(22.5 * 3_600),
            through: wateredAt.addingTimeInterval(3 * 86_400)
        )

        #expect(boundaries == [
            wateredAt.addingTimeInterval(23 * 3_600),
            wateredAt.addingTimeInterval(24 * 3_600),
            wateredAt.addingTimeInterval(2 * 86_400),
            wateredAt.addingTimeInterval(3 * 86_400)
        ])
    }
}
