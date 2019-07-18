# frozen_string_literal: true

# require 'pry'
require 'pdf-reader'
require 'mongo'


# puts reader.pdf_version
# puts reader.info
# puts reader.metadata
# puts reader.page_count

# binding.pry

# puts reader.pages.first

# reader.pages.each do |page|
#   puts page.text
# end


  reader = PDF::Reader.new('TuDienMoussay.pdf')
  page     = reader.page(1)

  paragraph = ""
  paragraphs = []
  # reader.pages.each do |page|
    lines = page.text.scan(/^.+/)
    lines.each do |line|
      if line.length > 55
        paragraph += " #{line}"
      else
        paragraph += " #{line}"
        paragraphs << paragraph
        paragraph = ""
      end
    end
    # return paragraphs
  # end

puts paragraphs[0]

client = Mongo::Client.new(['127.0.0.1:27017'], database: 'import')
dictionary = client[:dictionary]

def build_document(paragraphs)
  puts paragraphs[1]
  # binding.pry
  
  for i in 3..paragraphs.size - 1
    puts paragraphs[2]
    groups = paragraphs[i].split(' [Cam M] ')
    chams = groups[0].split(' ', 2)
    meanings = groups[1].split('=', 2)
    {
      rumi: chams[0],
      akharThrah: chams[1],
      source: 'Cam M',
      vietnamese: meanings[0],
      french: meanings[1]
    }
    # puts paragraph
    
    dictionary.insert_one(paragraphs[i])
  end
  
end

build_document(paragraphs)














# CODE HERE

# def build_document(sentence)
#   # binding.pry

#   groups = sentence.split(' [Cam M] ')
#   chams = groups[0].split(' ', 2)
#   meanings = groups[1].split('=', 2)
#   {
#     rumi: chams[0],
#     akharThrah: chams[1],
#     source: 'Cam M',
#     vietnamese: meanings[0],
#     french: meanings[1]
#   }
# end

# sentence = 'a-hei a_ hE [Cam M] hay, hoan hç ≠ bravo.'

# # insert sentence into mongod
# client = Mongo::Client.new(['127.0.0.1:27017'], database: 'import')
# dictionary = client[:dictionary]

# data = build_document(sentence)
# dictionary.insert_one(data)

# puts dictionary.find

# paragraph = ""
# paragraphs = []
# reader.pages.each do |page|
#   lines = page.text.scan(/^.+/)
#   lines.each do |line|
#     if line.length > 55
#       paragraph += " #{line}"
#     else
#       paragraph += " #{line}"
#       paragraphs << paragraph
#       paragraph = ""
#     end
#   end
# end