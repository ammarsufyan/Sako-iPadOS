import Foundation
import SwiftData

// MARK: - Products Model
@Model
final class Products {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var price: Int
    var items: [ProductsOnSales]?  // Relasi ke ProductOnSale
    
    init(name: String, price: Int) {
        self.name = name
        self.price = max(0, price)
    }
}

// MARK: - ProductsOnSales Model (Junction Table)
@Model
final class ProductsOnSales {
    @Attribute(.unique) var id: UUID = UUID()
    var product: Products
    var quantity: Int
    var priceAtSale: Int
    
    init(product: Products, quantity: Int, priceAtSale: Int? = nil) {
        self.product = product
        self.quantity = max(1, quantity)
        self.priceAtSale = priceAtSale ?? product.price
    }
}

// MARK: - Sales Model
@Model
final class Sales {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var items: [ProductsOnSales] = []
    
    // Computed property: Total harga transaksi
    var totalPrice: Int {
        items.reduce(0) { $0 + ($1.priceAtSale * $1.quantity) }
    }
    
    // Computed property: Daftar nama produk + quantity + harga
    var productDetails: String {
        items.map { "\($0.product.name) × \($0.quantity) @ Rp \($0.priceAtSale.formatPrice())" }.joined(separator: ", ")
    }
    
    init(date: Date) {
        self.date = date
    }
}
