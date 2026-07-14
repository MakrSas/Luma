import Foundation
import LocalLLMClient

struct SearchWebArguments: Decodable, ToolSchemaGeneratable {
    var query: String

    static var argumentsSchema: LLMToolArgumentsSchema {
        ["query": .string(description: "The search query text")]
    }
}

struct FetchURLArguments: Decodable, ToolSchemaGeneratable {
    var url: String

    static var argumentsSchema: LLMToolArgumentsSchema {
        ["url": .string(description: "The full URL to fetch, including https://")]
    }
}

/// Real internet-access tools, only included in the model's tool list when
/// the corresponding `ToolPermission` isn't `.denied` (see `ChatView`) —
/// this is what backs "Дай возможность дать модели доступ в интернет".
struct SearchWebTool: LLMTool {
    static let toolName = "search_web"
    let name = SearchWebTool.toolName
    let description = "Search the public web for current information the model doesn't already know (news, facts, prices, recent events). Returns a short list of titles with descriptions."
    typealias Arguments = SearchWebArguments

    func call(arguments: SearchWebArguments) async throws -> ToolOutput {
        let results = try await WebSearchService.search(query: arguments.query)
        return ToolOutput(data: ["results": results])
    }
}

struct FetchURLTool: LLMTool {
    static let toolName = "fetch_url"
    let name = FetchURLTool.toolName
    let description = "Fetch the text content of a specific web page URL, e.g. one found via search_web."
    typealias Arguments = FetchURLArguments

    func call(arguments: FetchURLArguments) async throws -> ToolOutput {
        let text = try await WebSearchService.fetchPageText(urlString: arguments.url)
        return ToolOutput(data: ["content": text])
    }
}
