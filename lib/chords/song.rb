require 'stringio'

module Chords
  class Song
    attr_accessor :name, :key, :progression, :uri, :fretboard

    def initialize(name, chord_progression, key=nil, uri='')
      self.name = name
      self.progression = chord_progression
      self.key = key
      self.uri = uri
      self.fretboard = Fretboard.new([G.new(1), D.new(1), A.new(2), E.new(3)], 17)
    end

    def to_s
      hijack_stdout = lambda { |block|
        begin; $stdout = o = StringIO.new; block.call; o.string; ensure; $stdout = STDOUT; end
      }
      
      "#{name}: #{progression.join(", ")}\n—————\n\n" + progression.inject("") do |out, c|
        chords = hijack_stdout[lambda {fretboard.print(eval(c))}]
        out << "#{c}\n#{chords}\n\n"
      end
    end
  end
end