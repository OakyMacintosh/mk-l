#!/usr/bin/awk -f

# MK/L Gen 1 Logic Handler Language Implementation
# An AWK-based interpreter with 80s BASIC-style REPL

BEGIN {
    print " __  __ _  __    ___     "
    print "|  \\/  | |/ /   / / |    "
    print "| |\\/| | ' /   / /| |    "
    print "| |  | | . \\  / / | |___ "
    print "|_|  |_|_|\\_\\/_/  |_____|"
    print ""
    print "MK/L Gen 1 Logic Handler Language v1.0"
    print "Type HELP for commands"
    print ""
    
    # Initialize system
    clear_program()
    running = 1
    
    while (running) {
        printf "* "
        if ((getline input) <= 0) break
        process_input(input)
    }
}

function clear_program() {
    delete program
    delete variables
    program_size = 0
    pc = 0  # program counter
}

function process_input(input) {
    # Remove leading/trailing whitespace
    gsub(/^[ \t]+|[ \t]+$/, "", input)
    
    if (input == "") return
    
    # Convert to uppercase for keywords
    upper_input = toupper(input)
    
    # Check for system commands first
    if (upper_input == "LIST") {
        list_program()
        return
    }
    if (upper_input == "RUN" || upper_input == "EXE") {
        run_program()
        return
    }
    if (upper_input == "NEW" || upper_input == "CLEAR") {
        clear_program()
        print "Program cleared."
        return
    }
    if (upper_input == "HELP") {
        show_help()
        return
    }
    if (upper_input == "QUIT" || upper_input == "EXIT") {
        running = 0
        return
    }
    
    # Check if it's a line number (starts with alphanumeric label)
    if (match(input, /^[A-Za-z][0-9]*:/)) {
        # Extract label and command
        label = substr(input, 1, RSTART + RLENGTH - 2)
        command = substr(input, RSTART + RLENGTH)
        gsub(/^[ \t]+/, "", command)  # trim leading whitespace
        
        if (command == "") {
            # Delete line if no command
            delete program[label]
            program_size--
            if (program_size < 0) program_size = 0
        } else {
            # Add or replace line
            if (!(label in program)) program_size++
            program[label] = command
        }
    } else {
        # Immediate mode execution
        execute_statement(input)
    }
}

function list_program() {
    if (program_size == 0) {
        print "No program in memory."
        return
    }
    
    # Sort labels (simple alphanumeric sort)
    n = asorti(program, sorted_labels)
    for (i = 1; i <= n; i++) {
        label = sorted_labels[i]
        printf "  %-4s %s\n", tolower(label), program[label]
    }
}

function run_program() {
    if (program_size == 0) {
        print "No program to run."
        return
    }
    
    # Get sorted list of labels
    n = asorti(program, sorted_labels)
    
    # Execute program
    for (i = 1; i <= n; i++) {
        current_label = sorted_labels[i]
        if (!execute_statement(program[current_label])) {
            break  # END statement or error
        }
    }
}

