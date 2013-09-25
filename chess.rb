require 'colorize'

class Piece
  attr_accessor :board, :color, :display_char

  def initialize(board, color, display_char)
    @board = board
    @color = color
    @display_char = display_char
  end

  def to_s
    @display_char.send(@color)
  end

  def move(old_pos, new_pos)
    if valid_move?(old_pos, new_pos)
      @board.board_map[old_pos[0]][old_pos[1]] = nil
      @board.board_map[new_pos[0]][new_pos[1]] = self
    end
    nil
  end

  def valid_move?(old_pos, new_pos)
    self.piece_can_move_there?(@board.board_map, old_pos, new_pos) &&
    !@board.check?(self.color, old_pos, new_pos)
  end
end

class SlidingPiece < Piece

  def piece_can_move_there?(board, old_pos, new_pos)
    delta = [new_pos[0]-old_pos[0],new_pos[1]-old_pos[1]]
    bigger = (delta.map { |el| el.abs }).max
    delta.map! { |el| el / bigger.to_f }
    return false if !self.class::MOVE_DIRS.include?(delta)
    !crash?(board, old_pos, new_pos, delta)
  end

  def crash?(board, old_pos, new_pos, delta)
    pos = [old_pos[0]+delta[0],old_pos[1]+delta[1]]
    until pos == new_pos
      return true if board[pos[0]][pos[1]].is_a?(Piece)
      pos = [pos[0]+delta[0],pos[1]+delta[1]]
    end
    false
  end
end

class SteppingPiece < Piece
  def piece_can_move_there?(board, old_pos, new_pos)
    self.class::DELTAS.include?([new_pos[0]-old_pos[0],new_pos[1]-old_pos[1]])
  end
end

class Pawn < Piece

  GREEN_DELTAS = [[2,0],[1,0],[1,-1],[1,1]]
  WHITE_DELTAS = [[-2,0],[-1,0],[-1,-1],[-1,1]]

  def initialize(board, color)
    super(board, color, [9817].pack('U*'))
  end

  def piece_can_move_there?(board, old_pos, new_pos)
    delta = [new_pos[0]-old_pos[0],new_pos[1]-old_pos[1]]
    if self.color == :green
      return false if !GREEN_DELTAS.include?(delta)
      case delta
      when GREEN_DELTAS[0]
        one_ahead = [old_pos[0]+1,old_pos[1]]
        return board[one_ahead[0]][one_ahead[1]].nil? &&
               board[new_pos[0]][new_pos[1]].nil?
      when GREEN_DELTAS[1]
        return board[new_pos[0]][new_pos[1]].nil?
      else
        return board[new_pos[0]][new_pos[1]].color == :white
      end
    else #color is white
      return false if !WHITE_DELTAS.include?(delta)
      case delta
      when WHITE_DELTAS[0]
        one_ahead = [old_pos[0]-1,old_pos[1]]
        return board[one_ahead[0]][one_ahead[1]].nil? &&
               board[new_pos[0]][new_pos[1]].nil?
      when WHITE_DELTAS[1]
        return board[new_pos[0]][new_pos[1]].nil?
      else
        return board[new_pos[0]][new_pos[1]].color == :green

      end
    end
  end
end

class Queen < SlidingPiece

  MOVE_DIRS = [[1,1],[1,-1],[-1,1],[-1,-1],[0,-1],[1,0],[0,1],[-1,0]]

  def initialize(board, color)
    super(board, color, [9813].pack('U*'))
  end
end

class Rook < SlidingPiece

  MOVE_DIRS = [[0,-1],[1,0],[0,1],[-1,0]]

  def initialize(board, color)
    super(board, color, [9814].pack('U*'))
  end
end


class Bishop < SlidingPiece

  MOVE_DIRS = [[1,1],[1,-1],[-1,1],[-1,-1]]

  def initialize(board, color)
    super(board, color, [9815].pack('U*'))
  end
end

class King < SteppingPiece

  DELTAS = [[0,1],[1,0],[1,-1],[-1,1],[0,-1],[-1,0],[-1,-1],[1,1]]

  def initialize(board, color)
    super(board, color, [9812].pack('U*'))
  end
end

class Knight < SteppingPiece

  DELTAS = [[2,1],[1,2],[2,-1],[-1,2],[1,-2],[-2,1],[-2,-1],[-1,-2]]

  def initialize(board, color)
    super(board, color, [9816].pack('U*'))
  end
end

