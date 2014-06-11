# encoding: UTF-8 
###require 'debugger'

class Board
  def initialize(board = Array.new(8) { Array.new(8) {nil}})
    @board = board
  end
  
  def pieces(color)
    @board.flatten.select { |x| x.color == color unless x.nil? }
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
  
  def in_check?(color)
    k_pos = pieces(color).select {|p| p.is_a?(King)}.last.position
    other_color = (color == :white ? :black : :white)
    pieces(other_color).any? { |piece| piece.moves.include?(k_pos) }
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
        raise "Can't move there."
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
      else
        raise "Can't move there."
      end
    else
      raise "No piece"
    end
  end
  
  def dup
    new_board = Board.new()
    @board.each_with_index do |row, i|
      row.each_with_index do |piece, j|
        next if piece.nil?
        new_board[[j, i]] = piece.class.new(piece.position, new_board,                                                                      piece.color)
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
    @character = "C"
  end
  
  def moves
    super(CARDINALS.drop(4))
  end
  
  def inspect
    "C"
  end
end

class Pawn < SteppingPiece
  
  def initialize(position, board, color)
    super
    @character = "P"
    @first_move = true
  end
  
  def moves()
    moves_arr = []
    if self.color == :white
      deltas = CARDINALS.take(2)
      moves_arr += check_for_enemies(:white, deltas)
      moves_arr << [0, @y_pos + 2] if @first_move
      moves_arr << [0, @y_pos + 1] 
    else
      deltas = CARDINALS[3..4]
      moves_arr += check_for_enemies(:black, deltas)
      moves_arr << [0, @y_pos - 2] if @first_move
      moves_arr << [0, @y_pos - 1] 
    end
    @first_move = false
    moves_arr
  end
  
  def check_for_enemies(color, deltas)
    o_color = (color == :white ? :black : :white)
    moves_arr = []
    deltas.each do |delta|
      new_x = @x_pos + delta.first
      new_y = @y_pos + delta.last
      unless @board[[new_x, new_y]].nil?
        if @board[[new_x, new_y]].color == o_color 
          moves_arr << [new_x, new_y]
        end
      end
    end
    moves_arr
  end
  def inspect
    "P"
  end
  
end
    

if __FILE__  == $PROGRAM_NAME
  b = Board.new
  white_k = King.new([3,0], b, :white)
  white_b = Bishop.new([2,0], b, :white)
  white_p = Pawn.new([0,1], b, :white)
  
  black_k = King.new([3,7], b, :black)
  black_b = Bishop.new([2,7], b, :black)
  b.display_board
  #b.move([3,0], [4,0])
  b.display_board
  b.move([2,7], [5,4])
  b.move([3,0], [2,1])
  b.display_board
end
