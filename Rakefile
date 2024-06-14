require 'active_support'
require 'json'
require 'rdf'
require 'rdf/turtle'

include ActiveSupport::Inflector
include RDF

LANG = :en

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
  $ontology = RDF::Graph.load(t.prerequisites.first)

  def js_type(property_type)
    case property_type
      when Array then property_type.map { |t| js_type(t) }
      when XSD.anyURI then { type: :string, format: :iri }
      when XSD.dateTime then { type: :string, format: :'date-time' }
      when XSD.language then { type: :string }
      when XSD.nonNegativeInteger then { type: :number, minimum: 0 }
      when XSD.string then { type: :string }
      else { '$ref': "#/$defs#{property_type.path}" }
    end
  end

  File.open(t.name, 'w') do |output|
    schema = {
      '$id': 'https://know.dev/know.schema.json',
      '$schema': 'https://json-schema.org/draft/2020-12/schema',
      '$comment': "The Know Ontology for JSON Schema",
      '$defs': {},
    }

    ontology_classes.each do |klass_name, parent_name|
      klass = KNOW.send(klass_name)
      klass_label = $ontology.query([klass, RDFS.label]).objects.find { |o| o.language == LANG }.to_s
      klass_props = ontology_relations(klass_name).merge(ontology_properties(klass_name))

      schema[:'$defs'][klass_name] = {
        '$anchor': klass_name,
        title: klass_label,
        type: :object,
        allOf: klass_name == :Thing ? [] : [{ '$ref': "#/$defs/#{parent_name}" }],
        properties: klass_props.keys.sort.inject({}) do |properties, property_name|
          property = KNOW.send(property_name)
          property_label = $ontology.query([property, RDFS.label]).objects.find { |o| o.language == LANG }.to_s
          property_ranges = $ontology.query([property, RDFS.range]).objects
          property_range = property_ranges.first || XSD.string

          properties[property_name] = {
            name: property_name,
            title: property_label,
          }.merge(js_type(property_range)).compact

          instance_count = klass_props[property_name]
          if instance_count.end.nil? then
            property_name = pluralize(property_name)
            properties[property_name] = {
              name: property_name,
              title: pluralize(property_label),
              type: :array,
              items: js_type(property_range),
            }.compact
          end

          properties
        end
      }
      schema[:'$defs'][klass_name].delete(:allOf) if schema[:'$defs'][klass_name][:allOf].empty?
    end

    output.puts JSON.pretty_generate(schema)
  end
end

desc "Generate export in TriX format"
file 'know.trix' => %w(src/know.ttl) do |t|
  require 'nokogiri'
  require 'rdf/trix'
  File.open(t.name, 'w') do |output|
    RDF::TriX::Writer.new(output, library: :nokogiri, prefixes: PREFIXES) do |writer|
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

# See: https://en.wikipedia.org/wiki/XML_Schema_(W3C)
desc "Generate export in XML Schema (XSD) format"
file 'know.xsd' => %w(src/know.ttl) do |t|
  require 'nokogiri'

  $ontology = RDF::Graph.load(t.prerequisites.first)

  def make_properties(xml, klass)
    properties = RDF::Query.new({
      property: {
        RDFS.domain => klass,
        RDF.type => OWL.ObjectProperty,
      },
    }).execute($ontology)

    return if properties.empty?

    xml[:xs].choice(minOccurs: 0, maxOccurs: :unbounded) do
      properties = properties.each.with_index do |solution, property_index|
        property_ranges = $ontology.query([solution.property, RDFS.range]).objects
        next if property_ranges.empty?

        property_name = solution.property.path[1..]
        property_label = $ontology.query([solution.property, RDFS.label]).objects.find { |o| o.language == LANG }.to_s
        property_type = property_ranges.first.qname(prefixes: PREFIXES).last
        property_functional = !$ontology.query([solution.property, RDF.type, OWL.FunctionalProperty]).nil?
        property_occurs = property_functional ? 1 : :unbounded

        xml[:xs].element(name: property_name, type: property_type, minOccurs: 0, maxOccurs: property_occurs)
      end
    end
  end

  xml_builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
    xml[:xs].schema('xmlns' => KNOW.to_s,
                    'xmlns:xs' => 'http://www.w3.org/2001/XMLSchema',
                    'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                    'xsi:schemaLocation' => 'http://www.w3.org/2001/XMLSchema http://www.w3.org/2001/XMLSchema.xsd',
                    targetNamespace: KNOW.to_s,
                    elementFormDefault: 'qualified') do

      klasses = ontology_classes()

      klasses.each do |klass_name, _|
        singular = dasherize(underscore(klass_name))
        plural = pluralize(singular)

        xml[:xs].element(name: singular, type: klass_name)
        xml[:xs].element(name: plural) do
          xml[:xs].complexType do
            xml[:xs].sequence do
              xml[:xs].element(ref: singular)
            end
          end
        end
      end

      klasses.each do |klass_name, parent_name|
        klass = KNOW.send(klass_name)
        klass_label = $ontology.query([klass, RDFS.label]).objects.find { |o| o.language == LANG }.to_s

        xml[:xs].complexType(name: klass_name) do
          if klass_name == 'Thing'
            make_properties(xml, klass)
          else
            xml[:xs].complexContent do
              xml[:xs].extension(base: parent_name) do
                make_properties(xml, klass)
              end
            end
          end
        end
      end
    end
  end

  File.open(t.name, 'w') do |output|
    output.puts xml_builder.to_xml
  end
