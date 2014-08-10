# encoding: UTF-8
require './board'
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
  end

  def move_into_check?(pos)
    new_board = @board.dup
    new_board.move!([@x_pos, @y_pos], pos)
    new_board.in_check?(@color)
  end

  def valid_moves
    @moves_arr.reject { |to_pos| move_into_check?(to_pos) }
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
    @moves_arr = []
    valid_arr.each do |move|
      dx = move.first
      dy = move.last
      new_pos = [@x_pos + dx, @y_pos + dy]
      if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
        if @board[new_pos] != nil
          @moves_arr << new_pos if @board[new_pos].color != @color
        else
          @moves_arr << new_pos
        end
      end
    end
    @moves_arr
  end
end

class SlidingPiece < Piece
  def initialize(position, board, color)
    super
  end

  def moves(valid_dir)
    @moves_arr = []
    valid_dir.each do |dir|
      stop_n = 8
      (1...stop_n).each do |n|
        dx = dir.first * n
        dy = dir.last * n
        new_pos = [@x_pos + dx, @y_pos + dy]
        if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
          if @board[new_pos] != nil
            @moves_arr << new_pos if @board[new_pos].color != @color
            stop_n = n
            break
          else
            @moves_arr << new_pos
          end
        end
      end
    end
    @moves_arr
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
    @moves_arr = []
    if self.color == :white
      deltas = CARDINALS.take(2)
      @moves_arr += check_for_enemies(:black, deltas)
      new_pos = [@x_pos, @y_pos + 1]
      new_pos2 = [@x_pos, @y_pos + 2]
      if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
        @moves_arr <<  new_pos if @board[new_pos] == nil
      end
      if new_pos2.first.between?(0,7) && new_pos2.last.between?(0,7)
        if self.position == @first_pos && @board[new_pos] == nil
          @moves_arr << new_pos2 if @board[new_pos2] == nil
        end
      end
    else
      deltas = CARDINALS[2..3]
      @moves_arr += check_for_enemies(:white, deltas)
      new_pos =  [@x_pos, @y_pos - 1]
      new_pos2 = [@x_pos, @y_pos - 2]
      if new_pos.first.between?(0,7) && new_pos.last.between?(0,7)
        @moves_arr << new_pos if @board[new_pos] == nil
      end
      if new_pos2.first.between?(0,7) && new_pos2.last.between?(0,7)
        if self.position == @first_pos && @board[new_pos] == nil
          @moves_arr << new_pos2 if @board[new_pos2] == nil
        end
      end
    end
    @moves_arr
  end

  def check_for_enemies(color, deltas)
    @moves_arr = []
    deltas.each do |delta|
      new_x = @x_pos + delta.first
      new_y = @y_pos + delta.last
      unless @board[[new_x, new_y]].nil?
        if new_x.between?(0,7) && new_y.between?(0,7)
          if @board[[new_x, new_y]].color == color
            @moves_arr << [new_x, new_y]
          end
        end
      end
    end
    @moves_arr
  end
  def inspect
    return "♙" if @color == :black
    "♟" if @color == :white
  end

end