function execute_statement(stmt) {
    # Remove leading/trailing whitespace
    gsub(/^[ \t]+|[ \t]+$/, "", stmt)
    
    if (stmt == "") return 1
    
    # Convert to uppercase for keyword matching
    upper_stmt = toupper(stmt)
    
    # PRINT statement
    if (match(upper_stmt, /^PRINT[ \t]/)) {
        return exec_print(substr(stmt, 7))
    }
    
    # SET statement (MK/L style: SET X TO value)
    if (match(upper_stmt, /^SET[ \t]/)) {
        return exec_set(substr(stmt, 5))
    }
    
    # LET statement (alternative assignment)
    if (match(upper_stmt, /^LET[ \t]/)) {
        return exec_let(substr(stmt, 5))
    }
    
    # IF statement
    if (match(upper_stmt, /^IF[ \t]/)) {
        return exec_if(substr(stmt, 4))
    }
    
    # INPUT statement
    if (match(upper_stmt, /^IN[ \t]/) || match(upper_stmt, /^INPUT[ \t]/)) {
        return exec_input(stmt)
    }
    
    # REM statement (comment)
    if (match(upper_stmt, /^REM[ \t]/) || match(upper_stmt, /^"/)) {
        return 1  # Comments do nothing
    }
    
    # END statement
    if (upper_stmt == "END") {
        return 0  # Stop execution
    }
    
    # Unknown statement
    print "Syntax error: " stmt
    return 1
}

function exec_print(args) {
    gsub(/^[ \t]+/, "", args)  # trim leading space
    
    if (args == "") {
        print ""
        return 1
    }
    
    # Handle string literals
    if (match(args, /^".*"$/)) {
        # Remove quotes and print
        output = substr(args, 2, length(args) - 2)
        print output
        return 1
    }
    
    # Handle MK/L string syntax: --str-> "content"
    if (match(args, /--str-> *".*"$/)) {
        match(args, /".*"/)
        output = substr(args, RSTART + 1, RLENGTH - 2)
        print output
        return 1
    }
    
    # Handle variable
    var_name = toupper(args)
    if (var_name in variables) {
        print variables[var_name]
    } else {
        print 0  # Uninitialized variables are 0
    }
    
    return 1
}

function exec_set(args) {
    gsub(/^[ \t]+/, "", args)
    
    # Parse: variable TO value
    if (match(toupper(args), /^([A-Z][A-Z0-9]*) +TO +(.+)$/)) {
        var_name = toupper(substr(args, 1, index(toupper(args), " TO ") - 1))
        gsub(/[ \t]+/, "", var_name)
        
        value_part = substr(args, index(toupper(args), " TO ") + 4)
        gsub(/^[ \t]+/, "", value_part)
        
        value = evaluate_expression(value_part)
        variables[var_name] = value
        return 1
    }
    
    print "Syntax error in SET statement"
    return 1
}

function exec_let(args) {
    gsub(/^[ \t]+/, "", args)
    
    # Parse: variable = expression
    if (match(args, /^[A-Za-z][A-Za-z0-9]* *= */)) {
        equals_pos = index(args, "=")
        var_name = toupper(substr(args, 1, equals_pos - 1))
        gsub(/[ \t]+/, "", var_name)
        
        value_part = substr(args, equals_pos + 1)
        gsub(/^[ \t]+/, "", value_part)
        
        value = evaluate_expression(value_part)
        variables[var_name] = value
        return 1
    }
    
    print "Syntax error in LET statement"
    return 1
}

function exec_if(args) {
    gsub(/^[ \t]+/, "", args)
    
    # Simple IF condition THEN action (or $$ for MK/L)
    then_pos = index(toupper(args), " THEN ")
    if (then_pos == 0) {
        then_pos = index(args, " $$ ")
        if (then_pos == 0) {
            print "Syntax error: IF without THEN or $$"
            return 1
        }
        then_len = 4
    } else {
        then_len = 6
    }
    
    condition = substr(args, 1, then_pos - 1)
    action = substr(args, then_pos + then_len)
    
    if (evaluate_condition(condition)) {
        execute_statement(action)
    }
    
    return 1
}

function exec_input(stmt) {
    # Handle both IN and INPUT
    if (match(toupper(stmt), /^IN[ \t]/)) {
        args = substr(stmt, 3)
    } else {
        args = substr(stmt, 6)
    }
    
    gsub(/^[ \t]+/, "", args)
    
    # Parse: variable = IN "prompt" or LET variable = INPUT "prompt"
    if (match(toupper(args), /^LET +([A-Z][A-Z0-9]*) *= *IN +/) || 
        match(toupper(args), /^([A-Z][A-Z0-9]*) *= */) ||
        match(args, /^LET +([A-Za-z][A-Za-z0-9]*) *= *INPUT +/)) {
        
        # Extract variable name
        if (match(args, /LET +([A-Za-z][A-Za-z0-9]*)/)) {
            var_name = toupper(substr(args, RSTART + 4, RLENGTH - 4))
        } else if (match(args, /^([A-Za-z][A-Za-z0-9]*)/)) {
            var_name = toupper(substr(args, RSTART, RLENGTH))
        }
        
        # Extract prompt if any
        prompt = ""
        if (match(args, /"[^"]*"/)) {
            prompt = substr(args, RSTART + 1, RLENGTH - 2)
        }
        
        if (prompt != "") printf "%s", prompt
        
        if ((getline input_value) > 0) {
            # Try to convert to number if possible
            if (input_value ~ /^-?[0-9]+(\.[0-9]+)?$/) {
                variables[var_name] = input_value + 0
            } else {
                variables[var_name] = input_value
            }
        }
        
        return 1
    }
    
    print "Syntax error in INPUT statement"
    return 1
}

function evaluate_expression(expr) {
    gsub(/^[ \t]+|[ \t]+$/, "", expr)
    
    # String literal
    if (match(expr, /^".*"$/)) {
        return substr(expr, 2, length(expr) - 2)
    }
    
    # Number literal
    if (expr ~ /^-?[0-9]+(\.[0-9]+)?$/) {
        return expr + 0
    }
    
    # Variable
    var_name = toupper(expr)
    if (var_name in variables) {
        return variables[var_name]
    }
    
    return 0  # Default for unknown variables
}

function evaluate_condition(cond) {
    gsub(/^[ \t]+|[ \t]+$/, "", cond)
    
    # Handle various comparison operators
    operators[1] = " ?+ "  # MK/L greater than
    operators[2] = " > "
    operators[3] = " < "
    operators[4] = " >= "
    operators[5] = " <= "
    operators[6] = " = "
    operators[7] = " == "
    operators[8] = " <> "
    operators[9] = " != "
    
    for (i = 1; i <= 9; i++) {
        op = operators[i]
        pos = index(cond, op)
        if (pos > 0) {
            left = substr(cond, 1, pos - 1)
            right = substr(cond, pos + length(op))
            
            left_val = evaluate_expression(left)
            right_val = evaluate_expression(right)
            
            if (op == " ?+ " || op == " > ") return left_val > right_val
            if (op == " < ") return left_val < right_val
            if (op == " >= ") return left_val >= right_val
            if (op == " <= ") return left_val <= right_val
            if (op == " = " || op == " == ") return left_val == right_val
            if (op == " <> " || op == " != ") return left_val != right_val
        }
    }
    
    # If no operator found, treat as boolean expression
    return evaluate_expression(cond) != 0
}

function show_help() {
    print "MK/L Commands:"
    print "  LIST          - List program"
    print "  RUN or EXE    - Execute program"
    print "  NEW or CLEAR  - Clear program"
    print "  HELP          - Show this help"
    print "  QUIT or EXIT  - Exit MK/L"
    print ""
    print "MK/L Statements:"
    print "  label: statement         - Add program line"
    print "  PRINT \"text\" or variable  - Output text/variable"
    print "  PRINT --str-> \"text\"     - MK/L string output"
    print "  SET var TO value         - Assign variable (MK/L style)"
    print "  LET var = value          - Assign variable (BASIC style)"
    print "  IF condition $$ action   - Conditional (MK/L style)"
    print "  IF condition THEN action - Conditional (BASIC style)"
    print "  LET var = IN \"prompt\"    - Input with prompt"
    print "  \"comment text            - Comment line"
    print "  END                      - End program"
    print ""
    print "Operators: ?+ (greater), >, <, >=, <=, =, <>, !="
}
