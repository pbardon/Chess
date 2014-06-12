# encoding: UTF-8 
require './piece'

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
  
  def display_board(cursor_pos, selection = nil)
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
        elsif [j,i] == selection
          if space == nil
            print  "▓" + " " if checker
            print  "▢" + " " if !checker
          else
            print "#{space.inspect} ".red
          end
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
    if pieces(other_color).any? { |piece| piece.moves.include?(k_pos) }
      puts "In check" 
    end
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
                            piece.position.dup,
                            new_board,                                                                      piece.color
                            )
      end
    end
    new_board
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
  
  def red
    colorize(31)
  end
end