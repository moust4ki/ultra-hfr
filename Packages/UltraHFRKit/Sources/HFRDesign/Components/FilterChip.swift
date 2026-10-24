//
//  FilterChip.swift
//  HFRDesign
//

/// One filter of a `FilterChips` row.
public struct FilterChip<Value: Hashable>: Identifiable {
    public var value: Value
    public var title: String
    /// Count shown in accent after the title ("Non lus 2").
    public var count: Int?
    public var isEnabled: Bool

    public var id: Value { value }

    public init(_ value: Value, title: String, count: Int? = nil, isEnabled: Bool = true) {
        self.value = value
        self.title = title
        self.count = count
        self.isEnabled = isEnabled
    }
}
