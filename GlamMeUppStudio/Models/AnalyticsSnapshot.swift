import Foundation
import SwiftData

@Model
final class AnalyticsSnapshot {
    var id: UUID
    var capturedAt: Date
    var instagramUsername: String
    var followerCount: Int
    var followingCount: Int
    var postCount: Int
    var averageLikes: Double
    var source: String
    var notes: String

    init(
        capturedAt: Date = .now,
        instagramUsername: String = "glam.me.upp",
        followerCount: Int = 0,
        followingCount: Int = 0,
        postCount: Int = 0,
        averageLikes: Double = 0,
        source: String = "api",
        notes: String = ""
    ) {
        self.id = UUID()
        self.capturedAt = capturedAt
        self.instagramUsername = instagramUsername
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.postCount = postCount
        self.averageLikes = averageLikes
        self.source = source
        self.notes = notes
    }
}

@Model
final class ImportMetadata {
    var id: UUID
    var sourceFile: String
    var importedAt: Date
    var clientCount: Int
    var appointmentCount: Int
    var expenseCount: Int
    var allocationCount: Int
    var version: Int

    init(
        sourceFile: String,
        importedAt: Date = .now,
        clientCount: Int = 0,
        appointmentCount: Int = 0,
        expenseCount: Int = 0,
        allocationCount: Int = 0,
        version: Int = 1
    ) {
        self.id = UUID()
        self.sourceFile = sourceFile
        self.importedAt = importedAt
        self.clientCount = clientCount
        self.appointmentCount = appointmentCount
        self.expenseCount = expenseCount
        self.allocationCount = allocationCount
        self.version = version
    }
}
