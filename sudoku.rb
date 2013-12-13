require 'sinatra'
require_relative 'lib/sudoku'
require_relative 'lib/cell'

enable :sessions

def random_sudoku
	#use 9 numbers 1-9 and 72 zeros
	#this avoids clashes as all numbers are unique
	seed = (1..9).to_a.shuffle + Array.new(81-9, 0)
	sudoku = Sudoku.new(seed.join)
	#then we solve this (super hard) Sudoku
	sudoku.solve!
	#and convert it back to a string of characters for transmission
	sudoku.to_s.chars
end

def puzzle(sudoku)
	#This method should remove some digits to create a solvable sudoku
	n = 40
	all_digits = (0..80).to_a
	removal_digits = []
	n.times do
		all_digits = all_digits.shuffle
		removal_digits << all_digits.first
		all_digits = all_digits - [all_digits.first]
	end
	removal_digits.each do |value|
		sudoku[value] = ""
	end
	return sudoku
end

def box_order_to_row_order(cells)
	#break cells into 9 rows of 9
	boxes = cells.each.slice(9).to_a
	#using an array of indices to understand how the data lies
	(0..8).to_a.inject([]) {|memo, i|
	first_box_index = (i/3) *3
	three_boxes = boxes[first_box_index, 3]
	three_rows_of_three = three_boxes.map do |box|
		row_number_in_a_box = i % 3
		first_cell_in_the_row_index = row_number_in_a_box * 3
		box[first_cell_in_the_row_index, 3]
	end
	memo += three_rows_of_three.flatten
	}
end

def generate_new_puzzle_if_necessary
	return if session[:current_solution]
	sudoku = random_sudoku
	session[:solution] = sudoku
	session[:puzzle] = puzzle(sudoku)
	session[:current_solution] = session[:puzzle]
end

def prepare_to_check_solution
	@check_solution = session[:check_solution]
	session[:check_solution] = nil
end

helpers do
	def colour_class(solution_to_check, puzzle_value, current_solution_value, solution_value)
		must_be_guessed = puzzle_value == 0
		tried_to_guess = current_solution_value.to_i != 0
		guessed_incorrectly = current_solution_value != solution_value
		if solution_to_check &&
			must_be_guessed &&
			tried_to_guess &&
			guessed_incorrectly
			'incorrect'
		elsif !must_be_guessed
			'value_provided'
		end
	end

	def cell_value(value)
		value.to_i == 0 ? '' : value
	end

end



get '/' do #this is the default route for the website
	prepare_to_check_solution
	generate_new_puzzle_if_necessary
	@current_solution = session[:current_solution] || session[:puzzle]
	@solution = session[:solution]
	@puzzle = session[:puzzle]	
	erb :index
end

post '/' do
	#cells in HTML are ordered box by box
	#so the form data params['cell'] is sent using this order
	#However, our code expects it to be row by row
	#so we need to transform it
	cells = params["cell"]
	session[:current_solution] = cells.map{|value| value.to_i}.join
	session[:check_solution] = true
	redirect to('/')
end

get '/solution' do #shows the answer to the user if needed
	@current_solution = session[:solution]
	@solution = session[:solution]
	@puzzle = session[:puzzle]
	erb :index
end
