import Foundation
import SwiftData

@Model
final class FaceChart {
    var id: UUID
    var title: String
    var canvasImageData: Data?
    var notes: String
    var settingTechnique: String
    var lightingKelvin: Int
    var cameraType: String
    var lensType: String
    var createdAt: Date

    var customer: CustomerProfile?
    var appointment: Appointment?

    @Relationship(deleteRule: .cascade, inverse: \FaceChartPoint.faceChart)
    var points: [FaceChartPoint]

    init(
        title: String = "Face Chart",
        canvasImageData: Data? = nil,
        notes: String = "",
        settingTechnique: String = "",
        lightingKelvin: Int = 5600,
        cameraType: String = "",
        lensType: String = "",
        createdAt: Date = .now,
        points: [FaceChartPoint] = []
    ) {
        self.id = UUID()
        self.title = title
        self.canvasImageData = canvasImageData
        self.notes = notes
        self.settingTechnique = settingTechnique
        self.lightingKelvin = lightingKelvin
        self.cameraType = cameraType
        self.lensType = lensType
        self.createdAt = createdAt
        self.points = points
    }
}

@Model
final class FaceChartPoint {
    var id: UUID
    var zoneRaw: String
    var productCategoryRaw: String
    var brand: String
    var productName: String
    var shade: String
    var applicationNotes: String
    var coordinateX: Double
    var coordinateY: Double
    var sortOrder: Int

    var faceChart: FaceChart?

    var zone: FaceZone {
        get { FaceZone(rawValue: zoneRaw) ?? .fullFace }
        set { zoneRaw = newValue.rawValue }
    }

    var productCategory: ProductCategory {
        get { ProductCategory(rawValue: productCategoryRaw) ?? .other }
        set { productCategoryRaw = newValue.rawValue }
    }

    init(
        zone: FaceZone = .fullFace,
        productCategory: ProductCategory = .foundation,
        brand: String = "",
        productName: String = "",
        shade: String = "",
        applicationNotes: String = "",
        coordinateX: Double = 0.5,
        coordinateY: Double = 0.5,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.zoneRaw = zone.rawValue
        self.productCategoryRaw = productCategory.rawValue
        self.brand = brand
        self.productName = productName
        self.shade = shade
        self.applicationNotes = applicationNotes
        self.coordinateX = coordinateX
        self.coordinateY = coordinateY
        self.sortOrder = sortOrder
    }
}

@Model
final class MediaAsset {
    var id: UUID
    var title: String
    var imageData: Data?
    var thumbnailData: Data?
    var isBeforePhoto: Bool
    var isAfterPhoto: Bool
    var lightingEnvironmentRaw: String
    var lightingKelvin: Int
    var cameraType: String
    var lensType: String
    var seasonTag: String
    var humidityLevel: String
    var capturedAt: Date
    var notes: String

    var customer: CustomerProfile?
    var appointment: Appointment?

    var lightingEnvironment: LightingEnvironment {
        get { LightingEnvironment(rawValue: lightingEnvironmentRaw) ?? .unknown }
        set { lightingEnvironmentRaw = newValue.rawValue }
    }

    init(
        title: String = "",
        imageData: Data? = nil,
        thumbnailData: Data? = nil,
        isBeforePhoto: Bool = false,
        isAfterPhoto: Bool = true,
        lightingEnvironment: LightingEnvironment = .unknown,
        lightingKelvin: Int = 5600,
        cameraType: String = "",
        lensType: String = "",
        seasonTag: String = "",
        humidityLevel: String = "",
        capturedAt: Date = .now,
        notes: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.isBeforePhoto = isBeforePhoto
        self.isAfterPhoto = isAfterPhoto
        self.lightingEnvironmentRaw = lightingEnvironment.rawValue
        self.lightingKelvin = lightingKelvin
        self.cameraType = cameraType
        self.lensType = lensType
        self.seasonTag = seasonTag
        self.humidityLevel = humidityLevel
        self.capturedAt = capturedAt
        self.notes = notes
    }
}
