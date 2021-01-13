#
# compute md5 checksums for files
#
%.md5::%
	md5sum $< > $@

FILES := $(wildcard *.txt *.pdf *.md *.csv fast?_????/*.fast?)
MD5S  := $(addsuffix .md5,$(FILES))

md5sum: $(MD5S)
	cat $< > $@

