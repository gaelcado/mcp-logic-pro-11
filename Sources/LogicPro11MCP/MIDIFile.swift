import CryptoKit
import CoreFoundation
import Darwin
import Foundation

enum MIDIFileError: Error, CustomStringConvertible {
    case invalid(String)
    case corrupt(String)

    var description: String {
        switch self {
        case .invalid(let message), .corrupt(let message): return message
        }
    }
}

struct MIDINote {
    let pitch: UInt8
    let velocity: UInt8
    let startTick: Int
    let endTick: Int
}

struct MIDITrack {
    let name: String
    let channel: UInt8 // MIDI wire channel, zero based
    let notes: [MIDINote]
}

struct MIDIClip {
    static let ticksPerBeat = 480
    let name: String
    let tempoBPM: Int
    let beatsPerBar: Int
    let tracks: [MIDITrack]

    init(arguments: [String: Any]) throws {
        guard Set(arguments.keys).isSubset(of: ["name", "tempoBPM", "beatsPerBar", "tracks"]) else {
            throw MIDIFileError.invalid("Paramètre MIDI inconnu.")
        }
        let name = arguments["name"] as? String ?? "Motif MIDI"
        guard Self.validName(name) else { throw MIDIFileError.invalid("Le nom doit contenir 1 à 40 caractères simples, sans chemin.") }
        self.name = name
        let tempo = Self.integer(arguments["tempoBPM"] ?? 120)
        guard let tempo, (20...300).contains(tempo) else { throw MIDIFileError.invalid("Le tempo doit être entre 20 et 300 BPM.") }
        tempoBPM = tempo
        let meter = Self.integer(arguments["beatsPerBar"] ?? 4)
        guard let meter, (2...12).contains(meter) else { throw MIDIFileError.invalid("La mesure doit contenir 2 à 12 temps.") }
        beatsPerBar = meter
        guard let rawTracks = arguments["tracks"] as? [[String: Any]],
              (1...8).contains(rawTracks.count) else {
            throw MIDIFileError.invalid("Fournissez 1 à 8 pistes MIDI.")
        }
        var parsed: [MIDITrack] = []
        var totalNotes = 0
        for (trackIndex, rawTrack) in rawTracks.enumerated() {
            guard Set(rawTrack.keys).isSubset(of: ["name", "channel", "notes"]),
                  let trackName = rawTrack["name"] as? String, Self.validName(trackName) else {
                throw MIDIFileError.invalid("Chaque piste doit avoir un nom simple de 1 à 40 caractères.")
            }
            let channel = Self.integer(rawTrack["channel"] ?? trackIndex + 1)
            guard let channel, (1...16).contains(channel) else {
                throw MIDIFileError.invalid("Le canal MIDI doit être entre 1 et 16.")
            }
            guard let rawNotes = rawTrack["notes"] as? [[String: Any]], rawNotes.count <= 512 else {
                throw MIDIFileError.invalid("Une piste contient au plus 512 notes.")
            }
            totalNotes += rawNotes.count
            guard totalNotes <= 2048 else { throw MIDIFileError.invalid("Le motif contient au plus 2048 notes.") }
            var notes: [MIDINote] = []
            for rawNote in rawNotes {
                guard Set(rawNote.keys).isSubset(of: ["pitch", "velocity", "startBeat", "durationBeats"]),
                      let pitch = Self.integer(rawNote["pitch"]), (0...127).contains(pitch),
                      let velocity = Self.integer(rawNote["velocity"] ?? 100), (1...127).contains(velocity),
                      let start = Self.number(rawNote["startBeat"]), start >= 0, start < 256,
                      let duration = Self.number(rawNote["durationBeats"]), duration > 0, duration <= 64,
                      start + duration <= 256 else {
                    throw MIDIFileError.invalid("Note invalide : hauteur 0–127, vélocité 1–127, début et durée dans 256 temps.")
                }
                let startTick = Int((start * Double(Self.ticksPerBeat)).rounded())
                let endTick = Int(((start + duration) * Double(Self.ticksPerBeat)).rounded())
                guard endTick > startTick else { throw MIDIFileError.invalid("La note est plus courte qu'un tick MIDI.") }
                notes.append(MIDINote(pitch: UInt8(pitch), velocity: UInt8(velocity),
                                      startTick: startTick, endTick: endTick))
            }
            parsed.append(MIDITrack(name: trackName, channel: UInt8(channel - 1), notes: notes))
        }
        tracks = parsed
    }

