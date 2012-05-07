
grammar Mql;

options {
	output			= AST;
	ASTLabelType	= CommonTree;
}

tokens {
	SEMI_COLON    	= ';';
	STAR          	= '*';
	BACK_SLASH    	= '\\';
	FORWARD_SLASH 	= '/';
	EQUALS        	= '=';
	NOT_EQUALS    	= '!=';
	COMMA         	= ',';
	MINUS         	= '-';
	GT            	= '>';
	LT            	= '<';
	LT_GT		= '<>';
	GT_EQUALS     	= '>=';
	LT_EQUALS     	= '<=';
	L_PAREN       	= '(';
	R_PAREN       	= ')';
	L_BRACKET     	= '[';
	R_BRACKET     	= ']';
	MATCHES       	= '=~';
	DOT           	= '.';
	TRUE          	= 'true';
	FALSE         	= 'false';
	FROM          	= 'from';
	WHERE         	= 'where';
	SKIP          	= 'skip';
	LIMIT         	= 'limit';
	NOT           	= 'not';
	SELECT       	= 'select';
	DELETE       	= 'delete';
	UPDATE        	= 'update';
	EXPLAIN       	= 'explain';
	HINT          	= 'hint';
	NATURAL       	= 'natural';
	ATOMIC        	= 'atomic';
	INC           	= 'inc';
	UPSERT        	= 'upsert';
	MULTI         	= 'multi';
	UNSET         	= 'unset';
	SET           	= 'set';
	POP           	= 'pop';
	SHIFT         	= 'shift';
	PUSH          	= 'push';
	EACH          	= 'each';
	PULL          	= 'pull';
	RENAME        	= 'rename';
	BITWISE       	= 'bitwise';
	SORT          	= 'sort';
	ASC           	= 'asc';
	DESC          	= 'desc';
	RETURN        	= 'return';
	NEW           	= 'new';
	OLD           	= 'old';
	OR            	= 'or';
	AND           	= 'and';
	ALL		= 'all';
	
	FIND_AND_MODIFY	= 'find and modify';
	FIND_AND_DELETE	= 'find and delete';
	ADD_TO_SET	= 'add to set';
	

	COMMANDS;
	COMMAND;
	ACTION;
	
	ADD_TO_SET_EACH;
	PUSH_ALL;
	PULL_ALL;
	
	CRITERION;
	COMPARE_CRITERION;
	NEGATED_CRITERION;
	DOCUMENT_FUNCTION_CRITERION;
	FIELD_FUNCTION_CRITERION;
	
	CRITERIA;
	CRITERIA_GROUP;
	CRITERIA_GROUP_LIST;
	
	SELECT_ACTION;
	EXPLAIN_ACTION;
	UPDATE_ACTION;
	UPSERT_ACTION;
	FAM_ACTION;
	FAD_ACTION;
	DELETE_ACTION;
	
	FIELD_LIST;
	UPDATE_OPERATIONS;
	
	ARRAY;
	VARIABLE_LIST;
	FUNCTION_CALL;
}

@header {
	package com.googlecode.mjorm.mql;
}

@lexer::header {
	package com.googlecode.mjorm.mql;
}

/** start **/
start
	: c+=command (c+=command)* EOF -> ^(COMMANDS $c+)
	;

/** command **/
command
	: FROM collection_name (WHERE criteria)? action SEMI_COLON? -> ^(COMMAND collection_name criteria? action)
	;

/** criteria **/

criteria
	: c+=criterion (COMMA? c+=criterion)* -> ^(CRITERIA $c+)
	;

criteria_group
	: L_PAREN criteria R_PAREN -> ^(CRITERIA_GROUP criteria)
	;

criteria_group_list
	: L_PAREN c+=criteria_group (COMMA? c+=criteria_group)* -> ^(CRITERIA_GROUP_LIST $c+)
	;

criterion
	: (function_criterion | negated_field_criterion | field_criterion)
	;
	
field_criterion
	: (field_function_criterion | compare_criterion)
	;
		
negated_field_criterion
	: NOT field_criterion -> ^(NEGATED_CRITERION field_criterion)
	;
	
