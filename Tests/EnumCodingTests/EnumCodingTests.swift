import XCTest
@testable import EnumCoding

struct Person: Codable, Equatable {
    var name: String
    init(name: String) {
        self.name = name
    }
}

enum Command: Codable, Equatable {
  case load(key: String)
  case store(key: String, value: Int)
    case single(Person)
    case none

    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      switch self {
      case let .load(key):
        var nestedContainer = container.nestedContainer(keyedBy: LoadCodingKeys.self, forKey: .load)
        try nestedContainer.encode(key, forKey: .key)
      case let .store(key, value):
        var nestedContainer = container.nestedContainer(keyedBy: StoreCodingKeys.self, forKey: .store)
        try nestedContainer.encode(key, forKey: .key)
        try nestedContainer.encode(value, forKey: .value)

      case let .single(_0):
        var nestedContainer = container.nestedContainer(keyedBy: SingleCodingKeys.self, forKey: .single)
        try nestedContainer.encode(_0, forKey: ._0)

      case .none:
        _ = container.nestedContainer(keyedBy: NoneCodingKeys.self, forKey: .none)
      }
    }

    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      if container.allKeys.count != 1 {
        let context = DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Invalid number of keys found, expected one.")
        throw DecodingError.typeMismatch(Command.self, context)
      }

      switch container.allKeys.first.unsafelyUnwrapped {
      case .load:
        let nestedContainer = try container.nestedContainer(keyedBy: LoadCodingKeys.self, forKey: .load)
        self = .load(
          key: try nestedContainer.decode(String.self, forKey: .key))
      case .store:
        let nestedContainer = try container.nestedContainer(keyedBy: StoreCodingKeys.self, forKey: .store)
        self = .store(
          key: try nestedContainer.decode(String.self, forKey: .key),
          value: try nestedContainer.decode(Int.self, forKey: .value))

      case .single:
        let nestedContainer = try container.nestedContainer(keyedBy: SingleCodingKeys.self, forKey: .single)
        self = .single(try nestedContainer.decode(Person.self, forKey: ._0))

      case .none:
        _ = try container.nestedContainer(keyedBy: NoneCodingKeys.self, forKey: .none)
        self = .none
      }
    }

}

// contains keys for all cases of the enum
enum CodingKeys: CodingKey, EnumCodingKey {
  case load
  case store
    case single
    case none
}

// contains keys for all associated values of `case load`
enum LoadCodingKeys: CodingKey {
  case key
}

// contains keys for all associated values of `case load`
enum SingleCodingKeys: CodingKey, SingleUnlabelledEnumCaseCodingKey {
  case _0
}

// contains keys for all associated values of `case load`
enum NoneCodingKeys: CodingKey, NoValueEnumCaseCodingKey {
  case _0
}



// contains keys for all associated values of `case store`
enum StoreCodingKeys: CodingKey {
  case key
  case value
}


final class EnumCodingTests: XCTestCase {
    func testDefaultCoding() {
        let encoder = EnumCoding.JSONEncoder()
        let data = try! encoder.encode(Command.store(key: "MyKey", value: 42))

        XCTAssertEqual(String(bytes: data, encoding: .utf8), """
{"store":{"key":"MyKey","value":42}}
""")

        let decoder = EnumCoding.JSONDecoder()
        let command = try! decoder.decode(Command.self, from: data)
        XCTAssertEqual(command, Command.store(key: "MyKey", value: 42))
    }

    func testDiscriminatorCoding() {
        let encoder = EnumCoding.JSONEncoder()
        encoder.enumEncodingStrategy = .useDiscriminator("_discrim")
        let data = try! encoder.encode(Command.store(key: "a", value: 42))

        XCTAssertEqual(String(bytes: data, encoding: .utf8), """
{"_discrim":"store","key":"a","value":42}
""")

        let decoder = EnumCoding.JSONDecoder()
        decoder.enumDecodingStrategy = .useDiscriminator("_discrim")
        let command = try! decoder.decode(Command.self, from: data)
        XCTAssertEqual(command, Command.store(key: "a", value: 42))
    }

    func testFlattenUnlabelledEnumValue() {
        let encoder = EnumCoding.JSONEncoder()
        encoder.enumEncodingStrategy = .flattenUnlabelledSingleValues
        let data = try! encoder.encode(Command.single(Person(name: "Jane Doe")))

        XCTAssertEqual(String(bytes: data, encoding: .utf8), """
{"single":{"name":"Jane Doe"}}
""")

        let decoder = EnumCoding.JSONDecoder()
        decoder.enumDecodingStrategy = .flattenUnlabelledSingleValues
        let command = try! decoder.decode(Command.self, from: data)
        XCTAssertEqual(command, Command.single(Person(name: "Jane Doe")))
    }

    func testNoValueCoding() {
        let encoder = EnumCoding.JSONEncoder()
        encoder.noValueEnumEncodingStrategy = .useBool(true)
        let data = try! encoder.encode(Command.none)

        XCTAssertEqual(String(bytes: data, encoding: .utf8), """
{"none":true}
""")

        let decoder = EnumCoding.JSONDecoder()
        decoder.noValueEnumDecodingStrategy = .useBool(true)
        let command = try! decoder.decode(Command.self, from: data)
        XCTAssertEqual(command, Command.none)
    }
}
