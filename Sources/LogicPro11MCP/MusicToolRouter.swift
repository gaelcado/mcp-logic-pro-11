import Foundation

enum MusicToolRouter {
    static func call(name: String, arguments: [String: Any]) throws -> [String: Any] {
        switch name {
        case "logic_status", "logic_diagnostic":
            guard arguments.isEmpty else { throw MIDIFileError.invalid("Cet outil ne prend aucun paramètre.") }
            let probe = LogicProbe.inspect()
            let details = probe.dictionary
            let message = name == "logic_diagnostic"
                ? "\(probe.summary) macOS \(details["macOSVersion"] ?? "inconnu") ; serveur \(details["serverVersion"] ?? "inconnu")."
                : probe.summary
            return result(message, details)
        case "midi_create_pattern":
            let clip = try MIDIClip(arguments: arguments)
            do {
                let (url, inspection, digest) = try MIDIFileStore.save(clip)
                var details = inspection.dictionary
                details.merge(["outcome": "confirmed", "fileConfirmed": true,
                               "logicImportQualification": "unverified",
                               "fileName": url.lastPathComponent, "path": url.path,
                               "sha256": digest]) { _, new in new }
                return result("Motif MIDI créé : \(url.path). Importez ce fichier dans Logic Pro ; son import reste à qualifier par les pilotes 11.1 et 11.2.", details)
            } catch {
                return failure("Création du fichier MIDI refusée : \(error.localizedDescription)")
            }
        case "midi_inspect_export":
            guard Set(arguments.keys) == ["fileName"], let fileName = arguments["fileName"] as? String,
                  (1...128).contains(fileName.count),
                  fileName == URL(fileURLWithPath: fileName).lastPathComponent,
                  !fileName.hasPrefix("."), fileName.hasSuffix(".mid") else {
                throw MIDIFileError.invalid("Indiquez le nom d'un fichier .mid exporté, sans chemin.")
            }
            do {
                let (url, inspection, digest) = try MIDIFileStore.inspectExport(fileName: fileName)
                var details = inspection.dictionary
                details.merge(["outcome": "confirmed", "fileConfirmed": true,
                               "logicImportQualification": "unverified",
                               "fileName": fileName, "path": url.path,
                               "sha256": digest]) { _, new in new }
                return result("Fichier MIDI vérifié : \(url.path). \(inspection.totalNotes) notes ; import Logic non vérifié.", details)
            } catch {
                return failure("Lecture du fichier MIDI impossible : \(error.localizedDescription)")
            }
        default:
            throw MIDIFileError.invalid("Outil inconnu.")
        }
    }

    private static func result(_ message: String, _ details: [String: Any]) -> [String: Any] {
        ["content": [["type": "text", "text": message]],
         "structuredContent": details, "isError": false]
    }

    private static func failure(_ message: String) -> [String: Any] {
        ["content": [["type": "text", "text": message]],
         "structuredContent": ["outcome": "refused", "fileConfirmed": false,
                               "logicImportQualification": "unverified", "reason": message],
         "isError": true]
    }
}