    private static func integer(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let double = number.doubleValue
        guard double.isFinite, double.rounded() == double, abs(double) < 1_000_000 else { return nil }
        return Int(double)
    }

    private static func number(_ value: Any?) -> Double? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let double = number.doubleValue
        return double.isFinite ? double : nil
    }

    private static func validName(_ name: String) -> Bool {
        guard (1...40).contains(name.count), name == name.trimmingCharacters(in: .whitespaces), !name.isEmpty else { return false }
        return name.unicodeScalars.allSatisfy { scalar in
            CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) ||
            scalar.value == 32 || scalar.value == 45 || scalar.value == 95
        }
    }

    func data() -> Data {
        var file = Data("MThd".utf8)
        file.appendBE32(6)
        file.appendBE16(1) // Standard MIDI File format 1
        file.appendBE16(UInt16(tracks.count + 1)) // conductor plus musical tracks
        file.appendBE16(UInt16(Self.ticksPerBeat))

        var conductor = Data()
        let tempo = Int((60_000_000.0 / Double(tempoBPM)).rounded())
        conductor.append(contentsOf: [0, 0xFF, 0x51, 3,
                                      UInt8((tempo >> 16) & 0xFF), UInt8((tempo >> 8) & 0xFF), UInt8(tempo & 0xFF)])
        conductor.append(contentsOf: [0, 0xFF, 0x58, 4, UInt8(beatsPerBar), 2, 24, 8])
        conductor.append(contentsOf: [0, 0xFF, 0x2F, 0])
        file.appendTrack(conductor)

        for track in tracks {
            var bytes = Data()
            let nameBytes = Array(track.name.utf8)
            bytes.append(contentsOf: [0, 0xFF, 0x03])
            bytes.appendVLQ(nameBytes.count)
            bytes.append(contentsOf: nameBytes)
            var events: [(tick: Int, priority: Int, ordinal: Int, bytes: [UInt8])] = []
            for (index, note) in track.notes.enumerated() {
                events.append((note.endTick, 0, index, [0x80 | track.channel, note.pitch, 0]))
                events.append((note.startTick, 1, index, [0x90 | track.channel, note.pitch, note.velocity]))
            }
            events.sort {
                if $0.tick != $1.tick { return $0.tick < $1.tick }
                if $0.priority != $1.priority { return $0.priority < $1.priority }
                return $0.ordinal < $1.ordinal
            }
            var previousTick = 0
            for event in events {
                bytes.appendVLQ(event.tick - previousTick)
                bytes.append(contentsOf: event.bytes)
                previousTick = event.tick
            }
            bytes.append(contentsOf: [0, 0xFF, 0x2F, 0])
            file.appendTrack(bytes)
        }
        return file
    }
}

private extension Data {
    mutating func appendBE16(_ value: UInt16) {
        append(contentsOf: [UInt8(value >> 8), UInt8(value & 0xFF)])
    }
    mutating func appendBE32(_ value: UInt32) {
        append(contentsOf: [UInt8((value >> 24) & 0xFF), UInt8((value >> 16) & 0xFF),
                             UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)])
    }
    mutating func appendVLQ(_ value: Int) {
        var parts = [UInt8(value & 0x7F)]
        var remaining = value >> 7
        while remaining > 0 {
            parts.insert(UInt8(remaining & 0x7F) | 0x80, at: 0)
            remaining >>= 7
        }
        append(contentsOf: parts)
    }
    mutating func appendTrack(_ track: Data) {
        append(contentsOf: Data("MTrk".utf8))
        appendBE32(UInt32(track.count))
        append(track)
    }
}

struct MIDIInspection {
    let trackCount: Int
    let noteCounts: [Int]
    let trackNames: [String]
    let tempoBPM: Int?
    let beatsPerBar: Int?
    let ticksPerBeat: Int

