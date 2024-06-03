require 'rdf'
require 'rdf/turtle'
require 'json/ld'

PREFIXES = {
  dcterms: 'http://purl.org/dc/terms/',
  foaf:    'http://xmlns.com/foaf/0.1/',
  know:    'https://know.dev/',
  owl:     'http://www.w3.org/2002/07/owl#',
  rdf:     'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
  rdfs:    'http://www.w3.org/2000/01/rdf-schema#',
  schema:  'https://schema.org/',
  xsd:     'http://www.w3.org/2001/XMLSchema#',
}

task default: %w(know.jsonld)

file 'know.jsonld' => %w(src/know.ttl) do |t|
  File.open(t.name, 'w') do |output|
    JSON::LD::Writer.new(output, prefixes: PREFIXES) do |writer|
      RDF::Reader.open(t.prerequisites.first) do |reader|
        reader.each { |stmt| writer << stmt }
      end
    end
    output.flush
    output.puts
  end
end

task check: %w(src/know.ttl) do |t|
  count = 0
  RDF::Reader.open(t.prerequisites.first) do |reader|
    reader.each { |stmt| count += 1 }
  end
  puts count
end

task classes: %w(src/know.ttl) do |t|
  graph = RDF::Graph.load(t.prerequisites.first)
  query = RDF::Query.new({ klass: { RDF.type => RDF::OWL.Class } }, **{})
  query.execute(graph).map { |solution| solution.klass.path[1..] }.sort.each do |klass|
    puts klass
  end
end

task properties: %w(src/know.ttl) do |t|
  graph = RDF::Graph.load(t.prerequisites.first)
  query = RDF::Query.new({ property: { RDF.type => RDF::OWL.ObjectProperty } }, **{})
  query.execute(graph).map { |solution| solution.property.path[1..] }.sort.each do |property|
    puts property
  end
end
