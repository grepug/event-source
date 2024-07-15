//
//  EventStreamParser.swift
//  EventSource
//
//  Created by Andres on 30/05/2019.
//  Copyright © 2019 inaka. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class EventStreamParser {

    //  Events are separated by end of line. End of line can be:
    //  \r = CR (Carriage Return) → Used as a new line character in Mac OS before X
    //  \n = LF (Line Feed) → Used as a new line character in Unix/Mac OS X
    //  \r\n = CR + LF → Used as a new line character in Windows
    private let validNewlineCharacters = ["\r\n", "\n", "\r"]
    private var dataBuffer: Data

    init() {
        dataBuffer = Data()
    }

    var currentBuffer: String? {
        return String(data: dataBuffer, encoding: .utf8)
    }

    func append(data: Data?) -> [Event] {
        guard let data = data else { return [] }
        dataBuffer.append(data)

        let events = extractEventsFromBuffer().compactMap { [weak self] eventString -> Event? in
            guard let self = self else { return nil }
            return Event(eventString: eventString, newLineCharacters: self.validNewlineCharacters)
        }

        return events
    }

    private func extractEventsFromBuffer() -> [String] {
        var events = [String]()
        var searchRange = 0..<dataBuffer.count

        while let foundRange = searchFirstEventDelimiter(in: searchRange) {
            let dataChunk = dataBuffer.subdata(in: searchRange.lowerBound..<foundRange.lowerBound)

            if let text = String(data: dataChunk, encoding: .utf8) {
                events.append(text)
            }

            searchRange = foundRange.upperBound..<dataBuffer.count
        }
        
        dataBuffer = dataBuffer.subdata(in: searchRange)

        return events
    }

    private func searchFirstEventDelimiter(in range: Range<Data.Index>) -> Range<Data.Index>? {
        let delimiters = validNewlineCharacters.map { "\($0)\($0)".data(using: .utf8)! }

        for delimiter in delimiters {
            if let foundRange = dataBuffer.range(of: delimiter, options: [], in: range) {
                return foundRange
            }
        }

        return nil
    }
}

extension Data {
    func range(of data: Data, options: Data.SearchOptions = [], in range: Range<Data.Index>) -> Range<Data.Index>? {
        let searchRange = range.clamped(to: 0..<self.count)
        guard let startIndex = self[searchRange].firstIndex(of: data[0]) else { return nil }
        let possibleRange = startIndex..<(startIndex + data.count)
        return possibleRange.clamped(to: searchRange)
    }
}
