#
# compute md5 checksums for files, and merge them
#
# 20230625 curtish; add pod5 support
# 
# check sum an individual file
%.md5::%
	md5sum $< > $@

# list all the files of interest
FILES := $(wildcard *.txt *.pdf *.md *.csv fast5/*.fast5 fast?_????/*.fast? fast?_????/*.fast?.gz pod5/*.pod5)
# add .md5 to each 
MD5S  := $(addsuffix .md5,$(FILES))

#
# roll up md5 for each file into a master file
#
md5sum: $(MD5S)
	cat $^ > $@

#
# debugging target
#
test: 
	@echo FILES $(FILES)
	@echo MD5S $(MD5S)


