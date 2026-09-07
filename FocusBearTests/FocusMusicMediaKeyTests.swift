//
//  FocusMusicMediaKeyTests.swift
//  Focus BearTests
//
//  Locks in how system media commands map onto focus-music playback (FOCUS-BEAR-MACOS-1CA): the
//  system's own `pause` (sleep, headphones unplugged) must never resume a paused track, `play` must
//  never pause, and only the hardware play/pause key toggles.
//

@testable import Focus_Bear
import XCTest

final class FocusMusicMediaKeyTests: XCTestCase {

    private typealias Command = FocusMusicViewModel.MediaKeyCommand

    private func resolve(_ command: Command, playing: Bool) -> Bool? {
        FocusMusicViewModel.resolvedPlaybackState(for: command, isPlaying: playing)
    }

    func testPauseWhilePlayingPauses() {
        XCTAssertEqual(resolve(.pause, playing: true), false)
    }

    func testPauseWhileAlreadyPausedIsANoOp() {
        // The 1CA regression: a second system Pause used to toggle the track back on.
        XCTAssertNil(resolve(.pause, playing: false))
    }

    func testPlayWhilePausedResumes() {
        XCTAssertEqual(resolve(.play, playing: false), true)
    }

    func testPlayWhileAlreadyPlayingIsANoOp() {
        XCTAssertNil(resolve(.play, playing: true))
    }

    func testToggleFlipsEitherWay() {
        XCTAssertEqual(resolve(.toggle, playing: true), false)
        XCTAssertEqual(resolve(.toggle, playing: false), true)
    }
}