compare_criterion
	: field_name comparison_operator variable_literal -> ^(COMPARE_CRITERION field_name comparison_operator variable_literal)
	;
	
field_function_criterion
	: field_name function_call -> ^(FIELD_FUNCTION_CRITERION function_call?)
	;

function_criterion 
	: function_call -> ^(DOCUMENT_FUNCTION_CRITERION function_call?)
	;

/** hint **/
hint
	: HINT NATURAL -> ^(HINT NATURAL)
	| HINT string -> ^(HINT string)
	| HINT f+=hint_field (COMMA? f+=hint_field)* -> ^(HINT $f+) 
	;

hint_field
	: field_name direction -> ^(field_name direction)
	;

/** action **/
action
	: (select_action | explain_action | delete_action | update_action | fam_action | fad_action)
	;

// explain
explain_action
	: EXPLAIN hint? -> ^(EXPLAIN_ACTION hint?)
	;

// select
select_action
	: SELECT select_fields hint? sort_field_list? pagination? -> ^(SELECT_ACTION select_fields? hint? sort_field_list? pagination?)
	;

select_fields 
	: STAR -> ^(FIELD_LIST STAR)
	| f+=field_name (COMMA? f+=field_name)* -> ^(FIELD_LIST $f+)
	;

pagination
 	: LIMIT s=integer (COMMA e=integer)? -> ^(LIMIT $s $e?)
 	;

// find and modify
fam_action
	: UPSERT? FIND_AND_MODIFY fam_return? update_operation_list SELECT select_fields sort_field_list? -> ^(FAM_ACTION UPSERT? fam_return? update_operation_list select_fields? sort_field_list?)
	;

fam_return
	: (RETURN^ (NEW | OLD))
	;
	
// find and delete
fad_action
	: FIND_AND_DELETE (SELECT select_fields)? sort_field_list? -> ^(FAD_ACTION select_fields? sort_field_list?)
	;

// delete
delete_action
	: ATOMIC? DELETE -> ^(DELETE_ACTION ATOMIC?)
	;

// update
update_action
	: ATOMIC? UPDATE MULTI? update_operation_list -> ^(UPDATE_ACTION ATOMIC? MULTI? update_operation_list)
	| ATOMIC? UPSERT MULTI? update_operation_list -> ^(UPSERT_ACTION ATOMIC? MULTI? update_operation_list)
	;
	
update_operation_list
	: u+=update_operation (COMMA? u+=update_operation)* -> ^(UPDATE_OPERATIONS $u+)
	;

update_operation
	: (
		operation_inc
		| operation_set 
		| operation_unset 
		| operation_push 
		| operation_push_all 
		| operation_add_to_set
		| operation_add_to_set_each
		| operation_pop
		| operation_shift
		| operation_pull
		| operation_pull_all
		| operation_rename
		| operation_bitwise
	)
	;

operation_inc
	: INC^ field_name number
	;
		
operation_set
	: SET^ field_name EQUALS! variable_literal
	;
	
operation_unset
	: UNSET^ field_name
	;
	
operation_push
	: PUSH^ field_name variable_literal
	;
			
operation_push_all
	: PUSH ALL field_name array -> ^(PUSH_ALL field_name array)
	;
			
operation_add_to_set_each
	: ADD_TO_SET field_name EACH array -> ^(ADD_TO_SET_EACH field_name array)
	;

operation_add_to_set
	: ADD_TO_SET^ field_name array
	;
		
operation_pop
	: POP^ field_name variable_literal
	;
	
operation_shift
	: SHIFT^ field_name variable_literal
	;
		
operation_pull
	: PULL^ field_name variable_literal
	;

operation_pull_all
	: PULL ALL field_name array -> ^(PULL_ALL field_name array)
	;

operation_rename
	: RENAME^ field_name field_name
	;

operation_bitwise
	: BITWISE^ (OR | AND) field_name INTEGER
	;
	
/** sort **/
sort_field_list
	: SORT s+=sort_field (COMMA? s+=sort_field)* -> ^(SORT $s+)
	;

sort_field
	: field_name direction
	;

/** general **/

collection_name
	: SCHEMA_IDENTIFIER
	;
		
field_name
	: SCHEMA_IDENTIFIER
	;

