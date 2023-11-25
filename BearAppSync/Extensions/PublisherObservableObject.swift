//
//  PublisherObservableObject.swift
//  BearAppSync
//
//  Created by d4Rk on 21.11.23.
//

import Combine

final class PublisherObservableObject: ObservableObject {
    var subscriber: AnyCancellable?

    init(publisher: AnyPublisher<Void, Never>) {
        subscriber = publisher.sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        })
    }
}
