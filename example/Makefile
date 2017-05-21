PROFDUMP	:= ../profdump
DUB	:= dub
SAMPLEDIR	:= sample/
SOURCES	:= profdump.log simple.log
PLAIN	:= $(addprefix $(SAMPLEDIR), $(SOURCES:.log=.txt))
JSON	:= $(addprefix $(SAMPLEDIR), $(SOURCES:.log=.json))
DOT	:= $(addprefix $(SAMPLEDIR), $(SOURCES:.log=.dot))
SVG	:= $(addprefix $(SAMPLEDIR), $(SOURCES:.log=.svg))
PNG	:= $(addprefix $(SAMPLEDIR), $(SOURCES:.log=.png))


.PHONY: dot svg png plain json

all: $(PROFDUMP) plain json dot png svg

plain: $(SAMPLEDIR) $(PLAIN)
$(SAMPLEDIR)%.txt	: %.log $(SAMPLEDIR) $(PROFDUMP)
	@echo Converting $< to $@
	@$(PROFDUMP) -fp $< $@

json: $(SAMPLEDIR) $(JSON)
$(SAMPLEDIR)%.json	: %.log $(SAMPLEDIR) $(PROFDUMP)
	@echo Converting $< to $@
	@$(PROFDUMP) -fj --pretty $< $@

dot: $(SAMPLEDIR) $(DOT)
$(SAMPLEDIR)%.dot	: %.log $(SAMPLEDIR) $(PROFDUMP)
	@echo Converting $< to $@
	@$(PROFDUMP) -fd $< $@

svg: $(SAMPLEDIR) $(SVG)
$(SAMPLEDIR)%.svg	: $(SAMPLEDIR)%.dot
	@echo Converting $< to $@
	@dot -Tsvg $< -o$@

png: $(SAMPLEDIR) $(PNG)
$(SAMPLEDIR)%.png	: $(SAMPLEDIR)%.dot
	@echo Converting $< to $@
	@dot -Tpng $< -o$@


$(SAMPLEDIR)	:
	@mkdir $(SAMPLEDIR)

$(PROFDUMP)	:
	@cd ../ && $(DUB) build

clean :
	@rm -rf $(SAMPLEDIR)
