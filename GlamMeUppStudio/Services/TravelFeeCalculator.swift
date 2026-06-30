import Foundation
import CoreLocation

enum TravelFeeCalculator {
    static func distanceKm(
        from studioLat: Double,
        studioLon: Double,
        toLat: Double,
        toLon: Double
    ) -> Double {
        let studio = CLLocation(latitude: studioLat, longitude: studioLon)
        let venue = CLLocation(latitude: toLat, longitude: toLon)
        return studio.distance(from: venue) / 1000.0
    }

    static func calculateFee(
        distanceKm: Double,
        perKm: Double,
        minimum: Double,
        freeRadiusKm: Double
    ) -> Double {
        let chargeable = max(0, distanceKm - freeRadiusKm)
        return max(minimum, chargeable * perKm)
    }

    static func applyTravelFee(to appointment: Appointment, config: StudioConfiguration) {
        guard appointment.venueLatitude != 0, appointment.venueLongitude != 0 else { return }
        let km = distanceKm(
            from: config.studioLatitude,
            studioLon: config.studioLongitude,
            toLat: appointment.venueLatitude,
            toLon: appointment.venueLongitude
        )
        appointment.travelDistanceKm = km
        if appointment.manualTransportCost <= 0 {
            appointment.travelFee = calculateFee(
                distanceKm: km,
                perKm: config.travelFeePerKm,
                minimum: config.travelFeeMinimum,
                freeRadiusKm: config.travelFeeFreeRadiusKm
            )
        }
        appointment.recalculateTotals()
    }
}
