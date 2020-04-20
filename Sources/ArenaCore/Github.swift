//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 10/03/2020.
//


import Foundation
import PackageModel
import Parser


let requestTimeout = 5


struct GithubClient {
    var latestRelease: (GithubRepository) -> Release?
    var tags: (GithubRepository) -> [Tag]
}


extension GithubClient {
    static let live = Self(
        latestRelease: latestReleaseRequest,
        tags: tagsRequest
    )
}


struct Release: Decodable {
    let tagName: String

    // can't use automatic camel case conversion - it raises an error:
    // decodingError("The data couldn’t be read because it is missing.")
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
    }

    var version: Version? {
        Parser.version.run(tagName).result
    }
}


struct Tag: Decodable {
    let name: String
}


struct GithubRepository: CustomStringConvertible {
    let owner: String
    let repository: String
    var description: String { owner + "/" + repository}

    init?(url: URL) {
        guard url.host == "github.com" else {
            return nil
        }
        let path = url.path
        guard path.hasPrefix("/") else { return nil }
        let parts = path.dropFirst().split(separator: "/")
        guard parts.count == 2 else { return nil }
        let repo = parts[1].lowercased().hasSuffix(".git") ? parts[1].dropLast(".git".count) : parts[1]
        owner = String(parts[0])
        repository = String(repo)
    }
}


extension GithubRepository {
    var latestReleaseURL: URL? {
        guard !owner.isEmpty, !repository.isEmpty else { return nil }
        return URL(string: "https://api.github.com/repos/\(description)/releases/latest")
    }

    var tagsURL: URL? {
        guard !owner.isEmpty, !repository.isEmpty else { return nil }
        return URL(string: "https://api.github.com/repos/\(description)/tags")
    }
}


func latestReleaseRequest(for repository: GithubRepository) -> Release? {
    guard let url = repository.latestReleaseURL else { return nil }

    let sema = DispatchSemaphore(value: 0)
    var result: Release? = nil
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else { return }
        result = try? JSONDecoder().decode(Release.self, from: data)
        sema.signal()
    }
    task.resume()
    let _ = sema.wait(timeout: DispatchTime.now() + .seconds(requestTimeout))
    return result
}


func tagsRequest(for repository: GithubRepository) -> [Tag] {
    guard let url = repository.tagsURL else { return [] }

    let sema = DispatchSemaphore(value: 0)
    var result = [Tag]()
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else { return }
        result = (try? JSONDecoder().decode([Tag].self, from: data)) ?? []
        sema.signal()
    }
    task.resume()
    let _ = sema.wait(timeout: DispatchTime.now() + .seconds(requestTimeout))
    return result
}
