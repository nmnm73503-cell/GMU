import SwiftUI
import SwiftData
import PDFKit

struct ReceiptPreviewView: View {
    let pdfData: Data
    let receiptNumber: String

    var body: some View {
        PDFKitView(data: pdfData)
            .navigationTitle(receiptNumber)
            .background(Theme.cream)
    }
}

struct PDFKitView: UIViewRepresentable {
    let data: Data
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = PDFDocument(data: data)
        view.autoScales = true
        return view
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

struct ReceiptListView: View {
    @Query(sort: \Receipt.issuedAt, order: .reverse) private var receipts: [Receipt]

    var body: some View {
        List(receipts) { receipt in
            if let pdf = receipt.pdfData {
                NavigationLink(receipt.receiptNumber) {
                    ReceiptPreviewView(pdfData: pdf, receiptNumber: receipt.receiptNumber)
                }
            } else {
                Text(receipt.receiptNumber)
            }
        }
        .navigationTitle("Receipts")
    }
}
