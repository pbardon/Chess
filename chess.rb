# encoding: UTF-8 
require 'io/console'
require 'debugger'


class Game
  def initialize
    @b = Board.new
    @cursor_pos = [3,3]
    @checkmate = false
    play_game
  end
  
  def input(choice)
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
      @checkmate = true
      return
    when 'c'
      @move_from = [@cursor_pos[0],@cursor_pos[1]]
      puts @cursor_pos
    when 'v'
      @move_to = [@cursor_pos[0],@cursor_pos[1]]
      @b.move(@move_from, @move_to)
      return
    end
  end
  
  def move_cursor(rel_pos)
    @cursor_pos[0] += rel_pos.first
    @cursor_pos[1] += rel_pos.last
  end
  
  def play_game
    until @checkmate
      begin
        system("clear")
        @b.display_board(@cursor_pos)
        puts "Use WASD to move and C to choose starting piece and V to place it."
        input(STDIN.getch)
        p @cursor_pos
        break if @checkmate
        system("clear")
        @b.display_board(@cursor_pos)
        
        @checkmate = @b.in_checkmate?(:white) || @b.in_checkmate?(:black)
      rescue StandardError => e
        puts e.message
        retry
      end
    end
  end
end

class Board
  def initialize(board = Array.new(8) { Array.new(8) {nil}})
    @board = board
    setup_board
  end
  
  def pieces(color)
    @board.flatten.select { |x| x.color == color unless x.nil? }
  end
  
  def setup_board
    King.new([3,0], self, :white)
    Queen.new([4,0], self, :white)
    Bishop.new([5,0], self, :white)
    Bishop.new([2,0], self, :white)
    Knight.new([6,0], self, :white)
    Knight.new([1,0], self, :white)
    Castle.new([0,0], self, :white)
    Castle.new([7,0], self, :white)
    8.times { |i| Pawn.new([i,1], self, :white) }
  
    King.new([3,7], self, :black)
    Queen.new([4,7], self, :black)
    Bishop.new([5,7], self, :black)
    Bishop.new([2,7], self, :black)
    Knight.new([6,7], self, :black)
    Knight.new([1,7], self, :black)
    Castle.new([0,7], self, :black)
    Castle.new([7,7], self, :black)
    8.times { |i| Pawn.new([i,6], self, :black) }
  end
  
  def display_board(cursor_pos)
    checker = false
    @board.each_with_index do |row, i|
      checker = !checker
      row.each_with_index do |space, j|
        if [j,i] == cursor_pos
          if space == nil
            print  "▓".green + " " if checker
            print  "▢".green + " " if !checker
          else
            print "#{space.inspect} ".green
          end
          checker = !checker
        else
          if space == nil
            print  "▓" + " " if checker
            print  "▢" + " " if !checker
          else
            print "#{space.inspect} "
          end
          checker = !checker
        end
      end
      puts
    end
    puts ""
  end
  
  def [](pos_arr)
    @board[pos_arr.last][pos_arr.first]
  end
  
  def []=(pos_arr, piece)
    @board[pos_arr.last][pos_arr.first] = piece
  end
  
  def get_king(color)
    pieces(color).find {|p| p.is_a?(King)}
  end
  
  def in_check?(color)
    k_pos = get_king(color).position
    other_color = (color == :white ? :black : :white)
    pieces(other_color).any? { |piece| piece.moves.include?(k_pos) }
  end
  
  def in_checkmate?(color)
    k_pos = get_king(color).position

    pieces(color).map do |piece|
      piece.moves.select do |move| 
        !piece.move_into_check?(move)
      end
    end.flatten(1).empty?

  end
  
  def move(start_pos, end_pos)
    piece = @board[start_pos[1]][start_pos[0]]
    puts "start pos:"
    p start_pos
    unless piece.nil?
      moves = piece.moves
      if moves.include?(end_pos)
        if piece.move_into_check?(end_pos)
          raise "This move would put you in check"
        else
          @board[start_pos[1]][start_pos[0]] = nil
           piece.set_position(end_pos)
        end
      else
        raise StandardError.new "Can't move there."
      end
    else
      raise "No piece"
    end
  end
  
  def move!(start_pos, end_pos)
    piece = @board[start_pos[1]][start_pos[0]]
    unless piece.nil?
      moves = piece.moves
      if moves.include?(end_pos)
        @board[start_pos[1]][start_pos[0]] = nil
          piece.set_position(end_pos)
      end
    end
  end
  
  def dup
    new_board = Board.new()
    @board.each_with_index do |row, i|
      row.each_with_index do |piece, j|
        next if piece.nil?
        new_board[[j, i]] = piece.class.new(
                            piece.position,
                            new_board,                                                                      piece.color
                            )
      end
    end
    new_board
  end
  
end

