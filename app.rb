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
    
    dictionary.delete_many() if dictionary.find()
    File.delete(UNIMPORT_FILE_NAME) if File.exist?(UNIMPORT_FILE_NAME)
  end

  def import
    # puts 'paragraphs 1', paragraphs[1]
    # binding.pry
    (0..paragraphs.size - 1).each do |i|
      sentence = paragraphs[i]
      count_cham_world = count_cham_world(sentence)
      
      
      document = build_fulfill_one_cham_world(sentence) if count_cham_world == 2 || count_cham_world == 3
      document = build_fulfill_two_cham_world(sentence) if count_cham_world == 4
      document = build_french_meaning_only(sentence) if document.nil?
      document = build_error_page1(sentence) if document.nil?

      dictionary.insert_one(document) if document

      File.open(UNIMPORT_FILE_NAME, 'a') { |file| file.write(sentence + "\n") } unless document
    end
  end

  private

  def paragraphs
    return @paragraphs if @paragraphs

    paragraph = ''
    @paragraphs = []

    # page = reader.page(1)
    reader.pages[0...20].each do |page|
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
    end
    @paragraphs
  end

  def count_cham_world(sentence)
    if sentence.include?(' [Cam M] ')
      groups = sentence.split(' [Cam M] ', 2)
      chams = groups[0].split()
      puts count_world = chams.count
    elsif sentence.include?(' [Cam M')
      groups = sentence.split(' [Cam M', 2)
      chams = groups[0].split()
      puts count_world = chams.count
    end
    count_world
  end

  def build_fulfill_two_cham_world(sentence)
    # puts 'count 4'
    return unless sentence.include?(' [Cam M] ') && sentence.include?('≠')

    groups = sentence.split(' [Cam M] ', 2)
    chams = groups[0].split(' ')
    meanings = groups[1].split('≠', 2)

    {
      rumi: chams[0, 2].join(' '),
      akharThrah: chams[2, 2].join(' '),
      source: 'Cam M',
      vietnamese: meanings[0],
      french: meanings[1]
    }
  end

  def build_fulfill_one_cham_world(sentence)
    # puts 'count 2'
    return unless sentence.include?(' [Cam M] ') && sentence.include?('≠')

    groups = sentence.split(' [Cam M] ', 2)
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
    return unless sentence.include?(' [Cam M] ')

    groups = sentence.split(' [Cam M] ', 2)
    chams = groups[0].split(' ', 2)

    {
      rumi: chams[0],
      akharThrah: chams[1],
      source: 'Cam M',
      vietnamese: nil,
      french: groups[1]
    }
  end

  def build_error_page1(sentence) # One world is error in page 1
    return unless sentence.include?('[Cam M')

    groups = sentence.split('[Cam M', 2)
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


# .gsub(/\s+$/m, '') remove any sequence of white spaces at the end of the string
# .gsub(/^\s+|\s+$/m, '')  remove any sequence of white space at the beginning and at the end of the string
# .gsub(/^\s+/m, '')  remove any sequence of white spaces at the beginning of the string