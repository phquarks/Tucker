import AppKit

@main
struct HiddenItemSelectionTests {
    static func main() {
        let boundary: CGFloat = 100
        func hidden(_ positions: [(String, CGFloat?)], rtl: Bool = false) -> Set<String> {
            HiddenItemSelection.hiddenBundles(positions: positions, boundary: boundary, rightToLeft: rtl)
        }
        precondition(hidden([]).isEmpty)
        precondition(hidden([("left", 20), ("right", 120)]) == ["left"])
        precondition(hidden([("left", 20), ("right", 120)], rtl: true) == ["right"])
        precondition(hidden([("edge", 100)]).isEmpty)
        precondition(hidden([("shared", 20), ("shared", 120)]).isEmpty)
        precondition(hidden([("unknown", 20), ("unknown", nil)]).isEmpty)
        precondition(hidden([("bad", .nan), ("bad", 20)]).isEmpty)
        precondition(hidden([("bad", .infinity)]).isEmpty)
        precondition(hidden([("multi", 20), ("multi", 30)]) == ["multi"])
        print("PASS: 9 hidden-section selection checks")
        // Read-only runtime probe: never activate a visibility restriction here.
        print("macOS native visibility API available: \(TKNativeVisibility.available)")
    }
}
