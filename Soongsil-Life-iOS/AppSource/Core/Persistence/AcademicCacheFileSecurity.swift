import Foundation

/// 서버에서 다시 만들 수 있는 학사 캐시가 백업에 포함되지 않도록 하고,
/// 기기가 잠겨 있는 동안에는 파일 내용을 읽을 수 없게 동일한 저장 정책을 적용합니다.
enum AcademicCacheFileSecurity {
    static func defaultDirectoryURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory
        return baseURL
            .appendingPathComponent("SoongsilLife", isDirectory: true)
            .appendingPathComponent("AcademicCache", isDirectory: true)
    }

    static func prepareDirectory(
        at directoryURL: URL,
        fileManager: FileManager
    ) -> Bool {
        do {
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            try? applyProtection(to: directoryURL, fileManager: fileManager)
            try? excludeFromBackup(directoryURL)
            return true
        } catch {
            return false
        }
    }

    static func secureFile(
        at fileURL: URL,
        fileManager: FileManager
    ) {
        // atomic write는 파일을 교체하므로 매 저장 뒤 속성을 다시 적용합니다.
        try? applyProtection(to: fileURL, fileManager: fileManager)
        try? excludeFromBackup(fileURL)
    }

    private static func applyProtection(
        to url: URL,
        fileManager: FileManager
    ) throws {
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }

    private static func excludeFromBackup(_ url: URL) throws {
        var mutableURL = url
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try mutableURL.setResourceValues(resourceValues)
    }
}
