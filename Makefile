FILES=src/01-title.md src/02-acknowledgements.md src/03-publisher.md src/04-trademarks.md src/05-intro.md src/chapter-01.md src/chapter-02.md src/chapter-03.md src/chapter-04.md src/chapter-05.md src/chapter-06.md src/chapter-07.md src/chapter-08.md src/chapter-09.md src/chapter-10.md src/chapter-11.md src/chapter-12.md src/chapter-13.md src/chapter-14.md src/chapter-15.md src/chapter-16.md src/06-listing-index.md src/07-appendix-a.md src/07-appendix-b.md src/08-index.md src/about-this-version.md

.PHONY: html epub

all: html epub mobi

html:
	rm -rf out/html && mkdir -p out/html
	cp -r images html/book.css out/html/
	pandoc -S --to html5 -o out/html/zen-of-asm.html --section-divs --toc --standalone --template=html/template.html $(FILES)

epub:
	mkdir -p out
	rm -f out/zen-of-asm.epub
	pandoc -S --to epub3 -o out/zen-of-asm.epub --epub-cover-image images/cover.png --toc --epub-chapter-level=2 --data-dir=epub --template=epub/template.html $(FILES)

mobi:
	rm -f out/zen-of-asm.mobi
	kindlegen out/zen-of-asm.epub -c2
