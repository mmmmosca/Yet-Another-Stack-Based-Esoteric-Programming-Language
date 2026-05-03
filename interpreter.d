import core.stdc.stdlib : exit;
import std;
import std.ascii : isDigit, isWhite;

enum TokenKind {
    PUSH,         // > 0
    POP,          // < 1
    ADD,          // + 2
    SUB,          // - 3
    PRINT_CHAR,   // @ 4
    PRINT_NUM,    // % 5
    INPUT_STRING, // # 6
    INPUT_NUM,    // ^ 7
    INVERT,       // $ 8
    LOOP_START,   // : 9
    LOOP_END,     // ; 10
    COMPARE,      // ? 11
    DUPLICATE,    // = 12
    END,          // ! 13
    CLEAR,        // & 14
    NUMBER
}

struct Token {
    TokenKind kind;
    int value;
}

int[] stack;

class Lexer {
    string line;
    this(string line) {
        this.line = line;
    }

    Token[] tokenize() {
        Token[] tokenized;
        size_t i = 0;
        size_t l = this.line.length;

        while (i < l) {
            char ch = this.line[i];
            switch (ch) {
                case '>':
                    tokenized ~= Token(TokenKind.PUSH, 0);
                    i++;
                    break;
                case '<':
                    tokenized ~= Token(TokenKind.POP, 0);
                    i++;
                    break;
                case '+':
                    tokenized ~= Token(TokenKind.ADD, 0);
                    i++;
                    break;
                case '-':
                    tokenized ~= Token(TokenKind.SUB, 0);
                    i++;
                    break;
                case '@':
                    tokenized ~= Token(TokenKind.PRINT_CHAR, 0);
                    i++;
                    break;
                case '%':
                    tokenized ~= Token(TokenKind.PRINT_NUM, 0);
                    i++;
                    break;
                case '#':
                    tokenized ~= Token(TokenKind.INPUT_STRING, 0);
                    i++;
                    break;
                case '^':
                    tokenized ~= Token(TokenKind.INPUT_NUM, 0);
                    i++;
                    break;
                case '$':
                    tokenized ~= Token(TokenKind.INVERT, 0);
                    i++;
                    break;
                case ':':
                    tokenized ~= Token(TokenKind.LOOP_START, 0);
                    i++;
                    break;
                case ';':
                    tokenized ~= Token(TokenKind.LOOP_END, 0);
                    i++;
                    break;
                case '?':
                    tokenized ~= Token(TokenKind.COMPARE, 0);
                    i++;
                    break;
                case '=':
                    tokenized ~= Token(TokenKind.DUPLICATE, 0);
                    i++;
                    break;
                case '!':
                    tokenized ~= Token(TokenKind.END, 0);
                    i++;
                    break;
                case '&':
                    tokenized ~= Token(TokenKind.CLEAR, 0);
                    i++;
                    break;
                default:
                    if (isDigit(ch)) {
                        size_t j = i;
                        while (j < l && isDigit(this.line[j])) {
                            j++;
                        }
                        int value = to!int(this.line[i .. j]);
                        tokenized ~= Token(TokenKind.NUMBER, value);
                        i = j;
                    } else if (isWhite(ch)) {
                        i++;
                    } else {
                        throw new Exception("Invalid instruction: " ~ to!string(ch));
                    }
            }
        }

        return tokenized;
    }
}

class Parser {
    Token[] tokenList;
    this(Token[] tokenList) {
        this.tokenList = tokenList;
    }

    private size_t instructionWidth(size_t index) {
        if (index >= tokenList.length) {
            return 0;
        }

        switch (tokenList[index].kind) {
            case TokenKind.PUSH:
                if (index + 1 >= tokenList.length || tokenList[index + 1].kind != TokenKind.NUMBER) {
                    throw new Exception("Invalid token: PUSH requires a number");
                }
                return 2;
            case TokenKind.NUMBER:
                throw new Exception("Invalid token in parse stream");
            default:
                return 1;
        }
    }

