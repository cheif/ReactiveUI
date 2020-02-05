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
            return AnyView(
                List(items) { item in item.rowView(with: dataSource) }
            )
        }
    }
}

extension Item {
    func rowView(with dataSource: DataSource) -> some View {
        dataSource.getName(for: self).view {  name in
            NavigationLink(destination: self.detailView(with: dataSource)) {
                Text(name)
            }
        }
    }

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
        // emit [0], [0, 1] ... [0, ..., 20] with 150ms delay
        return (0...20)
            .map { no in Just(Array((0...no))).delay(for: .seconds(1) + .milliseconds(no * 150), scheduler: RunLoop.main).eraseToAnyPublisher() }
            .reduce(Just([0]).eraseToAnyPublisher(), { $0.merge(with: $1).eraseToAnyPublisher() })
            .map { .data($0.map(Item.init)) }
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
