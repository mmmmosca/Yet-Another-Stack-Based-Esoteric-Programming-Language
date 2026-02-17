import sys

TOKENS = [
    "PUSH",         # >  0
    "POP",          # <  1
    "ADD",          # +  2
    "SUB",          # -  3
    "PRINT_CHAR",   # @  4
    "PRINT_NUM",    # %  5
    "INPUT",        # #  6
    "INVERT",       # $  7
    "LOOP_START",   # :  8
    "LOOP_END",     # ;  9
    "COMPARE",      # ?  10
    "DUPLICATE",    # =  11
    "END",          # !  12
    "NUMBER"
]

stack = []

class Lexer:
    def __init__(self, line):
        self.line = line

    def tokenize(self):
        tokenized = []
        i = 0
        l = len(self.line)
        while i < l:
            if self.line[i] == '>':
                tokenized.append(TOKENS[0])
                i += 1
            elif self.line[i] == '<':
                tokenized.append(TOKENS[1])
                i += 1
            elif self.line[i] == '+':
                tokenized.append(TOKENS[2])
                i += 1
            elif self.line[i] == '-':
                tokenized.append(TOKENS[3])
                i += 1
            elif self.line[i] == '@':
                tokenized.append(TOKENS[4])
                i += 1
            elif self.line[i] == '%':
                tokenized.append(TOKENS[5])
                i += 1
            elif self.line[i] == '#':
                tokenized.append(TOKENS[6])
                i += 1
            elif self.line[i] == '$':
                tokenized.append(TOKENS[7])
                i += 1
            elif self.line[i] == ':':
                tokenized.append(TOKENS[8])
                i += 1
            elif self.line[i] == ';':
                tokenized.append(TOKENS[9])
                i += 1
            elif self.line[i] == '?':
                tokenized.append(TOKENS[10])
                i += 1
            elif self.line[i] == '=':
                tokenized.append(TOKENS[11])
                i += 1
            elif self.line[i] == '!':
                tokenized.append(TOKENS[12])
                i += 1
            elif self.line[i].isdigit():
                j = i
                while j < l and self.line[j].isdigit():
                    j += 1
                tokenized.append({TOKENS[-1]: int(self.line[i:j])})
                i = j
            elif self.line[i].isspace():
                i += 1
            else:
                raise Exception(f"Invalid instruction: {self.line[i]}")
        return tokenized

class Parser:
    def __init__(self, token_list):
        self.token_list = token_list

    def parse(self):
        i = 0
        while i < len(self.token_list):
            if self.token_list[i] == TOKENS[0]:
                try:
                    stack.append(self.token_list[i+1][TOKENS[-1]])
                    i+=2
                except:
                    raise Exception(f"Invalid token: {self.token_list[i+1]} is not a number")
            elif self.token_list[i] == TOKENS[1]:
                stack.pop()
                i += 1
            elif self.token_list[i] == TOKENS[2]:
                a = stack.pop()
                b = stack.pop()
                c = a+b
                stack.append(c)
                i+=1
            elif self.token_list[i] == TOKENS[3]:
                a = stack.pop()
                b = stack.pop()
                c = a-b
                stack.append(c)
                i+=1
            elif self.token_list[i] == TOKENS[4]:
                char = stack.pop()
                print(chr(char),end='')
                i+=1
            elif self.token_list[i] == TOKENS[5]:
                print(stack.pop(),end='')
                i+=1
            elif self.token_list[i] == TOKENS[6]:
                user_input = input()
                if user_input:
                    stack.append(ord(user_input[0]))
                i+=1
            elif self.token_list[i] == TOKENS[7]:
                stack.reverse()
                i += 1
            elif self.token_list[i] == TOKENS[8]:
                j = i + 1
                depth = 1
                loop_inst = []
                while j < len(self.token_list) and depth > 0:
                    if self.token_list[j] == TOKENS[8]:
                        depth += 1
                    elif self.token_list[j] == TOKENS[9]:
                        depth -= 1

                    if depth > 0:
                        loop_inst.append(self.token_list[j])
                    j += 1
                
                if depth != 0:
                    raise Exception("Unterminated loop")
                
                while stack and stack[-1] != 0:
                    Parser(loop_inst).parse()
                i = j

            elif self.token_list[i] == TOKENS[10]:
                if len(stack) < 2:
                    raise Exception("COMPARE requires at least two arguments")
                
                a = stack[-1]
                b = stack[-2]
                if a == b:
                    i += 1
                else:
                    if self.token_list[i+1] == TOKENS[8]:
                        j = i+2
                        depth = 1
                        while j < len(self.token_list) and depth > 0:
                            if self.token_list[j] == TOKENS[8]:
                                depth += 1
                            elif self.token_list[j] == TOKENS[9]:
                                depth -= 1

                            j += 1

                        i = j
                    else:
                        i += 2
                continue
            elif self.token_list[i] == TOKENS[11]:
                if stack:
                    stack.append(stack[-1])
                else:
                    raise Exception("DUPLICATE on empty stack")
                i += 1
            elif self.token_list[i] == TOKENS[12]:
                sys.exit()
            else:
                raise Exception(f"Invalid token: {self.token_list[i]}")


with open(sys.argv[1]) as code:
    code = code.readlines()
    for line in code:
        lexer = Lexer(line)
        token_list = lexer.tokenize()
        parser = Parser(token_list)

        parser.parse()

