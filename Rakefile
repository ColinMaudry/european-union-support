require 'csv'
require 'delegate'

# The script doesn't check whether all tags of the forms are visited during parsing, instead assuming the TED
# documentation is correct. See https://webgate.ec.europa.eu/fpfis/wikis/pages/viewpage.action?spaceKey=TEDeSender&title=XML+Schema+2.0.9#XMLSchema2.0.9-2.2.Formstructure

require 'nokogiri'

# These known attributes will automatically be added to the built tree.
# `:use` and `:fixed` are unique to `attribute` tags.
ATTRIBUTES   = %i(name type minOccurs maxOccurs use fixed ref)
# These attributes are used internally to build a locator for a node in the tree.
LOCATORS     = %i(index0 index1 index2 index3 index4 index5 index6 index7 index8 index9 index10)
# These are the supported restrictions on the tag's value.
RESTRICTIONS = %i(enumeration maxLength maxInclusive minInclusive minExclusive pattern totalDigits)
# These are calculated or other non-XML attributes of the node.
OTHERS       = %i(annotation unique base reference)

NO_FOLLOW = [
  # type
  'ac_definition',
  'contact_contracting_body',
  'contact_contractor',
  'contact_review',
  'empty', # has annotation "only-element"
  'no_award',
  'phone',
  'text_ft_multi_lines', # see readme

  # ref
  'annex_d1_part1',
  'annex_d2_part1',
]

# All attributes that can be assigned.
ASSIGNABLE = ATTRIBUTES + LOCATORS + OTHERS + RESTRICTIONS
# All attributes, excluding internal locators.
PROPERTIES = ATTRIBUTES + OTHERS + RESTRICTIONS

require_relative 'lib/tree_node'
require_relative 'lib/xml_parser'

task :download do
  # TODO download the necessary files
  # http://publications.europa.eu/mdr/eprocurement/ted/specific_versions_new.html#div2
end

def directories
  if ENV['DIRECTORY']
    directories = [ENV['DIRECTORY']]
  else
    directories = Dir['TED_*_R2'].sort
  end
end

task :preprocess do
  directories.each do |directory|
    refs = Set.new
    types = Set.new

    # Get the `ref`'s and `type`'s re-used across forms.
    Dir[File.join(directory, 'F*_2014.xsd')].sort.each do |filename|
      parser = XmlParser.new(filename)

      refs += parser.schema.xpath('.//*[@ref]').reject{ |n|
        parser.schema.xpath("./xs:#{n.name}[@name='#{n['ref'].split(':', 2).last}']").any?
      }.map{ |n| n['ref'] }

      types += parser.schema.xpath('.//*[@type]').reject{ |n|
        parser.schema.xpath(%w(complex simple).map{ |prefix| "./xs:#{prefix}Type[@name='#{n['type']}']" }.join('|')).any?
      }.map{ |n| n['type'] }
    end

    parser = XmlParser.new(File.join(directory, 'common_2014.xsd'))

    types += %w(contact_contractor contact_review phone)

    ns = parser.node_set(parser.schema.element_children, size: 0..999, names: %w(import include element group complexType simpleType), name_only: true)
    ns.each do |c|
      if refs.include?(c['name']) || types.include?(c['name'])
        parser.elements(c, 0, index0: c['name'], enter: true)
      end
    end

    parser.to_csv
  end
end

task :process do
  directories.each do |directory|
    # Other files described at https://webgate.ec.europa.eu/fpfis/wikis/pages/viewpage.action?spaceKey=TEDeSender&title=XML+Schema+2.0.9#XMLSchema2.0.9-2.1.Overview
    Dir[File.join(directory, 'F*_2014.xsd')].sort.each do |filename|
      parser = XmlParser.new(filename)

      abbreviation = parser.basename.sub('_2014', '')

      # Navigate to the form's main sequence.
      ns = parser.node_set(parser.schema.xpath("./xs:element[@name='#{parser.basename}']"), size: 1, names: ['element'], attributes: ['name'], children: true)
      ns = parser.node_set(ns[0].element_children, size: 2, index: 1, names: ['complexType'], children: true, xml: {0 => "<xs:annotation>\n\t\t\t<xs:documentation>ROOT element #{abbreviation}</xs:documentation>\n\t\t</xs:annotation>"})
      ns = parser.node_set(ns[1].element_children, size: 4, index: 0, names: ['sequence'], children: true, xml: {1..3 => %(<xs:attribute name="LG" type="t_ce_language_list" use="required"/><xs:attribute name="CATEGORY" type="original_translation" use="required"/><xs:attribute name="FORM" use="required" fixed="#{abbreviation}"/>)})
      ns = parser.node_set(ns[0].element_children, size: 4..8, names: %w(choice element), name_only: true)
      ns.to_enum.with_index(1) do |c, i|
        parser.elements(c, 0, index0: i)
      end

      parser.to_csv
    end
  end
end

task tmp: :preprocess do
  directories.each do |directory|
    parser = XmlParser.new(File.join(directory, 'common_2014.xsd'))

    counts = Hash.new(0)
    parser.schema.xpath('.//@ref').each do |attribute|
      counts[attribute.value] += 1
    end
    parser.schema.xpath('.//@type').each do |attribute|
      counts[attribute.value] += 1
    end

    text = File.read('common.csv') # must redirect output to common.csv

    $stderr.puts "\nFrequently occurring references:"
    counts.map{ |k, v|
      [text.scan(/,#{Regexp.escape(k)}\b/).count - v, k]
    }.sort.select{ |v, k| v > 1 }.each{ |v, k|
      $stderr.puts "#{v}: #{k}"
    }

    $stderr.puts "\nFrequently occurring attributes:"
    counts = Hash.new(0)
    text.scan(/\+,([^,\n]+)/).each{ |s| counts[s[0]] += 1 }
    counts.sort_by(&:last).each do |k, v|
      $stderr.puts "#{v}: #{k}"
    end

    NO_FOLLOW.each do |index|
      if !text[/^common_2014,#{index}/]
        $stderr.puts "#{index} is undefined in common.csv - change `types` in :preprocess task?"
      end
    end
  end
end
