import Foundation
import OSLog

public enum ImportMode: String, Sendable {
    case merge
    case replace
}

public struct ImportPreview: Equatable, Sendable {
    public let schemaVersion: Int
    public let presetCount: Int
    public let scheduleCount: Int
    public let appRuleCount: Int

    public init(configuration: AwakeConfiguration) {
        schemaVersion = configuration.schemaVersion
        presetCount = configuration.presets.count
        scheduleCount = configuration.schedules.count
        appRuleCount = configuration.appRules.count
    }
}

public enum ConfigurationStoreError: LocalizedError, Equatable, Sendable {
    case unsupportedSchema(Int)
    case invalidImport
    case unableToCreateDirectory

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let version):
            return "This configuration was created by a newer version (schema \(version))."
        case .invalidImport:
            return "The configuration could not be read. Nothing was changed."
        case .unableToCreateDirectory:
            return "CapsAwake could not prepare its settings folder."
        }
    }
}

public struct ConfigurationStore: Sendable {
    private static let logger = Logger(subsystem: "com.gaijindev.CapsAwake", category: "persistence")
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func appSupportStore(
        fileManager: FileManager = .default,
        appName: String = "CapsAwake"
    ) throws -> ConfigurationStore {
        let directory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent(appName, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return ConfigurationStore(fileURL: directory.appendingPathComponent("configuration.json"))
    }

    public func load() throws -> AwakeConfiguration {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return AwakeConfiguration() }
        do {
            let data = try Data(contentsOf: fileURL)
            let configuration = try JSONDecoder.capsAwake.decode(AwakeConfiguration.self, from: data)
            guard configuration.schemaVersion <= AwakeConfiguration.currentSchemaVersion else {
                throw ConfigurationStoreError.unsupportedSchema(configuration.schemaVersion)
            }
            return migrate(configuration)
        } catch let error as ConfigurationStoreError {
            throw error
        } catch {
            Self.logger.error("Configuration decode failed; quarantining the file")
            try quarantineCorruptFile()
            return AwakeConfiguration()
        }
    }

    public func save(_ configuration: AwakeConfiguration) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder.capsAwake.encode(configuration)
        let temporaryURL = directory.appendingPathComponent("configuration.\(UUID().uuidString).tmp")
        try data.write(to: temporaryURL, options: [.atomic])
        if FileManager.default.fileExists(atPath: fileURL.path) {
            _ = try FileManager.default.replaceItemAt(
                fileURL, withItemAt: temporaryURL, backupItemName: nil, options: .usingNewMetadataOnly)
        } else {
            try FileManager.default.moveItem(at: temporaryURL, to: fileURL)
        }
    }

    public func exportData(_ configuration: AwakeConfiguration) throws -> Data {
        try JSONEncoder.capsAwake.encode(configuration)
    }

    public func previewImport(_ data: Data) throws -> ImportPreview {
        let configuration = try decodeImport(data)
        return ImportPreview(configuration: configuration)
    }

    public func importData(_ data: Data, mode: ImportMode, into current: AwakeConfiguration) throws
        -> AwakeConfiguration
    {
        let incoming = try decodeImport(data)
        switch mode {
        case .replace:
            return incoming
        case .merge:
            return merge(incoming, into: current)
        }
    }

    private func decodeImport(_ data: Data) throws -> AwakeConfiguration {
        do {
            let configuration = try JSONDecoder.capsAwake.decode(AwakeConfiguration.self, from: data)
            guard configuration.schemaVersion <= AwakeConfiguration.currentSchemaVersion else {
                throw ConfigurationStoreError.unsupportedSchema(configuration.schemaVersion)
            }
            return migrate(configuration)
        } catch let error as ConfigurationStoreError {
            throw error
        } catch {
            throw ConfigurationStoreError.invalidImport
        }
    }

    private func migrate(_ configuration: AwakeConfiguration) -> AwakeConfiguration {
        var migrated = configuration
        migrated.schemaVersion = AwakeConfiguration.currentSchemaVersion
        return migrated
    }

    private func merge(_ incoming: AwakeConfiguration, into current: AwakeConfiguration) -> AwakeConfiguration {
        var merged = current
        let existingPresetIDs = Set(merged.presets.map(\.id))
        merged.presets += incoming.presets.filter { !existingPresetIDs.contains($0.id) }
        let existingScheduleIDs = Set(merged.schedules.map(\.id))
        merged.schedules += incoming.schedules.filter { !existingScheduleIDs.contains($0.id) }
        let existingRuleIDs = Set(merged.appRules.map(\.id))
        merged.appRules += incoming.appRules.filter { !existingRuleIDs.contains($0.id) }
        let existingTimerIDs = Set(merged.timerSessions.map(\.id))
        merged.timerSessions += incoming.timerSessions.filter { !existingTimerIDs.contains($0.id) }
        merged.onboardingCompleted = current.onboardingCompleted || incoming.onboardingCompleted
        merged.launchAtLogin = incoming.launchAtLogin
        merged.timerEndNotifications = incoming.timerEndNotifications
        merged.assertionFailureNotifications = incoming.assertionFailureNotifications
        return merged
    }

    private func quarantineCorruptFile() throws {
        let backup = fileURL.deletingPathExtension().appendingPathExtension(
            "corrupt-\(Int(Date().timeIntervalSince1970)).json")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.moveItem(at: fileURL, to: backup)
        }
    }
}

extension JSONEncoder {
    fileprivate static var capsAwake: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    fileprivate static var capsAwake: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
