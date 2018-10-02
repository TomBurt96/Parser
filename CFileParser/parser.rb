#!/usr/bin/ruby
class Scanner

	#initilizing the Scanner with its variables
	def initialize(file_name)
		@input_file = File.open(file_name)
		@output_file = File.new("outputfile.c", "w")
		@allLines = @input_file.readlines
		@Line = @allLines[0]
		@allLines.shift
	end

	#moves to the next line and detects white space to output an empty line and moves onto the next line
	def nextLine
		@output_file.puts ""
		while (@allLines[0] == "" || @allLines[0] == "\r\n" || @allLines[0] == "\n")
			@output_file.puts ""
			@allLines.shift
		end
		if(@allLines[0]!=nil)
			@Line = @allLines[0]
			@allLines.shift
			checkSpace
		end
	end

	def peekEnd
		return @Line
	end

	def peek
		checkLine
		checkSpace
		return @Line
	end

	def checkSpace
		if(@Line[0] == nil)
		elsif(@Line[0] == " " || @Line[0] == "\t")
			while(@Line[0] == " " || @Line[0] == "\t")
				@output_file.print @Line[0]
				@Line.slice!(0,1)
			end
		else
		end
	end

#prints first character of cur_tok and then deletes the character
	def NextChar
		@output_file.print @Line[0]
		@Line.slice!(0, 1)
	end
#method used to put iterate through a string in the language
	def stringNextChar
		@output_file.print @Line[0]
		@Line.slice!(0, 1)
		checkLine
	end

#changes the name of an identifier, a function or variable
	def changeName
		checkSpace
	end 

#same as match but just with the first characater of cur_tok
	def matchChar(c)
		checkSpace
		checkLine
		raise "rejects wrong match" unless c == @Line[0]
			@Line.slice!(0, 1)
			@output_file.print c
			checkSpace
	end 

#returns the first character of cur_tok string
	def peekChar
		checkLine
		checkSpace
		return @Line[0]
	end

	def peekCh_include_space
		checkLine
		return @Line[0]
	end

#checks if the Line array is empty and needs to be filled
	def checkLine
		if(@Line == "" || @Line == nil || @Line == "\n" || @Line == "\r\n")
			nextLine
		end
	end

	#returns the line array of strings
	def getLine
		return @Line
	end

	def match(tok)
		chars = tok.split("")
		chars.each { |ch|
			matchChar(ch)
		}
		checkSpace
		checkLine
	end

	#checks if the file has been completely run through
	def end?
		if(@allLines.empty?)
			return true
		else
			return false
		end
	end
end

#parser class, does the parsing
class Parser
	#first production of the grammar. Checks for any starting meta_statements, then calls program_tail production
	def program
		if(meta_statement)
			program
		else
			program_tail
		end
	end

