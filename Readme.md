### What's all this, then? ###

This is an example project demonstrating an `NSTextView` subclass which does programmatic modification
of if its contents based on user actions.  This would be useful, for example, in a programmer's
text editor, whereby it could automatically insert close braces when one types an open brace, or
automatically indent when one presses return.


### Why? ###

Because I needed this functionality for a project I'm writing. I faced several challenges:

1. I had been calling `insertText:` to perform programmatic changes, and although this appeared to
   work, I was troubled by some verbiage in `NSTextView`'s documentation for `insertText:`
   > This method is the entry point for inserting text typed by the user and is generally 
   > not suitable for other purposes. Programmatic modification of the text is best done 
   > by operating on the text storage directly.
   
   Problem with that is, modifying text by directly manipulating the text storage completely 
   bypasses Undo. I think the proper answer is to do you own undo handling in your text
   storage, but I did not want to do this.

   I posted [this question](http://stackoverflow.com/questions/14722223/is-nstextviews-inserttext-really-not-suitable-for-programmatic-modification) to stackoverflow, without much in the way of an answer.

2. I had issues getting Undo to work correctly, and I was apparently not alone, as witnessed
   by [this question](http://stackoverflow.com/questions/5585944/cocoa-looking-for-a-general-strategy-for-programmatic-manipulation-of-nstextvie) on stackoverflow.
   

So the point of this is to demonstrate an `NSTextView` subclass which does programmatic modification
of its contents using `insertText:` and without screwing up Undo.


### How's it work? ###

`ZPTextView` is an `NSTextView` subclass. It overrides `insertText:`, and does it's modification of
its contents there. Additionally, it does its own undo grouping in `insertText:`, basicallly by
creating an undo group for each `insertText:` call. Additionally, it overrides
`replaceCharactersInRange:` to also call `shouldChangeTextInRange:`, also to keep undo working 
properly.

Note that this is code in progress. It's basically a cut-down version of code I'm using in a project
I'm working on, and I've not actually shipped it (yet). So far, however, it appears to work well.


### Who's responsible for this? ###

I'm Zacharias Pasternack, lead developer for [Fat Apps, LLC](http://www.fat-apps.com). You can check 
out [my blog](http://zpasternack.org), or follow me on [Twitter](https://twitter.com/zpasternack)
or [App.net](https://alpha.app.net/zpasternack).


### Can I use this code? ###

You bet. Do whatever you want with it. If you find issues, please let me know. If you make it
better, please let me know.

### License ###

The code is available under a Modified BSD License. See the LICENSE file for more info.
