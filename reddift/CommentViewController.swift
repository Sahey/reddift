//
//  CommentViewController.swift
//  reddift
//
//  Created by sonson on 2015/04/17.
//  Copyright (c) 2015年 sonson. All rights reserved.
//

import UIKit

class CommentViewController: UITableViewController, UZTextViewCellDelegate {
    var session:Session? = nil
    var subreddit:Subreddit? = nil
    var link:Link? = nil
	var comments:[Comment] = []
    var paginator:Paginator? = Paginator()
    var contents:[CellContent] = []
	
	deinit{
		println("deinit")
	}
    
    func updateStrings() {
        contents.removeAll(keepCapacity:true)
        contents = comments.map { (comment:Comment) -> CellContent in
            return CellContent(string:comment.body, width:self.view.frame.size.width, hasRelies:(comment.replies != nil))
        }
    }
    
    func vote(direction:Int) {
        if let link = self.link {
            session?.setVote(direction, thing: link, completion: { (result) -> Void in
                switch result {
                case let .Error(error):
                    println(error.code)
                case let .Value(box):
                    println(box.value)
                }
            })
        }
    }
    
    func save(save:Bool) {
        if let link = self.link {
            session?.setSave(save, thing: link, category:"default", completion: { (result) -> Void in
                switch result {
                case let .Error(error):
                    println(error.code)
                case let .Value(box):
                    println(box.value)
                }
            })
        }
    }
    
    func hide(hide:Bool) {
        if let link = self.link {
            session?.setHide(hide, thing: link, completion: { (result) -> Void in
                switch result {
                case let .Error(error):
                    println(error.code)
                case let .Value(box):
                    println(box.value)
                }
            })
        }
    }
    
    func downVote(sender:AnyObject?) {
        vote(-1)
    }
    
    func upVote(sender:AnyObject?) {
        vote(1)
    }
    
    func cancelVote(sender:AnyObject?) {
        vote(0)
    }
    
    func doSave(sender:AnyObject?) {
        save(true)
    }
    
    func doUnsave(sender:AnyObject?) {
        save(false)
    }
    
    func doHide(sender:AnyObject?) {
        hide(true)
    }
    
    func doUnhide(sender:AnyObject?) {
        hide(false)
    }
    
    func updateToolbar() {
        var items:[UIBarButtonItem] = []
        let space = UIBarButtonItem(barButtonSystemItem:.FlexibleSpace, target: nil, action: nil)
        if let link = self.link {
            items.append(space)
            // voting status
            if let likes = link.likes {
                if likes {
                    items.append(UIBarButtonItem(image: UIImage(named: "thumbDown"), style:.Plain, target: self, action: "downVote:"))
                    items.append(space)
                    items.append(UIBarButtonItem(image: UIImage(named: "thumbUpFill"), style:.Plain, target: self, action: "cancelVote:"))
                }
                else {
                    items.append(UIBarButtonItem(image: UIImage(named: "thumbDownFill"), style:.Plain, target: self, action: "cancelVote:"))
                    items.append(space)
                    items.append(UIBarButtonItem(image: UIImage(named: "thumbUp"), style:.Plain, target: self, action: "upVote:"))
                }
            }
            else {
                items.append(UIBarButtonItem(image: UIImage(named: "thumbDown"), style:.Plain, target: self, action: "downVote:"))
                items.append(space)
                items.append(UIBarButtonItem(image: UIImage(named: "thumbUp"), style:.Plain, target: self, action: "upVote:"))
            }
            items.append(space)
            
            // save
            if link.saved {
                items.append(UIBarButtonItem(image: UIImage(named: "favoriteFill"), style:.Plain, target: self, action:"doUnsave:"))
            }
            else {
                items.append(UIBarButtonItem(image: UIImage(named: "favorite"), style:.Plain, target: self, action:"doSave:"))
            }
            items.append(space)
            
            // hide
            if link.hidden {
                items.append(UIBarButtonItem(image: UIImage(named: "eyeFill"), style:.Plain, target: self, action: "doUnhide:"))
            }
            else {
                items.append(UIBarButtonItem(image: UIImage(named: "eye"), style:.Plain, target: self, action: "doHide:"))
            }
            items.append(space)
            
            // comment button
            items.append(UIBarButtonItem(image: UIImage(named: "comment"), style:.Plain, target: nil, action: nil))
            items.append(space)
        }
        self.toolbarItems = items
    }
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: "UZTextViewCell", bundle: nil), forCellReuseIdentifier: "Cell")
        self.tableView.registerNib(UINib(nibName: "UZTextViewWithMoreButtonCell", bundle: nil), forCellReuseIdentifier: "MoreCell")
        
        updateToolbar()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.toolbarHidden = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let link = self.link {
            session?.getArticles(self.paginator, link:link, sort:CommentSort.New, completion: { (result) -> Void in
                switch result {
                case let .Error(error):
                    println(error.code)
                case let .Value(box):
                    if let objects = box.value as? [AnyObject] {
                        if let listing = objects[0] as? Listing {
                            if let links = listing.children as? [Link] {
                                for link:Link in links {
                                    println(link.selftext)
                                    println(link.selftext_html)
                                    println(link.permalink)
                                }
                            }
                        }
                        if let listing = objects[1] as? Listing {
                            if let comments = listing.children as? [Comment] {
                                self.comments += comments
                            }
                            self.paginator = listing.paginator()
                        }
                    }
                    self.updateStrings()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                    })
                }
            });
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indices(contents) ~= indexPath.row {
            return contents[indexPath.row].textHeight
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell! = nil
        if indices(contents) ~= indexPath.row {
            if comments[indexPath.row].replies != nil {
                cell = tableView.dequeueReusableCellWithIdentifier("MoreCell", forIndexPath: indexPath) as! UITableViewCell
            }
            else {
                cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
            }
            if let cell = cell as? UZTextViewCell {
                cell.delegate = self
                cell.textView?.attributedString = contents[indexPath.row].attributedString
                cell.content = comments[indexPath.row]
            }
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
            return cell
        }
    }
    
    func pushedMoreButton(cell:UZTextViewCell) {
        if let comment = cell.content, link = self.link {
            if let replies = comment.replies as? Listing {
                for obj in replies.children {
                    if let comment = obj as? Thing {
                        println(comment.toString())
                        println(comment)
                    }
                }
            }
//            session?.getMoreChildren(comment.name, link_id: link.name, children:, sort: <#CommentSort#>, completion: <#(Result<JSON>) -> Void##(Result<JSON>) -> Void#>), link_id: <#String#>, children: <#[String]#>, sort: <#CommentSort#>, completion: <#(Result<JSON>) -> Void##(Result<JSON>) -> Void#>
        }
    }
}