#production that get 
	def program_tail
		if(@s.peek[0,3] == "int" || @s.peek[0,4] == "void")
			type_name
			identifier
			data_or_func
			program_tail
		end
	end

	def data_or_func
		if(@s.peekChar == "," || @s.peekChar == ";")
			beginning_data_decls
			@s.matchChar(';')
		elsif(@s.peekChar == "(")
			start_func
		end
	end

	def beginning_data_decls
		@var_counter += 1
		if(@s.peekChar == ',')
			@s.matchChar(',')
			id_list
		end
	end

	def start_func
		@s.matchChar("(")
		parameter_list
		@s.matchChar(")")
		func_follow
		func_list
	end

	def func_list
		if(@s.peek[0,3] == "int" || @s.peek[0,4] == "void")
			func
			func_list
		end
	end	

	def func
		func_decl
		func_follow
	end

	def func_decl
		type_name
		identifier
		@s.matchChar("(")
		parameter_list
		@s.matchChar(")")
	end

	def func_follow
		if(@s.peekChar == ";")
			@s.matchChar(";")
		elsif(@s.peekChar == "{")
			@func_counter += 1
			@s.matchChar("{")
			data_decls
			statements
			@s.matchChar("}")
		else
			raise "Error"
		end			
	end

	def parameter_list
		if(@s.peek[0,4] == "void" || @s.peek[0,3] == "int")
			type_name
			parameter_list_tail
		end
	end

	def parameter_list_tail
		if(@alph.has_key?(@s.peekChar))
			identifier
			non_empty_list
		end
	end

	def non_empty_list
		@s.checkSpace
		if(@s.peekChar == ",")
			@s.matchChar(",")
			type_name
			identifier
			non_empty_list
		end
	end

	def data_decls
		if(@s.peek[0,3] == "int" || @s.peek[0,4] == "void")
			type_name
			id_list
			@s.matchChar(";")
			data_decls
		end
	end

	def type_name
		if(@s.peek[0,4] == "void")
			@s.match("void")
		elsif(@s.peek[0,3] == "int")
			@s.match("int")
		else
			raise "Error"
		end
	end

	def id_list	
		identifier
		@var_counter += 1
		id_list_tail
	end

	def id_list_tail
		if(@s.peekChar == ",")
			@s.matchChar(",")
			identifier
			@var_counter += 1
			id_list_tail
		end
	end

	def statements
		@s.checkLine
		if(@alph.has_key?(@s.peekChar) || @s.peekChar == '#' || @s.peekChar == '<')
			@statement_counter += 1
			statement
			statements
		end
	end

	def statement
		if(@s.peek[0, 6] == "printf")
			print_func_call
		elsif(@s.peek[0,5] == "scanf")
			scan_func_call
		elsif(@s.peek[0,2] == "if")
			if_statement
		elsif(@s.peek[0,5] == "while")
			while_statement
		elsif(@s.peek[0,6] == "return")
			return_statement
		elsif(@s.peek[0,5] == "break")
			break_statement
		elsif(@s.peek[0,8] == "continue")
			continue_statement
		elsif(@alph.has_key?(@s.peekChar) && @s.peekChar != "_")
			exp_statement
		elsif(metastatement)

		else
			raise "Error"
		end
	end

	def exp_statement
		identifier
		assign_or_func
	end

	def assign_or_func
		if(@s.peekChar == "=")
			@s.matchChar("=")
			@s.checkSpace
			expression
			@s.matchChar(";")
		elsif(@s.peekChar == "(")
			@s.matchChar("(")
			@s.checkSpace
			expr_list
			@s.checkSpace
			@s.matchChar(")")
			@s.matchChar(';')
		else
			raise "Error"
		end
	end

	def print_func_call
		@s.match("printf")
		@s.matchChar("(")
		str
		printf_tail
	end

	def printf_tail
		@s.checkSpace
		if(@s.peekChar == ")")
			@s.matchChar(")")
			@s.matchChar(';')
		elsif(@s.peekChar == ",")
			@s.matchChar(",")
			@s.checkSpace
			expression
			@s.matchChar(")")
			@s.matchChar(';')
		else
			raise "Error"
		end
	end

	def scan_func_call
		@s.match("scanf")
		@s.matchChar("(")
		str
		@s.matchChar(",")
		@s.matchChar("&")
		expression
		@s.matchChar(")")
		@s.matchChar(';')
	end

	def expr_list
		if(@alph.has_key?(@s.peekChar))
			non_empty_expr_list
		end
	end

	def non_empty_expr_list
		expression 
		expr_list_tail
	end

	def expr_list_tail
		if(@s.peekChar == ",")
			@s.matchChar(",")
			expression
			expr_list_tail
		end
	end

	def if_statement
		@s.match("if")
		@s.matchChar("(")
		condition_expression
		@s.matchChar(")")
		block_statements
		else_statement
	end

	def else_statement
		if(@s.peek[0,4] == "else")
			@s.match("else")
			block_statements
		end
	end

	def while_statement
		@s.match("while")
		@s.matchChar("(")
		condition_expression
		@s.matchChar(")")
		block_statements
	end

	def return_statement
		@s.match("return")
		return_tail
	end

	def return_tail
		if(@alph.has_key?(@s.peekChar) || @dig.has_key?(@s.peekChar) || @s.peekChar == '(' || @s.peekChar == '-')
			expression
			@s.matchChar(";")
		elsif(@s.peekChar == ';')
			@s.matchChar(';')
		else
			raise "Error"
		end
	end

	def break_statement
		@s.match("break")
		@s.matchChar(';')
	end

	def continue_statement
		@s.match("continue")
		@s.matchChar(';')
	end

	def block_statements
		@s.matchChar('{')
		statements
		@s.matchChar('}')
	end

	def condition_expression
		condition 
		condition_expression_tail
	end

	def condition_expression_tail
		if(@s.peekChar == '&' || @s.peekChar == '|')
			condition_op
			condition
			condition_expression_tail
		end
	end

	def condition_op
		if(@s.peek[0,2] == "&&")
			@s.match("&&")
		elsif(@s.peek[0,2] == "||")
			@s.match("||")
		else
			raise "Error"
		end
	end

	def condition
		expression
		comparison_op
		expression
	end
