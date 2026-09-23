import Foundation
import XCTest
@testable import LogicPro11MCP

final class MIDITests: XCTestCase {
    private let example: [String: Any] = [
        "name": "Accord été", "tempoBPM": 120, "beatsPerBar": 4,
        "tracks": [
            ["name": "Piano", "channel": 1, "notes": [
                ["pitch": 60, "velocity": 100, "startBeat": 0, "durationBeats": 1],
                ["pitch": 64, "velocity": 90, "startBeat": 1, "durationBeats": 1]]],
            ["name": "Basse", "channel": 2, "notes": [
                ["pitch": 36, "startBeat": 0, "durationBeats": 2]]]
        ]
    ]

    func testFormatOneRoundTripAndExport() throws {
        let clip = try MIDIClip(arguments: example)
        let data = clip.data()
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "MThd")
        let parsed = try MIDIInspector.inspect(data)
        XCTAssertEqual(parsed.trackCount, 3)
        XCTAssertEqual(parsed.noteCounts, [0, 2, 1])
        XCTAssertEqual(parsed.trackNames, ["", "Piano", "Basse"])
        XCTAssertEqual(parsed.tempoBPM, 120)
        XCTAssertEqual(parsed.beatsPerBar, 4)
        XCTAssertEqual(parsed.ticksPerBeat, 480)

        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let (url, saved, digest) = try MIDIFileStore.save(clip, directory: folder)
        XCTAssertEqual(saved.totalNotes, 3)
        XCTAssertEqual(try Data(contentsOf: url), data)
        let (readURL, read, readDigest) = try MIDIFileStore.inspectExport(fileName: url.lastPathComponent, directory: folder)
        XCTAssertEqual(readURL, url)
        XCTAssertEqual(read.totalNotes, 3)
        XCTAssertEqual(readDigest, digest)
        XCTAssertThrowsError(try MIDIFileStore.inspectExport(fileName: "../\(url.lastPathComponent)", directory: folder))
        let link = folder.appendingPathComponent("lien.mid")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: url)
        XCTAssertThrowsError(try MIDIFileStore.inspectExport(fileName: link.lastPathComponent, directory: folder))
    }

    func testRejectsMalformedNotesAndFiles() throws {
        var invalid = example
        invalid["tracks"] = [["name": "Piano", "notes": [["pitch": 128, "startBeat": 0, "durationBeats": 1]]]]
        XCTAssertThrowsError(try MIDIClip(arguments: invalid))
        invalid["tracks"] = [["name": "Piano", "notes": [["pitch": 60, "startBeat": 0, "durationBeats": 0.00001]]]]
        XCTAssertThrowsError(try MIDIClip(arguments: invalid))
        let clip = try MIDIClip(arguments: example)
        var truncated = clip.data()
        truncated.removeLast()
        XCTAssertThrowsError(try MIDIInspector.inspect(truncated))
    }
}
