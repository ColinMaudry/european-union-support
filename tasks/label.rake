def pdftotext(path)
  `pdftotext -layout #{path} -`
end

def label_keys(text)
  text.scan(/<<([^>]+)>>/).flatten
end

namespace :label do
  desc 'Create or update files for mapping XPath values to corresponding label keys'
  task :xpath do
    FileUtils.mkdir_p('output/mapping')

    files('output/samples/F{}_*.xml').each do |filename|
      basename = File.basename(filename, '.xml')
      path = "output/mapping/#{basename}.csv"

      rows_by_xpath = {}
      if File.exist?(path)
        CSV.read(path, headers: true).each do |row|
          rows_by_xpath[row['xpath']] = row
        end
      end

      xpaths = Set.new
      Nokogiri::XML(File.read(filename)).xpath("/#{basename}//*|/#{basename}//@*").each do |element|
        xpath = element.path.gsub(/\[\d+\]/, '').gsub(%r{\b(?:choice|group|sequence)/}, '')
        # Exclude XSD elements, paragraph tags, form identifier, and attributes for empty elements.
        if !%w(choice group sequence P @FORM @CODE @TYPE @VALUE).include?(xpath.split('/')[-1])
          xpaths << xpath
        end
      end

      # Preserve the label-key and index columns, if a file existed.
      CSV.open(path, 'w') do |csv|
        csv << ['xpath', 'label-key', 'index', 'comment']
        xpaths.each do |xpath|
          csv << (rows_by_xpath[xpath] || [xpath, nil, nil, nil])
        end
      end
    end
  end

  desc 'Create or update a file for listing label keys without corresponding XPath values'
  task :ignore do
    path = 'output/mapping/ignore.csv'
    non_default_keys = []
    if File.exist?(path)
      CSV.read(path, headers: true).each do |row|
        if !row['label-key'][/\AHD?_/]
          non_default_keys << row
        end
      end
    end

    keys = Set.new
    files('source/*_TED_forms_templates/F{}_*.pdf').each do |filename|
      keys += label_keys(pdftotext(filename)).select{ |key| key[/\AHD?_/] }
    end

    CSV.open(path, 'w') do |csv|
      csv << ['label-key', 'index', 'comment']
      keys.each do |key|
        csv << [key, nil, nil]
      end
      non_default_keys.each do |row|
        csv << row
      end
    end
  end

  desc 'Report any XPath values without corresponding label keys, and vice versa'
  task :missing do
    label_keys_seen = Set.new
    indices_seen = Set.new
    %w(enumerations.csv ignore.csv).each do |basename|
      CSV.read(File.join('output', 'mapping', basename), headers: true).each do |row|
        label_keys_seen << row['label-key']
        indices_seen << row['index']
      end
    end

    files('output/mapping/F{}_*.csv').each do |filename|
      CSV.foreach(filename, headers: true) do |row|
        if row['label-key'].nil?
          if row['comment'].nil?
            puts "#{row['xpath']} has no label-key or comment"
          end
        else
          label_keys_seen << row['label-key']
          indices_seen << row['index']
        end
      end
    end

    files('source/*_TED_forms_templates/F{}_*.pdf').each do |filename|
      text = pdftotext(filename)

      difference = Set.new(label_keys(text)) - label_keys_seen
      if difference.any?
        puts "#{File.basename(filename)}: #{difference.to_a.join(', ')}"
      end

      difference = Set.new(text.scan(/\b[IV]+(?:\.\d+)*/).flatten) - indices_seen
      if difference.any?
        puts "#{File.basename(filename)}: #{difference.to_a.join(', ')}"
      end
    end
  end

  desc 'Report any incoherences in mappings across forms'
  task :coherence do
    mappings = {}

    files('output/mapping/F{}_*.csv').each do |filename|
      CSV.foreach(filename, headers: true) do |row|
        if row['label-key']
          key = row['xpath'].split('/', 3)[2]
          value = row.fields[1..-1].join(',')
          if mappings.key?(key)
            expected = mappings[key]
            if expected[:value] != value
              puts "#{expected[:filename]} #{expected[:value].ljust(21)} != #{filename} #{value}"
            end
          else
            mappings[key] = {filename: filename, value: value}
          end
        end
      end
    end
  end
end
