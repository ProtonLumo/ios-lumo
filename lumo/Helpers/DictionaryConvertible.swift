import Foundation

protocol DictionaryConvertible {
    func toDictionary() -> [String: Any]
}

extension DictionaryConvertible {

    func toDictionary() -> [String: Any] {
        let reflect = Mirror(reflecting: self)
        let children = reflect.children
        let dictionary = toAnyHashable(elements: children)
        return dictionary
    }

    private func toAnyHashable(elements: AnyCollection<Mirror.Child>) -> [String: Any] {
        var dictionary: [String: Any] = [:]
        for element in elements {
            if let key = element.label?.capitalizedFirst {

                if let _ = element.value as? [AnyHashable] {
                    dictionary[key] = element.value
                }

                if let _ = element.value as? AnyHashable {
                    dictionary[key] = element.value
                }

                if let convertor = element.value as? DictionaryConvertible {
                    dictionary[key] = convertor.toDictionary()
                }

                if let convertorList = element.value as? [DictionaryConvertible] {
                    dictionary[key] = convertorList.map({ e in
                        e.toDictionary()
                    })
                }
            }
        }
        return dictionary
    }
}

