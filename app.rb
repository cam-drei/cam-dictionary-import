# frozen_string_literal: true

require 'pry'
require 'pdf-reader'
require 'mongo'

class ImportPDF
  attr_reader :reader, :dictionary
  UNIMPORT_FILE_NAME = 'other_document.txt'

  def initialize
    @reader = PDF::Reader.new('TuDienMoussay.pdf')
    client = Mongo::Client.new(['127.0.0.1:27017'], database: 'import')
    @dictionary = client[:dictionary]

    File.delete(UNIMPORT_FILE_NAME) if File.exist?(UNIMPORT_FILE_NAME)
  end

  def import
    # puts 'paragraphs 1', paragraphs[1]
    # binding.pry
    (0..paragraphs.size - 1).each do |i|
      sentence = paragraphs[i]
      document = build_fulfill_sentence(sentence)
      document = build_french_meaning_only(sentence) if document

      dictionary.insert_one(document) if document

      File.open(UNIMPORT_FILE_NAME, 'a') { |file| file.write(sentence + "\n") } unless document
    end
  end

  private

  def paragraphs
    return @paragraphs if @paragraphs

    paragraph = ''
    @paragraphs = []

    page = reader.page(1)
    # reader.pages.each do |page|
    lines = page.text.scan(/^.+/)
    lines.each do |line|
      if line.length > 55
        paragraph += " #{line}"
      else
        paragraph += " #{line}"
        @paragraphs << paragraph
        paragraph = ''
      end
    end

    @paragraphs
  end

  def build_fulfill_sentence(sentence)
    return unless sentence.include?('[Cam M]') && sentence.include?('≠')

    groups = sentence.split('[Cam M]')
    chams = groups[0].split(' ', 2)
    meanings = groups[1].split('≠', 2)

    {
      rumi: chams[0],
      akharThrah: chams[1],
      source: 'Cam M',
      vietnamese: meanings[0],
      french: meanings[1]
    }
  end

  def build_french_meaning_only(sentence)
    return unless sentence.include?('[Cam M]')

    groups = sentence.split('[Cam M]')
    chams = groups[0].split(' ', 2)

    {
      rumi: chams[0],
      akharThrah: chams[1],
      source: 'Cam M',
      vietnamese: nil,
      french: groups[1]
    }
  end
end

ImportPDF.new.import
