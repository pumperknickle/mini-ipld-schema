class Lexer {
    private let input: String
    private var current: String.Index
    private var line: Int = 1
    
    init(input: String) {
        self.input = input
        self.current = input.startIndex
    }
    
    func tokenize() throws -> [Token] {
        var tokens: [Token] = []

        while current < input.endIndex {
            let char = input[current]

            switch char {
            case " ", "\t", "\r":
                advance()
            case "\n":
                line += 1
                advance()
            case "{", "}", "[", "]", ":", ",", "&":
                tokens.append(Token(type: .symbol, value: String(char), line: line))
                advance()
            case _ where char.isLetter || char.isNumber || char == "_":
                tokens.append(scanIdentifierOrKeyword())
            case "/":  // Handle comments
                if peek() == "/" {
                    skipLineComment()
                } else if peek() == "*" {
                    try skipBlockComment()
                } else {
                    throw SchemaError.invalidSyntax("Unexpected character: \(char)")
                }
            default:
                throw SchemaError.invalidSyntax("Unexpected character: \(char)")
            }
        }
        return tokens
    }

    private func scanIdentifierOrKeyword() -> Token {
        let start = current

        while current < input.endIndex && (isIdentifierChar(input[current])) {
            advance()
        }

        let value = String(input[start..<current])

        // Check if it's a keyword
        let keywords = Set([
            "type", "representation", "advanced", "optional", "nullable", "struct",
            "enum", "Bool", "String", "Bytes", "Int", "Float", "map", "list", "link", "RMT"
        ])

        return Token(
            type: keywords.contains(value) ? .keyword : .identifier,
            value: value,
            line: line
        )
    }

    private func skipLineComment() {
        advance() // Skip first /
        advance() // Skip second /

        while current < input.endIndex && input[current] != "\n" {
            advance()
        }
    }

    private func skipBlockComment() throws {
        advance() // Skip /
        advance() // Skip *

        while current < input.endIndex {
            if input[current] == "*" && peek() == "/" {
                advance() // Skip *
                advance() // Skip /
                return
            }

            if input[current] == "\n" {
                line += 1
            }

            advance()
        }

        throw SchemaError.invalidSyntax("Unterminated block comment")
    }

    private func isIdentifierChar(_ char: Character) -> Bool {
        return char.isLetter || char.isNumber || char == "_"
    }

    private func advance() {
        current = input.index(after: current)
    }

    private func peek() -> Character? {
        let nextIndex = input.index(after: current)
        guard nextIndex < input.endIndex else { return nil }
        return input[nextIndex]
    }
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
