import Foundation

@MainActor
protocol BaseViewModel: AnyObject {
    associatedtype Input
    associatedtype Output

    var output: Output { get }

    @discardableResult
    func transform(input: Input) async -> Output
}
