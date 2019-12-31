//
//  Parser.swift
//  
//
//  Created by Sven A. Schmidt on 29/12/2019.
//

import Foundation


public struct Match<A> {
    let result: A?
    let rest: Substring
}


extension Match: Equatable where A: Equatable {}


public struct Parser<A> {
    public let run: (inout Substring) -> A?

    public init(_ run: @escaping (inout Substring) -> A?) {
        self.run = run
    }

    public func map<B>(_ f: @escaping (A) -> B) -> Parser<B> {
      return Parser<B> { str -> B? in
        self.run(&str).map(f)
      }
    }

    public func flatMap<B>(_ f: @escaping (A) -> Parser<B>) -> Parser<B> {
        return Parser<B> { str -> B? in
            let original = str
            let matchA = self.run(&str)
            let parserB = matchA.map(f)
            guard let matchB = parserB?.run(&str) else {
                str = original
                return nil
            }
            return matchB
        }
    }

    public func run(_ str: String) -> Match<A> {
      var str = str[...]
      let res = self.run(&str)
      return Match(result: res, rest: str)
    }

    public static var end: Parser<Void> {
        Parser<Void> { $0.isEmpty ? () : nil }
    }

    public static func appendEnd(_ p: Parser<A>) -> Parser<A> {
        zip(p, .end).flatMap { a, _ in always(a) }
    }
}


public let int = Parser<Int> { str in
  let prefix = str.prefix(while: { $0.isNumber })
  let match = Int(prefix)
  str.removeFirst(prefix.count)
  return match
}


public let char = Parser<Character> { str in
  guard !str.isEmpty else { return nil }
  return str.removeFirst()
}


public func char(in characterSet: CharacterSet) -> Parser<Character> {
    return Parser<Character> { str in
        guard let first = str.first, characterSet.contains(character: first) else { return nil }
        return str.removeFirst()
    }
}


func prefix(charactersIn characterSet: CharacterSet) -> Parser<Substring> {
    return prefix(while: { characterSet.contains(character: $0) })
}


public func literal(_ p: String) -> Parser<Void> {
  return Parser<Void> { str in
    guard str.hasPrefix(p) else { return nil }
    str.removeFirst(p.count)
    return ()
  }
}


public func string(_ p: String) -> Parser<String> {
  return Parser<String> { str in
    guard str.hasPrefix(p) else { return nil }
    str.removeFirst(p.count)
    return p
  }
}


public func always<A>(_ a: A) -> Parser<A> {
    return Parser<A> { _ in a }
}

extension Parser {
    public static var never: Parser {
        return Parser { _ in nil }
    }
}

public func zip<A, B>(_ a: Parser<A>, _ b: Parser<B>) -> Parser<(A, B)> {
  return Parser<(A, B)> { str -> (A, B)? in
    let original = str
    guard let matchA = a.run(&str) else { return nil }
    guard let matchB = b.run(&str) else {
      str = original
      return nil
    }
    return (matchA, matchB)
  }
}


public func zip<A, B, C>(
  _ a: Parser<A>,
  _ b: Parser<B>,
  _ c: Parser<C>
  ) -> Parser<(A, B, C)> {
  return zip(a, zip(b, c))
    .map { a, bc in (a, bc.0, bc.1) }
}

public func zip<A, B, C, D>(
  _ a: Parser<A>,
  _ b: Parser<B>,
  _ c: Parser<C>,
  _ d: Parser<D>
  ) -> Parser<(A, B, C, D)> {
  return zip(a, zip(b, c, d))
    .map { a, bcd in (a, bcd.0, bcd.1, bcd.2) }
}

public func zip<A, B, C, D, E>(
  _ a: Parser<A>,
  _ b: Parser<B>,
  _ c: Parser<C>,
  _ d: Parser<D>,
  _ e: Parser<E>
  ) -> Parser<(A, B, C, D, E)> {

  return zip(a, zip(b, c, d, e))
    .map { a, bcde in (a, bcde.0, bcde.1, bcde.2, bcde.3) }
}

public func zip<A, B, C, D, E, F>(
  _ a: Parser<A>,
  _ b: Parser<B>,
  _ c: Parser<C>,
  _ d: Parser<D>,
  _ e: Parser<E>,
  _ f: Parser<F>
  ) -> Parser<(A, B, C, D, E, F)> {
  return zip(a, zip(b, c, d, e, f))
    .map { a, bcdef in (a, bcdef.0, bcdef.1, bcdef.2, bcdef.3, bcdef.4) }
}

public func zip<A, B, C, D, E, F, G>(
  _ a: Parser<A>,
  _ b: Parser<B>,
  _ c: Parser<C>,
  _ d: Parser<D>,
  _ e: Parser<E>,
  _ f: Parser<F>,
  _ g: Parser<G>
  ) -> Parser<(A, B, C, D, E, F, G)> {
  return zip(a, zip(b, c, d, e, f, g))
    .map { a, bcdefg in (a, bcdefg.0, bcdefg.1, bcdefg.2, bcdefg.3, bcdefg.4, bcdefg.5) }
}

public func oneOf<A>(
  _ ps: [Parser<A>]
  ) -> Parser<A> {
  return Parser<A> { str -> A? in
    for p in ps {
      if let match = p.run(&str) {
        return match
      }
    }
    return nil
  }
}


public func prefix(while p: @escaping (Character) -> Bool) -> Parser<Substring> {
  return Parser<Substring> { str in
    let prefix = str.prefix(while: p)
    str.removeFirst(prefix.count)
    return prefix
  }
}


public func prefix(upTo p: String) -> Parser<Substring> {
  return Parser<Substring> { str in
    guard let range = str.range(of: p) else {
        let match = str[...]
        str = ""
        return match
    }
    let match = str[..<range.lowerBound]
    str = str[range.lowerBound...]
    return match
  }
}


public func shortestOf<A>(_ ps: [Parser<A>]) -> Parser<A> {
    return Parser<A> { str -> A? in
        var shortest: A? = nil
        var longestRestLength = -1
        for p in ps {
            var orig = str
            let m = p.run(&orig)
            if orig.count > longestRestLength {
                longestRestLength = orig.count
                shortest = m
            }
        }
        str.removeFirst(str.count - longestRestLength)
        return shortest
    }
}


extension CharacterSet {
    func contains(character: Character) -> Bool {
        if character.unicodeScalars.count <= 1 {
            return character.unicodeScalars.allSatisfy(contains(_:))
        } else {
            let testSet = CharacterSet(charactersIn: String(character))
            return testSet.isSubset(of: self)
        }
    }
}