end

#desc "Generate export in GraphQL SDL format"
file 'know.graphqls' => %w(src/know.ttl) do |t|
  # TODO: https://en.wikipedia.org/wiki/GraphQL https://graphql.org/learn/schema/
end

desc "Check for syntax errors"
task check: %w(src/know.ttl) do |t|
  require 'active_support'
  require 'json/ld'
  require 'nokogiri'
  require 'rdf/json'
  require 'rdf/trix'
  puts RDF::Reader.open(t.prerequisites.first).count
end

desc "List ontology classes"
task classes: %w(src/know.ttl) do |t|
  $ontology = RDF::Graph.load(t.prerequisites.first)
  ontology_classes.keys.sort.each do |klass|
    if ENV['JSON']
      puts "\"#{klass}\","
    else
      puts klass
    end
  end
end

desc "List ontology properties"
task properties: %w(src/know.ttl) do |t|
  $ontology = RDF::Graph.load(t.prerequisites.first)
  ontology_relations.merge(ontology_properties).keys.sort.each do |property|
    if ENV['JSON']
      puts "\"#{property}\","
    else
      puts property
    end
  end
end

task :website => %w(src/know.ttl) do |t|
  $ontology = RDF::Graph.load(t.prerequisites.first)

  ontology_classes.each do |klass, parent|
    sh "touch ../know-website/doc/#{klass}.md" || abort
  end

  ontology_relations.each do |property, _|
    sh "touch ../know-website/doc/#{property}.md" || abort
  end

  ontology_properties.each do |property, _|
    sh "touch ../know-website/doc/#{property}.md" || abort
    File.open("../know-website/doc/#{property}.md", 'w') do |out|
      out.puts <<~EOF
        # #{property}

        :::note
        https://know.dev/#{property}
        (`know:#{property}`)
        :::
      EOF
    end
  end
end

def ontology_classes
  result = {}
  query = RDF::Query.new({ klass: { RDF.type => OWL.Class, RDFS.subClassOf => :parent } })
  query.execute($ontology).each do |solution|
    klass_name = solution.klass.qname(prefixes: PREFIXES).last
    parent_name = solution.parent.qname(prefixes: PREFIXES).last
    result[klass_name] = parent_name
  end
  result
end

def ontology_relations(klass_name = nil)
  result = {}
  filter = klass_name ? { RDFS.domain => KNOW.send(klass_name) } : {}
  query = RDF::Query.new({ property: { RDF.type => OWL.ObjectProperty }.merge(filter) })
  query.execute($ontology).each do |solution|
    property = solution.property
    property_name = property.qname(prefixes: PREFIXES).last
    property_functional = !$ontology.query([property, RDF.type, OWL.FunctionalProperty]).nil?
    result[property_name] = (0..(property_functional ? 1 : nil))
  end
  result
end

def ontology_properties(klass_name = nil)
  result = {}
  filter = klass_name ? { RDFS.domain => KNOW.send(klass_name) } : {}
  query = RDF::Query.new({ property: { RDF.type => OWL.DatatypeProperty }.merge(filter) })
  query.execute($ontology).each do |solution|
    property = solution.property
    property_name = property.qname(prefixes: PREFIXES).last
    property_functional = !$ontology.query([property, RDF.type, OWL.FunctionalProperty]).nil?
    result[property_name] = (0..(property_functional ? 1 : nil))
  end
  result
end
