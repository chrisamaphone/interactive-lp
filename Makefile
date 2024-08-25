.PHONY: ceptre syn

ceptre:
	mlton -output ceptre src/sources.mlb


syn: src/ceptre.cmlex.sml src/ceptre.cmyacc.sml

%.cmlex.sml : %.cmlex
	cmlex $< -o $@

%.cmyacc.sml : %.cmyacc
	cmyacc $< -o $@


