public struct ParsedSchema {
    let types: [String: TypeDefinition]
}

public enum TypeDefinition: Equatable {
    case nodeKind(value: SchemaNode, advanced: Bool)
    case structKind(fields: [String: FieldDefinition])
    case enumKind(values: [String])
    case scalarKind(value: ScalarKind)
}

public enum ScalarKind: String, Sendable, Equatable {
    case bool = "Bool"
    case int = "Int"
    case float = "Float"
    case string = "String"
    case bytes = "Bytes"
}

public enum SchemaNode: Sendable {
    case scalar(type: ScalarKind)
    case link(expectedType: String)
    case type(name: String)
    indirect case list(valueType: SchemaNode, valueNullable: Bool)
    indirect case map(valueType: SchemaNode, valueNullable: Bool)
}

extension SchemaNode: Equatable { }

public struct FieldDefinition: Equatable {
    let type: SchemaNode
    let optional: Bool
    let valueNullable: Bool
}

public enum SchemaError: Error {
    case invalidToken(String)
    case unexpectedEndOfInput
    case invalidSyntax(String)
    case invalidType(String)
    case invalidRepresentation(String)
    case invalidUnionRepresentation(String)
    case inlineComplexTypeNotAllowed(String)
}


