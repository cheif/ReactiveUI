# ReactiveUI

A way of writing SwiftUI using a more reactive approach, install using SPM and then starting should be as simple as:

```swift
struct ContentView: View {
    var body: some View {
        // emit [0], [0, 1] ... [0, ..., 20] with 150ms delay
        let items = (0...20)
            .map { max in Just(Array((0...max))).delay(for: .milliseconds(max * 150), scheduler: RunLoop.main).eraseToAnyPublisher() }
            .reduce(Just([0]).eraseToAnyPublisher(), { $0.merge(with: $1).eraseToAnyPublisher() })

        // This block is evaluated (on mainthread) everytime `items` emit
        return items.view { numbers in
            List(numbers, id: \.self) { Text("\($0)") }
        }
    }
}
```
