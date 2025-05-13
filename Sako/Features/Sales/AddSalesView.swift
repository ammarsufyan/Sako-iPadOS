import SwiftUI
import SwiftData

struct AddSalesView: View {
    @Query private var allProducts: [Products]
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var selectedItems: [Products: Int] = [:]
    @State private var searchText = ""
    @State private var showConfirmationSheet = false
    
    let selectedDate: Date

    var filteredProducts: [Products] {
        if searchText.isEmpty {
            return allProducts
        }
        return allProducts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var totalItems: Int {
        selectedItems.values.reduce(0, +)
    }

    var totalPrice: Int {
        selectedItems.reduce(0) { $0 + $1.value * $1.key.price }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Batal") { dismiss() }
                    .foregroundColor(.blue)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            Text("Tambah Penjualan")
                .font(.system(size: 28, weight: .bold))
                .padding(.horizontal)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Cari produk...", text: $searchText)
                    .autocorrectionDisabled()
            }
            .padding(10)
            .background(Color(.systemGray5))
            .cornerRadius(12)
            .padding(.horizontal)

            if filteredProducts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    
                    Text("Belum ada produk")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredProducts) { product in
                            SalesProductCardView(product: product, quantity: selectedItems[product] ?? 0) { newQty in
                                if newQty == 0 {
                                    selectedItems.removeValue(forKey: product)
                                } else {
                                    selectedItems[product] = newQty
                                }
                            }
                        }
                    }
                    .padding()
                }
            }

            if totalItems > 0 {
                Button {
                    showConfirmationSheet = true
                } label: {
                    HStack {
                        Label("\(totalItems) Item", systemImage: "basket.fill")
                        Spacer()
                        Text("Rp\(Int(totalPrice).formattedWithSeparator())")
                    }
                    .font(.system(size: 20, weight: .bold))
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color(.systemGray6))
        .sheet(isPresented: $showConfirmationSheet) {
            ConfirmationSalesView(
                selectedDate: selectedDate,
                selectedItems: selectedItems,
                onSave: {
                    selectedItems = [:]
                    dismiss()
                }
            )
        }
    }
}
