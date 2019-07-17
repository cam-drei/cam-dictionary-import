# frozen_string_literal: true

# require 'pry'
# require 'pdf-reader'

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
puts sentence

# insert sentence into mongod
