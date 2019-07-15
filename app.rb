# frozen_string_literal: true

require 'pdf-reader'

reader = PDF::Reader.new('TuDienMoussay.pdf')

puts reader.pdf_version
puts reader.info
puts reader.metadata
# puts reader.page_count

# CODE HERE
