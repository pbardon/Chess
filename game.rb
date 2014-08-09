# encoding: UTF-8
require 'io/console'
require './board.rb'
require './piece.rb'

class Game
  def initialize
    @b = Board.new
    @cursor_pos = [3,3]
    play_game
  end

  def input(choice)

    if @b.in_checkmate?(:white) || @b.in_checkmate?(:black)
      return
    end

    case choice.to_s
    when 'w'
      move_cursor([0, -1])
    when 'a'
      move_cursor([-1, 0])
    when 's'
      move_cursor([0, 1])
    when 'd'
      move_cursor([1, 0])
    when 'q'
      @quit = true
    when 'c'
      @move_from = [@cursor_pos[0],@cursor_pos[1]]
      @b.display_board(@cursor_pos, @move_from)
    when 'v'
      @move_to = [@cursor_pos[0],@cursor_pos[1]]
      if @b[@move_from].move_into_check?(@move_to)
        puts "You must move your piece out of check"
        return
      else
        @b.move(@move_from, @move_to)
      end
    end
  end

  def move_cursor(rel_pos)
    @cursor_pos[0] += rel_pos.first
    @cursor_pos[0] = @cursor_pos[0] % 8
    @cursor_pos[1] += rel_pos.last
    @cursor_pos[1] = @cursor_pos[1] % 8
  end

  def play_game
    until @b.in_checkmate?(:white) || @b.in_checkmate?(:black) || @quit == true
      message = ""
      begin
        system("clear")
        if @b.turn == "white"
          puts "White's turn"
        else
          puts "Black's turn"
        end
        @b.display_board(@cursor_pos, @move_from)
        puts "Use WASD to move and C to choose starting piece and V to place it. Or enter 'q' to quit"
        puts message
        input(STDIN.getch)
      rescue StandardError => e
        message = e.message
        retry
      end
    end
  end
end

if __FILE__  == $PROGRAM_NAME
  g = Game.new
end