    void parse() {
        size_t i = 0;
        while (i < tokenList.length) {
            auto tok = tokenList[i];
            final switch (tok.kind) {
                case TokenKind.PUSH:
                    if (i + 1 >= tokenList.length || tokenList[i + 1].kind != TokenKind.NUMBER) {
                        throw new Exception("Invalid token: PUSH requires a number");
                    }
                    stack ~= tokenList[i + 1].value;
                    i += 2;
                    break;
                case TokenKind.POP:
                    if (stack.length == 0) {
                        throw new Exception("POP on empty stack");
                    }
                    stack.popBack();
                    i++;
                    break;
                case TokenKind.ADD: {
                    if (stack.length < 2) {
                        throw new Exception("ADD requires at least two arguments");
                    }
                    int a = stack[$ - 1];
                    int b = stack[$ - 2];
                    stack.popBack();
                    stack.popBack();
                    stack ~= a + b;
                    i++;
                    break;
                }
                case TokenKind.SUB: {
                    if (stack.length < 2) {
                        throw new Exception("SUB requires at least two arguments");
                    }
                    int a = stack[$ - 1];
                    int b = stack[$ - 2];
                    stack.popBack();
                    stack.popBack();
                    stack ~= a - b;
                    i++;
                    break;
                }
                case TokenKind.PRINT_CHAR:
                    if (stack.length == 0) {
                        throw new Exception("PRINT_CHAR on empty stack");
                    }
                    stdout.write(cast(char) stack[$ - 1]);
                    stack.popBack();
                    i++;
                    break;
                case TokenKind.PRINT_NUM:
                    if (stack.length == 0) {
                        throw new Exception("PRINT_NUM on empty stack");
                    }
                    stdout.write(stack[$ - 1]);
                    stack.popBack();
                    i++;
                    break;
                case TokenKind.INPUT_STRING: {
                    auto line = readln();
                    line = line[0..$-1].dup.reverse;
                    foreach (char key; line) {
                        stack ~= cast(ubyte) key;
                    }
                    i++;
                    break;
                }
                case TokenKind.INPUT_NUM: {
                    auto line = readln();
                    auto result = line[0..$-1].to!int;
                    stack ~= result;
                    i++;
                    break;
                }
                case TokenKind.INVERT:
                    stack.reverse();
                    i++;
                    break;
                case TokenKind.LOOP_START: {
                    size_t j = i + 1;
                    int depth = 1;
                    Token[] loopInst;
                        while (j < tokenList.length && depth > 0) {
                            auto t = tokenList[j];
                            if (t.kind == TokenKind.LOOP_START) {
                                depth++;
                            } else if (t.kind == TokenKind.LOOP_END) {
                            depth--;
                        }
                        if (depth > 0) {
                            loopInst ~= t;
                        }
                        j++;
                    }
                    if (depth != 0) {
                        throw new Exception("Unterminated loop");
                    }
                    while (stack.length > 0 && stack[$ - 1] != 0) {
                        auto loopParser = new Parser(loopInst);
                        loopParser.parse();
                    }
                    i = j;
                    break;
                }
                case TokenKind.COMPARE:
                    if (stack.length < 2) {
                        throw new Exception("COMPARE requires at least two arguments");
                    }
                    int a = stack[$ - 1];
                    int b = stack[$ - 2];
                    if (a == b) {
                        i++;
                    } else {
                        if (i + 1 < tokenList.length && tokenList[i + 1].kind == TokenKind.LOOP_START) {
                            size_t j = i + 2;
                            int depth = 1;
                            while (j < tokenList.length && depth > 0) {
                                auto t = tokenList[j];
                                if (t.kind == TokenKind.LOOP_START) {
                                    depth++;
                                } else if (t.kind == TokenKind.LOOP_END) {
                                    depth--;
                                }
                                j++;
                            }
                            i = j;
                        } else {
                            i += 1 + instructionWidth(i + 1);
                        }
                    }
                    break;
                case TokenKind.DUPLICATE:
                    if (stack.length == 0) {
                        throw new Exception("DUPLICATE on empty stack");
                    }
                    stack ~= stack[$ - 1];
                    i++;
                    break;
                case TokenKind.END:
                    writeln(stack);
                    exit(0);
                case TokenKind.CLEAR:
                    stack = null;
                    i++;
                    break;
                case TokenKind.LOOP_END:
                case TokenKind.NUMBER:
                    throw new Exception("Invalid token in parse stream");
            }
        }
    }
}

void main(string[] args) {
    if (args.length < 2) {
        writeln("Usage: interpreter <program file>");
        return;
    }

    string code = readText(args[1]);
    Token[] tokenList;
    foreach (line; code.splitLines()) {
        Lexer lexer = new Lexer(line);
        tokenList ~= lexer.tokenize();
    }
    Parser parser = new Parser(tokenList);
    parser.parse();
}
