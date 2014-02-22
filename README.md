# Zen of Assembly Language: Volume I, Knowledge

This is the source for an ebook version of Michael Abrash's Zen of Assembly Language: Volume I, Knowledge, originally published in 1990 and.

Reproduced with blessing of Michael Abrash, converted and maintained by [James Gregory](mailto:james@jagregory.com). Original conversion produced by Ron Welch.

The [Github releases list](https://github.com/jagregory/abrash-zen-of-asm/releases) has an Epub and Mobi version available for download, and you can find a mirror of the HTML version at [www.jagregory.com/abrash-zen-of-asm](http://www.jagregory.com/abrash-zen-of-asm/).

## How does this differ from the previously released versions?

The book is now out of print, and hard to come by. The original publisher was bought out, and the particular line that this book belonged to was cancelled.

A version of this book was included on the CD of the [Graphics Programming Black Book](http://www.jagregory.com/abrash-black-book/), and that was converted by Ron Welch to a PDF.

This version has been thoroughly cleaned of artifacts and condensed into something which can easily be converted into an ebook-friendly format. You can read this version online at Github, or download any of the Epub or Mobi releases. You can clone the repository and generate your own version with [pandoc](http://johnmacfarlane.net/pandoc/) if necessary.

## Contributing

Changes are welcome, especially conversion-related ones. If you spot any problems while reading, please [submit an issue](https://github.com/jagregory/abrash-zen-of-asm/issues) and I'll correct it. Pull Requests are always welcome.

Some larger changes could be made to improve the content. I'd love to see some of the images converted to a vector representation so we can provide higher-resolution versions.  Formulas and equations could be typeset with [MathJax](http://www.mathjax.org/).

## Generating your own ebook

You need to have the following software installed and on your `PATH` before you begin:

  * [pandoc](http://johnmacfarlane.net/pandoc/) for Markdown to HTML and Epub conversion.
  * [kindlegen](http://www.amazon.com/gp/feature.html?docId=1000765211) for Epub to Mobi conversion.

To generate an e-reader friendly version of the book, you can use `make` with one of the following options:

  * `html` - build a HTML5 single-page version of the book
  * `epub` - build an Epub3 ebook
  * `mobi` - build a Kindle-friendly Mobi
  * `all`  - do all of the above

Once complete, there'll be an `out` directory with a `black-book.epub`, a `black-book.mobi` and a `html` directory with a `black-book.html` file.

> Note: Generating a mobi requires an epub to already exist. Also, mobi generation can be *slow* because of compression. If you want a quick mobi conversion you can just run `kindlegen out/black-book.epub`.
