import SwiftUI
import SwiftData
import Charts

struct RecapView: View {
    @State private var selectedDate = Date()
    @State private var isPresented = false
    @State private var showShareSheet = false
    @State private var pdfData: Data?
    @State private var isGeneratingPDF = false
    @State private var showAlert = false
    @State private var isExportingPDF = false
    @Environment(\.modelContext) private var modelContext
    
    // Reference untuk container view yang akan di-capture
    @State private var viewContainer: UIView?
    
    // Query data transaksi dari SwiftData
    @Query private var allSales: [Sales]
    
    // Computed properties untuk mendapatkan data berdasarkan bulan yang dipilih
    private var filteredSales: [Sales] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedDate)
        
        guard let startDate = calendar.date(from: components),
              let _ = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
            return []
        }
        
        return allSales.filter { sale in
            let saleComponents = calendar.dateComponents([.year, .month], from: sale.date)
            return saleComponents.year == components.year && saleComponents.month == components.month
        }
    }
    
    // Computed property untuk data bulan sebelumnya
    private var previousMonthSales: [Sales] {
        let calendar = Calendar.current
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedDate) else {
            return []
        }
        
        let components = calendar.dateComponents([.year, .month], from: previousMonth)
        
        return allSales.filter { sale in
            let saleComponents = calendar.dateComponents([.year, .month], from: sale.date)
            return saleComponents.year == components.year && saleComponents.month == components.month
        }
    }
    
    // Computed property untuk total penjualan
    private var totalRevenue: Int {
        return filteredSales.reduce(0) { $0 + $1.totalPrice }
    }
    
    // Computed property untuk total penjualan bulan sebelumnya
    private var previousMonthRevenue: Int {
        return previousMonthSales.reduce(0) { $0 + $1.totalPrice }
    }
    
    // Computed property untuk total pesanan
    private var totalOrders: Int {
        return filteredSales.count
    }
    
    // Computed property untuk total pesanan bulan sebelumnya
    private var previousMonthOrders: Int {
        return previousMonthSales.count
    }
    
    // Computed properties untuk perhitungan pertumbuhan
    private var revenueGrowth: Double {
        guard previousMonthRevenue > 0 else { return 0 }
        return Double(totalRevenue - previousMonthRevenue) / Double(previousMonthRevenue) * 100
    }
    
    private var ordersGrowth: Double {
        guard previousMonthOrders > 0 else { return 0 }
        return Double(totalOrders - previousMonthOrders) / Double(previousMonthOrders) * 100
    }
    
    private var isRevenueGrowthPositive: Bool {
        return revenueGrowth >= 0
    }
    
    private var isOrdersGrowthPositive: Bool {
        return ordersGrowth >= 0
    }
    
    // Computed property untuk data pendapatan mingguan
    private var weeklyRevenueData: [WeeklyData] {
        let weeklyData = groupSalesByWeek(filteredSales)
        
        return (1...4).map { week in
            let weekRevenue = weeklyData[week] ?? 0
            return WeeklyData(week: "Minggu Ke-\(week)", value: weekRevenue)
        }
    }
    
    // Computed property untuk data pesanan mingguan
    private var weeklyOrdersData: [WeeklyData] {
        let weeklyData = groupOrdersByWeek(filteredSales)
        
        return (1...4).map { week in
            let weekOrders = weeklyData[week] ?? 0
            return WeeklyData(week: "Minggu Ke-\(week)", value: weekOrders)
        }
    }
    
    // Computed property untuk produk terlaris
    private var topProducts: [TopProduct] {
        // Dictionary untuk menghitung jumlah terjual per produk
        var productSales: [UUID: (name: String, sales: Int, quantity: Int)] = [:]
        
        // Iterasi semua transaksi dan item di dalamnya
        for sale in filteredSales {
            for item in sale.items {
                let productId = item.product.id
                let productName = item.product.name
                let itemPrice = item.priceAtSale * item.quantity
                let itemQuantity = item.quantity
                
                if let existing = productSales[productId] {
                    productSales[productId] = (
                        name: existing.name,
                        sales: existing.sales + itemPrice,
                        quantity: existing.quantity + itemQuantity
                    )
                } else {
                    productSales[productId] = (
                        name: productName,
                        sales: itemPrice,
                        quantity: itemQuantity
                    )
                }
            }
        }
        
        // Sort dan ambil 10 teratas
        let sorted = productSales.values.sorted { $0.sales > $1.sales }
        let topTen = sorted.prefix(10)
        
        return topTen.enumerated().map { index, product in
            TopProduct(
                rank: index + 1, 
                name: product.name, 
                sales: product.sales, 
                quantity: product.quantity
            )
        }
    }
    
    init() {
        // Initialize query untuk mengambil semua transaksi
        let currentDate = Date()
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: currentDate))!
        
        let predicate = #Predicate<Sales> { sale in
            sale.date >= startOfYear
        }
        
        _allSales = Query(filter: predicate, sort: \Sales.date)
    }

    var body: some View {
        ZStack {
            // Main content without controls when exporting
            VStack(spacing: 30) {
                // Only show header when not exporting
                if !isExportingPDF {
                    HStack {
                        DatePickerButton()
                        Spacer()
                        DownloadButton()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .zIndex(isPresented ? 101 : 1)
                } else {
                    // Title for PDF
                    HStack {
                        Text(formattedDate(selectedDate))
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Row with revenue and orders cards
                        HStack(spacing: 30) {
                            // Revenue Card
                            RevenueCard()
                            
                            // Orders Card
                            OrdersCard()
                        }
                        .padding(.horizontal, 20)
                        
                        // Top Products Card
                        TopProductsCard()
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(ViewCaptureRepresentable(viewContainer: $viewContainer))
            
            // Overlays only when not exporting and specific conditions are met
            if !isExportingPDF {
                if isPresented {
                    // Dimming overlay when date picker is showing
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(100)
                        .onTapGesture {
                            withAnimation {
                                isPresented = false
                            }
                        }
                }
            }
            
            // Loading indicator shown OVER the UI and ONLY during generation
            // This ensures it doesn't get captured in the PDF
            if isGeneratingPDF {
                LoadingOverlay()
                    .zIndex(200)
            }
        }
        .animation(.easeInOut, value: isPresented)
        .onChange(of: selectedDate) { _, _ in
            // Refresh data when date changes
        }
        .sheet(isPresented: $showShareSheet) {
            if let pdfData = pdfData {
                PDFShareSheet(pdf: pdfData, subject: "Rekapan \(formattedDate(selectedDate))")
            }
        }
        .alert("PDF Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Gagal membuat PDF. Silakan coba lagi.")
        }
    }

    // Function untuk grup transaksi berdasarkan minggu dalam bulan
    private func groupSalesByWeek(_ sales: [Sales]) -> [Int: Int] {
        let calendar = Calendar.current
        var weeklyRevenue: [Int: Int] = [:]
        
        // Isi default 0 untuk semua minggu
        for weekIndex in 1...4 {
            weeklyRevenue[weekIndex] = 0
        }
        
        // Isi dengan data aktual jika ada
        for sale in sales {
            let weekOfMonth = calendar.component(.weekOfMonth, from: sale.date)
            let weekIndex = min(max(1, weekOfMonth), 4) // 1-4 only
            
            weeklyRevenue[weekIndex, default: 0] += sale.totalPrice
        }
        
        return weeklyRevenue
    }
    
    // Function untuk grup jumlah order berdasarkan minggu dalam bulan
    private func groupOrdersByWeek(_ sales: [Sales]) -> [Int: Int] {
        let calendar = Calendar.current
        var weeklyOrders: [Int: Int] = [:]
        
        // Isi default 0 untuk semua minggu
        for weekIndex in 1...4 {
            weeklyOrders[weekIndex] = 0
        }
        
        // Isi dengan data aktual jika ada
        for sale in sales {
            let weekOfMonth = calendar.component(.weekOfMonth, from: sale.date)
            let weekIndex = min(max(1, weekOfMonth), 4) // 1-4 only
            
            weeklyOrders[weekIndex, default: 0] += 1
        }
        
        return weeklyOrders
    }

    private func DatePickerButton() -> some View {
        Button(action: {
            withAnimation {
                isPresented.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                Text(formattedDate(selectedDate))
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .rotationEffect(.degrees(isPresented ? 180 : 0))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4))
            )
            .frame(width: 150, height: 34)
        }
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            VStack {
                MonthYearPicker(selectedDate: $selectedDate)
                    .frame(width: 300, height: 200)
                    .presentationCompactAdaptation(.popover)
            }
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }
    
    private func DownloadButton() -> some View {
        Button(action: {
            exportToPDF()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 17))
                Text("Unduh Rekapan")
                    .font(.system(size: 17))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4))
            )
        }
    }

    private func RevenueCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Pendapatan Bulanan")
                .font(.system(size: 17, weight: .bold))
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Rp\(formattedPrice(totalRevenue))")
                    .font(.system(size: 36, weight: .bold))
                
                let difference = abs(totalRevenue - previousMonthRevenue)
                Text("Rp\(formattedPrice(difference)) (\(isRevenueGrowthPositive ? "↑" : "↓")\(String(format: "%.1f", abs(revenueGrowth)))%)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isRevenueGrowthPositive ? .green : .red)
            }
            .padding(.bottom, 6)
            
            // Line chart untuk pendapatan
            LineChartView(data: weeklyRevenueData)
                .frame(height: 150)
                .padding(.trailing, 30)
                .padding(.bottom, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4))
        )
        .frame(maxWidth: .infinity, maxHeight: 344)
    }
    
    private func OrdersCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Pesanan Bulanan")
                .font(.system(size: 17, weight: .bold))
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(totalOrders)")
                    .font(.system(size: 32, weight: .bold))
                
                let difference = abs(totalOrders - previousMonthOrders)
                Text("\(difference) (\(isOrdersGrowthPositive ? "↑" : "↓")\(String(format: "%.1f", abs(ordersGrowth)))%)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isOrdersGrowthPositive ? .green : .red)
            }
            .padding(.bottom, 6)
            
            // Bar chart untuk pesanan
            BarChartView(data: weeklyOrdersData)
                .frame(height: 150)
                .padding(.trailing, 30)
                .padding(.bottom, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4))
        )
        .frame(maxWidth: .infinity, maxHeight: 344)
    }
    
    private func TopProductsCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Produk Terlaris Bulanan")
                .font(.system(size: 17, weight: .bold))
                .padding(.horizontal)
            
            if topProducts.isEmpty {
                Text("Belum ada penjualan di bulan ini")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                HStack(alignment: .top, spacing: 0) {
                    // Menghitung jumlah produk untuk kolom kiri
                    // Jika total produk ganjil, kolom kiri mendapat 1 produk lebih banyak
                    let leftCount = (topProducts.count + 1) / 2
                    
                    // Kolom kiri
                    VStack(spacing: 0) {
                        let leftProducts = topProducts.prefix(leftCount)
                        ForEach(Array(leftProducts.enumerated()), id: \.element.id) { index, product in
                            VStack(spacing: 0) {
                                HStack(alignment: .center) {
                                    Text("\(product.rank).")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.gray)
                                        .frame(width: 30, alignment: .leading)
                                    
                                    Text(product.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.black)

                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("Rp\(formattedPrice(product.sales))")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.black)

                                        Text("(\(product.quantity) terjual)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.gray)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                
                                if index < leftProducts.count - 1 {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Divider tengah selalu muncul
                    Divider()
                    
                    // Kolom kanan
                    VStack(spacing: 0) {
                        if topProducts.count > leftCount {
                            let rightProducts = topProducts.suffix(topProducts.count - leftCount)
                            ForEach(Array(rightProducts.enumerated()), id: \.element.id) { index, product in
                                VStack(spacing: 0) {
                                    HStack(alignment: .center) {
                                        Text("\(product.rank).")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.gray)
                                            .frame(width: 30, alignment: .leading)
                                        
                                        Text(product.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.black)
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("Rp\(formattedPrice(product.sales))")
                                                .font(.system(size: 14))
                                                .foregroundStyle(.black)
                                            
                                            Text("(\(product.quantity) terjual)")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.gray)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    
                                    if index < rightProducts.count - 1 {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        } else {
                            // Placeholder kosong untuk kolom kanan jika tidak ada produk
                            Text("Belum ada produk lainnya")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 30)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.4))
        )
        .frame(maxWidth: .infinity, maxHeight: 352)
    }

    private func exportToPDF() {
        // Set flags but DON'T generate PDF yet - just prepare the view
        isGeneratingPDF = true
        isExportingPDF = true
        
        // Using a longer delay to ensure view is fully updated without loading overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // At this point the view should be updated with isExportingPDF = true
            // Now create a completely separate view just for export
            let printableView = VStack(spacing: 20) {
                // Title
                HStack {
                    Text(self.formattedDate(self.selectedDate))
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Content
                VStack(spacing: 20) {
                    // Row with revenue and orders cards
                    HStack(spacing: 20) {
                        // Revenue Card
                        self.RevenueCard()
                        
                        // Orders Card
                        self.OrdersCard()
                    }
                    .padding(.horizontal, 20)
                    
                    // Top Products Card
                    self.TopProductsCard()
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .frame(width: 1000) // Extra wide for better layout
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .background(Color.white)
            
            // Now generate PDF from this clean, separate view
            RecapExporter.exportRecapToPDF(content: printableView, width: 1080) { result in
                DispatchQueue.main.async {
                    self.isGeneratingPDF = false
                    self.isExportingPDF = false
                    
                    switch result {
                    case .success(let data):
                        self.pdfData = data
                        self.showShareSheet = true
                    case .failure:
                        self.showAlert = true
                    }
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalized
    }

    private func formattedPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// Model data untuk produk terlaris
struct TopProduct: Identifiable {
    let id = UUID()
    let rank: Int
    let name: String
    let sales: Int
    let quantity: Int
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

#Preview {
    RecapView()
}
