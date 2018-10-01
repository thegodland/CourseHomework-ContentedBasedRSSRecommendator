//
//  UrlViewController.swift
//  DeveloperNews
//
//  Created by Xiang Liu on 9/29/18.
//

import UIKit
import SVProgressHUD

class UrlViewController: UIViewController {
    
    @IBOutlet weak var secondTextfield: UITextField!
    @IBOutlet weak var firstUrlTextfield: UITextField!
    
    
    var term_idf_array : [String:Double] = [:]
    var number_of_term : Int = 0
    var term_tf_idf_userprofile : [String:Double] = [:]
    var term_idf_secondArray : [String:Double] = [:]
    var number_of_term_second : Int = 0
    var rankedItems : [RankedItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        firstUrlTextfield.text = "http://halley.exp.sis.pitt.edu/comet/utils/_rss.jsp?v=bookmark&user_id=3600"
        secondTextfield.text = "http://halley.exp.sis.pitt.edu/comet/utils/_rss.jsp"
        
        // Do any additional setup after loading the view.
    }
    
    func calculateCosine(userprofile:[String:Double], incomingDoc:[String:Double]) -> Double{
        var q : Double = 0.0
        var d : Double = 0.0
        var qd : Double = 0.0
        var absQ : Double = 0.0
        var absD : Double = 0.0
        
//        for key in Set(userprofile.keys).intersection(Set(incomingDoc.keys)){
//
        for key in incomingDoc.keys{
            if let userValue = userprofile[key]{
                q = q + pow(userValue,2)
                
                if let docValue = incomingDoc[key]{
                    d += pow(docValue,2)
                    qd += userValue * docValue
                }
            }
        }
        absD = pow(d, 0.5)
        absQ = pow(q, 0.5)
        
        let cosine = qd / ( absD * absQ )
        
        
        return cosine
        
    }
    
    private func fetchData(url:String, secondUrl:String, completion: @escaping (_ success: Bool) -> Void)
    {
        //fetch the first url data and build up data profile.
        let feedParser = FeedParser()
        feedParser.parseFeed(url: url) { (rssItems) in
            
            
            
            // get number of documents
            let numberOfDocument = Double(rssItems.count)
            // will only use the df data stored at last document for document frequency
            
            var lastDocument = rssItems[rssItems.count-1].df
            
            for term in Array(lastDocument.keys){
                if let termDf = lastDocument[term]{
                    let idf = log(Double(numberOfDocument / termDf))
                    self.term_idf_array[term] = idf
                }
            }
            
            self.number_of_term = lastDocument.count
            
            if self.term_idf_array.count == lastDocument.count{
                // idf was caculated so we can * term frequency
                for item in rssItems{
                    //                    print(item.df.count)
                    //get the number of terms in each documents
                    let numOfTermsInEachDoc = Double(item.description.count)
                    
                    for term in Array(item.description.keys){
                        if let tf = item.description[term]{
                            if let idf = self.term_idf_array[term]{
                                if Array(self.term_tf_idf_userprofile.keys) .contains(term){
                                    if let previousValue = self.term_tf_idf_userprofile[term]{
                                        self.term_tf_idf_userprofile[term] = previousValue + (1+log(Double(tf) / numOfTermsInEachDoc)) * idf
                                    }
                                    
                                }else{
                                    self.term_tf_idf_userprofile[term] = (1+log(Double(tf) / numOfTermsInEachDoc)) * idf
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                }
                
            }
            
        }
        
        
        //fetch second url's data and build up data model
        if self.term_tf_idf_userprofile.count == self.number_of_term{
            
            let secondFeedsParser = FeedParser()
            secondFeedsParser.parseFeed(url: secondUrl) { (secondRssItems) in
                
                // get number of documents
                let numberOfDocument = secondRssItems.count
                
                // will only use the df data stored at last document for document frequency
                var lastDocument = secondRssItems[secondRssItems.count-1].df
                for term in Array(lastDocument.keys){
                    if let termDf = lastDocument[term]{
                        let idf = log(Double(Double(numberOfDocument) / termDf))
                        self.term_idf_secondArray[term] = idf
                    }
                }
                self.number_of_term_second = lastDocument.count
                if self.term_idf_secondArray.count == lastDocument.count{
                    // idf was caculated so we can * term frequency
                    for item in secondRssItems{
                        let numOfTermsInEachDoc = Double(item.description.count)
                        var oneIncomingDoc : [String:Double] = [:]
                        for term in Array(item.description.keys){
                            if Array(self.term_tf_idf_userprofile.keys).contains(term){
                                //only include term inside user profile
                                if let tf = item.description[term]{
                                    if let idf = self.term_idf_secondArray[term]{
                                        oneIncomingDoc[term] = (1+log(Double(tf) / numOfTermsInEachDoc)) * idf
                                    }
                                }
                                
                            }
                            
                        }
                        let rankedItem = RankedItem(title:item.title, score:oneIncomingDoc, pubDate:item.pubDate, similarity:0)
                        self.rankedItems.append(rankedItem)
                        
                    }
                    //                    print(self.term_tf_idf_incoming)
                    //                    print(self.term_tf_idf_incoming.count)
                }
                
                //compute the similarity of each document vector with userprofile.
                completion(true)
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoTableView"{
            let destinationVC = segue.destination as! NewsTableViewController
            //pass the ranked list with title and cosine score
            
            destinationVC.passedRankedItems = rankedItems
            
        }
        
    }
    
    @IBAction func clickBtnTapped(_ sender: UIButton) {
        
        SVProgressHUD.show()
        
        if let firstUrl = firstUrlTextfield.text{
            if let secondUrl = secondTextfield.text{
                
                fetchData(url: firstUrl, secondUrl: secondUrl){ (success) in
                    if success {
                        // do second task if success
                        //calculate the cosine
                        
                        for (index,doc) in self.rankedItems.enumerated(){
                            
                            self.rankedItems[index].similarity = self.calculateCosine(userprofile: self.term_tf_idf_userprofile, incomingDoc: doc.score)
                            
                        }
                        
                        DispatchQueue.main.async {
                            
                            SVProgressHUD.dismiss()
                            
                            self.performSegue(withIdentifier: "gotoTableView", sender: self)
                            
                        }
                        
                    }
                }
                
            }
        }
    }
}
