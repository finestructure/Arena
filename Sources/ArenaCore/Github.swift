//
//  File.swift
//  
//
//  Created by Sven A. Schmidt on 10/03/2020.
//


import Foundation


struct Release: Decodable {
    let tagName: String

    // can't use automatic camel case conversion - it raises an error:
    // decodingError("The data couldn’t be read because it is missing.")
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
    }
}


struct Repository: CustomStringConvertible {
    let owner: String
    let repository: String
    var description: String { owner + "/" + repository}

    init?(url: URL) {
        let path = url.path
        guard path.hasPrefix("/") else { return nil }
        let parts = path.dropFirst().split(separator: "/")
        guard parts.count == 2 else { return nil }
        let repo = parts[1].lowercased().hasSuffix(".git") ? parts[1].dropLast(".git".count) : parts[1]
        owner = String(parts[0])
        repository = String(repo)
    }
}


func latestReleaseURL(repository: String) -> URL? {
    guard !repository.isEmpty else { return nil }
    return URL(string: "https://api.github.com/repos/\(repository)/releases/latest")
}


func latestReleaseRequest(for repository: Repository) -> Release? {
    guard let url = latestReleaseURL(repository: repository.description) else {
        return nil
    }

    let sema = DispatchSemaphore(value: 0)
    var result: Release? = nil
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else { return }
        result = try? JSONDecoder().decode(Release.self, from: data)
        sema.signal()
    }
    task.resume()
    let _ = sema.wait(timeout: DispatchTime.now() + .seconds(2))
    return result
}
