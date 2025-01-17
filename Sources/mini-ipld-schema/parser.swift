class SchemaParser {
    private var tokens: [Token]
    private var currentIndex: Int = 0
    
    init(schema: String) throws {
        let lexer = Lexer(input: schema)
        self.tokens = try lexer.tokenize()
    }
    
    func parse() throws -> ParsedSchema {
        var types: [String: TypeDefinition] = [:]

        while !isAtEnd {
            let (name, typedef) = try parseType()
            types[name] = typedef
        }

        return ParsedSchema(types: types)
    }
    
    private func parseType() throws -> (String, TypeDefinition) {
        try consume(.keyword, value: "type")
        let name = try consume(.identifier, value: nil).value
        
        let typeDef = try parseTypeDefinition()

        return (name, typeDef)
    }
    
    private func parseTypeDefinition() throws -> TypeDefinition {
        let token = try peek()
        
        switch token.value {
        case "Bool":
            advance()
            return .scalarKind(value: .bool)
        case "String":
            advance()
            return .scalarKind(value: .string)
        case "Bytes":
            advance()
            return .scalarKind(value: .bytes)
        case "Int":
            advance()
            return .scalarKind(value: .int)
        case "Float":
            advance()
            return .scalarKind(value: .float)
        case "struct":
            advance()
            return .structKind(fields: try parseStruct())
        case "enum":
            advance()
            return .enumKind(values: try parseEnum())
        case "map":
            advance()
            let node = try parseMap()
            if (match(.keyword, value: "representation") && match(.keyword, value: "advanced")) && match(.keyword, value: "RMT"){
                return .nodeKind(value: node, advanced: true)
            }
            return .nodeKind(value: node, advanced: false)
        case "{":
            let node = try parseMap()
            if (match(.keyword, value: "representation") && match(.keyword, value: "advanced")) && match(.keyword, value: "RMT") {
                return .nodeKind(value: node, advanced: true)
            }
            return .nodeKind(value: node, advanced: false)
        case "list":
            advance()
            let node = try parseList()
            if match(.keyword, value: "representation") && match(.keyword, value: "advanced") && match(.keyword, value: "RMT") {
                return .nodeKind(value: node, advanced: true)
            }
            return .nodeKind(value: node, advanced: false)
        case "[":
            let node = try parseListInline()
            if match(.keyword, value: "representation") && match(.keyword, value: "advanced") && match(.keyword, value: "RMT") {
                return .nodeKind(value: node, advanced: true)
            }
            return .nodeKind(value: node, advanced: false)
        case "link":
            advance()
            return .nodeKind(value: try parseLink(), advanced: false)
        case "&":
            advance()
            return .nodeKind(value: try parseLink(), advanced: false)
        default:
            return .nodeKind(value: .type(name: try consume(.identifier, value: nil).value), advanced: false)
        }
    }
    
    private func parseStruct() throws -> [String: FieldDefinition] {
        var fieldDefinitions = [String: FieldDefinition]()
        try consume(.symbol, value: "{")
        while !check(.symbol, value: "}") {
            var fieldName = try consume(.identifier, value: nil).value
            var valueOptional = false
            var valueNullable = false
            if match(.keyword, value: "optional") {
                valueOptional = true
            }
            if match(.keyword, value: "nullable") {
                valueNullable = true
            }
            let valueType = try parseNodeValue()
            fieldDefinitions[fieldName] = FieldDefinition(type: valueType, optional: valueOptional, valueNullable: valueNullable)
        }
        try consume(.symbol, value: "}")
        return fieldDefinitions
    }
    
    private func parseEnum() throws -> [String] {
        try consume(.symbol, value: "{")

        var members: [String] = []
        while !check(.symbol, value: "}") {
            let member = try consume(.identifier, value: nil).value
            members.append(member)

            if !check(.symbol, value: "}") {
                try consume(.symbol, value: ",")
            }
        }

        try consume(.symbol, value: "}")
        return members
    }
    
    private func parseNodeValue() throws -> SchemaNode {
        let token = try peek()
        print(token.value)
        switch token.value {
        case "Bool":
            advance()
            return .scalar(type: .bool)
        case "String":
            advance()
            return .scalar(type: .string)
        case "Int":
            advance()
            return .scalar(type: .int)
        case "Float":
            advance()
            return .scalar(type: .float)
        case "Bytes":
            advance()
            return .scalar(type: .bytes)
        case "[":
            return try parseListInline()
        case "{":
            return try parseMap()
        case "&":
            advance()
            return try parseLink()
        default:
            return .type(name: try consume(.identifier, value: nil).value)
        }
            
    }
    
    private func parseLink() throws -> SchemaNode {
        let linkToken = try peek()
        return .link(expectedType: try consume(.identifier, value: nil).value)
    }
 
    private func parseMap() throws -> SchemaNode {
        var valueNullable = false
        try consume(.symbol, value: "{")
        if !match(.keyword, value: "String") {
            throw SchemaError.invalidType("Key value must be String, not: \(try peek())")
        }
        try consume(.symbol, value: ":")
        if match(.keyword, value: "nullable") {
            valueNullable = true
        }
        let valueType = try parseNodeValue()
        try consume(.symbol, value: "}")
        return .map(valueType: valueType, valueNullable: valueNullable)
    }
    
    private func parseList() throws -> SchemaNode {
        var valueNullable = false
        if match(.keyword, value: "nullable") {
            valueNullable = true
        }
        let valueType = try parseNodeValue()
        return .list(valueType: valueType, valueNullable: valueNullable)
    }
        
    private func parseListInline() throws -> SchemaNode {
        var valueNullable = false
        try consume(.symbol, value: "[")
        if match(.keyword, value: "nullable") {
            valueNullable = true
        }
        let valueType = try parseNodeValue()
        try consume(.symbol, value: "]")
        return .list(valueType: valueType, valueNullable: valueNullable)
    }
    
    private func match(_ tokenType: TokenType, value: String?) -> Bool {
        if check(tokenType, value: value) {
            advance()
            return true
        }
        return false
    }

    private func check(_ tokenType: TokenType, value: String?) -> Bool {
        guard !isAtEnd else { return false }
        if let value = value {
            if !(tokens[currentIndex].value == value) {
                return false
            }
        }
        return tokens[currentIndex].type == tokenType
    }

    private func consume(_ tokenType: TokenType, value: String?) throws -> Token {
        if check(tokenType, value: value) {
            return tokens[advance()]
        }

        let foundToken = try peek()
        throw SchemaError.invalidToken("Expected type \(tokenType) with value \(foundToken.value), found \(foundToken.type) with value \(foundToken.value)")
    }

    private func peek() throws -> Token {
        guard !isAtEnd else {
            throw SchemaError.unexpectedEndOfInput
        }
        return tokens[currentIndex]
    }

    @discardableResult
    private func advance() -> Int {
        let current = currentIndex
        currentIndex += 1
        return current
    }

    private var isAtEnd: Bool {
        currentIndex >= tokens.count
    }
}
