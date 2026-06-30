import Foundation

enum FitzpatrickType: String, Codable, CaseIterable, Identifiable {
    case typeI = "Type I"
    case typeII = "Type II"
    case typeIII = "Type III"
    case typeIV = "Type IV"
    case typeV = "Type V"
    case typeVI = "Type VI"

    var id: String { rawValue }
}

enum SkinHydrationBaseline: String, Codable, CaseIterable, Identifiable {
    case dry, normal, combination, oily, dehydrated

    var id: String { rawValue }
}

enum AppointmentStatus: String, Codable, CaseIterable, Identifiable {
    case inquiry, confirmed, depositPaid, completed, cancelled, noShow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inquiry: return "Inquiry"
        case .confirmed: return "Confirmed"
        case .depositPaid: return "Deposit Paid"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .noShow: return "No Show"
        }
    }
}

enum AppointmentType: String, Codable, CaseIterable, Identifiable {
    case bridal, event, photoshoot, touchUp, consultation, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bridal: return "Bridal"
        case .event: return "Event"
        case .photoshoot: return "Photoshoot"
        case .touchUp: return "Touch-Up"
        case .consultation: return "Consultation"
        case .other: return "Other"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case card, cash, mpesa, bank_MM, transfer_bank, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .card: return "Card"
        case .cash: return "Cash"
        case .mpesa: return "M-Pesa"
        case .bank_MM: return "Bank Transfer"
        case .transfer_bank: return "Bank Transfer"
        case .other: return "Other"
        }
    }
}

enum MakeupServiceStyle: String, Codable, CaseIterable, Identifiable {
    case simple, soft, dramatic, bridalTrial, bridal, cancelled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .soft: return "Soft"
        case .dramatic: return "Dramatic"
        case .bridalTrial: return "Simple Bridal Trial"
        case .bridal: return "Bridal"
        case .cancelled: return "Cancelled"
        }
    }
}

enum HeadcountTier: String, Codable, CaseIterable, Identifiable {
    case oneToTwo = "1-2"
    case threePlus = "3+"

    var id: String { rawValue }

    var displayName: String { rawValue }
}

enum LeadSource: String, Codable, CaseIterable, Identifiable {
    case referral, instagram, tiktok, walkIn, repeatClient, weddingPlanner, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .referral: return "Referral"
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .walkIn: return "Walk-In"
        case .repeatClient: return "Repeat Client"
        case .weddingPlanner: return "Wedding Planner"
        case .other: return "Other"
        }
    }
}

enum PaymentType: String, Codable, CaseIterable, Identifiable {
    case deposit, partial, final, refund, cancellationFee

    var id: String { rawValue }
}

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case productRestock, disposables, travelFuel, education, equipment, marketing, studio, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .productRestock: return "Product Restock"
        case .disposables: return "Disposables"
        case .travelFuel: return "Travel & Fuel"
        case .education: return "Education"
        case .equipment: return "Equipment"
        case .marketing: return "Marketing"
        case .studio: return "Studio"
        case .other: return "Other"
        }
    }
}

enum LightingEnvironment: String, Codable, CaseIterable, Identifiable {
    case studioRingLight, naturalOutdoor, windowLight, flashPhotography, mixed, unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .studioRingLight: return "Studio Ring Light"
        case .naturalOutdoor: return "Natural Outdoor"
        case .windowLight: return "Window Light"
        case .flashPhotography: return "Flash Photography"
        case .mixed: return "Mixed"
        case .unknown: return "Unknown"
        }
    }
}

enum FaceZone: String, Codable, CaseIterable, Identifiable {
    case forehead, leftCheek, rightCheek, nose, chin, jawline, underEye, lips, brows, fullFace

    var id: String { rawValue }
}

enum ProductCategory: String, Codable, CaseIterable, Identifiable {
    case primer, foundation, concealer, powder, blush, bronzer, highlight, eyeshadow, liner, mascara, lip, setting, other

    var id: String { rawValue }
}

enum BridalPartyRole: String, Codable, CaseIterable, Identifiable {
    case bride, bridesmaid, motherOfBride, motherOfGroom, flowerGirl, guestOfHonor, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bride: return "Bride"
        case .bridesmaid: return "Bridesmaid"
        case .motherOfBride: return "Mother of Bride"
        case .motherOfGroom: return "Mother of Groom"
        case .flowerGirl: return "Flower Girl"
        case .guestOfHonor: return "Guest of Honor"
        case .other: return "Other"
        }
    }
}

enum TimelineEventType: String, Codable, CaseIterable, Identifiable {
    case appointment, payment, note, formulaChange, mediaAdded, receiptGenerated, touchUpSent

    var id: String { rawValue }
}

enum CustomFieldType: String, Codable, CaseIterable, Identifiable {
    case text, number, boolean, date, currency, percentage, url, color

    var id: String { rawValue }
}

enum CustomFieldScope: String, Codable, CaseIterable, Identifiable {
    case global, client, appointment, receipt, expense, kit

    var id: String { rawValue }
}

enum KitItemStatus: String, Codable, CaseIterable, Identifiable {
    case active, lowStock, expired, disposed

    var id: String { rawValue }
}
