// BEGIN nlp_pg_imports
import NaturalLanguage
import Foundation
import CoreML
// END nlp_pg_imports

//"My hovercraft is full of eels" // English
//"Mijn hovercraft zit vol palingen" // Afrikaans
//"我的氣墊船裝滿了鱔魚 [我的气垫船装满了鳝鱼]" // Chinese
//"Mit luftpudefartøj er fyldt med ål" // Danish
//"Το χόβερκραφτ μου είναι γεμάτο χέλια" // Greek
//"제 호버크래프트가 장어로 가득해요" // Korean
//"Mi aerodeslizador está lleno de anguilas" // Spanish
//"Mein Luftkissenfahrzeug ist voller Aale" // German

// Language Identification
// BEGIN nlp_pg_li_ext
extension String {
    func predictLanguage() -> String {
        let locale = Locale(identifier: "es")
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(self)
        let language = recognizer.dominantLanguage
        return locale.localizedString(forLanguageCode: language!.rawValue) ?? "unknown"
    }
}
// END nlp_pg_li_ext

print("### Language Identification Demo ###")
// BEGIN nlp_pg_li_string
let text = ["My hovercraft is full of eels",
            "Mijn hovercraft zit vol palingen",
            "我的氣墊船裝滿了鱔魚 [我的气垫船装满了鳝鱼]",
            "Mit luftpudefartøj er fyldt med ål",
            "Το χόβερκραφτ μου είναι γεμάτο χέλια",
            "제 호버크래프트가 장어로 가득해요",
            "Mi aerodeslizador está lleno de anguilas",
            "Mein Luftkissenfahrzeug ist voller Aale"]
// END nlp_pg_li_string

// BEGIN nlp_pg_li_test
for string in text {
    print("\(string) is in \(string.predictLanguage())")
}
// END nlp_pg_li_test

// Named Entity Recognition
// BEGIN ner_pg_ext
extension String {
    func printNamedEntities() {
        let tagger = NSLinguisticTagger(tagSchemes: [.nameType], options: 0)
        tagger.string = self
        
        let range = NSRange(location: 0, length: self.utf16.count)
        
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NSLinguisticTag] = [.personalName, .placeName, .organizationName]
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange, stop in
            if let tag = tag, tags.contains(tag) {
                let name = (self as NSString).substring(with: tokenRange)
                print("\(name) is a \(tag.rawValue)")
            }
        }
    }
}
// END ner_pg_ext
print("### Named Entity Recognition Demo ###")
// BEGIN ner_pg_sentence
let sentence = "Marina, Jon, and Tim write books for O'Reilly Media and live in Tasmania, Australia."
// END ner_pg_sentence
// BEGIN ner_pg_testner
sentence.printNamedEntities()
// END ner_pg_testner

// Tokenization
extension String {
    func printWords() {
        let tagger = NSLinguisticTagger(tagSchemes:[.tokenType], options: 0)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        tagger.string = self
        let range = NSRange(location: 0, length: self.utf16.count)
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .tokenType, options: options) { tag, tokenRange, stop in
            let word = (self as NSString).substring(with: tokenRange)
            print(word)
        }
    }
}
print("### Tokenization Demo ###")
let speech = "Space, the final frontier. These are the voyages of the Starship Enterprise. Its continuing mission to explore strange new worlds, to seek out new life and new civilization, to boldly go where no one has gone before!"
speech.printWords()

// Parts of Speech
extension String {
    func printPartsOfSpeech() {
        let tagger = NSLinguisticTagger(tagSchemes:[.lexicalClass], options: 0)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        tagger.string = self
        let range = NSRange(location: 0, length: self.utf16.count)
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange, _ in
            if let tag = tag {
                let word = (self as NSString).substring(with: tokenRange)
                print("\(word) is a \(tag.rawValue)")
            }
        }
    }
}
print("### Parts of Speech Demo ###")
speech.printPartsOfSpeech()

//Lemmatization
extension String {
    func printLemmas() {
        let tagger = NSLinguisticTagger(tagSchemes:[.lemma], options: 0)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        tagger.string = self
        let range = NSRange(location: 0, length: self.utf16.count)

        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { tag, tokenRange, stop in
            if let lemma = tag?.rawValue { print(lemma) }
        }
    }
}
print("### Lemmatization Demo ###")
speech.printLemmas()    

// Custom Tagger

class ReviewTagger {
    private let scheme = NLTagScheme("Review")
    private let options: NLTagger.Options = [.omitPunctuation]
    
    private lazy var tagger: NLTagger? = {
        do {
            let modelFile = URL(fileURLWithPath: "/Users/parisba/ORM Projects/Practical AI with Swift 1st Edition/PracticalAIwithSwift1stEd-Code/ChapterXX-NaturalLanguage/ReviewMLTextClassifier.mlmodel")
            let model = try NLModel(contentsOf: modelFile) // makes the ML model an NL model
            let tagger = NLTagger(tagSchemes: [scheme])
            tagger.setModels([model], forTagScheme: scheme) // connect model to (custom) scheme name
            print("Success loading model")
            return tagger
        } catch {
            return nil
        }
    }()
    
    func prediction(for text: String) -> String? {
        print("Prediction requested for: \(text)")
        tagger?.string = text
        let range = text.startIndex ..< text.endIndex
        tagger?.setLanguage(.english, range: range)
        return tagger?.tags(in: range,
                            unit: .document,
                            scheme: scheme,
                            options: options)
            .compactMap { tag, _ -> String? in
                return tag?.rawValue
            }
            .first
    }
}

let reviewTagger = ReviewTagger()
let reviews = ["I hated everything.", "I loved everything, it was amazing."]

reviews.forEach { review in
    guard let prediction = reviewTagger.prediction(for: review) else { return }
    print("\(prediction) -- \(review)")
}
