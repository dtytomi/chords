require 'forwardable'

class Array
  def sum; inject(0) {|sum, n| sum += n}; end
  def mean; sum/size; end
end

module Chords
  class Fingering
    attr_reader :fretboard, :presses, :chord, :stretch
    extend Forwardable
    def_delegators :@presses, :[], :==, :inspect, :each, :each_with_index
    
    def initialize(fretboard, chord, presses=nil)
      @fretboard, @chord = fretboard, chord
      @presses           = presses || []
      @stretch           = fretboard.stretch || 7
    end
    
    def fork(presses)
      self.class.new(@fretboard, @chord, presses)
    end
    
    def self.find_variations(fretboard, chord, opts={})
      fingering = Fingering.new(fretboard, chord)

      fingering.trace(1).select(&:appropriate).map(&:presses)
    end
    
    # Builds a chord starting with the the bottom string, picking one note at a time and building
    # a tree while moving up the strings, searching for complementing notes.
    # Repeat until all strings are filled.
    def trace(string)
      return self if string > @fretboard.open_notes.size
      open_note = @fretboard.open_notes[string-1]

      @chord.notes.inject([]) do |acc, chord_note|
        next_press = (chord_note.new.value - open_note.value) % 12 # the fret to press on the open string to get chord_note
        
        [next_press, next_press+12].each do |np|
          acc << fork([presses, np].flatten).trace(string+1) if chord?(np)
        end
        
        acc.flatten
      end.sort
    end
    
    # Make sure that the new finger press isn't too far from those already placed.
    def stretchable?(next_press)
      @presses.all? {|p| p == 0 || (p - next_press).abs < @stretch}
    end
    
    # The next press has to be within finger's reach and also on the fretboard?
    def chord?(next_press)
      stretchable?(next_press) && (0..@fretboard.frets).include?(next_press)
    end
    
    # do different checks here? Not inverted?
    def appropriate
      notes.map(&:class).uniq.size >= @chord.notes.size
    end
    
    def notes
      @notes ||= fretboard.fretted_notes(presses)
    end
    
    def <=>(other)
      presses.mean <=> (other.respond_to?(:presses) ? other.presses.mean : other)
    end
  end
end