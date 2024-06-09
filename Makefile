BUNDLE = bundle
RAPPER = rapper

all: know.jsonld know.nq know.nt know.rdf know.rj know.schema.json know.trig know.trix know.ttl

know.dot: src/know.ttl
	$(RAPPER) -i turtle -o dot $< > $@

know.jsonld: src/know.ttl
	$(BUNDLE) exec rake -B $@

know.nq: src/know.ttl
	$(RAPPER) -i turtle -o nquads $< | sort > $@

know.nt: src/know.ttl
	$(RAPPER) -i turtle -o ntriples $< | sort > $@

know.rdf: src/know.ttl
	$(RAPPER) -i turtle -o rdfxml-abbrev $< > $@

know.rj: src/know.ttl
	$(BUNDLE) exec rake -B $@

know.schema.json: src/know.ttl
	$(BUNDLE) exec rake -B $@

know.trig: know.ttl
	ln -f $< $@

know.trix: src/know.ttl
	$(BUNDLE) exec rake -B $@

know.ttl: src/know.ttl
	$(RAPPER) -i turtle -o turtle $< > $@

check: src/know.ttl
	$(RAPPER) -i turtle -c $<
	$(BUNDLE) install && $(BUNDLE) exec rake -B check

clean:
	@rm -f *~ know.*

.PHONY: all check clean
