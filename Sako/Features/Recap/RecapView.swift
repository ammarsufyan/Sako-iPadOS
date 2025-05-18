import SwiftUI
import SwiftData
import Charts

struct RecapView: View {
    // MARK: - State variables untuk mengontrol UI dan interaksi
    @State private var selectedDate = Date() 
    @State private var isPresented = false  
    @State private var showShareSheet = false 
    @State private var pdfData: Data?        
    @State private var isGeneratingPDF = false 
    @State private var showAlert = false     
    @State private var isExportingPDF = false 
    
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext 

    // Query data transaksi dari SwiftData
    @Query(sort: \Sales.date) private var allSales: [Sales]
    
    // MARK: - Data Filtering dan Kalkulasi
    
    // Mendapatkan daftar transaksi sesuai bulan yang dipilih
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
    
    // Mendapatkan daftar transaksi dari bulan sebelumnya (untuk perbandingan)
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
    
    // Menghitung total pendapatan bulan yang dipilih
    private var totalRevenue: Int {
        return filteredSales.reduce(0) { $0 + $1.totalPrice }
    }
    
    // Menghitung total pendapatan bulan sebelumnya
    private var previousMonthRevenue: Int {
        return previousMonthSales.reduce(0) { $0 + $1.totalPrice }
    }
    
    // Menghitung total jumlah pesanan bulan yang dipilih
    private var totalOrders: Int {
        return filteredSales.count
    }
    
    // Menghitung total jumlah pesanan bulan sebelumnya
    private var previousMonthOrders: Int {
        return previousMonthSales.count
    }
    
    // MARK: - Perhitungan Pertumbuhan
    
    // Persentase pertumbuhan pendapatan dibanding bulan lalu
    private var revenueGrowth: Double {
        guard previousMonthRevenue > 0 else { return 0 }
        return Double(totalRevenue - previousMonthRevenue) / Double(previousMonthRevenue) * 100
    }
    
    // Persentase pertumbuhan jumlah pesanan dibanding bulan lalu
    private var ordersGrowth: Double {
        guard previousMonthOrders > 0 else { return 0 }
        return Double(totalOrders - previousMonthOrders) / Double(previousMonthOrders) * 100
    }
    
    // Apakah pertumbuhan pendapatan positif atau negatif
    private var isRevenueGrowthPositive: Bool {
        return revenueGrowth >= 0
    }
    
    // Apakah pertumbuhan jumlah pesanan positif atau negatif 
    private var isOrdersGrowthPositive: Bool {
        return ordersGrowth >= 0
    }
    
    // MARK: - Data untuk Charts
    
    // Menyiapkan data pendapatan mingguan untuk chart
    private var weeklyRevenueData: [WeeklyData] {
        let weeklyData = groupSalesByWeek(filteredSales)
        
        return (1...4).map { week in
            let weekRevenue = weeklyData[week] ?? 0
            return WeeklyData(week: "Minggu \(week)", value: weekRevenue)
        }
    }
    
    // Menyiapkan data pesanan mingguan untuk chart
    private var weeklyOrdersData: [WeeklyData] {
        let weeklyData = groupOrdersByWeek(filteredSales)
        
        return (1...4).map { week in
            let weekOrders = weeklyData[week] ?? 0
            return WeeklyData(week: "Minggu \(week)", value: weekOrders)
        }
    }
    
    // MARK: - Produk Terlaris
    
