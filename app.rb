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

    dictionary.delete_many if dictionary.find
    File.delete(UNIMPORT_FILE_NAME) if File.exist?(UNIMPORT_FILE_NAME)
  end

  def import

    (0..paragraphs.size - 1).each do |i|
      sentence = paragraphs[i]
      cham_word = count_cham_word(sentence)
      meaning_word = count_meaning_word(sentence)

      if sentence.include?(' [Cam M]:') && (meaning_word == 0)
        document = build_without_meaning_include_source_name(sentence, cham_word, meaning_word)
      elsif sentence.include?(' [Cam M]:') && (meaning_word >= 1 && meaning_word <= 3)
        document = build_pronunciation_only(sentence, cham_word, meaning_word)
      elsif sentence.include?(' [Cam M] ') && sentence.include?('≠')
        document = build_fulfill_sentence(sentence, cham_word)
      elsif sentence.include?(' [Cam M]: ') && sentence.include?('≠')
        document = build_fulfill_sentence_include_colon(sentence, cham_word)
      elsif sentence.include?(' [Cam M] ')
        document = build_french_meaning_only(sentence, cham_word)
      elsif sentence.include?(' [Cam M]: ')
        document = build_french_meaning_only_include_colon(sentence, cham_word)
      elsif sentence.include?(' [Cam M]:')
        document = build_fulfill_sentence_include_special_colon(sentence, cham_word)
      elsif sentence.include?('[Cam M')
        document = build_error_page1(sentence)
      elsif sentence.include?('G. Moussay') || sentence.include?('Tu Dien Cham-Viet-Phap') || sentence.include?(('Po Dharma'))
        # File.open(UNIMPORT_FILE_NAME, 'a') { |file| file.write(sentence + "\n") }
        next
      elsif !sentence.match?(/\d/)
        document = build_without_meaning(sentence, cham_word)
      end

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
    # end
    @paragraphs
  end

  def count_cham_word(sentence)
    if sentence.include?('[Cam M]')
      groups = sentence.split('[Cam M]', 2)
      chams = groups[0].split
      count_word = chams.count
    elsif !sentence.match?(/\d/)
      chams = sentence.split
      count_word = chams.count
    end
    count_word
  end

  def count_meaning_word(sentence)
    if sentence.include?('[Cam M]')
      groups = sentence.split('[Cam M]', 2)
      meaning = groups[1]
      count_word = meaning.count '^: .' # count except ':', '.' and ' '
    end
    count_word
  end


  def build_fulfill_sentence(sentence, cham_word)
    return unless sentence.include?(' [Cam M] ') && sentence.include?('≠')

    groups = sentence.split(' [Cam M] ', 2)
    chams = groups[0].split(' ')
    meanings = groups[1].split('≠', 2)

    {
      rumi: chams[0, cham_word / 2].join(' '),
      akharThrah: chams[cham_word / 2, cham_word / 2].join(' '),
      source: 'Cam M',
      vietnamese: meanings[0],
      french: meanings[1],
      fullDescription: sentence
    }
  end

  def build_fulfill_sentence_include_colon(sentence, cham_word)
    return unless sentence.include?(' [Cam M]: ') && sentence.include?('≠')

    groups = sentence.split(' [Cam M]: ', 2)
    chams = groups[0].split(' ')
    meanings = groups[1].split('≠', 2)

    {
      rumi: chams[0, cham_word / 2].join(' '),
      akharThrah: chams[cham_word / 2, cham_word / 2].join(' '),
      source: 'Cam M',
      vietnamese: meanings[0],
      french: meanings[1],
      fullDescription: sentence
    }
  end

  def build_french_meaning_only(sentence, cham_word)
    return unless sentence.include?(' [Cam M] ')

    groups = sentence.split(' [Cam M] ', 2)
    chams = groups[0].split(' ')

    {
      rumi: chams[0, cham_word / 2].join(' '),
      akharThrah: chams[cham_word / 2, cham_word / 2].join(' '),
      source: 'Cam M',
      vietnamese: nil,
      french: groups[1],
      fullDescription: sentence
    }
  end

  def build_french_meaning_only_include_colon(sentence, cham_word)
    return unless sentence.include?(' [Cam M]: ')

    groups = sentence.split(' [Cam M]: ', 2)
    chams = groups[0].split(' ')

    {
      rumi: chams[0, cham_word / 2].join(' '),
      akharThrah: chams[cham_word / 2, cham_word / 2].join(' '),
      source: 'Cam M',
      vietnamese: nil,
      french: groups[1],
      fullDescription: sentence
    }
  end

  def build_fulfill_sentence_include_special_colon(sentence, cham_word)
    return unless sentence.include?(' [Cam M]:') && sentence.include?('≠')

    groups = sentence.split(' [Cam M]:', 2)
    chams = groups[0].split(' ')
    meanings = groups[1].split('≠', 2)

    {
      rumi: chams[0, cham_word / 2].join(' '),
      akharThrah: chams[cham_word / 2, cham_word / 2].join(' '),
      source: 'Cam M',
      vietnamese: meanings[0],
      french: meanings[1],
      fullDescription: sentence
    }
  end

  def build_error_page1(sentence) # One word is error in page 1
    return unless sentence.include?('[Cam M')

    groups = sentence.split('[Cam M', 2)
    chams = groups[0].split(' ', 2)

    {
      rumi: chams[0],
      akharThrah: chams[1],
      source: 'Cam M',
      vietnamese: nil,
      french: groups[1],
      fullDescription: sentence
    }
  end
  
  def build_without_meaning_include_source_name(sentence, cham_word, meaning_word)
    return unless sentence.include?(' [Cam M]:') && (meaning_word == 0)

    groups = sentence.split(' [Cam M]:', 2)
    chams = groups[0].split(' ')

    {
      rumi: chams[0, cham_word / 2].join(' '),
      akharThrah: chams[cham_word / 2, cham_word / 2].join(' '),
      source: 'Cam M',
      vietnamese: nil,
      french: nil,
      fullDescription: sentence
    }
  end

  def build_pronunciation_only(sentence, cham_word, meaning_word)
    return unless sentence.include?(' [Cam M]:') && (meaning_word >= 1 && meaning_word <= 3)

    groups = sentence.split(' [Cam M]:', 2)
    chams = groups[0].split(' ')

    {
      rumi: chams[0, cham_word / 2].join(' '),
      akharThrah: chams[cham_word / 2, cham_word / 2].join(' '),
      source: 'Cam M',
      vietnamese: nil,
      french: nil,
      pronunciation: groups[1].delete(':. '),
      fullDescription: sentence
    }
  end

  def build_without_meaning(sentence, cham_word)
    
    return unless !sentence.match?(/\d/)

    chams = sentence.split(' ')

    {
      rumi: chams[0, cham_word / 2].join(' '),
      akharThrah: chams[cham_word / 2, cham_word / 2].join(' '),
      source: 'Cam M',
      vietnamese: nil,
      french: nil,
      fullDescription: sentence
    }
  end

end

ImportPDF.new.import

# .gsub(/\s+$/m, '') remove any sequence of white spaces at the end of the string
# .gsub(/^\s+|\s+$/m, '')  remove any sequence of white space at the beginning and at the end of the string
# .gsub(/^\s+/m, '')  remove any sequence of white spaces at the beginning of the string
