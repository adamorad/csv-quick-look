import Foundation

struct CSVParseResult {
    let headers: [String]
    let rows: [[String]]
    let totalRowCount: Int
    let delimiter: Character
}

enum CSVParser {

    static func decode(_ data: Data) -> String? {
        // BOM detection
        if data.count >= 3, data[0] == 0xEF, data[1] == 0xBB, data[2] == 0xBF {
            return String(data: data.dropFirst(3), encoding: .utf8)
        }
        if data.count >= 2 {
            if data[0] == 0xFF, data[1] == 0xFE {
                return String(data: data, encoding: .utf16LittleEndian)
            }
            if data[0] == 0xFE, data[1] == 0xFF {
                return String(data: data, encoding: .utf16BigEndian)
            }
        }
        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .windowsCP1252)
            ?? String(data: data, encoding: .isoLatin1)
    }

    static func detectDelimiter(in sample: String) -> Character {
        let candidates: [Character] = [",", "\t", ";", "|"]
        return candidates.max { a, b in
            sample.filter { $0 == a }.count < sample.filter { $0 == b }.count
        } ?? ","
    }

    static func parse(_ string: String, delimiter: Character? = nil, maxRows: Int = 100_000) -> CSVParseResult {
        let sample = String(string.prefix(2048))
        let delim = delimiter ?? detectDelimiter(in: sample)

        var parsedRows: [[String]] = []
        var totalRowCount = 0
        var pos = string.startIndex

        while pos < string.endIndex {
            let (fields, next) = parseRow(string: string, from: pos, delimiter: delim)
            pos = next

            // Skip blank lines
            if fields.count == 1 && fields[0].isEmpty { continue }

            totalRowCount += 1
            if parsedRows.count <= maxRows {
                parsedRows.append(fields)
            }
        }

        guard !parsedRows.isEmpty else {
            return CSVParseResult(headers: [], rows: [], totalRowCount: 0, delimiter: delim)
        }

        let headers = parsedRows[0]
        let colCount = headers.count
        let dataRows = parsedRows.dropFirst().map { row -> [String] in
            if row.count == colCount { return row }
            var r = row
            if r.count < colCount {
                r += Array(repeating: "", count: colCount - r.count)
            } else {
                r = Array(r.prefix(colCount))
            }
            return r
        }

        // totalRowCount includes the header row; subtract 1
        return CSVParseResult(
            headers: headers,
            rows: Array(dataRows),
            totalRowCount: max(0, totalRowCount - 1),
            delimiter: delim
        )
    }

    // Returns (fields, nextPosition)
    private static func parseRow(
        string: String, from start: String.Index, delimiter: Character
    ) -> ([String], String.Index) {
        var fields: [String] = []
        var pos = start

        while true {
            let (field, next, endedRow) = parseField(string: string, from: pos, delimiter: delimiter)
            fields.append(field)
            pos = next
            if endedRow { break }
        }

        return (fields, pos)
    }

    // Returns (field value, nextPosition, didEndRow)
    private static func parseField(
        string: String, from start: String.Index, delimiter: Character
    ) -> (String, String.Index, Bool) {
        var pos = start

        if pos < string.endIndex && string[pos] == "\"" {
            // RFC 4180 quoted field
            pos = string.index(after: pos)
            var field = ""
            while pos < string.endIndex {
                let ch = string[pos]
                if ch == "\"" {
                    pos = string.index(after: pos)
                    if pos < string.endIndex && string[pos] == "\"" {
                        field.append("\"")
                        pos = string.index(after: pos)
                    } else {
                        break
                    }
                } else {
                    field.append(ch)
                    pos = string.index(after: pos)
                }
            }
            // Consume trailing garbage before delimiter/newline
            while pos < string.endIndex && string[pos] != delimiter && string[pos] != "\n" && string[pos] != "\r" {
                pos = string.index(after: pos)
            }
            let endedRow = pos >= string.endIndex || string[pos] == "\n" || string[pos] == "\r"
            pos = consumeLineBreakOrDelimiter(string: string, at: pos, delimiter: delimiter, endedRow: endedRow)
            return (field, pos, endedRow)
        } else {
            var field = ""
            while pos < string.endIndex {
                let ch = string[pos]
                if ch == delimiter || ch == "\n" || ch == "\r" { break }
                field.append(ch)
                pos = string.index(after: pos)
            }
            let endedRow = pos >= string.endIndex || string[pos] == "\n" || string[pos] == "\r"
            pos = consumeLineBreakOrDelimiter(string: string, at: pos, delimiter: delimiter, endedRow: endedRow)
            return (field, pos, endedRow)
        }
    }

    private static func consumeLineBreakOrDelimiter(
        string: String, at pos: String.Index, delimiter: Character, endedRow: Bool
    ) -> String.Index {
        var p = pos
        if endedRow {
            if p < string.endIndex && string[p] == "\r" { p = string.index(after: p) }
            if p < string.endIndex && string[p] == "\n" { p = string.index(after: p) }
        } else {
            if p < string.endIndex { p = string.index(after: p) } // skip delimiter
        }
        return p
    }
}