    // Menghitung dan menyusun data produk terlaris berdasarkan nilai penjualan
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
                    // Update nilai jika produk sudah ada dalam perhitungan
                    productSales[productId] = (
                        name: existing.name,
                        sales: existing.sales + itemPrice,
                        quantity: existing.quantity + itemQuantity
                    )
                } else {
                    // Tambahkan produk baru ke perhitungan
                    productSales[productId] = (
                        name: productName,
                        sales: itemPrice,
                        quantity: itemQuantity
                    )
                }
            }
        }
        
        // Urutkan berdasarkan nilai penjualan dan ambil 10 teratas
        let sorted = productSales.values.sorted { $0.sales > $1.sales }
        let topTen = sorted.prefix(10)
        
        // Konversi ke model TopProduct untuk UI
        return topTen.enumerated().map { index, product in
            TopProduct(
                rank: index + 1, 
                name: product.name, 
                sales: product.sales, 
                quantity: product.quantity
            )
        }
    }
    
    // MARK: - Body View
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                HStack {
                    DatePickerButton()
                    Spacer()
                    DownloadButton()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 30) {
                        HStack(spacing: 30) {
                            // Card Pendapatan
                            RevenueCard()
                            
                            // Card Pesanan
                            OrdersCard()
                        }
                        .padding(.horizontal, 20)
                        
                        // Card Produk Terlaris
                        TopProductsCard()
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGray6))
            
            // Overlay untuk latar belakang gelap saat date picker ditampilkan
            if !isExportingPDF {
                if isPresented {
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
            
            // Indikator loading ditampilkan HANYA saat generate PDF
            if isGeneratingPDF {
                LoadingOverlay()
                    .zIndex(200)
            }
        }
        .animation(.easeInOut, value: isPresented)
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

    // MARK: - Fungsi Pengelompokan Data
    
    // Mengelompokkan pendapatan berdasarkan minggu dalam bulan
    // Satu bulan dibagi menjadi 4 minggu berdasarkan tanggal:
    // Minggu 1: tanggal 1-7
    // Minggu 2: tanggal 8-14
    // Minggu 3: tanggal 15-21
    // Minggu 4: tanggal 22-31 (termasuk semua hari tersisa)
    private func groupSalesByWeek(_ sales: [Sales]) -> [Int: Int] {
        let calendar = Calendar.current
        var weeklyRevenue: [Int: Int] = [:]
        
        // Inisialisasi semua minggu dengan nilai 0
        for weekIndex in 1...4 {
            weeklyRevenue[weekIndex] = 0
        }
        
        // Isi dengan data aktual dari setiap transaksi
        for sale in sales {
            // Menggunakan komponen hari dalam bulan untuk menentukan minggu secara manual
            let dayOfMonth = calendar.component(.day, from: sale.date)
            
            // Mengelompokkan berdasarkan 7 hari per minggu, dengan hari 29+ masuk ke minggu 4
            let weekIndex: Int
            if dayOfMonth <= 7 {
                weekIndex = 1        // Hari 1-7 = Minggu 1
            } else if dayOfMonth <= 14 {
                weekIndex = 2        // Hari 8-14 = Minggu 2
            } else if dayOfMonth <= 21 {
                weekIndex = 3        // Hari 15-21 = Minggu 3
            } else {
                weekIndex = 4        // Hari 22-31 = Minggu 4 (termasuk hari-hari dari "minggu 5")
            }
            
            // Tambahkan nilai transaksi ke minggu yang sesuai
            weeklyRevenue[weekIndex, default: 0] += sale.totalPrice
        }
        
        return weeklyRevenue
    }
    
    // Mengelompokkan jumlah pesanan berdasarkan minggu dalam bulan
    // Menggunakan pendekatan yang sama dengan pendapatan, tapi menambahkan jumlah (bukan nilai)
    private func groupOrdersByWeek(_ sales: [Sales]) -> [Int: Int] {
        let calendar = Calendar.current
        var weeklyOrders: [Int: Int] = [:]
        
        // Inisialisasi semua minggu dengan nilai 0
        for weekIndex in 1...4 {
            weeklyOrders[weekIndex] = 0
        }
        
        // Isi dengan data aktual dari setiap transaksi
        for sale in sales {
            // Menggunakan komponen hari dalam bulan untuk menentukan minggu secara manual
            let dayOfMonth = calendar.component(.day, from: sale.date)
            
            // Mengelompokkan berdasarkan 7 hari per minggu, dengan hari 29+ masuk ke minggu 4
            let weekIndex: Int
            if dayOfMonth <= 7 {
                weekIndex = 1        // Hari 1-7 = Minggu 1
            } else if dayOfMonth <= 14 {
                weekIndex = 2        // Hari 8-14 = Minggu 2
            } else if dayOfMonth <= 21 {
                weekIndex = 3        // Hari 15-21 = Minggu 3
            } else {
                weekIndex = 4        // Hari 22-31 = Minggu 4 (termasuk hari-hari dari "minggu 5")
            }
            
            // Tambahkan 1 pesanan ke minggu yang sesuai
            weeklyOrders[weekIndex, default: 0] += 1
        }
        
        return weeklyOrders
    }

    // MARK: - Komponen UI
    
    // Tombol untuk memilih tanggal
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
                    .fill(.white)
                    .stroke(Color.gray.opacity(0.4))
            )
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
    
    // Tombol untuk mengunduh rekapan sebagai PDF
    private func DownloadButton() -> some View {
        Button(action: {
            exportToPDF()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 17))
                Text("Download Rekapan")
                    .font(.system(size: 17))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .stroke(Color.gray.opacity(0.4))
            )
        }
    }

    // Card yang menampilkan informasi pendapatan
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
            
            // Grafik garis untuk pendapatan mingguan
            LineChartView(data: weeklyRevenueData)
                .frame(height: 150)
                .padding(.trailing, 30)
                .padding(.bottom, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .stroke(Color.gray.opacity(0.4))
        )
        .frame(maxWidth: .infinity, maxHeight: 344)
    }
    
    // Card yang menampilkan informasi jumlah pesanan
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
            
            // Grafik batang untuk jumlah pesanan mingguan
            BarChartView(data: weeklyOrdersData)
                .frame(height: 150)
                .padding(.trailing, 30)
                .padding(.bottom, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .stroke(Color.gray.opacity(0.4))
        )
        .frame(maxWidth: .infinity, maxHeight: 344)
    }
    
    // MARK: - Card Produk Terlaris
    
    // Card yang menampilkan daftar produk terlaris
    private func TopProductsCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Produk Terlaris Bulanan")
                .font(.system(size: 17, weight: .bold))
                .padding(.horizontal)
            
            if topProducts.isEmpty {
                // Tampilkan pesan jika tidak ada penjualan
                Text("Belum ada penjualan di bulan ini")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
            } else {
                // Tampilkan daftar produk terlaris dalam dua kolom
                HStack(alignment: .top, spacing: 0) {
                    // Hitung jumlah produk untuk kolom kiri
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
                    
                    // Garis pemisah tengah
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
                            // Tampilkan placeholder jika tidak ada produk di kolom kanan
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
        .background(.white)
        .frame(maxWidth: .infinity, maxHeight: 352)
    }

    // MARK: - Ekspor PDF
    
    // Fungsi untuk mengekspor tampilan sebagai PDF
    private func exportToPDF() {
        // Set flags untuk persiapan tampilan ekspor
        isGeneratingPDF = true
        isExportingPDF = true
        
        // Tunda pembuatan PDF untuk memastikan tampilan sudah diperbarui
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Buat tampilan terpisah khusus untuk ekspor
            let printableView = VStack(spacing: 30) {
                // Judul
                HStack {
                    Text(self.formattedDate(self.selectedDate))
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Konten
                VStack(spacing: 20) {
                    // Baris dengan card pendapatan dan pesanan
                    HStack(spacing: 20) {
                        // Card Pendapatan
                        self.RevenueCard()
                        
                        // Card Pesanan
                        self.OrdersCard()
                    }
                    .padding(.horizontal, 20)
                    
                    // Card Produk Terlaris
                    self.TopProductsCard()
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .frame(width: 1000) // Lebar ekstra untuk tata letak yang lebih baik
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
            .background(Color.white)
            
            // Generate PDF menggunakan RecapExporter
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

    // MARK: - Helpers
    
    // Format tanggal menjadi "Bulan Tahun" dalam Bahasa Indonesia
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalized
    }

    // Format angka menjadi format ribuan dengan pemisah titik
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
    let rank: Int        // Peringkat produk (1, 2, 3, dst)
    let name: String     // Nama produk
    let sales: Int       // Total nilai penjualan (Rupiah)
    let quantity: Int    // Jumlah unit terjual
}

#Preview {
    RecapView()
}
