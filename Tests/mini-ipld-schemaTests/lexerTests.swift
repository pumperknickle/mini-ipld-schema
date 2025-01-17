import XCTest
@testable import mini_ipld_schema

final class LexerTests: XCTestCase {
    func testBasicSchema() throws {
        let schemas = [
            "type BasicBool Bool",
            "type BasicString String",
            "type BasicBytes Bytes",
            "type BasicInt Int",
            "type BasicFloat Float"
        ]
        
        for schema in schemas {
            let lexer = Lexer(input: schema)
            let tokens = try lexer.tokenize()
            XCTAssertEqual(tokens[0].type, TokenType.keyword)
            XCTAssertEqual(tokens[0].value, "type")
            XCTAssertEqual(tokens[1].type, TokenType.identifier)
            XCTAssertEqual(tokens[2].type, TokenType.keyword)
        }
    }
    
    func testStructSchema() throws {
        let schema = """
            type Person struct {
            name String,
            age optional Int,
            bio nullable optional String
        }
        """
        let lexer = Lexer(input: schema)
        let tokens = try lexer.tokenize()
        let values = ["type", "Person", "struct", "{", "name", "String", ",", "age", "optional", "Int", ",", "bio", "nullable", "optional", "String", "}"]
        let types: [TokenType] = [.keyword, .identifier, .keyword, .symbol, .identifier, .keyword, .symbol, .identifier, .keyword, .keyword, .symbol, .identifier, .keyword, .keyword, .keyword, .symbol]
        for i in 0..<tokens.count {
            XCTAssertEqual(tokens[i].value, values[i])
            XCTAssertEqual(tokens[i].type, types[i])
        }
    }
}

