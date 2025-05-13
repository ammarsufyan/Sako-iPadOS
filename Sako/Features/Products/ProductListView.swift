import SwiftUI
import SwiftData

struct ProductListView: View {
    @Query var products: [Products]
    
    @Environment(\.dismiss) var dismiss

    @State private var showTambahProduk = false
    @State private var searchText = ""

    var filteredProducts: [Products] {
        searchText.isEmpty ? products : products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Kembali")
                    }
                }
                .foregroundColor(.blue)

                Spacer()

                Button {
                    showTambahProduk = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Tambah")
                    }
                }
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                Text("Kelola Produk")
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
            }
            .background(Color(.systemGray6))
            
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
                            ProductCardView(product: product)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
            }
        }
        .background(Color(.systemGray6))
        .sheet(isPresented: $showTambahProduk) {
            AddProductView()
                .presentationDetents([.large])
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview
#Preview {
    ProductListView()
}
