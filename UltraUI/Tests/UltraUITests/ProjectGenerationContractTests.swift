import Foundation
import XCTest

/// `project.yml` 用目录通配收集 `Demo` 与 `UltraUI/Tests` 下的源文件，新增文件后
/// 若忘记执行 `xcodegen generate`，文件不会进入 Xcode 工程，模拟器全量测试会静默
/// 漏跑而不报错。这里在宿主侧比对生成结果，把这种漏跑变成一次失败。
#if os(macOS)
final class ProjectGenerationContractTests: XCTestCase {
    func testDetectsSourceFileMissingFromSourcesBuildPhase() throws {
        let project = try Self.generatedProject()
        let names = try Self.swiftFileNames(in: ["UltraUI/Tests"])
        let victim = try XCTUnwrap(names.first)
        let stripped = project.replacingOccurrences(
            of: "/* \(victim) in Sources */",
            with: "/* RemovedFromBuildPhase.swift in Sources */"
        )

        XCTAssertEqual(Self.missingFromSourcesBuildPhase(project: stripped, fileNames: [victim]), [victim])
        XCTAssertEqual(Self.missingFromSourcesBuildPhase(project: project, fileNames: [victim]), [])
    }

    func testEveryDemoAndTestSourceFileIsCompiledByGeneratedProject() throws {
        let project = try Self.generatedProject()
        let names = try Self.swiftFileNames(in: ["Demo", "UltraUI/Tests"])

        XCTAssertGreaterThan(names.count, 100)
        XCTAssertEqual(Self.missingFromSourcesBuildPhase(project: project, fileNames: names), [])
    }

    private static let repoRoot: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static func generatedProject() throws -> String {
        let url = repoRoot.appendingPathComponent("UltraUIDemo.xcodeproj/project.pbxproj")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw XCTSkip("尚未生成 UltraUIDemo.xcodeproj，跳过工程同步契约检查")
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private static func swiftFileNames(in relativePaths: [String]) throws -> [String] {
        var names: Set<String> = []
        for relativePath in relativePaths {
            let root = repoRoot.appendingPathComponent(relativePath)
            guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else {
                throw XCTSkip("无法枚举 \(relativePath)，跳过工程同步契约检查")
            }
            for case let url as URL in enumerator where url.pathExtension == "swift" {
                names.insert(url.lastPathComponent)
            }
        }
        return names.sorted()
    }

    private static func missingFromSourcesBuildPhase(project: String, fileNames: [String]) -> [String] {
        fileNames.filter { !project.contains("/* \($0) in Sources */") }
    }
}
#endif
