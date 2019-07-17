# frozen_string_literal: true

# require 'pry'
# require 'pdf-reader'
require 'mongo'

# reader = PDF::Reader.new('TuDienMoussay.pdf')

# puts reader.pdf_version
# puts reader.info
# puts reader.metadata
# puts reader.page_count

# binding.pry

# puts reader.pages.first

# reader.pages.each do |page|
#   puts page.text
# end

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

# CODE HERE

sentence = 'a-hei a_ hE [Cam M] hay, hoan hç ≠ bravo.'

# insert sentence into mongod
client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'import')

dictionary = client[:paragraph]

data = { rumi: 'a-hei', akharThrah: 'a-hei', source: 'Cam M', vietnamese: 'hoan ho', french: 'bravo' }

result = dictionary.insert_one(data)
puts dictionary.find()
