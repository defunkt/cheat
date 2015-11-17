# >> Evan Weaver
# => http://blog.evanweaver.com/articles/2006/09/03/smart-plaintext-wrapping
class String
  def wrap(width = 80, hanging_indent = 0, magic_lists = false)
    lines = split(/\n/)

    lines.collect! do |line|
      if magic_lists
        line =~ /^([\s\-\d\.\:]*\s)/
      else
        line =~ /^([\s]*\s)/
      end

      indent = begin
                 Regexp.last_match(1).length + hanging_indent
               rescue
                 hanging_indent
               end

      buffer = ''
      first = true

      while line.length > 0
        first ? (i = 0
                 first = false) : i = indent
        pos = width - i

        if line.length > pos && line[0..pos] =~ /^(.+)\s/
          subline = Regexp.last_match(1)
        else
          subline = line[0..pos]
        end
        buffer += ' ' * i + subline + "\n"
        line.tail!(subline.length)
      end
      buffer[0..-2]
    end

    lines.join("\n")
  end

  def tail!(pos)
    self[0..pos] = ''
    strip!
  end
end
