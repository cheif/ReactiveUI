import SwiftUI
import Combine
import ReactiveUI

struct Item: Identifiable {
    let id: Int
}

struct ContentView: View {
    let dataSource: DataSource = MockSource()
    var body: some View {
        NavigationView {
            ReactiveView(source: dataSource.getItems()) { state in state.view(with: self.dataSource) }
        }
    }
}

extension DataState {
    func view(with dataSource: DataSource) -> some View {
        switch self {
        case .loading:
            return AnyView(Text("Loading..."))
        case .data(let items):
            return AnyView(List {
                ForEach(items) { item in
                    ReactiveView(source: dataSource.getName(for: item)) { name in
                        NavigationLink(destination: item.detailView(with: dataSource)) {
                            Text(name)
                        }
                    }
                }
            })
        }
    }
}

extension Item {
    func detailView(with dataSource: DataSource) -> some View {
        let image = dataSource.getImage(for: self).map { $0 as UIImage? }.prepend(nil)
        let description = dataSource.getDescription(for: self).map { $0 as String? }.prepend(nil)
        let imageAndDescription = image.combineLatest(description).eraseToAnyPublisher()
        return imageAndDescription.view { (image, description) in
            return VStack {
                image.map(Image.init)
                description.map(Text.init)
            }
        }
    }
}

enum DataState {
    case loading
    case data([Item])
}

protocol DataSource {
    func getItems() -> AnyPublisher<DataState, Never>

    func getName(for item: Item) -> AnyPublisher<String, Never>
    func getImage(for item: Item) -> AnyPublisher<UIImage, Never>
    func getDescription(for item: Item) -> AnyPublisher<String, Never>
}

struct MockSource: DataSource {
    func getItems() -> AnyPublisher<DataState, Never> {
        return Just(.data((0...15).map(Item.init)))
            .delay(for: .seconds(2.0), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
            .merge(with: Just(.loading).eraseToAnyPublisher())
            .eraseToAnyPublisher()
    }

    func getName(for item: Item) -> AnyPublisher<String, Never> {
        return Just("Item: \(item.id)")
            .delay(for: .milliseconds((100...400).randomElement()!), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }

    func getImage(for item: Item) -> AnyPublisher<UIImage, Never> {
        URLSession.shared
            .dataTaskPublisher(for: URL(string: "https://upload.wikimedia.org/wikipedia/commons/d/dd/A-haVistalegre19.JPG")!)
            .map { data, _ in UIImage(data: data)! }
            .replaceError(with: .init())
            .eraseToAnyPublisher()
    }

    func getDescription(for item: Item) -> AnyPublisher<String, Never> {
        return Just("Testing item no: \(item.id)").delay(for: .milliseconds(300), scheduler: RunLoop.main).eraseToAnyPublisher()
    }

}
