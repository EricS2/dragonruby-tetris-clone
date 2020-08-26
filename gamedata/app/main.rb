$gtk.reset
class TetrisGame
  def initialize args
    @args = args
    @next_piece = nil
    @next_move = 30
    @score = 0
    @gameover = false
    @grid_w = 10
    @grid_h = 20
    @grid = []
    for x in 0..@grid_w-1 do
      @grid[x] = []
      for y in 0..@grid_h-1 do
        @grid[x][y] = 0
      end
    end
    @color_index = [
      [0,0,0],
      [255,0,0],
      [0,255,0],
      [0,0,255],
      [255,255,0],
      [255,0,255],
      [0,255,255],
      [127,127,127]
    ]
    select_next_piece
    select_next_piece

  end

  # x e y são posições na array. não em pixels.
  def render_cube x, y, color
    boxsize = 30
    grid_x = (1280- (@grid_w * boxsize)) / 2
    grid_y = (720- ((@grid_h-2) * boxsize)) / 2
    @args.outputs.solids << [grid_x + (x*boxsize),(720 - grid_y) - (y * boxsize),boxsize,boxsize,*@color_index[color]]
    @args.outputs.borders << [grid_x + (x*boxsize),(720 - grid_y) - (y * boxsize),boxsize,boxsize,50,50,50,255]
  end

  def render_grid
    for x in 0..@grid_w-1 do
      for y in 0..@grid_h-1 do
        render_cube  x, y, @grid[x][y] if @grid[x][y] != 0
      end
    end
  end
  def render_grid_border x,y,w,h
    color = 7
    for i in x..(x+w)-1 do
      render_cube i, y, color
      render_cube i, (y+h)-1, color
    end
    for i in y..(y+h)-1 do
      render_cube x,i, color
      render_cube (x+w)-1,i, color
    end
  end

  def render_background
    @args.outputs.sprites << [75,300,300,300,'console-logo.png']
    @args.outputs.solids << [0,0,1280,720,0,0,0]
    render_grid_border -1, -1, @grid_w + 2,@grid_h + 2
  end
  
  def render_piece piece, piece_x, piece_y
    for x in 0..piece.length-1 do
      for y in 0..piece[x].length-1 do
        render_cube piece_x + x, piece_y + y, piece[x][y] if piece[x][y] != 0
      end
    end
  end

  def render_current_piece 
    render_piece @current_piece, @current_piece_x, @current_piece_y
  end

  def render_next_piece 
    #PARA ARRRUMAR!!!! tirar o hardcode daqui
    render_grid_border 13,2,8,8
    centerx = (8-@next_piece.length)/2
    centery = (8-@next_piece[0].length)/2
    render_piece @next_piece, 13 + centerx, 2 + centery
    @args.outputs.labels << [890, 640, "Próxima peça",10,255,255,255,255]
  end

  def render_score
  @args.outputs.labels << [75,75, "Score: #{@score}",10,255,255,255,255]
  @args.outputs.labels << [200, 450, "GAME OVER",100,255,255,255,255] if @gameover
  end

  def render
    render_background
    render_grid
    render_next_piece
    render_current_piece
    render_score
  end

  def current_piece_colliding
    for x in 0..@current_piece.length-1 do
      for y in 0..@current_piece[x].length-1 do
        if (@current_piece[x][y] != 0) 
          if (@current_piece_y + y  >= @grid_h-1)
            return true
          elsif (@grid[@current_piece_x + x][@current_piece_y + y + 1] != 0)
            return true 
          end
        end
      end
    end
    return false
  end

  def select_next_piece
    @current_piece = @next_piece
    X = rand(6) + 1
    @next_piece = case X
    when 0 then [[0,X],[0,X],[X,X]]
    when 1 then [[X,X],[0,X],[0,X]]
    when 2 then [[X,X,X,X]]
    when 3 then [[X,0],[X,X],[0,X]]
    when 4 then [[0,X],[X,X],[X,0]]
    when 5 then [[X,X],[X,X]]
    when 6 then [[0,X],[X,X],[0,X]]
    end
    @current_piece_x = 5
    @current_piece_y = 0
  end

  def plant_current_piece
    #fazer parte da tela do jogo
    for x in 0..@current_piece.length-1 do
      for y in 0..@current_piece[x].length-1 do
        if @current_piece[x][y] != 0
          @grid[@current_piece_x + x][@current_piece_y+y] = @current_piece[x][y]
        end
      end
    end
    #verificar linhas para serem limpas
    for y in 0..@grid_h-1
      full = true
      for x in 0..@grid_w-1
        if @grid[x][y] == 0
          full = false
          break
        end
      end
      if full #limpeza
        @score += 1
        for i in y.downto(1) do
          for j in 0..@grid_w-1
          @grid[j][i]= @grid[j][i-1]
          end
        end
        for i in 0..@grid_w-1
          @grid[i][0] = 0
        end
      end
    end

    select_next_piece
    if current_piece_colliding
    @gameover = true
    end
  end

  def rotate_current_piece_left
   @current_piece = @current_piece.transpose.map(&:reverse)
    if (@current_piece_x + @current_piece.length >= @grid_w)
      @current_piece_x = @grid_w - @current_piece.length
    end
  end

  def rotate_current_piece_right
    @current_piece = @current_piece.transpose.map(&:reverse)
    @current_piece = @current_piece.transpose.map(&:reverse)
    @current_piece = @current_piece.transpose.map(&:reverse)
    if (@current_piece_x + @current_piece.length >= @grid_w)
      @current_piece_x = @grid_w - @current_piece.length
    end
  end

  def iterate
    k = @args.inputs.keyboard
    c = @args.inputs.controller_one
    if @gameover
      if k.key_down.space || c.key_down.start
        $gtk.reset
      end
      return
    end
    #check inputs
    if k.key_down.left || c.key_down.left
      if @current_piece_x > 0
        @current_piece_x -= 1
      end
    end
    if k.key_down.right || c.key_down.right
      if (@current_piece_x + @current_piece.length) < @grid_w 
      @current_piece_x += 1
      end
    end

    if k.key_down.down || k.key_held.down || c.key_down.down || c.key_held.down 
      @next_move -= 10
    end

    if k.key_down.a || c.key_down.a
      rotate_current_piece_left
    end
    if k.key_down.d || c.key_down.b
      rotate_current_piece_right
    end
    @next_move -= 1
    if @next_move <= 0 #peça cai
      if current_piece_colliding
          plant_current_piece
      else
        @current_piece_y += 1
      end
      @next_move = 30
    end
  end

  def tick
    iterate
    render
  end
end

def tick args
  args.state.game ||= TetrisGame.new args
  args.state.game.tick
end
 