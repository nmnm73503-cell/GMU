import Foundation
import UIKit
import PDFKit

enum ReceiptPDFGenerator {
    static func generate(
        receipt: Receipt,
        appointment: Appointment?,
        config: StudioConfiguration,
        logo: UIImage?
    ) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 48
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()
            var y = margin

            if let logo {
                let logoRect = CGRect(x: margin, y: y, width: 72, height: 72)
                logo.draw(in: logoRect)
                y += 80
            }

            let navy = UIColor(red: 0.1, green: 0.1, blue: 0.18, alpha: 1)
            let gold = UIColor(red: 0.79, green: 0.66, blue: 0.38, alpha: 1)

            drawText(config.businessName, at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 22), color: navy)
            y += 28
            drawText(config.tagline, at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 11), color: .gray)
            y += 18
            drawText("@\(config.instagramHandle)", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 11), color: gold)
            y += 36

            drawText("RECEIPT \(receipt.receiptNumber)", at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 14), color: navy)
            y += 22
            drawText("Date: \(receipt.issuedAt.formatted())", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 11), color: .darkGray)
            y += 28

            drawText("Bill To: \(receipt.clientName)", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 12, weight: .medium), color: navy)
            y += 30

            drawLine(atY: y, width: pageWidth - margin * 2, x: margin, color: gold)
            y += 16

            for item in receipt.lineItems.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                let line = "\(item.label)  ×\(item.quantity)    \(item.lineTotal.currencyFormatted(code: config.currencyCode))"
                drawText(line, at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 11), color: navy)
                y += 18
            }

            if receipt.travelFee > 0 {
                drawText("Transport  \(receipt.travelFee.currencyFormatted(code: config.currencyCode))", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 11), color: navy)
                y += 18
            }

            y += 8
            drawLine(atY: y, width: pageWidth - margin * 2, x: margin, color: gold)
            y += 16

            drawText("Subtotal  \(receipt.subtotal.currencyFormatted(code: config.currencyCode))", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 11), color: .darkGray)
            y += 16
            if receipt.taxAmount > 0 {
                drawText("Tax (\(Int(receipt.taxRate))%)  \(receipt.taxAmount.currencyFormatted(code: config.currencyCode))", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 11), color: .darkGray)
                y += 16
            }
            drawText("TOTAL  \(receipt.totalAmount.currencyFormatted(code: config.currencyCode))", at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 14), color: navy)
            y += 40

            if let appt = appointment {
                drawText("Service: \(appt.serviceLabel)", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 10), color: .gray)
                y += 14
            }

            for field in config.customFields.filter({ $0.isVisibleOnReceipt }) {
                let value = field.stringValue.isEmpty ? String(field.numberValue) : field.stringValue
                drawText("\(field.label): \(value)", at: CGPoint(x: margin, y: y), font: .systemFont(ofSize: 10), color: .gray)
                y += 14
            }

            y = pageHeight - margin - 40
            drawText(config.receiptFooterText, at: CGPoint(x: margin, y: y), font: .italicSystemFont(ofSize: 10), color: .gray)
        }
    }

    private static func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        text.draw(at: point, withAttributes: attrs)
    }

    private static func drawLine(atY y: CGFloat, width: CGFloat, x: CGFloat, color: UIColor) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y))
        color.setStroke()
        path.lineWidth = 1
        path.stroke()
    }
}
