require 'json'
require 'rdf'
require 'rdf/turtle'

include RDF

KNOW = RDF::Vocabulary.new('https://know.dev/')

PREFIXES = {
  dcterms: 'http://purl.org/dc/terms/',
  foaf:    'http://xmlns.com/foaf/0.1/',
  know:    KNOW.to_s,
  owl:     'http://www.w3.org/2002/07/owl#',
  rdf:     'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
  rdfs:    'http://www.w3.org/2000/01/rdf-schema#',
  schema:  'https://schema.org/',
  xsd:     'http://www.w3.org/2001/XMLSchema#',
}

task default: %w(know.jsonld)

desc "Generate export in JSON-LD format"
file 'know.jsonld' => %w(src/know.ttl) do |t|
  require 'json/ld'
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

desc "Generate export in RDF/JSON format"
file 'know.rj' => %w(src/know.ttl) do |t|
  require 'rdf/json'
  File.open(t.name, 'w') do |output|
    json = RDF::JSON::Writer.buffer(prefixes: PREFIXES) do |writer|
      RDF::Reader.open(t.prerequisites.first) do |reader|
        reader.each { |stmt| writer << stmt }
      end
    end
    output.puts JSON.pretty_generate(JSON.parse(json))
  end
end

desc "Generate export in JSON Schema format"
file 'know.schema.json' => %w(src/know.ttl) do |t|
  ontology = RDF::Graph.load(t.prerequisites.first)
  File.open(t.name, 'w') do |output|
    schema = {
      '$id': 'https://know.dev/know.schema.json',
      '$schema': 'https://json-schema.org/draft/2020-12/schema',
      '$comment': "The Know Ontology for JSON Schema",
      '$defs': {},
    }

    query = RDF::Query.new({ klass: { RDF.type => RDF::OWL.Class } })
    query.execute(ontology).each do |solution|
      klass_name = solution.klass.path[1..]
      klass_label = ontology.query([solution.klass, RDFS.label]).objects.find { |o| o.language == :en }

      properties = RDF::Query.new({
        property: {
          RDF.type => RDF::OWL.FunctionalProperty,
          RDFS.domain => solution.klass,
        },
      }).execute(ontology)

      properties = properties.map do |solution|
        property_name = solution.property.path[1..]
        property_label = ontology.query([solution.property, RDFS.label]).objects.find { |o| o.language == :en }
        property_ranges = ontology.query([solution.property, RDFS.range]).objects
        next if property_ranges.empty?
        property_types = property_ranges.map do |property_range|
          case property_range
            when XSD.anyURI then [:string, :iri]
            when XSD.dateTime then [:string, :'date-time']
            when XSD.nonNegativeInteger then [:number, nil]
            when XSD.string then [:string, nil]
            else [{ '$ref': "#/$defs#{property_range.path}" }, nil]
          end
        end
        property_types.compact!
        property = {
          name: property_name,
          title: property_label,
          type: property_types.size == 1 ? property_types.first[0] : property_types.map(&:first),
          format: property_types.size == 1 ? property_types.first[1] : nil,
          minimum: property_ranges.include?(XSD.nonNegativeInteger) ? 0 : nil,
        }.compact
      end
      properties.compact!

      schema[:'$defs'][klass_name] = {
        '$anchor': klass_name,
        title: klass_label,
        type: :object,
        #required: [],
        properties: properties,
      }
    end

    output.puts JSON.pretty_generate(schema)
  end
end

desc "Generate export in TriX format"
file 'know.trix' => %w(src/know.ttl) do |t|
  require 'rdf/trix'
  File.open(t.name, 'w') do |output|
    RDF::TriX::Writer.new(output, library: :rexml, prefixes: PREFIXES) do |writer|
      RDF::Reader.open(t.prerequisites.first) do |reader|
        reader.each { |stmt| writer << stmt }
      end
    end
  end
end

#desc "Generate export in Avro format"
file 'know.avdl' => %w(src/know.ttl) do |t|
  # TODO: https://avro.apache.org/docs/1.11.1/idl-language/
end

#desc "Generate export in CDDL format"
file 'know.cddl' => %w(src/know.ttl) do |t|
  # TODO: https://datatracker.ietf.org/doc/html/rfc8610
end

#desc "Generate export in Amazon Ion format"
file 'know.ion' => %w(src/know.ttl) do |t|
  # TODO: https://en.wikipedia.org/wiki/Ion_(serialization_format)
end

#desc "Generate export in Protocol Buffers (Protobuf) format"
file 'know.proto' => %w(src/know.ttl) do |t|
  # TODO: https://en.wikipedia.org/wiki/Protocol_Buffers
end

#desc "Generate export in RELAX NG (RNG) format"
file 'know.rnc' => %w(src/know.ttl) do |t|
  # TODO: https://en.wikipedia.org/wiki/RELAX_NG
end

#desc "Generate export in XML Schema (XSD) format"
file 'know.xsd' => %w(src/know.ttl) do |t|
  # TODO: https://en.wikipedia.org/wiki/XML_Schema_(W3C)
end

#desc "Generate export in GraphQL SDL format"
file 'know.graphqls' => %w(src/know.ttl) do |t|
  # TODO: https://en.wikipedia.org/wiki/GraphQL https://graphql.org/learn/schema/
end

desc "Check for syntax errors"
task check: %w(src/know.ttl) do |t|
  count = 0
  RDF::Reader.open(t.prerequisites.first) do |reader|
    reader.each { |stmt| count += 1 }
  end
  puts count
end

desc "List ontology classes"
task classes: %w(src/know.ttl) do |t|
  ontology = RDF::Graph.load(t.prerequisites.first)
  query = RDF::Query.new({ klass: { RDF.type => RDF::OWL.Class } })
  query.execute(ontology).map { |solution| solution.klass.path[1..] }.sort.each do |klass|
    puts klass
  end
end

desc "List ontology properties"
task properties: %w(src/know.ttl) do |t|
  ontology = RDF::Graph.load(t.prerequisites.first)
  query = RDF::Query.new({ property: { RDF.type => RDF::OWL.ObjectProperty } })
  query.execute(ontology).map { |solution| solution.property.path[1..] }.sort.each do |property|
    puts property
  end
end
