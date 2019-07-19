# frozen_string_literal: true

require 'pry'
require 'pdf-reader'
require 'mongo'

# puts reader.pdf_version
# puts reader.info
# puts reader.metadata
# puts reader.page_count

reader = PDF::Reader.new('TuDienMoussay.pdf')
# page = reader.page(1)

paragraph = ''
paragraphs = []
reader.pages.each do |page|
  lines = page.text.scan(/^.+/)
  lines.each do |line|
    if line.length > 55
      paragraph += " #{line}"
    else
      paragraph += " #{line}"
      paragraphs << paragraph
      paragraph = ''
    end
  end
end

# puts paragraphs[0]

client = Mongo::Client.new(['127.0.0.1:27017'], database: 'import')
dictionary = client[:dictionary]

def build_document(paragraphs, dictionary)
  # puts 'paragraphs 1', paragraphs[1]
  # binding.pry
  (0..paragraphs.size - 1 - 1).each do |i|
    # puts "paragraphs #{i}", paragraphs[2]
    if paragraphs[i].include?('[Cam M]') && paragraphs[i].include?('≠')
      
      groups = paragraphs[i].split('[Cam M]')
      chams = groups[0].split(' ', 2)
      meanings = groups[1].split('≠', 2)
      document = {
        rumi: chams[0],
        akharThrah: chams[1],
        source: 'Cam M',
        vietnamese: meanings[0],
        french: meanings[1]
      }
      # binding.pry

      # puts "inside #{i}", document
      dictionary.insert_one(document)
    elsif paragraphs[i].include?('[Cam M]')
      groups = paragraphs[i].split('[Cam M]')
      chams = groups[0].split(' ', 2)
      document = {
        rumi: chams[0],
        akharThrah: chams[1],
        source: 'Cam M',
        vietnamese: nil,
        french: groups[1]
      }
      
      dictionary.insert_one(document)
      
    else
      # puts "file #{i}", paragraphs[i]
      # binding.pry
      File.open('other_document.txt', 'a') {|file| file.write(paragraphs[i] + "\n")}
    end
  end
end

build_document(paragraphs, dictionary)