    var totalNotes: Int { noteCounts.reduce(0, +) }

    var dictionary: [String: Any] {
        ["format": 1, "trackCount": trackCount, "trackNames": trackNames,
         "noteCounts": noteCounts, "totalNotes": totalNotes,
         "tempoBPM": tempoBPM as Any? ?? NSNull(),
         "beatsPerBar": beatsPerBar as Any? ?? NSNull(), "ticksPerBeat": ticksPerBeat]
    }
}

enum MIDIInspector {
    static func inspect(_ data: Data) throws -> MIDIInspection {
        guard data.count >= 14, data.count <= 2_000_000,
              String(data: data[0..<4], encoding: .ascii) == "MThd",
              be32(data, 4) == 6, be16(data, 8) == 1,
              let count = be16(data, 10), (2...9).contains(count),
              let division = be16(data, 12), division > 0, division < 0x8000 else {
            throw MIDIFileError.corrupt("En-tête MIDI format 1 invalide ou fichier trop grand.")
        }
        var offset = 14
        var names: [String] = []
        var notes: [Int] = []
        var tempo: Int?
        var meter: Int?
        for _ in 0..<count {
            guard offset + 8 <= data.count,
                  String(data: data[offset..<(offset + 4)], encoding: .ascii) == "MTrk",
                  let length = be32(data, offset + 4),
                  length <= data.count - offset - 8 else {
                throw MIDIFileError.corrupt("Piste MIDI tronquée.")
            }
            var cursor = offset + 8
            let end = cursor + length
            var name = ""
            var noteCount = 0
            var runningStatus: UInt8?
            var ended = false
            while cursor < end {
                _ = try vlq(data, &cursor, end)
                guard cursor < end else { throw MIDIFileError.corrupt("Événement MIDI tronqué.") }
                let first = data[cursor]
                let status: UInt8
                if first & 0x80 != 0 {
                    status = first
                    cursor += 1
                    runningStatus = status < 0xF0 ? status : nil
                } else {
                    guard let previous = runningStatus else { throw MIDIFileError.corrupt("Running status MIDI invalide.") }
                    status = previous
                }
                if status == 0xFF {
                    guard cursor < end else { throw MIDIFileError.corrupt("Méta-événement MIDI tronqué.") }
                    let kind = data[cursor]; cursor += 1
                    let size = try vlq(data, &cursor, end)
                    guard size <= end - cursor else { throw MIDIFileError.corrupt("Méta-événement MIDI hors limites.") }
                    if kind == 0x03 { name = String(data: data[cursor..<(cursor + size)], encoding: .utf8) ?? "(nom illisible)" }
                    if kind == 0x51 && size == 3 {
                        let micros = Int(data[cursor]) << 16 | Int(data[cursor + 1]) << 8 | Int(data[cursor + 2])
                        if micros > 0 { tempo = Int((60_000_000.0 / Double(micros)).rounded()) }
                    }
                    if kind == 0x58 && size == 4 && data[cursor + 1] == 2 {
                        meter = Int(data[cursor])
                    }
                    if kind == 0x2F { ended = true }
                    cursor += size
                } else if status == 0xF0 || status == 0xF7 {
                    let size = try vlq(data, &cursor, end)
                    guard size <= end - cursor else { throw MIDIFileError.corrupt("SysEx MIDI hors limites.") }
                    cursor += size
                } else if status < 0xF0 {
                    let kind = status & 0xF0
                    let width = kind == 0xC0 || kind == 0xD0 ? 1 : 2
                    guard cursor + width <= end else { throw MIDIFileError.corrupt("Message MIDI tronqué.") }
                    if kind == 0x90 && data[cursor + 1] > 0 { noteCount += 1 }
                    cursor += width
                } else {
                    throw MIDIFileError.corrupt("Message système MIDI non pris en charge.")
                }
            }
            guard ended else { throw MIDIFileError.corrupt("Fin de piste MIDI absente.") }
            names.append(name)
            notes.append(noteCount)
            offset = end
        }
        guard offset == data.count else { throw MIDIFileError.corrupt("Données supplémentaires après les pistes MIDI.") }
        return MIDIInspection(trackCount: count, noteCounts: notes, trackNames: names,
                              tempoBPM: tempo, beatsPerBar: meter, ticksPerBeat: division)
    }

