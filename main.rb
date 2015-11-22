#! /usr/local/bin/ruby

require "gosu"
require "colorize"
require "./circle.rb"
require "./big_letters.rb"

class Hash

  def rand
    a = to_a
    return a[Kernel.rand(a.length)]
  end

end

module MasterMind

WIDTH = 400
HEIGHT = 600

private

class Board

  attr_accessor :guesses

  def initialize(images, big_circle, small_images)
    @images = images
    @small_images = small_images
    @big_circle = big_circle
    @sulution = [images.rand[0], images.rand[0], images.rand[0], images.rand[0]]
    @guesses = [[]]
    @reply_column = [[]]
    @won = false
  end

  def draw
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, 0xff_0033aa)
    #Gosu.draw_line(WIDTH / 2, 0, 0xff_000000, WIDTH / 2, HEIGHT, 0xff_000000) # draw a line down the center
    @sulution.each_with_index do |thing, i|
      @images[thing].draw(i * 60 + WIDTH / 2 - 100, 10, 0)
    end
    if !@won
      Gosu.draw_rect(WIDTH / 2 - 120, 0, 240, 40, 0xff_001188)
    end
    10.times do |y|
      4.times do |x|
        @big_circle.draw(x * 60 + WIDTH / 2 - 105, y * 50 + 100, 0)
      end
    end
    @guesses.each_with_index do |row, row_num|
      row.each_with_index do |item, index|
        @images[item].draw(index * 60 + WIDTH / 2 - 100, HEIGHT - 45 - row_num * 50, 0)if item != nil
      end
    end
    @reply_column.each_with_index do |row, row_num|
      row.each_with_index do |item, item_num|
        @small_images[item].draw(item_num * 15 + 325, HEIGHT - 40 - row_num * 50, 0) if @small_images[item] != nil
        if item == :black
          50.times do
            @small_images[item].draw(item_num * 15 + 325, HEIGHT - 40 - row_num * 50, 0)
          end
        end
      end
    end
    # draw a triangle next too the current row
    Gosu.draw_triangle(60, HEIGHT - 45 - (@guesses.length - 1) * 50, 0xff_000000, 80, HEIGHT - 35 - (@guesses.length - 1) * 50, 0xff_000000, 60, HEIGHT - 25 - (@guesses.length - 1) * 50, 0xff_000000)
  end

  def submit_guess
    if @guesses.last.length < 4
      return nil
    end
    if @guesses.last == @sulution
      @won = true
      return :win
    end
    if @guesses.length == 10
      @won = true
      return :loose
    end
    @guesses.last.each_with_index do |thing, i|
      already_checked_items = []
      if thing == nil
        return nil
      elsif thing == @sulution[i]
        @reply_column.last.push :black
        already_checked_items.push thing
      end
      @sulution.each_with_index do |item, item_num|
        if thing == item && !already_checked_items.include?(item)
          if i != item_num
            @reply_column.last.push :white
          end
        end
        already_checked_items.push item
      end
    end
    @guesses.push []
    @reply_column.push []
    nil
  end

end

class Menu

  def initialize(images)
    @images = images
  end

  def draw(x, y)
    @images.to_a.each_with_index do |arr, num|
      arr[1].draw(35, num * 50 + 155, 0) # x and y are top left of circle
      #Gosu.draw_rect(35, num * 50 + 155, 10, 10, 0xff_000000)
    end
    if @thing_in_hand != nil
      @images[@thing_in_hand].draw(x - 10, y - 10, 0)
    end
  end

  def click(x, y, board)
    if @thing_in_hand == nil
      if x > 35 && x < 55
        if y > 155 && y < 175 # on :red
          @thing_in_hand = :red
        elsif y > 205 && y < 225 # on :yellow
          @thing_in_hand = :yellow
        elsif y > 255 && y < 275 # on :green
          @thing_in_hand = :green
        elsif y > 305 && y < 325 # on :turquoise
          @thing_in_hand = :turquoise
        elsif y > 355 && y < 375 # on :purple
          @thing_in_hand = :purple
        elsif y > 405 && y < 425 # on :white
          @thing_in_hand = :white
        end
      end
    else
      guesses = board.guesses
      if y > HEIGHT - (((guesses.length - 1) * 50) + 45) && y < HEIGHT - (((guesses.length - 1) * 50) + 25) # on current row (or not)
        num = nil
        if x > WIDTH / 2 - 100 && x < WIDTH / 2 - 100 + 20
          num = 0
        elsif x > WIDTH / 2 - 100 + 60 && x < WIDTH / 2 - 100 + 80
          num = 1
        elsif x > WIDTH / 2 - 100 + 120 && x < WIDTH / 2 - 100 + 140
          num = 2
        elsif x > WIDTH / 2 - 100 + 180 && x < WIDTH / 2 - 100 + 200
          num = 3
        end
        if num != nil
          board.guesses.last[num] = @thing_in_hand
          @thing_in_hand = nil
        end
      end
    end
  end

end

public

class Screen < Gosu::Window

  def initialize
    super WIDTH, HEIGHT
    self.caption = "Master Mind"
    @images = {:red       => Gosu::Image.new(self, Circle.new(10, 255, 0, 0), false),
               :yellow    => Gosu::Image.new(self, Circle.new(10, 255, 255, 0), false),
               :green     => Gosu::Image.new(self, Circle.new(10, 0, 255, 0), false),
               :turquoise => Gosu::Image.new(self, Circle.new(10, 0, 255, 255), false),
               :purple    => Gosu::Image.new(self, Circle.new(10, 255, 0, 255), false),
               :white     => Gosu::Image.new(self, Circle.new(10, 255, 255, 255), false)}
    @small_images = {:black => Gosu::Image.new(self, Circle.new(5, 11, 0, 0), false),
                     :white => Gosu::Image.new(self, Circle.new(5, 255, 255, 255), false)}
    @board = Board.new(@images, Gosu::Image.new(self, Circle.new(15, 50, 0, 0), false), @small_images)
    @menu = Menu.new(@images)
  end

  def draw
    @board.draw
    @menu.draw(mouse_x, mouse_y)
  end

  def button_down(id)
    if id == Gosu::MsLeft
      @menu.click(mouse_x, mouse_y, @board)
    elsif id == Gosu::KbReturn
      var = @board.submit_guess
      if var == :win
        puts big_string("You Win!!!").green
        puts
      elsif var == :loose
        puts big_string("You Lost").red
        puts
      end
    elsif id == Gosu::KbR
      @board = Board.new(@images, Gosu::Image.new(self, Circle.new(15, 50, 0, 0), false), @small_images)
      @menu = Menu.new(@images)
    end
  end

  def needs_cursor?
    true
  end

end

end

MasterMind::Screen.new.show