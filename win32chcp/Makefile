rest_files = $(wildcard *.rst)

all : html


html_files=$(rest_files:.rst=.html)

html : $(html_files)

$(html_files): %.html: %.rst Makefile
	rst2html.py $< $@
