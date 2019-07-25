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
    # puts 'paragraphs 1', paragraphs[1]
    # binding.pry
    (0..paragraphs.size - 1).each do |i|
      sentence = paragraphs[i]
      cham_word = count_cham_word(sentence)

      # if (cham_word == 2 || cham_word == 3) && sentence.include?(' [Cam M] ') && sentence.include?('≠')
      #   document = build_fulfill_one_rumi_word(sentence)
      # elsif cham_word == 4 && sentence.include?(' [Cam M] ') && sentence.include?('≠')
      #   document = build_fulfill_two_rumi_word(sentence)
      # elsif (cham_word == 2 || cham_word == 3) && sentence.include?(' [Cam M]: ') && sentence.include?('≠')
      #   document = build_fulfill_one_rumi_word_include_colon(sentence)
      # elsif cham_word == 4 && sentence.include?(' [Cam M]: ') && sentence.include?('≠')
      #   document = build_fulfill_two_rumi_word_include_colon(sentence)
      # elsif (cham_word == 2 || cham_word == 3) && sentence.include?(' [Cam M] ')
      #   document = build_french_meaning_only_one_rumi_word(sentence)
      # elsif (cham_word == 2 || cham_word == 3) && sentence.include?(' [Cam M]: ')
      #   document = build_french_meaning_only_one_rumi_word_include_colon(sentence)
      # elsif cham_word == 4 && sentence.include?(' [Cam M]: ')
      #   document = build_french_meaning_only_two_rumi_word_include_colon(sentence)
      # elsif sentence.include?('[Cam M')
      #   document = build_error_page1(sentence)
      # end

      if sentence.include?(' [Cam M] ') && sentence.include?('≠')
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
      elsif !sentence.match(/\d/)
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

    page = reader.page(200)
    # reader.pages[0...20].each do |page|
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
    end
    count_word
  end

  # testing...
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
      french: meanings[1]
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
      french: meanings[1]
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
      french: groups[1]
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
      french: groups[1]
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
      french: meanings[1]
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
      french: groups[1]
    }
  end

  def build_without_meaning(sentence, cham_word)
    return unless sentence.match(/\d/)

    chams = snetence.split(' ')

    {
      rumi: chams[0, cham_word / 2].join(' '),
      akharThrah: chams[cham_word / 2, cham_word / 2].join(' '),
      source: 'Cam M',
      vietnamese: nil,
      french: nil
    }
  end

  # finish test

  # def build_fulfill_one_rumi_word(sentence)

  #   return unless sentence.include?(' [Cam M] ') && sentence.include?('≠')

  #   groups = sentence.split(' [Cam M] ', 2)
  #   chams = groups[0].split(' ', 2)
  #   meanings = groups[1].split('≠', 2)

  #   {
  #     rumi: chams[0],
  #     akharThrah: chams[1],
  #     source: 'Cam M',
  #     vietnamese: meanings[0],
  #     french: meanings[1]
  #   }
  # end

  # def build_fulfill_two_rumi_word(sentence)

  #   return unless sentence.include?(' [Cam M] ') && sentence.include?('≠')

  #   groups = sentence.split(' [Cam M] ', 2)
  #   chams = groups[0].split(' ')
  #   meanings = groups[1].split('≠', 2)

  #   {
  #     rumi: chams[0, 2].join(' '),
  #     akharThrah: chams[2, 2].join(' '),
  #     source: 'Cam M',
  #     vietnamese: meanings[0],
  #     french: meanings[1]
  #   }
  # end

  # def build_fulfill_one_rumi_word_include_colon(sentence)

  #   return unless sentence.include?(' [Cam M]: ') && sentence.include?('≠')

  #   groups = sentence.split(' [Cam M]: ', 2)
  #   chams = groups[0].split(' ', 2)
  #   meanings = groups[1].split('≠', 2)

  #   {
  #     rumi: chams[0],
  #     akharThrah: chams[1],
  #     source: 'Cam M',
  #     vietnamese: meanings[0],
  #     french: meanings[1]
  #   }
  # end

  # def build_fulfill_two_rumi_word_include_colon(sentence)

  #   return unless sentence.include?(' [Cam M]: ') && sentence.include?('≠')

  #   groups = sentence.split(' [Cam M]: ', 2)
  #   chams = groups[0].split(' ')
  #   meanings = groups[1].split('≠', 2)

  #   {
  #     rumi: chams[0, 2].join(' '),
  #     akharThrah: chams[2, 2].join(' '),
  #     source: 'Cam M',
  #     vietnamese: meanings[0],
  #     french: meanings[1]
  #   }
  # end

  # def build_french_meaning_only_one_rumi_word(sentence)
  #   return unless sentence.include?(' [Cam M] ')

  #   groups = sentence.split(' [Cam M] ', 2)
  #   chams = groups[0].split(' ', 2)

  #   {
  #     rumi: chams[0],
  #     akharThrah: chams[1],
  #     source: 'Cam M',
  #     vietnamese: nil,
  #     french: groups[1]
  #   }
  # end

  # def build_french_meaning_only_one_rumi_word_include_colon(sentence)
  #   return unless sentence.include?(' [Cam M]: ')

  #   groups = sentence.split(' [Cam M]: ', 2)
  #   chams = groups[0].split(' ', 2)

  #   {
  #     rumi: chams[0],
  #     akharThrah: chams[1],
  #     source: 'Cam M',
  #     vietnamese: nil,
  #     french: groups[1]
  #   }
  # end

  # def build_french_meaning_only_two_rumi_word_include_colon(sentence)
  #   return unless sentence.include?(' [Cam M]: ')

  #   groups = sentence.split(' [Cam M]: ', 2)
  #   chams = groups[0].split(' ')

  #   {
  #     rumi: chams[0, 2].join(' '),
  #     akharThrah: chams[2, 2].join(' '),
  #     source: 'Cam M',
  #     vietnamese: nil,
  #     french: groups[1]
  #   }
  # end
end

ImportPDF.new.import

# .gsub(/\s+$/m, '') remove any sequence of white spaces at the end of the string
# .gsub(/^\s+|\s+$/m, '')  remove any sequence of white space at the beginning and at the end of the string
# .gsub(/^\s+/m, '')  remove any sequence of white spaces at the beginning of the string
