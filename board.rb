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
    king = pieces(color).find { |p| p.is_a?(King) }
    king || (raise 'king not found')
  end
  
  def in_check?(color)
    k_pos = get_king(color).position
    other_color = (color == :white ? :black : :white)
    pieces(other_color).any? { |piece| piece.moves.include?(k_pos) unless piece.moves.nil? }
  end
  
  def in_checkmate?(color)
    return false unless in_check?(color)
    pieces(color).all? do |piece|
      piece.moves.empty?
    end
  end
  
  def move(start_pos, end_pos)
    piece = self[start_pos]
    unless piece.nil?
      moves = piece.moves
      if moves.include?(end_pos)
        puts "hello 1"
        piece.valid_moves
        if piece.move_into_check?(end_pos)
          puts "hello 2"
          raise StandardError.new "This move would put you in check"
        else
           move!(start_pos, end_pos)
        end
      else
        raise StandardError.new "Can't move there."
      end
    else
      raise StandardError.new "No piece"
    end
  end
  
  def move!(start_pos, end_pos)
    piece = self[start_pos]
    moves = piece.moves
    if moves.include?(end_pos)
      self[end_pos] = piece
      self[start_pos] = nil
      piece.set_position(end_pos)
      
    end
    nil
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