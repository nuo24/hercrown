import XCTest
@testable import HerCrown

@MainActor final class ReaderFallbackTests: XCTestCase {
    func testOfflineLicensedPreferenceUsesCorrectlyLabelledKJVWithoutChangingPreference() throws {
        let app = AppModel()
        app.preferences.translation = "nkjv"
        app.offline = true
        let reader = ReaderModel(app: app)
        XCTAssertEqual(reader.translation, "kjv")
        XCTAssertEqual(reader.chapter?.translation, "kjv")
        XCTAssertEqual(app.preferences.translation, "nkjv")
        XCTAssertFalse(reader.loading)
        XCTAssertNil(reader.failure)
    }
    func testEveryBundledChoiceRemainsReadableOffline() throws {
        let app = AppModel()
        app.offline = true
        for id in BibleStore.offlineIDs {
            app.preferences.translation = id
            let reader = ReaderModel(app: app)
            reader.open("PSA", 23, verse: 1)
            XCTAssertEqual(reader.translation, id)
            XCTAssertEqual(reader.chapter?.translation, id)
            XCTAssertFalse(reader.verses.isEmpty, id)
            XCTAssertFalse(reader.loading, id)
        }
    }
    func testPreferenceSyncKeepsPositionAndDoesNotReplaceStoredRemoteChoice() {
        let app = AppModel()
        app.offline = true
        app.preferences.translation = "nlt"
        let reader = ReaderModel(app: app)
        reader.open("PSA", 23, verse: 3)
        app.preferences.translation = "bsb"
        reader.syncPreferredTranslation()
        XCTAssertEqual(reader.translation, "bsb")
        XCTAssertEqual(reader.currentRef?.description, "PSA.23.3")
        app.preferences.translation = "msg"
        reader.syncPreferredTranslation()
        XCTAssertEqual(reader.translation, "kjv")
        XCTAssertEqual(reader.currentRef?.description, "PSA.23.3")
        XCTAssertEqual(app.preferences.translation, "msg")
    }
}