class Board
  attr_accessor :board_map

  INIT_POS = [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook]

  def initialize
    @board_map = create_board
  end

  def [](pos)   #this doesn't work yet - we need to figure out why
    @board_map[pos[0]][pos[1]]
  end

  def create_board
    empty_board = Array.new(8) { Array.new(8) }
    empty_board[6].each_index { |index| empty_board[6][index] = Pawn.new(self, :white) }
    empty_board[1].each_index { |index| empty_board[1][index] = Pawn.new(self, :green) }
    empty_board[0].each_index { |index| empty_board[0][index] = INIT_POS[index].new(self, :green) }
    empty_board[7].each_index { |index| empty_board[7][index] = INIT_POS[index].new(self, :white) }
    empty_board
  end

  def show
    @board_map.each_index do |x| # row number
      print "#{8-x} "
      @board_map.each_index do |y| # column number
        print @board_map[x][y].to_s + " "
      end
      print "\n"
    end
    print "  a b c d e f g h\n"
    nil
  end

  def blatantly_illegal?(board, old_pos, new_pos, color)
    !inside_the_board?(old_pos, new_pos) ||
    !my_piece_at_start?(board, old_pos, color) ||
    my_piece_at_end?(board, new_pos, color)
  end

  def inside_the_board?(old_pos, new_pos)
    positions = old_pos + new_pos
    positions.each { |position| return false if position.nil? || !position.between?(0,7)}
    true
  end

  def my_piece_at_start?(board, old_pos, color)
    board[old_pos[0]][old_pos[1]].color == color
  end

  def my_piece_at_end?(board, new_pos, color)
    board[new_pos[0]][new_pos[1]].color == color
  end

  def check?(color, old_pos, new_pos)
    color == :white ? opposite_color = :green : opposite_color = :white
    king_pos = nil

    # duplicate the board
    duped_board = Array.new(8) { Array.new(8) }
    @board_map.each_with_index { |row, index| duped_board[index] = row.dup }

    # do the move on the duplicated board
    duped_board[old_pos[0]][old_pos[1]] = nil
    duped_board[new_pos[0]][new_pos[1]] = @board_map[old_pos[0]][old_pos[1]]

    # find where color's king is - name this king_pos
    duped_board.each_index do |x| # row number
      duped_board.each_index do |y| # column number
        if duped_board[x][y].is_a?(King) && duped_board[x][y].color == color
          king_pos = [x,y]
        end
      end
    end

    # loop through opposite_color's pieces.
    # for each piece, see if it is a legal move to go to king_pos
    # if there is even one piece like this, return true
    duped_board.each_index do |x| # row number
      duped_board.each_index do |y| # column number
        if duped_board[x][y].color == opposite_color
          piece = duped_board[x][y]
          return true if piece.piece_can_move_there?(duped_board,[x,y],king_pos) && !blatantly_illegal?(duped_board, [x,y], king_pos, opposite_color)
        end
      end
    end

    #otherwise, return false: the king is not in check
    false
  end

  def checkmate?(color)
    all_positions = [0,1,2,3,4,5,6,7].product([0,1,2,3,4,5,6,7])
    color == :white ? opposite_color = :green : opposite_color = :white

    # loop through all pieces of color
    @board_map.each_index do |x| # row number
      @board_map.each_index do |y| # column number
        if @board_map[x][y].color == color
          piece = @board_map[x][y]

          possible_new_pos = all_positions.select do |pos| # narrow down only to valid moves
            piece.piece_can_move_there?(@board_map, [x,y], pos) && !blatantly_illegal?(@board_map, [x,y], pos, color)
          end

          possible_new_pos.each do |new_pos|
            return false if !check?(color, [x,y], new_pos)
          end
        end
      end
    end
    true
  end
end

class Game

  CONVERT = {"1" => 7, "2" => 6, "3" => 5, "4" => 4, "5" => 3, "6" => 2, "7" => 1, "8" => 0,
             "a" => 0, "b" => 1, "c" => 2, "d" => 3, "e" => 4, "f" => 5, "g" => 6, "h" => 7}

  def initialize
    @board = Board.new
    @turn = :white
  end

  def play
    until @board.checkmate?(@turn)
      puts "\n"
      @board.show
      puts "\nPlease enter your move. It is #{@turn.to_s}'s turn."
      positions = convert(gets.chomp.split(' '))
      old_pos, new_pos = positions[0], positions[1]
      if @board.blatantly_illegal?(@board.board_map, old_pos, new_pos, @turn) ||
         !@board.board_map[old_pos[0]][old_pos[1]].valid_move?(old_pos, new_pos)
        puts "\nIllegal move."
        next
      end
      @board.board_map[old_pos[0]][old_pos[1]].move(old_pos, new_pos)
      @turn == :white ? @turn = :green : @turn = :white
    end
    @board.show
    @turn == :white ? @turn = :green : @turn = :white
    puts "\nCheckmate! #{@turn.to_s.capitalize} wins!"
    exit
  end

  def convert(positions) #convert user input and indices to ruby-understandable code
    old_pos, new_pos = positions[0], positions[1]
    old_pos = [CONVERT[old_pos[1]], CONVERT[old_pos[0]]]
    new_pos = [CONVERT[new_pos[1]], CONVERT[new_pos[0]]]
    [old_pos, new_pos]
  end
end

class NilClass
  def to_s
    " "
  end

  def color
    :nil
  end
end

game = Game.new
game.play