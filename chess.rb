# encoding: UTF-8 

class Board
  def initialize
    @board = Array.new(8) { Array.new(8) {nil}}
  end
  
  def pieces(color)
    @board.flatten.select { |x| x.color == color }
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
  end
  
  def [](pos_arr)
    @board[pos_arr.last][pos_arr.first]
  end
  
  def []=(pos_arr, piece)
    @board[pos_arr.last][pos_arr.first] = piece
    piece.position(pos_arr)
  end
  
  def in_check?(color)
    check_color = {:white => white_pieces}
  end
end

class Piece
  attr_accessor :x_pos, :y_pos, :color
  
  CARDINALS = [ [ 1,  1],
                [-1, -1],
                [ 1, -1],
                [-1,  1],
                [ 0,  1],
                [ 0, -1],
                [ 1,  0],
                [-1,  0]]
                
                
                

  def initialize(position, board, color)
    @board = board
    @x_pos = position.first
    @y_pos = position.last
    @color = color
    @board[position] = self
  end
  
  def position(position)
    @x_pos = position.first
    @y_pos = position.last
  end
  
  def moves
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
    puts "sliding"
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
  end
  
  def inspect
    "K"
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
    "N"
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
    "Q"
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
    "B"
  end
end

class Castle < SlidingPiece
             
  def initialize(position, board, color)
    super
    @charcter = "C"
  end
  
  def moves
    super(CARDINALS.drop(4))
  end
  
  def inspect
    "C"
  end
end