#comparison operator production
	def comparison_op
		if(@s.peek[0,2] == "==")
			@s.match("==")
		elsif(@s.peekChar == '!')
			@s.match("!=")
		elsif(@s.peekChar == '>')
			@s.matchChar('>')
			inequality_tail
		elsif(@s.peekChar == '<')
			@s.matchChar('<')
			inequality_tail
		else
			raise "Error"
		end
	end

	def inequality_tail
		if(@s.peekChar == '=')
			@s.matchChar('=')
		end
	end

	def expression
		term
		expression_tail
	end

	def expression_tail
		if(@s.peekChar == '+' || @s.peekChar == '-')
			addop
			term
			expression_tail
		end
	end

	def addop
		if(@s.peekChar == '+')
			@s.matchChar('+')
		elsif(@s.peekChar == '-')
			@s.matchChar('-')
		else
			raise "Error"
		end
	end

	def term
		factor
		term_tail
	end

	def term_tail
		if(@s.peekChar == '*' || @s.peekChar == '/')
			mulop
			factor
			term_tail
		end
	end

	def mulop
		if(@s.peekChar == '*')
			@s.matchChar('*')
		elsif(@s.peekChar == '/')
			@s.matchChar('/')
		else
			raise "Error"
		end
	end

	def factor
		if(@alph.has_key?(@s.peekChar))
			identifier
			factor_tail
		elsif(@dig.has_key?(@s.peekChar))
			number
		elsif(@s.peekChar == '-')
			@s.matchChar('-')
			number
		elsif(@s.peekChar == '(')
			@s.matchChar('(')
			expression
			@s.matchChar(')')
		else
			raise "Error"
		end
	end

	def factor_tail
		if(@s.peekChar == '(')
			@s.matchChar('(')
			expr_list
			@s.matchChar(')')
		elsif(@s.peekChar == '[')
			@s.matchChar('[')
			expression
			@s.matchChar(']')
		end
	end

	def identifier
		id
		identifier_tail
	end

	def identifier_tail
		if(@s.peekChar == '[')
			@s.matchChar('[')
			expression
			@s.matchChar(']')
		end
	end

	#function to check if the given token is an identifier
	def id
		letter
		let_or_dig
	end

	def let_or_dig
		if(@alph.has_key?(@s.peekChar))
			letter
			let_or_dig
		elsif(@dig.has_key?(@s.peekChar))
			digit
			let_or_dig
		elsif(@s.peekChar == '_')
			@s.matchChar('_')
			let_or_dig
		end
	end

	#function to check if the current token is a number
	def number
		digit
		number_tail
	end

	def number_tail
		if(@dig.has_key?(@s.peekChar))
			digit
			number_tail
		elsif(@alph.has_key?(@s.peekChar))
			raise "Error"
		end
	end

	#checks if the current token is a letter, if it is returns true, else false
	def letter
		if(@alph.has_key?(@s.peekChar))
			@s.NextChar
		else 
			raise "Error"
		end
	end


#function to check if the current token's beginning character is a digit
	def digit
		if(@dig.has_key?(@s.peekChar))
			@s.NextChar
		else 
			raise "Error"
		end
	end

	def meta_statement
		if(@s.peekChar == '/')
			@s.matchChar('/')
			@s.matchChar('/')
			meta_statement_tail
			return true
		elsif(@s.peekChar == '#')
			@s.matchChar('#')
			meta_statement_tail
			return true
		else
			return false
		end
	end

	def meta_statement_tail
		if(@s.peekEnd != "\n")
			@s.NextChar
			meta_statement_tail
		end
	end

#checks if the token is a string
	def str
		if(@s.peekChar == '"')
			@s.matchChar('"')
			while(@s.peekChar != '"')
				@s.stringNextChar
			end
			@s.matchChar('"')
		else
			raise "Error"
		end
	end

	#the function that is called to start the parser
	def parse(input)
		@s = Scanner.new(input)
		@alph = Hash['a' => nil, 'b' => nil, 'c' => nil, 'd' => nil, 'e' => nil, 'f' => nil, 'g' => nil, 'h' => nil, 'i' => nil, 'j' => nil, 'k' => nil, 'l' => nil, 'm' => nil,  
			'n' => nil, 'o' => nil, 'p' => nil, 'q' => nil, 'r' => nil, 's' => nil, 't' => nil, 'u' => nil, 'v' => nil, 'w' => nil, 'x' => nil, 'y' => nil, 'z' => nil, 
			'A' => nil, 'B' => nil, 'C' => nil, 'D' => nil, 'E' => nil, 'F' => nil, 'G' => nil, 'H' => nil, 'I' => nil, 'J' => nil, 'K' => nil, 'L' => nil, 'M' => nil, 'N' => nil, 
			'O' => nil, 'P' => nil, 'Q' => nil, 'R' => nil, 'S' => nil, 'T' => nil, 'U' => nil, 'V' => nil, 'W' => nil, 'X' => nil, 'Y' => nil, 'Z' => nil]
		@dig = Hash['0' => nil, '1' => nil, '2' => nil, '3' => nil, '4' => nil, '5' => nil, '6' => nil, '7' => nil, '8' => nil, '9' => nil]
		@var_counter = 0
		@func_counter = 0
		@statement_counter = 0
		program
	if @s.end?
        puts "Pass"
        print "Variables: " 
        puts @var_counter
        print "Functions: " 
        puts @func_counter
        print "Statements: " 
        puts @statement_counter
    else
        puts "Error"
    end
	end
end

#takes in arguement from command line and calls parser to start the program
arg = ARGV[0]
p = Parser.new
p.parse(arg)

