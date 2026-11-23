import SwiftUI

/// Approved original book art, keyed by canonical USFM identifier in every language.
enum BibleBookArtwork {
    static func opening(bookID: String, chapter: Int, verse: Int) -> String? {
        guard chapter == 1, verse == 1 else { return nil }
        return names[bookID]
    }
    static let names: [String: String] = [
        "GEN": "bible-book-gen",
        "EXO": "bible-book-exo",
        "LEV": "bible-book-lev",
        "NUM": "bible-book-num",
        "DEU": "bible-book-deu",
        "JOS": "bible-book-jos",
        "JDG": "bible-book-jdg",
        "RUT": "bible-book-rut",
        "1SA": "bible-book-1sa",
        "2SA": "bible-book-2sa",
        "1KI": "bible-book-1ki",
        "2KI": "bible-book-2ki",
        "1CH": "bible-book-1ch",
        "2CH": "bible-book-2ch",
        "EZR": "bible-book-ezr",
        "NEH": "bible-book-neh",
        "EST": "bible-book-est",
        "JOB": "bible-book-job",
        "PSA": "bible-book-psa",
        "PRO": "bible-book-pro",
        "ECC": "bible-book-ecc",
        "SNG": "bible-book-sng",
        "ISA": "bible-book-isa",
        "JER": "bible-book-jer",
        "LAM": "bible-book-lam",
        "EZK": "bible-book-ezk",
        "DAN": "bible-book-dan",
        "HOS": "bible-book-hos",
        "JOL": "bible-book-jol",
        "AMO": "bible-book-amo",
        "OBA": "bible-book-oba",
        "JON": "bible-book-jon",
        "MIC": "bible-book-mic",
        "NAM": "bible-book-nam",
        "HAB": "bible-book-hab",
        "ZEP": "bible-book-zep",
        "HAG": "bible-book-hag",
        "ZEC": "bible-book-zec",
        "MAL": "bible-book-mal",
        "MAT": "bible-book-mat",
        "MRK": "bible-book-mrk",
        "LUK": "bible-book-luk",
        "JHN": "bible-book-jhn",
        "ACT": "bible-book-act",
        "ROM": "bible-book-rom",
        "1CO": "bible-book-1co",
        "2CO": "bible-book-2co",
        "GAL": "bible-book-gal",
        "EPH": "bible-book-eph",
        "PHP": "bible-book-php",
        "COL": "bible-book-col",
        "1TH": "bible-book-1th",
        "2TH": "bible-book-2th",
        "1TI": "bible-book-1ti",
        "2TI": "bible-book-2ti",
        "TIT": "bible-book-tit",
        "PHM": "bible-book-phm",
        "HEB": "bible-book-heb",
        "JAS": "bible-book-jas",
        "1PE": "bible-book-1pe",
        "2PE": "bible-book-2pe",
        "1JN": "bible-book-1jn",
        "2JN": "bible-book-2jn",
        "3JN": "bible-book-3jn",
        "JUD": "bible-book-jud",
        "REV": "bible-book-rev",
    ]
}

struct BibleBookImage: View {
    let bookID: String
    var body: some View {
        if let name = BibleBookArtwork.names[bookID] {
            Image(name).resizable().scaledToFit().accessibilityHidden(true)
        }
    }
}
