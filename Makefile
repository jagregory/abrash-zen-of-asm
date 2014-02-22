FILES=src/01-title.md src/02-acknowledgements.md src/03-publisher.md src/04-source.md src/05-trademarks.md src/06-intro.md src/07-contents.md src/chapter-01.md src/chapter-02.md src/chapter-03.md src/chapter-04.md src/chapter-05.md src/chapter-06.md src/chapter-07.md src/chapter-08.md src/chapter-09.md src/chapter-10.md src/chapter-11.md src/chapter-12.md src/chapter-13.md src/chapter-14.md src/chapter-15.md src/chapter-16.md src/08-listing-index.md src/09-appendix-a.md src/09-appendix-b.md src/10-index.md

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
