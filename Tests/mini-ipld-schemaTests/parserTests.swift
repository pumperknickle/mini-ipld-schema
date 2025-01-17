import XCTest
@testable import mini_ipld_schema

final class ParserTests: XCTestCase {
    func testBasicSchema() throws {
        let schemas = [
            "type BasicBool Bool",
            "type BasicString String",
            "type BasicBytes Bytes",
            "type BasicInt Int",
            "type BasicFloat Float"
        ]
        
        for schema in schemas {
            let tokens = try Lexer(input: schema).tokenize()
            let parsedSchema = try SchemaParser(schema: schema).parse()
            XCTAssertNotNil(parsedSchema.types[tokens[1].value])
            XCTAssertEqual(parsedSchema.types[tokens[1].value]!, TypeDefinition.scalarKind(value: ScalarKind(rawValue: tokens[2].value)!))
        }
    }
    
    func testStructSchema() throws {
        let schema = """
        type Person struct {
            name String
            age optional Int
            bio optional nullable String
        }
        """
        let parsedSchema = try SchemaParser(schema: schema).parse()
        XCTAssertEqual(parsedSchema.types["Person"], TypeDefinition.structKind(fields: ["name": FieldDefinition(type: SchemaNode.scalar(type: ScalarKind.string), optional: false, valueNullable: false), "age": FieldDefinition(type: .scalar(type: .int), optional: true, valueNullable: false), "bio": FieldDefinition(type: .scalar(type: .string), optional: true, valueNullable: true)]))
    }
    
    func testListSchema() throws {
        let schemas = [
            "type StringList list String",
            "type StringList [String]"
        ]
        for schema in schemas {
            let parsedSchema = try SchemaParser(schema: schema).parse()
            XCTAssertEqual(parsedSchema.types["StringList"], TypeDefinition.nodeKind(value: SchemaNode.list(valueType: .scalar(type: .string), valueNullable: false), advanced: false))
        }
    }
    
    func testLinkSchema() throws {
        let schemas = [
            "type BasicLink link Person",
            "type BasicLink &Person"
        ]

        for schema in schemas {
            let parsedSchema = try SchemaParser(schema: schema).parse()
            XCTAssertEqual(parsedSchema.types["BasicLink"], TypeDefinition.nodeKind(value: .link(expectedType: "Person"), advanced: false))

        }
    }
    
    func testEnumType() throws {
        let schema =
          """
          type Color enum {
              red,
              green,
              blue
          }
          """
        
        let parsedSchema = try SchemaParser(schema: schema).parse()
        XCTAssertEqual(parsedSchema.types["Color"], TypeDefinition.enumKind(values: ["red", "green", "blue"]))
    }
    
    func testMapSchema() throws {
        let schemas = ["type StringIntMap { String : Int }",
                       "type StringIntMap map { String : Int }"]
        
        for schema in schemas {
            let parsedSchema = try SchemaParser(schema: schema).parse()
            XCTAssertEqual(parsedSchema.types["StringIntMap"], TypeDefinition.nodeKind(value: .map(valueType: .scalar(type: .int), valueNullable: false), advanced: false))
        }
    }
    
    func testAdvancedMap() throws {
        let schema = "type AdvancedStringIntMap { String : Int } representation advanced RMT"
        let parsedSchema = try SchemaParser(schema: schema).parse()
        XCTAssertEqual(parsedSchema.types["AdvancedStringIntMap"], TypeDefinition.nodeKind(value: .map(valueType: .scalar(type: .int), valueNullable: false), advanced: true))
    }
    
    func testAdvancedList() throws {
        let schema = "type People [String] representation advanced RMT"
        let parsedSchema = try SchemaParser(schema: schema).parse()
        XCTAssertEqual(parsedSchema.types["People"], TypeDefinition.nodeKind(value: SchemaNode.list(valueType: .scalar(type: .string), valueNullable: false), advanced: true))

    }
    
    func testRecursiveSchema() throws {
        let schema = """
            type Person struct {
                name String
                address {
                    String: String
                }
            }
        """
        let parsedSchema = try SchemaParser(schema: schema).parse()
        XCTAssertEqual(parsedSchema.types["Person"], TypeDefinition.structKind(fields: ["name": FieldDefinition(type: .scalar(type: .string), optional: false, valueNullable: false), "address": FieldDefinition(type: .map(valueType: .scalar(type: .string), valueNullable: false), optional: false, valueNullable: false)]))
    }
    
    func testRecursiveStruct() throws {
        let schema = """
            type Person struct {
                name String
                address Address
                friends [Person]
            }
            type Address struct {
                street String
                city String
            }
        """
        let parsedSchema = try SchemaParser(schema: schema).parse()
        XCTAssertEqual(parsedSchema.types["Person"], TypeDefinition.structKind(fields: ["name": FieldDefinition(type: .scalar(type: .string), optional: false, valueNullable: false), "address": FieldDefinition(type: .type(name: "Address"), optional: false, valueNullable: false), "friends": FieldDefinition(type: .list(valueType: .type(name: "Person"), valueNullable: false), optional: false, valueNullable: false)]))
        XCTAssertEqual(parsedSchema.types["Address"], TypeDefinition.structKind(fields: ["street": FieldDefinition(type: .scalar(type: .string), optional: false, valueNullable: false), "city": FieldDefinition(type: .scalar(type: .string), optional: false, valueNullable: false)]))
    }
    
    func testNullableInList() throws {
        let schema = "type People [nullable String]"
        let parsedSchema = try SchemaParser(schema: schema).parse()
        XCTAssertEqual(parsedSchema.types["People"], TypeDefinition.nodeKind(value: .list(valueType: .scalar(type: .string), valueNullable: true), advanced: false))
    }
    
    func testNullableInMap() throws {
        let schema = "type StringIntMap { String : nullable Int }"
        let parsedSchema = try SchemaParser(schema: schema).parse()
        XCTAssertEqual(parsedSchema.types["StringIntMap"], TypeDefinition.nodeKind(value: .map(valueType: .scalar(type: .int), valueNullable: true), advanced: false))
    }
    
    func testMultipleTypes() throws {
        let schema = """
          type Color enum {
              red,
              green,
              blue
          }
          type StringIntMap { String : Int }
          type Person struct {
              name String
              age optional Int
              bio optional nullable String
          }
        """
        let parsedSchema = try SchemaParser(schema: schema).parse()
        XCTAssertEqual(parsedSchema.types["Color"], TypeDefinition.enumKind(values: ["red", "green", "blue"]))
        XCTAssertEqual(parsedSchema.types["StringIntMap"], TypeDefinition.nodeKind(value: .map(valueType: .scalar(type: .int), valueNullable: false), advanced: false))
        XCTAssertEqual(parsedSchema.types["Person"], TypeDefinition.structKind(fields: ["name": FieldDefinition(type: SchemaNode.scalar(type: ScalarKind.string), optional: false, valueNullable: false), "age": FieldDefinition(type: .scalar(type: .int), optional: true, valueNullable: false), "bio": FieldDefinition(type: .scalar(type: .string), optional: true, valueNullable: true)]))
    }
}