class Piece
  attr_accessor :x_pos, :y_pos, :color
  
  CARDINALS = [ [ 1,  1],
                [-1,  1],
                [ 1, -1],
                [-1, -1],
                [ 0,  1],
                [ 0, -1],
                [ 1,  0],
                [-1,  0]]
                

  def initialize(pos, board, color)
    @board = board
    @x_pos = pos.first
    @y_pos = pos.last
    @color = color
    @board[pos] = self
  end
  
  def position
    [@x_pos, @y_pos]
  end
  
  def set_position(pos_arr)
    @x_pos = pos_arr.first
    @y_pos = pos_arr.last
    @board[pos_arr] = self
  end    
  
  def move_into_check?(pos)
    new_board = @board.dup
    new_board.move!([@x_pos, @y_pos], pos)
    new_board.in_check?(@color)
  end
  
  def inspect
    raise "not implemented"
  end
end

class SteppingPiece < Piece
  def initialize(position, board, color)
    super
  end
  
  def moves(valid_arr)
    moves_arr = []
    valid_arr.each do |move| 
      dx = move.first
      dy = move.last
      new_pos = [@x_pos + dx, @y_pos + dy]
      if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
        if @board[new_pos] != nil
          moves_arr << new_pos if @board[new_pos].color != @color
        else
          moves_arr << new_pos
        end
      end
    end
    moves_arr
  end
end

class SlidingPiece < Piece
  def initialize(position, board, color)
    super
  end
  
  def moves(valid_dir)
    moves_arr = []
    valid_dir.each do |dir|
      stop_n = 8
      (1...stop_n).each do |n|
        dx = dir.first * n
        dy = dir.last * n
        new_pos = [@x_pos + dx, @y_pos + dy]
        if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
          if @board[new_pos] != nil
            moves_arr << new_pos if @board[new_pos].color != @color 
            stop_n = n
            break
          else
            moves_arr << new_pos
          end
        end
      end
    end
    moves_arr
  end 
end

class King < SteppingPiece
                  
  def initialize(position, board, color)
    super
    @character = "K"
  end
  
  def inspect
    return "♔" if @color == :black
    "♚" if @color == :white
  end
  
                
  def moves
    super(CARDINALS)
  end
  
end

class Knight < SteppingPiece
  
  N_MOVES = [     [ 2,  1],
                  [-2,  1],
                  [ 1,  2],
                  [ 1, -2],
                  [-1,  2],
                  [-1, -2],
                  [ 2, -1],
                  [-2, -1]]
                
                
  def initialize(position, board, color)
    super
    @character = "N"
  end
                
  def moves(move = N_MOVES)
    super
  end
  
  def inspect
    return "♘" if @color == :black
    "♞" if @color == :white
  end
  
end
  
class Queen < SlidingPiece
  
  def initialize(position, board, color)
    super
    @character = "Q"
  end

  def moves
    super(CARDINALS)
  end
  
  def inspect
    return "♕" if @color == :black
    "♛" if @color == :white
  end
end
  
class Bishop < SlidingPiece
  
                
  def initialize(position, board, color)
    super
    @character = "B"
  end
  
  def moves
    super(CARDINALS.take(4))
  end
  
  def inspect
    return "♗" if @color == :black
    "♝" if @color == :white
  end
end

class Castle < SlidingPiece
             
  def initialize(position, board, color)
    super
    @character = "C"
  end
  
  def moves
    super(CARDINALS.drop(4))
  end
  
  def inspect
    return "♖" if @color == :black
    "♜" if @color == :white
  end
end

class Pawn < SteppingPiece
  
  def initialize(position, board, color)
    super
    @character = "P"
    @first_pos = position
  end
  
  def moves()
    moves_arr = []
    if self.color == :white
      deltas = CARDINALS.take(2)
      moves_arr += check_for_enemies(:black, deltas)
      new_pos = [@x_pos, @y_pos + 1]
      new_pos2 = [@x_pos, @y_pos + 2]
      if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
        moves_arr <<  new_pos if @board[new_pos] == nil
      end
      if new_pos2.first.between?(0,7) && new_pos2.last.between?(0,7)
        if self.position == @first_pos && @board[new_pos] == nil
          moves_arr << new_pos2 
        end
      end
    else
      deltas = CARDINALS[2..3]
      moves_arr += check_for_enemies(:white, deltas)
      new_pos =  [@x_pos, @y_pos - 1]
      new_pos2 = [@x_pos, @y_pos - 2]
      if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
        moves_arr << new_pos if @board[new_pos] == nil
      end
      if new_pos2.first.between?(0,7) && new_pos2.last.between?(0,7)
        if self.position == @first_pos && @board[new_pos] == nil
          moves_arr << new_pos2
        end
      end
    end
    moves_arr
  end
  
  def check_for_enemies(color, deltas)
    moves_arr = []
    deltas.each do |delta|
      new_x = @x_pos + delta.first
      new_y = @y_pos + delta.last
      unless @board[[new_x, new_y]].nil?
        if new_x.between?(0,7) && new_y.between?(0,7)
          if @board[[new_x, new_y]].color == color
            moves_arr << [new_x, new_y]
          end
        end
      end
    end
    moves_arr
  end
  def inspect
    return "♙" if @color == :black
    "♟" if @color == :white
  end
  
end


class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def green
    colorize(32)
  end
end
    

if __FILE__  == $PROGRAM_NAME
  g = Game.new
end
