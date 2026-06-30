import Foundation
import SwiftData

enum CancellationFeeCalculator {
    static func fee(
        for appointment: Appointment,
        tiers: [CancellationPolicyTier],
        cancelledAt: Date = .now
    ) -> Double {
        let hoursUntil = appointment.startDate.timeIntervalSince(cancelledAt) / 3600
        let sorted = tiers.sorted { $0.hoursBeforeAppointment > $1.hoursBeforeAppointment }
        guard let tier = sorted.first(where: { hoursUntil >= Double($0.hoursBeforeAppointment) }) ?? sorted.last else {
            return 0
        }
        let percentageFee = appointment.baseRate * (tier.feePercentage / 100)
        return max(percentageFee, tier.flatFee)
    }
}
