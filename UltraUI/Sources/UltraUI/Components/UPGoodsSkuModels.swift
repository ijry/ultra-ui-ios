import Foundation

/// 商品信息，对应上游 `goodsInfo`。上游同时读 `image`/`picture`、
/// `price`/`price_fee`、`stock`/`quantity` 两套字段名，这里取并集后归一。
public struct UPGoodsInfo: Equatable, Sendable {
    public var image: String
    public var price: Double
    public var stock: Int
    public var title: String

    public init(image: String = "", price: Double = 0, stock: Int = 0, title: String = "") {
        self.image = image
        self.price = price
        self.stock = stock
        self.title = title
    }
}

/// `skuTree` 的叶子节点：`{ id, name }`。
public struct UPGoodsSkuLeaf: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// `skuTree` 的一个维度：`{ name, label, children }`。
/// `name` 是 `skuList` 里对应的键，`label` 是展示标题。
public struct UPGoodsSkuTreeItem: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var label: String
    public var children: [UPGoodsSkuLeaf]

    public init(name: String, label: String = "", children: [UPGoodsSkuLeaf] = []) {
        self.name = name
        self.label = label.isEmpty ? name : label
        self.children = children
        self.id = name
    }
}

/// `skuList` 的一项：每个维度取值 + 库存价格。
/// 上游是扁平对象（`{ color: '1', size: '2', stock: 5, price: 9.9 }`）。
public struct UPGoodsSkuItem: Equatable, Sendable {
    /// 维度名 → 叶子 id。
    public var selections: [String: String]
    public var stock: Int
    public var price: Double?

    public init(selections: [String: String], stock: Int, price: Double? = nil) {
        self.selections = selections
        self.stock = max(0, stock)
        self.price = price
    }
}

/// `confirm` 的事件负载，对应上游
/// `{ sku, goodsInfo, num, selectedText }`。
public struct UPGoodsSkuConfirmEvent: Equatable, Sendable {
    public let sku: UPGoodsSkuItem?
    public let goodsInfo: UPGoodsInfo
    public let num: Int
    public let selectedText: String

    public init(sku: UPGoodsSkuItem?, goodsInfo: UPGoodsInfo, num: Int, selectedText: String) {
        self.sku = sku
        self.goodsInfo = goodsInfo
        self.num = num
        self.selectedText = selectedText
    }
}
