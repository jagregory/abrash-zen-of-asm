.POSIX:
.PHONY: html epub mobi clean

FILES=$(wildcard src/*.md)
NAME=zen-of-asm

all: html epub mobi

html: out/html/zen-of-asm.html
epub: out/zen-of-asm.epub
mobi: out/zen-of-asm.mobi

out/html/$(NAME).html: $(FILES) out html/book.css html/template.html
	mkdir -p out/html
	cp -r images html/book.css out/html/
	pandoc -f markdown+smart --to html5 -o $@ \
		--section-divs --toc --toc-depth=2 --standalone \
		--template=html/template.html --ascii $(FILES)

out/$(NAME).epub: $(FILES) out
	pandoc -f markdown+smart --to epub3 -o $@ \
		--epub-cover-image images/cover.png --toc --toc-depth=2 \
		--epub-chapter-level=2 --data-dir=epub \
		--template=epub/template.html $(FILES)

out/$(NAME).mobi: $(FILES) epub
	kindlegen out/zen-of-asm.epub -c2

out:
	mkdir out

clean:
	rm -rf out/