field_list
	: f=field_name (COMMA? f=field_name)* -> ^(FIELD_LIST $f+)
	;

function_name
	: SCHEMA_IDENTIFIER | ALL | OR | AND
	;

comparison_operator
	: (MATCHES | EQUALS | NOT_EQUALS | LT_GT | GT | LT | GT_EQUALS | LT_EQUALS)
	;

variable_literal
	: (regex | string | bool | number | array)
	;
		
variable_list
	: v+=variable_literal (COMMA v+=variable_literal)* -> ^(VARIABLE_LIST $v+)
	;

function_call
	: function_name L_PAREN (criteria_group_list| criteria | variable_list)? R_PAREN -> ^(FUNCTION_CALL function_name criteria_group_list? criteria? variable_list?)
	;

integer
	: (SIGNED_INTEGER | INTEGER)
	;

decimal
	: (SIGNED_DECIMAL | DECIMAL)
	;

number
	: (HEX_NUMBER | integer | decimal)
	;
	
direction
	: (ASC | DESC)
	;

array
	: L_BRACKET variable_list? R_BRACKET -> ^(ARRAY variable_list)
	;

regex
	: REGEX
	;

string
	: (DOUBLE_QUOTED_STRING | SINGLE_QUOTED_STRING)
	;

bool
	: (TRUE | FALSE)
	;

/**
 * LEXER RULES
 */

fragment HEX_DIGIT
	: ('0'..'9' | 'a'..'f' | 'A'..'F')
	;

fragment DIGIT
	: ('0'..'9')
	;

fragment SINGLE_QUOTE
	: '\''
	;

fragment DOUBLE_QUOTE
	: '\"'
	;

INTEGER
	: DIGIT+
	;

SIGNED_INTEGER
	: MINUS? DIGIT+
	;

HEX_NUMBER
	: '0' 'x' HEX_DIGIT+
	;

DECIMAL
	: INTEGER (DOT INTEGER)?
	;
	
SIGNED_DECIMAL
	: SIGNED_INTEGER (DOT INTEGER)?
	;
		
SCHEMA_IDENTIFIER
	: ('a'..'z' | 'A'..'Z' | '0'..'9' | '.' | '$' | '_' )+
	;

REGEX
	: FORWARD_SLASH (ESCAPE | ~(BACK_SLASH | FORWARD_SLASH))* FORWARD_SLASH
	;
	
DOUBLE_QUOTED_STRING @init { final StringBuilder buf = new StringBuilder(); }
	: DOUBLE_QUOTE (ESCAPE_EVALUATED[buf] | i = ~(BACK_SLASH | DOUBLE_QUOTE) { buf.appendCodePoint(i); })* DOUBLE_QUOTE { setText(buf.toString()); }
	;
	    
SINGLE_QUOTED_STRING @init { final StringBuilder buf = new StringBuilder(); }
	: '\'' (ESCAPE_EVALUATED[buf] | i = ~(BACK_SLASH | SINGLE_QUOTE) { buf.appendCodePoint(i); })* SINGLE_QUOTE { setText(buf.toString()); }
	;

fragment ESCAPE_EVALUATED[StringBuilder buf]
	: '\\'
	  ( 
		'n'		{buf.append("\n");}
	        | 'r' 		{buf.append("\r");}
	        | 't'		{buf.append("\t");}
	        | 'b'		{buf.append("\b");}
	        | 'f'		{buf.append("\f");}
	        | '"'		{buf.append("\"");}
	        | '\'' 		{buf.append("\'");}
	        | FORWARD_SLASH {buf.append("/"); }
	        | BACK_SLASH 	{buf.append("\\");}
	        | 'u' i=HEX_DIGIT j=HEX_DIGIT k=HEX_DIGIT l=HEX_DIGIT   {setText(i.getText()+j.getText()+k.getText()+l.getText());}
	  )
	;

fragment ESCAPE
	: '\\' ( 'n' | 'r' | 't' | 'b' | 'f' | '"' | '\'' | FORWARD_SLASH | BACK_SLASH | 'u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT)
	;

WHITESPACE
	: ( '\t' | ' ' | '\r' | '\n' )+ {skip();}
	;