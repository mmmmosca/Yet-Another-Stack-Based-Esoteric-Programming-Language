use std::{io::{self, Write}, process::exit, env, fs};


#[derive(Clone)]
enum TokenId {
    Push,
    Pop,
    Add,
    Sub,
    PrintChar,
    PrintNum,
    Input,
    Invert,
    LoopStart,
    LoopEnd,
    Compare,
    Duplicate,
    End,
    Number
}

#[derive(Clone)]
#[allow(dead_code)]
struct Token {
    id: TokenId,
    num: Option<i32>
}

struct Lexer {
    line: String
}

fn make_token(id: TokenId) -> Token {
    Token { id, num: None }
}

impl Lexer {

    fn tokenize(self) -> Vec<Token>{
        let mut tokenized: Vec<Token> = Vec::new();
        let mut i = 0;

        let chars: Vec<char> = self.line.chars().collect();
        while i < chars.len() {
            let c = chars[i];
            match c {
                '>' => tokenized.push(make_token(TokenId::Push)),
                '<' => tokenized.push(make_token(TokenId::Pop)),
                '+' => tokenized.push(make_token(TokenId::Add)),
                '-' => tokenized.push(make_token(TokenId::Sub)),
                '@' => tokenized.push(make_token(TokenId::PrintChar)),
                '%' => tokenized.push(make_token(TokenId::PrintNum)),
                '#' => tokenized.push(make_token(TokenId::Input)),
                '$' => tokenized.push(make_token(TokenId::Invert)),
                ':' => tokenized.push(make_token(TokenId::LoopStart)),
                ';' => tokenized.push(make_token(TokenId::LoopEnd)),
                '?' => tokenized.push(make_token(TokenId::Compare)),
                '=' => tokenized.push(make_token(TokenId::Duplicate)),
                '!' => tokenized.push(make_token(TokenId::End)),
                _ => (),
            }
            
            if c.is_numeric() {
                let mut j: usize = i;
                while j < self.line.len() && self.line.chars().nth(j).unwrap().is_numeric(){
                    j += 1;
                }
                let slice = self.line.get(i..j).expect("slice out of bounds");
                let result: i32 = slice.parse().expect("not a number");
                tokenized.push(Token { id: TokenId::Number, num: Some(result)});

                i = j;
                continue;
            }


            i += 1;
        }

        return tokenized;
    }
}

struct Parser {
    token_list: Vec<Token>
}

impl Parser {
    fn parse(&mut self, stack: &mut Vec<i32>) {
        let tokens: Vec<Token> = self.token_list.clone();
        let mut i = 0;
        while i < tokens.len() {
            match tokens[i].id {
                TokenId::Push => {
                    let next: &Token = &tokens[i+1];
                    stack.push(next.num.unwrap());
                    i += 2;
                },
                TokenId::Pop => {
                    stack.pop();
                    i += 1;
                },
                TokenId::Add => {
                    let a = stack.pop().unwrap();
                    let b = stack.pop().unwrap();
                    let c = a+b;
                    stack.push(c);
                    i += 1;
                },
                TokenId::Sub => {
                    let a = stack.pop().unwrap();
                    let b = stack.pop().unwrap();
                    let c = a-b;
                    stack.push(c);
                    i += 1;
                },
                TokenId::PrintChar => {
                    let ch: i32 = stack.pop().unwrap();
                    print!("{}", ch as u8 as char);
                    io::stdout().flush().unwrap();
                    i += 1;
                },
                TokenId::PrintNum => {
                    let ch: i32 = stack.pop().unwrap();
                    print!("{}", ch);
                    io::stdout().flush().unwrap();
                    i += 1;
                },
                TokenId::Input => {
                    let mut s = String::new();
                    std::io::stdin().read_line(&mut s).unwrap();
                    let ascii = s.as_bytes().get(0).copied();

                    stack.push(ascii.unwrap() as i32);
                    i += 1;
                },
                TokenId::Invert => {
                    stack.reverse();
                    i += 1;
                },
                TokenId::LoopStart => {
                    let mut j = i + 1;
                    let mut depth: i32 = 1;
                    let mut loop_inst: Vec<Token> = Vec::new();

                    while j < tokens.len() && depth > 0 {
                        match tokens[j].id {
                            TokenId::LoopStart => depth += 1,
                            TokenId::LoopEnd => depth -= 1,
                            _ => ()
                        }

                        if depth > 0 {
                            loop_inst.push(tokens[j].clone());
                        }

                        j += 1;
                    }

                    let mut loop_parser: Parser = Parser { token_list: loop_inst };

                    while !stack.is_empty() && stack[stack.len() - 1] != 0{
                        loop_parser.parse(stack);
                    }

                    i = j;
                },
                TokenId::Compare => {
                    if stack.len() < 2 {
                        println!("Compare needs at least two elements");
                        exit(1);
                    }

                    let a = stack[stack.len() - 1];
                    let b = stack[stack.len() - 2];

                    if a == b {
                        i += 1;
                    } else {
                        let next: Option<&Token> = self.token_list.get(i+1);
                        match next.unwrap().id {
                            TokenId::LoopStart => {
                                let mut j = i + 2;
                                let mut depth = 1;
                                while j < self.token_list.len() && depth > 0 {
                                    match self.token_list[j].id {
                                        TokenId::LoopStart => depth += 1,
                                        TokenId::LoopEnd => depth -= 1,
                                        _ => ()
                                    }
                                    j += 1;
                                }
                                i = j;
                            },
                            _ => i += 2
                        }
                    }
                    continue;
                },
                TokenId::Duplicate => {
                    if let Some(&last) = stack.last() {
                        stack.push(last);
                    } else {
                        println!("Duplicate on empty stack");
                        exit(1);
                    }
                    i += 1;
                },
                TokenId::End => exit(0),

                _ => ()
            }
        }
    }
}

fn main() -> io::Result<()> {
    let mut args = env::args();
    let _exe = args.next();
    let filename = match args.next() {
        Some(f) => f,
        None => {
            eprintln!("usage: bolaga_rust <file>");
            return Ok(());
        }
    };

    let code = fs::read_to_string(&filename)?;
    let lexer = Lexer { line: code };
    let tokens = lexer.tokenize();
    let mut parser = Parser { token_list: tokens };
    let mut stack: Vec<i32> = Vec::new();
    parser.parse(&mut stack);
    Ok(())
}
