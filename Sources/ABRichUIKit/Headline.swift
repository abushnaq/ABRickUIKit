import Foundation

public struct Headline : Hashable {
    public init() {
        
    }
    public static func == (lhs: Headline, rhs: Headline) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
    public let id = UUID().uuidString
    public var title : String = ""
    public var touchCallback : ((String) -> Void)?
    
}
