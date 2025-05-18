import SwiftUI
import LinkPresentation

// Extension untuk mengaktifkan rendering SwiftUI ke PDF
extension View {
    func renderAsImage() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .white

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// Helper untuk export PDF
class RecapExporter {
    static func exportRecapToPDF<Content: View>(
        content: Content,
        width: CGFloat = 834,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        // Render dengan delay kecil untuk memberikan waktu UI diupdate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Ukuran view port
            let exportView = content
                .frame(width: width)
                .padding(.top, 20)
                .padding(.bottom, 30)
            
            // Render view ke image
            let image = exportView.renderAsImage()
            
            // Generate PDF dari image
            if let pdfData = PDFGenerator.generatePDF(from: image, title: "Rekapan") {
                completion(.success(pdfData))
            } else {
                completion(.failure(PDFGenerationError()))
            }
        }
    }
}

// PDF Generator
struct PDFGenerator {
    static func generatePDF(from image: UIImage, title: String) -> Data? {
        // Buat PDF dari gambar
        let pdfData = NSMutableData()
        let pdfPageBounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        UIGraphicsBeginPDFContextToData(pdfData, pdfPageBounds, nil)
        UIGraphicsBeginPDFPage()
        
        // Gambar image ke PDF
        let context = UIGraphicsGetCurrentContext()!
        context.saveGState()
        context.setFillColor(UIColor.white.cgColor)
        context.fill(pdfPageBounds)
        image.draw(in: pdfPageBounds)
        context.restoreGState()
        
        UIGraphicsEndPDFContext()
        
        return pdfData as Data
    }
}

// Struct untuk menampilkan share sheet
struct PDFShareSheet: UIViewControllerRepresentable {
    var pdf: Data
    var subject: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Buat file temporary dengan nama simpel
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(subject).pdf")
        try? pdf.write(to: tempURL)
        
        // Buat preview data untuk PDF
        let previewProvider = PreviewItem(url: tempURL, title: subject)
        
        // Buat activity controller dengan hanya satu item
        let activityController = UIActivityViewController(
            activityItems: [previewProvider],
            applicationActivities: nil
        )
        
        return activityController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
    // Inner class untuk menyediakan preview untuk PDF
    class PreviewItem: NSObject, UIActivityItemSource {
        let url: URL
        let title: String
        
        init(url: URL, title: String) {
            self.url = url
            self.title = title
            super.init()
        }
        
        func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
            return url
        }
        
        func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            return url
        }
        
        func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
            let metadata = LPLinkMetadata()
            metadata.originalURL = url
            metadata.url = url
            metadata.title = title
            return metadata
        }
    }
}

// Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                Text("Menyiapkan dokumen...")
                    .foregroundColor(.black)
                    .font(.headline)
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5))
        }
    }
}

// Error struct untuk PDF generation
struct PDFGenerationError: Error {
    let message = "Gagal membuat file PDF"
}

// Helper untuk capture UIView dari SwiftUI View
struct ViewCaptureRepresentable: UIViewRepresentable {
    @Binding var viewContainer: UIView?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            viewContainer = view
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