    private static func be16(_ data: Data, _ offset: Int) -> Int? {
        guard offset + 2 <= data.count else { return nil }
        return Int(data[offset]) << 8 | Int(data[offset + 1])
    }
    private static func be32(_ data: Data, _ offset: Int) -> Int? {
        guard offset + 4 <= data.count else { return nil }
        return Int(data[offset]) << 24 | Int(data[offset + 1]) << 16 |
               Int(data[offset + 2]) << 8 | Int(data[offset + 3])
    }
    private static func vlq(_ data: Data, _ cursor: inout Int, _ end: Int) throws -> Int {
        var result = 0
        for _ in 0..<4 {
            guard cursor < end else { throw MIDIFileError.corrupt("Longueur variable MIDI tronquée.") }
            let byte = data[cursor]; cursor += 1
            result = (result << 7) | Int(byte & 0x7F)
            if byte & 0x80 == 0 { return result }
        }
        throw MIDIFileError.corrupt("Longueur variable MIDI trop longue.")
    }
}

enum MIDIFileStore {
    static func exportDirectory() -> URL {
        if let configured = ProcessInfo.processInfo.environment["LOGIC_MCP_EXPORT_DIR"],
           !configured.isEmpty, configured.hasPrefix("/") {
            return URL(fileURLWithPath: configured, isDirectory: true)
        }
        let music = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Music", isDirectory: true)
        return music.appendingPathComponent("Logic Pro 11 MCP Exports", isDirectory: true)
    }

    static func save(_ clip: MIDIClip, directory: URL? = nil) throws -> (URL, MIDIInspection, String) {
        let data = clip.data()
        let inspection = try MIDIInspector.inspect(data)
        guard inspection.totalNotes == clip.tracks.reduce(0, { $0 + $1.notes.count }) else {
            throw MIDIFileError.corrupt("Les notes MIDI générées ne correspondent pas à la demande.")
        }
        let folder = directory ?? exportDirectory()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let fileName = clip.name.replacingOccurrences(of: " ", with: "-") + "-" + UUID().uuidString + ".mid"
        let url = folder.appendingPathComponent(fileName, isDirectory: false)
        let descriptor = open(url.path, O_CREAT | O_EXCL | O_WRONLY, 0o600)
        guard descriptor >= 0 else { throw MIDIFileError.invalid("Impossible de créer un nouveau fichier MIDI.") }
        do {
            let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
            try handle.write(contentsOf: data)
            try handle.synchronize()
            try handle.close()
            guard try Data(contentsOf: url) == data else { throw MIDIFileError.corrupt("La vérification du fichier MIDI a échoué.") }
            let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            return (url, inspection, digest)
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    static func inspectExport(fileName: String, directory: URL? = nil) throws -> (URL, MIDIInspection, String) {
        guard (1...128).contains(fileName.count),
              fileName == URL(fileURLWithPath: fileName).lastPathComponent,
              !fileName.hasPrefix("."), fileName.hasSuffix(".mid") else {
            throw MIDIFileError.invalid("Indiquez seulement le nom d'un fichier .mid exporté.")
        }
        let folder = directory ?? exportDirectory()
        let url = folder.appendingPathComponent(fileName, isDirectory: false)
        let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW)
        guard descriptor >= 0 else {
            throw MIDIFileError.invalid("Le fichier MIDI est absent ou inaccessible.")
        }
        defer { _ = Darwin.close(descriptor) }
        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0,
              (metadata.st_mode & S_IFMT) == S_IFREG,
              metadata.st_size <= 2_000_000 else {
            throw MIDIFileError.invalid("Le fichier MIDI est absent, lié ou trop grand.")
        }
        let data = try FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
            .read(upToCount: 2_000_001) ?? Data()
        let inspection = try MIDIInspector.inspect(data)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return (url, inspection, digest)
    }
}
