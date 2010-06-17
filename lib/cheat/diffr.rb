require 'diff/lcs'
require 'diff/lcs/hunk'

module Cheat
  class Diffr
    def self.diff(sheet_old, sheet_new)
      format, lines, output = :unified, 10000, ''
      file_length_difference = 0

      data_old = sheet_old.body.wrap.split(/\n/).map! { |e| e.chomp }
      data_new = sheet_new.body.wrap.split(/\n/).map! { |e| e.chomp }

      diffs = Diff::LCS.diff(data_old, data_new)
      return if diffs.empty?

      header = ''
      ft = sheet_old.updated_at
      header << "#{'-' * 3} #{sheet_new.title} version #{sheet_old.version}\t#{ft}\n"
      ft = sheet_new.updated_at
      header <<  "#{'+' * 3} #{sheet_new.title} version #{sheet_new.version}\t#{ft}\n"

      oldhunk = hunk = nil

      diffs.each do |piece|
        begin
          hunk = Diff::LCS::Hunk.new(data_old, data_new, piece, lines, file_length_difference)
          file_length_difference = hunk.file_length_difference

          next unless oldhunk

          if lines > 0 && hunk.overlaps?(oldhunk)
            hunk.unshift(oldhunk)
          else
            output << oldhunk.diff(format)
          end
        ensure
          oldhunk = hunk
          output << "\n"
        end
      end

      output << oldhunk.diff(format)
      output << "\n"

      return header + output.lstrip
    end
  end
end
