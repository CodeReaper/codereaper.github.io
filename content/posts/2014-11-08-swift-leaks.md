---
title: Swift leaks
date: 2014-11-08T00:00:00+02:00
draft: false
---

Apple released their new language [Swift](https://developer.apple.com/swift/) into the world earlier this year and there are a lot of people that still cannot get their arms down about it (to use [a great Danish expression](http://blogs.denmark.dk/diane/2010/12/16/great-dane-ish-expressions-part-one/)), myself included. There are a great many things to enjoy about this new language. Now Swift is at version 1.1 and by no means perfect yet.

## Declaration leak
If you were to use the seemingly handy syntax for creating a constant property on your new and fresh Swift UIViewController, you will find that your constant is leaked. The following example will leak a UITableView:

```swift
class LeakyViewController : UIViewController {
  let tableView = UITableView() // leaked

  func viewDidLoad() {
    // your normal usage of the table view
  }
}
```

How? After spending hours of quality time with Instruments I can say a few things about it. The UIViewController class is created along with the constant property, then the property is recreated leaking the first property creation.

The remedy is easy enough, but it does sadden me that we are really denied this shorthand syntax, since the alternative makes us duplicate code like with the following non-leaking example:

```swift
class WaterProofViewController : UIViewController {
  let tableView:UITableView

  override init() {
    tableView = UITableView()
    super.init(nibName: nil, bundle: nil);
  }

  required init(coder aDecoder: NSCoder) {
    tableView = UITableView()
    super.init(coder:aDecoder)
  }

  func viewDidLoad() {
    // your normal usage of the table view
  }
}
```

For now we will just have to write some extra code until this issue is fixed, so keep enjoying Swift folks.
