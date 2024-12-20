ODIN = odin

OUTDIR = bin

dirs: 
	mkdir -p ./$(OUTDIR)

build: dirs
	odin build . -out:$(OUTDIR)/breakout

run: dirs
	odin run . -out:$(OUTDIR)/breakout
