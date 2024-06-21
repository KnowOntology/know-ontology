require 'active_support'
require 'json'
require 'know/ontology'
require 'rdf'
require 'rdf/turtle'

include ActiveSupport::Inflector
include RDF

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular 'cafe', 'cafes'
end

LANG = :en

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
  ontology = Know::Ontology.load(t.prerequisites.first)

  def js_type(property_type)
    case property_type
      when ::Array then property_type.map { |t| js_type(t) }
      when ::Know::Ontology::Concept then { '$ref': "#/$defs/#{property_type.name}" }
      when ::XSD.anyURI then { type: :string, format: :iri }
      when ::XSD.dateTime then { type: :string, format: :'date-time' }
      when ::XSD.language then { type: :string }
      when ::XSD.nonNegativeInteger then { type: :number, minimum: 0 }
      when ::XSD.string then { type: :string }
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

    ontology.classes.each do |klass|
      schema[:'$defs'][klass.name] = {
        '$anchor': klass.name,
        title: klass.label,
        type: :object,
        allOf: klass.top? ? [] : [{ '$ref': "#/$defs/#{klass.superclass.name}" }],
        properties: klass.properties.inject({}) do |properties, property|
          properties[property.name] = {
            name: property.name,
            title: property.label,
          }.merge(js_type(property.range || XSD.string)).compact

          unless property.functional?
            property_name = pluralize(property.name)
            properties[property_name] = {
              name: property_name,
              title: pluralize(property.label),
              type: :array,
              items: js_type(property.range || XSD.string),
            }.compact
          end

          properties
        end
      }
      schema[:'$defs'][klass.name].delete(:allOf) if schema[:'$defs'][klass.name][:allOf].empty?
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

  ontology = Know::Ontology.load(t.prerequisites.first)

  def xsd_type(property_type)
    return 'xs:anySimpleType' if property_type.nil?
    case property_type
      when ::Array then property_type.map { |t| xsd_type(t) }
      when ::Know::Ontology::Concept then property_type.name
      else
        curie = property_type.qname(prefixes: PREFIXES)
        case curie.first
          when :know then curie.last
          when :xsd then "xs:#{curie.last}"
          else raise "unknown property type: #{property_type.inspect}"
        end
    end
  end

  def emit_properties(xml, klass)
    return if klass.properties.empty?
    xml[:xs].choice(minOccurs: 0, maxOccurs: :unbounded) do
      klass.properties.each do |property|
        property_type = xsd_type(property.range)
        property_occurs = property.cardinality.end || :unbounded
        xml[:xs].element(name: property.name, type: property_type, minOccurs: 0, maxOccurs: property_occurs)
      end
    end
  end

  xml_builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
    xml[:xs].schema(xmlns: KNOW.to_s,
                    'xmlns:xs' => 'http://www.w3.org/2001/XMLSchema',
                    'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                    'xsi:schemaLocation' => 'http://www.w3.org/2001/XMLSchema http://www.w3.org/2001/XMLSchema.xsd',
                    targetNamespace: KNOW.to_s,
                    elementFormDefault: 'qualified') do

      ontology.classes.each do |klass|
        singular = dasherize(underscore(klass.name))
        plural = pluralize(singular)

        xml[:xs].element(name: singular, type: klass.name)
        xml[:xs].element(name: plural) do
          xml[:xs].complexType do
            xml[:xs].sequence do
              xml[:xs].element(ref: singular, minOccurs: 0, maxOccurs: :unbounded)
            end
          end
        end
      end

      ontology.classes.each do |klass|
        xml[:xs].complexType(name: klass.name) do
          if klass.top?
            emit_properties(xml, klass)
          else
            xml[:xs].complexContent do
              xml[:xs].extension(base: klass.superclass.name) do
                emit_properties(xml, klass)
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
  require 'rdf/rdfxml'
  require 'rdf/trix'
  puts RDF::Reader.open(t.prerequisites.first).count
end

desc "List ontology classes"
task classes: %w(src/know.ttl) do |t|
  ontology = Know::Ontology.load(t.prerequisites.first)
  ontology.classes.each do |klass|
    if ENV['JSON']
      puts "\"#{klass.name}\","
    else
      puts klass.name
    end
  end
end

desc "List ontology properties"
task properties: %w(src/know.ttl) do |t|
  ontology = Know::Ontology.load(t.prerequisites.first)
  ontology.properties.each do |property|
    if ENV['JSON']
      puts "\"#{property.name}\","
    else
      puts property.name
    end
  end
end
