grammar Modern;

options 
{
    output			= AST;
    language		= C;
	ASTLabelType	= pANTLR3_BASE_TREE;
}

tokens 
{
    VAR_DEF;
    ARG_DEF;
    FUNC_HDR;
    FUNC_DECL;
    FUNC_DEF;
    BLOCK;
    ASSIGNMENT;
    COND;
    MULTIPLY;
    ADDITION;
}

@header
{
   #define _empty NULL
}

program
    :   declaration+
    ;

declaration
    :   variableDeclaration
    |   functionHeader block -> ^(FUNC_DEF functionHeader block)
    ;

variableDeclaration
    :   type declarator ';'	-> ^(VAR_DEF type declarator)
    ;

declarator
    :   ID 
    ;

functionHeader
    :   type ID '(' ( formalParameter ( ',' formalParameter )* )? ')'

				-> ^(FUNC_HDR type ID formalParameter+)
    ;

formalParameter
    :   type declarator 
				-> ^(ARG_DEF type declarator)
    ;

type
    :   'int'   
    |   'char'  
    |   'void'
    |   ID
    |	{false}? NeverUsedRule
    ;

block
    :   lc='{'
            variable*
            statement*
        '}'
        -> ^(BLOCK[$lc, "BLOCK"] variable* statement*)
    ;

statement
	: forStatement
    | expression ';'
    | block
    | assignStatement ';'
    | ';'
    ;

forStatement
    :   'for' '(' start=assignStatement ';' e=expression ';' next=assignStatement ')' block
        -> ^('for' $start $e $next block)
    ;

assignStatement
    :	ID EQ expression -> ^(ASSIGNMENT ID expression)
    ;

expression
	:	comparisonExpression
    ;

comparisonExpression
    :   aexpr (comparisonOperator aexpr)?  -> ^(COND aexpr (comparisonOperator aexpr)?)
    ;

comparisonOperator
	:	OPLT | EQEQ 
    |	{false}? NeverUsedRule	
	;

aexpr
    :   mexpr  ('+' mexpr)*  -> ^(ADDITION mexpr  ('+' mexpr)*)
    ;

mexpr
    :   atom ('*' atom)* -> ^(MULTIPLY atom ('*' atom)*)
    ;
    
atom
    : ID      
    | INT      
    | '(' expression ')' -> expression
    ; 
    

NeverUsedRule: /* don't care*/ ;

FOR : 'for' ;
INT_TYPE : 'int' ;
CHAR_TYPE: 'char';
VOID_TYPE: 'void';

ID  :   ('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
    ;

INT :	('0'..'9')+
    ;

EQ   : '=' ;
EQEQ : '==' ;
OPLT   : '<' ;
PLUS : '+' ;

WS  :   (   ' '
        |   '\t'
        |   '\r'
        |   '\n'
        )+
        { $channel=HIDDEN; }
    ; 