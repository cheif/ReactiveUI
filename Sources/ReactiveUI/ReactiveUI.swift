import SwiftUI
import Combine

/**
 A Reactive SwiftUI view, it uses publisher as a data-source, and then the builder to build the UI whenever source emits.
 */
public func ReactiveView<Data, Content: View>(source: AnyPublisher<Data, Never>, builder: @escaping (Data) -> Content) -> some View {
    WrapperView(source: source.share(), builder: builder)
}

public extension Publisher where Failure == Never {
    func view<Content: View>(builder: @escaping (Output) -> Content) -> some View {
        WrapperView(source: self.eraseToAnyPublisher().share(), builder: builder)
    }
}

public protocol ReactiveBuilderView: View {
    associatedtype Data
    associatedtype Content: View
    
    func createBody(from state: Data) -> Content
    var source: AnyPublisher<Data, Never> { get }
}

private struct WrapperView<Data, ViewType: View>: View {
    @State private var state: Data? = nil
    // We require the source to be shared, since otherwise we'll re-subscribe to it whenever the UI changes
    let source: Publishers.Share<AnyPublisher<Data, Never>>
    let builder: (Data) -> ViewType
    var body: some View {
        Group {
            if state != nil {
                state.map(builder)
            } else {
                // We need a VStack here, otherwise e.g. NavigationView will crash when containing a ReactiveView without data
                VStack {
                    EmptyView()
                }
            }
        }
        .onReceive(source.receive(on: RunLoop.main), perform: { data in
            self.state = data
        })
    }
}

public extension ReactiveBuilderView {
    var body: some View {
        return WrapperView(source: source.share(), builder: createBody)
    }
}
