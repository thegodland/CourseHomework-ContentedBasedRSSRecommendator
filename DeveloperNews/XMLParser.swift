//
//  XMLParser.swift
//  Developers News
//
//  Original coder by Duc Tran on 9/14/17, amended by Xiang Liu on 30 Sep, 2018
//  Copyright © 2017 Developers Academy. All rights reserved.
//

import Foundation


struct RSSItem {
    var title: String
    var description: [String:Double]
    var pubDate: String
    var df: [String:Double]
}

// download xml from a server
// parse xml to foundation objects
// call back

class FeedParser: NSObject, XMLParserDelegate
{
    private var rssItems: [RSSItem] = []
    private var currentElement = ""
    var document_frequency : [String:Double] = [:]
    
    // list of stop words
    // source is from 'xpo6.com/list-of-english-stop-words' and added 'st' and 'pm' and 'I'
    let wordsToRemove = ["a", "about", "above", "above", "across", "after", "afterwards", "again", "against", "all", "almost", "alone", "along", "already", "also","although","always","am","among", "amongst", "amoungst", "amount",  "an", "and", "another", "any","anyhow","anyone","anything","anyway", "anywhere", "are", "around", "as",  "at", "back","be","became", "because","become","becomes", "becoming", "been", "before", "beforehand", "behind", "being", "below", "beside", "besides", "between", "beyond", "bill", "both", "bottom","but", "by", "call", "can", "cannot", "cant", "co", "con", "could", "couldnt", "cry", "de", "describe", "detail", "do", "done", "down", "due", "during", "each", "eg", "eight", "either", "eleven","else", "elsewhere", "empty", "enough", "etc", "even", "ever", "every", "everyone", "everything", "everywhere", "except", "few", "fifteen", "fify", "fill", "find", "fire", "first", "five", "for", "former", "formerly", "forty", "found", "four", "from", "front", "full", "further", "get", "give", "go", "had", "has", "hasnt", "have", "he", "hence", "her", "here", "hereafter", "hereby", "herein", "hereupon", "hers", "herself", "him", "himself", "his", "how", "however", "hundred", "ie", "if", "in", "inc", "indeed", "interest", "into", "is", "it", "its", "itself", "keep", "last", "latter", "latterly", "least", "less", "ltd", "made", "many", "may", "me", "meanwhile", "might", "mill", "mine", "more", "moreover", "most", "mostly", "move", "much", "must", "my", "myself", "name", "namely", "neither", "never", "nevertheless", "next", "nine", "no", "nobody", "none", "noone", "nor", "not", "nothing", "now", "nowhere", "of", "off", "often", "on", "once", "one", "only", "onto", "or", "other", "others", "otherwise", "our", "ours", "ourselves", "out", "over", "own","part", "per", "perhaps", "please", "put", "rather", "re", "same", "see", "seem", "seemed", "seeming", "seems", "serious", "several", "she", "should", "show", "side", "since", "sincere", "six", "sixty", "so", "some", "somehow", "someone", "something", "sometime", "sometimes", "somewhere", "still", "such", "system", "take", "ten", "than", "that", "the", "their", "them", "themselves", "then", "thence", "there", "thereafter", "thereby", "therefore", "therein", "thereupon", "these", "they", "thickv", "thin", "third", "this", "those", "though", "three", "through", "throughout", "thru", "thus", "to", "together", "too", "top", "toward", "towards", "twelve", "twenty", "two", "un", "under", "until", "up", "upon", "us", "very", "via", "was", "we", "well", "were", "what", "whatever", "when", "whence", "whenever", "where", "whereafter", "whereas", "whereby", "wherein", "whereupon", "wherever", "whether", "which", "while", "whither", "who", "whoever", "whole", "whom", "whose", "why", "will", "with", "within", "without", "would", "yet", "you", "your", "yours", "yourself", "yourselves", "the", "st", "pm", "I"]
    
    private var currentTitle: String = "" {
        didSet {
            currentTitle = currentTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    private var currentDescription: String = "" {
        didSet {
            currentDescription = currentDescription.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    private var currentPubDate: String = "" {
        didSet {
            currentPubDate = currentPubDate.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    private var parserCompletionHandler: (([RSSItem]) -> Void)?
    
    func parseFeed(url: String, completionHandler: (([RSSItem]) -> Void)?)
    {
        self.parserCompletionHandler = completionHandler
        
        let request = URLRequest(url: URL(string: url)!)
        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            guard var data = data else { //###<-- `var` here
                if let error = error {
                    print(error.localizedDescription)
                }
                
                return
            }
            
            //to deal with parse CDATA problem. always have invalid characters.
            //### When the input `data` cannot be decoded as a UTF-8 String,
            if String(data: data, encoding: .utf8) == nil {
                //Interpret the data as an ISO-LATIN-1 String,
                let isoLatin1 = String(data: data, encoding: .isoLatin1)!
                //And re-encode it as a valid UTF-8
                data = isoLatin1.data(using: .utf8)!
            }
            
            /// parse our xml data
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }
        
        task.resume()
    }
    
    // MARK: - XML Parser Delegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:])
    {
        currentElement = elementName
        if currentElement == "item" {
            currentTitle = ""
            currentDescription = ""
            currentPubDate = ""
        }
    }
    
    
    
    func parser(_ parser: XMLParser, foundCharacters string: String)
    {
        switch currentElement {
        case "title": currentTitle += string
        case "description" : currentDescription += string
        case "pubDate" : currentPubDate += string
            
        default: break
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?)
    {
        
        
        if elementName == "item" {
            
            // every time the result will be different for same context for the NSLinguishticTagger
            var newDocument : [String:Double] = [:]
            
            // using NSLinguishticTagger to parse natural language to stems
            let tagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
            tagger.string = currentDescription
            
            
            let range = NSRange(location: 0, length: currentDescription.utf16.count)
            let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
            tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options)  { tag, tokenRange, stop in
                if let lemma = tag?.rawValue {
                    var addedIntoDocument = false
                    if !self.wordsToRemove.contains(lemma){
                        // if the words are already in current document tracking list, added to previous value
                        if Array(newDocument.keys).contains(lemma){
                            // tf increase 1
                            if let tf = newDocument[lemma]{
                                newDocument[lemma] = tf + 1.0
                            }
                            
                        }else{
                            newDocument[lemma] = 1.0
                        }
                        
                        
                        if Array(document_frequency.keys).contains(lemma){
                            
                            if !addedIntoDocument{
                                //same doc don't add second time
                                // only the final df contains all the term df
                                
                                if let df = document_frequency[lemma]{
                                    document_frequency[lemma] = df + 1.0
                                    addedIntoDocument = true
                                }
                            }
                        }else{
                            //first time added into document
                            document_frequency[lemma] = 1.0
                            addedIntoDocument = true
                            
                        }
                        
                    }
                    
                }
            }
            
            let rssItem = RSSItem(title: currentTitle, description: newDocument, pubDate: currentPubDate, df: document_frequency)
            
            self.rssItems.append(rssItem)
            
        }
        
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        
        parserCompletionHandler?(rssItems)
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error)
    {
        print(parseError.localizedDescription)
    }
    
}
























