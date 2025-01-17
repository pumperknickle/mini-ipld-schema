struct ParsedSchema {
    let types: [String: TypeDefinition]
}

enum TypeDefinition: Equatable {
    case nodeKind(value: SchemaNode, advanced: Bool)
    case structKind(fields: [String: FieldDefinition])
    case enumKind(values: [String])
    case scalarKind(value: ScalarKind)
}

enum ScalarKind: String, Equatable {
    case bool = "Bool"
    case int = "Int"
    case float = "Float"
    case string = "String"
    case bytes = "Bytes"
}

enum SchemaNode: Sendable {
    case scalar(type: ScalarKind)
    case link(expectedType: String)
    case type(name: String)
    indirect case list(valueType: SchemaNode, valueNullable: Bool)
    indirect case map(valueType: SchemaNode, valueNullable: Bool)
}

extension SchemaNode: Equatable { }

struct FieldDefinition: Equatable {
    let type: SchemaNode
    let optional: Bool
    let valueNullable: Bool
}

enum TokenType: Equatable {
    case keyword
    case identifier
    case symbol

    static func == (lhs: TokenType, rhs: TokenType) -> Bool {
        switch (lhs, rhs) {
        case (.keyword, .keyword):
            return true
        case (.identifier, .identifier):
            return true
        case (.symbol, .symbol):
            return true
        default:
            return false
        }
    }
}

struct Token {
    let type: TokenType
    let value: String
    let line: Int
}

enum SchemaError: Error {
    case invalidToken(String)
    case unexpectedEndOfInput
    case invalidSyntax(String)
    case invalidType(String)
    case invalidRepresentation(String)
    case invalidUnionRepresentation(String)
    case inlineComplexTypeNotAllowed(String)
}


