# encoding: UTF-8 
##require 'debugger'
class Game
  def initialize
    @b = Board.new
    checkmate = false
    until checkmate
      begin
        @b.display_board
        current_move = get_move
        @b.move(current_move.first, current_move.last)
        @b.display_board
        checkmate = @b.in_checkmate?(:white) || @b.in_checkmate?(:black) 
      rescue StandardError => e
        puts e.message
        retry
      end
    end
  end
  
  def get_move
    puts "Enter the x coordinate space you would like to move from:"
    move_from_x = gets.chomp.to_i
    puts "Enter the y coordinate space you would like to move from:"
    move_from_y = gets.chomp.to_i
    puts "Enter the x coordinate space you would like to move to:"
    move_to_x = gets.chomp.to_i
    puts "Enter the y coordinate space you would like to move to:"
    move_to_y = gets.chomp.to_i
    
    move_from = [move_from_x, move_from_y]
    move_to = [move_to_x, move_to_y]
    
    [move_from, move_to]
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
  
  def display_board
    checker = false
    @board.each do |row|
      checker = !checker
      row.each do |space|
        if space == nil
          print  "▓" + " " if checker
          print  "▢" + " " if !checker
        else
          print "#{space.inspect} "
        end
        checker = !checker
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
      if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
        moves_arr << [@x_pos, @y_pos + 2] if self.position == @first_pos 
        moves_arr << [@x_pos, @y_pos + 1]
      end
    else
      deltas = CARDINALS[3..4]
      moves_arr += check_for_enemies(:white, deltas)
      new_pos = [@x_pos, @y_pos - 1] 
      if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
        moves_arr << [@x_pos, @y_pos - 2] if self.position == @first_pos 
        moves_arr << new_pos
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
        if @board[[new_x, new_y]].color == color 
          moves_arr << [new_x, new_y]
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
    

if __FILE__  == $PROGRAM_NAME
  g = Game.new
end
