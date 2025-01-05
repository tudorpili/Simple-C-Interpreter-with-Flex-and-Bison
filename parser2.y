%{
    using namespace std;
    #include<iostream>
    #include <stdio.h>
    #include <string.h>
    #include<map>
    #include<vector>
    #include"enum.h"
    extern FILE *yyin;
    int yylex();
    int yyerror(const char *msg);
    int EsteCorecta = 1;
    char msg[500];

struct Function{
    Type returnType;
    vector<pair<string,Type>> parameters;
    vector<string> code;
};


struct Variable{
    Type type;
    union {
        int intVal;
        float floatVal;
        double doubleVal;
    } value;
    bool initialized;
};

map<string,Variable> symbolTable;
map<string,Function> functionTable;
vector<string>codeOutput;

%}

%locations

%union{
    char *id;
    char *sir;
    int intVal;
    float floatVal;
    double doubleVal;
    struct {
        Type type;
        union {
            int intVal;
            float floatVal;
            double doubleVal;
        } value;
    } exprValue;
    bool boolVal;

}
    
%token TOK_INT TOK_FLOAT TOK_DOUBLE TOK_RETURN
%token TOK_IF TOK_ELSE TOK_WHILE
%token TOK_PRINTF TOK_SCANF TOK_COMMA TOK_AMPERSAND
%token TOK_PLUS TOK_MINUS TOK_MULTIPLY TOK_DIVIDE
%token TOK_LEFT TOK_RIGHT TOK_LBRACE TOK_RBRACE 
%token TOK_GT TOK_LT TOK_GE TOK_LE TOK_EQ TOK_NE TOK_AND TOK_OR
%token TOK_ERROR
%token TOK_CAST_INT TOK_CAST_FLOAT TOK_CAST_DOUBLE

%token <intVal> TOK_NUMBER_INT
%token <floatVal> TOK_NUMBER_FLOAT
%token <doubleVal> TOK_NUMBER_DOUBLE

%token <id> TOK_ID
%token <sir> TOK_STRING

%type <exprValue> expr
%type <exprValue> condition



%nonassoc LOWER_THAN_ELSE
%nonassoc TOK_ELSE

%left TOK_PLUS TOK_MINUS
%left TOK_MULTIPLY TOK_DIVIDE
%right TOK_CAST_INT TOK_CAST_FLOAT TOK_CAST_DOUBLE

%left TOK_OR
%left TOK_AND
%left TOK_EQ TOK_NE
%left TOK_LT TOK_LE TOK_GT TOK_GE

%start program


%%


program:
        | program statement //global_statement
        ;


statement:
        declaration ';'
        | assignment ';'
        | if_statement
        | while_statement
        | io_statement ';'
        | compound_statement
        ;

compound_statement:
    TOK_LBRACE program TOK_RBRACE
    ;

declaration:
    TOK_INT TOK_ID {
        if(symbolTable.find($2) == symbolTable.end()) {
            symbolTable[$2] = {INT, {.intVal = 0}, false};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $2);
            yyerror(msg);
        }
    }
    | TOK_INT TOK_ID '=' expr {
        if(symbolTable.find($2) == symbolTable.end()) {
            symbolTable[$2] = {INT, {.intVal = $4.value.intVal}, true};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $2);
            yyerror(msg);
        }
    }
    | TOK_FLOAT declaration_float
    | TOK_DOUBLE declaration_double
    ;


declaration_float:
    TOK_ID {
        if(symbolTable.find($1) == symbolTable.end()) {
            symbolTable[$1] = {FLOAT, {.floatVal = 0.0f}, false};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        }
    }
    | TOK_ID '=' expr {
        if(symbolTable.find($1) == symbolTable.end()) {
            float value;
            switch($3.type) {
                case INT:
                    value = (float)$3.value.intVal;
                    break;
                case FLOAT:
                    value = $3.value.floatVal;
                    break;
                case DOUBLE:
                    value = (float)$3.value.doubleVal;
                    break;
            }
            symbolTable[$1] = {FLOAT, {.floatVal = value}, true};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        
        }
    }
    ;

declaration_double:
    TOK_ID {
        if(symbolTable.find($1) == symbolTable.end()) {
            symbolTable[$1] = {DOUBLE, {.doubleVal = 0.0}, false};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        }
    }
    | TOK_ID '=' expr {
        if(symbolTable.find($1) == symbolTable.end()) {
            double value;
            switch($3.type) {
                case INT:
                    value = (double)$3.value.intVal;
                    break;
                case FLOAT:
                    value = (double)$3.value.floatVal;
                    break;
                case DOUBLE:
                    value = $3.value.doubleVal;
                    break;
            }
            symbolTable[$1] = {DOUBLE, {.doubleVal = value}, true};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        }
    }
    ;

assignment:
    TOK_ID '=' expr {
        auto it = symbolTable.find($1);
        if(it == symbolTable.end()) {
            sprintf(msg,"%d:%d Eroare semantica: Variabila nu a fost declarata %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        }
        
        // Type conversion and assignment based on variable type
        switch(it->second.type) {
            case INT:
                switch($3.type) {
                    case INT:
                        it->second.value.intVal = $3.value.intVal;
                        break;
                    case FLOAT:
                        it->second.value.intVal = (int)$3.value.floatVal;
                        break;
                    case DOUBLE:
                        it->second.value.intVal = (int)$3.value.doubleVal;
                        break;
                }
                break;
                
            case FLOAT:
                switch($3.type) {
                    case INT:
                        it->second.value.floatVal = (float)$3.value.intVal;
                        break;
                    case FLOAT:
                        it->second.value.floatVal = $3.value.floatVal;
                        break;
                    case DOUBLE:
                        it->second.value.floatVal = (float)$3.value.doubleVal;
                        break;
                }
                break;
                
            case DOUBLE:
                switch($3.type) {
                    case INT:
                        it->second.value.doubleVal = (double)$3.value.intVal;
                        break;
                    case FLOAT:
                        it->second.value.doubleVal = (double)$3.value.floatVal;
                        break;
                    case DOUBLE:
                        it->second.value.doubleVal = $3.value.doubleVal;
                        break;
                }
                break;
        }
        it->second.initialized = true;
    }
    ;


/*if_statement:
    TOK_IF TOK_LEFT condition TOK_RIGHT statement %prec LOWER_THAN_ELSE
    | TOK_IF TOK_LEFT condition TOK_RIGHT statement TOK_ELSE statement 
    ;*/

if_statement:
    TOK_IF TOK_LEFT condition TOK_RIGHT statement %prec LOWER_THAN_ELSE
    {
        if ($3.boolVal) {
            // Execute the 'if' block only if the condition is true
            $$.value=$5.value

        }
    }
    | TOK_IF TOK_LEFT condition TOK_RIGHT statement TOK_ELSE statement
    {
        if ($3.boolVal) {
            // Execute the 'if' block
            $$.value=$5.value

        } else {
            // Execute the 'else' block
            $$.value=$7.value

        }
    }
    ;


while_statement:
    TOK_WHILE TOK_LEFT condition TOK_RIGHT statement
    ;


io_statement:
    TOK_PRINTF TOK_LEFT TOK_STRING TOK_RIGHT {

        printf("%s",$3);
    }
    | TOK_PRINTF TOK_LEFT TOK_STRING TOK_COMMA expr TOK_RIGHT {
        // Handle different format specifiers based on expr type
        switch($5.type) {
            case INT:
                printf($3, $5.value.intVal);
                break;
            case FLOAT:
                printf($3, $5.value.floatVal);
                break;
            case DOUBLE:
                printf($3, $5.value.doubleVal);
                break;
        }
    }
    | TOK_SCANF TOK_LEFT TOK_STRING TOK_COMMA TOK_AMPERSAND TOK_ID TOK_RIGHT {
        auto it = symbolTable.find($6);
        if(it != symbolTable.end()) {
            switch(it->second.type) {
                case INT:
                    scanf($3, &it->second.value.intVal);
                    break;
                case FLOAT:
                    scanf($3, &it->second.value.floatVal);
                    break;
                case DOUBLE:
                    scanf($3, &it->second.value.doubleVal);
                    break;
            }
            it->second.initialized = true;
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Variabila nu a fost declarata %s!", @1.first_line, @1.first_column, $6);
            yyerror(msg);
        }
    }
    ;



/*condition:
    expr TOK_GT expr { $$ = ($1 > $3); }
    | expr TOK_LT expr { $$ = ($1 < $3); }
    | expr TOK_GE expr { $$ = ($1 >= $3); }
    | expr TOK_LE expr { $$ = ($1 <= $3); }
    | expr TOK_EQ expr { $$ = ($1 == $3); } 
    | expr TOK_NE expr { $$ = ($1 != $3); } 
    | condition TOK_AND condition { $$ = ($1 && $3); }
    | condition TOK_OR condition { $$ = ($1 || $3); }
    ;*/
condition:
    expr TOK_GT expr {
        if ($1.type == INT && $3.type == INT) {
            $$.boolVal = ($1.value.intVal > $3.value.intVal);
        } else if ($1.type == FLOAT && $3.type == FLOAT) {
            $$.boolVal = ($1.value.floatVal > $3.value.floatVal);
        } else if ($1.type == DOUBLE && $3.type == DOUBLE) {
            $$.boolVal = ($1.value.doubleVal > $3.value.doubleVal);
        }
    }
    | expr TOK_LT expr {
        if ($1.type == INT && $3.type == INT) {
            $$.boolVal = ($1.value.intVal < $3.value.intVal);
        } else if ($1.type == FLOAT && $3.type == FLOAT) {
            $$.boolVal = ($1.value.floatVal < $3.value.floatVal);
        } else if ($1.type == DOUBLE && $3.type == DOUBLE) {
            $$.boolVal = ($1.value.doubleVal < $3.value.doubleVal);
        }
    }
    | expr TOK_GE expr {
        if ($1.type == INT && $3.type == INT) {
            $$.boolVal = ($1.value.intVal >= $3.value.intVal);
        } else if ($1.type == FLOAT && $3.type == FLOAT) {
            $$.boolVal = ($1.value.floatVal >= $3.value.floatVal);
        } else if ($1.type == DOUBLE && $3.type == DOUBLE) {
            $$.boolVal = ($1.value.doubleVal >= $3.value.doubleVal);
        }
    }
    | expr TOK_LE expr {
        if ($1.type == INT && $3.type == INT) {
            $$.boolVal = ($1.value.intVal <= $3.value.intVal);
        } else if ($1.type == FLOAT && $3.type == FLOAT) {
            $$.boolVal = ($1.value.floatVal <= $3.value.floatVal);
        } else if ($1.type == DOUBLE && $3.type == DOUBLE) {
            $$.boolVal = ($1.value.doubleVal <= $3.value.doubleVal);
        }
    }
    | expr TOK_EQ expr {
        if ($1.type == INT && $3.type == INT) {
            $$.boolVal = ($1.value.intVal == $3.value.intVal);
        } else if ($1.type == FLOAT && $3.type == FLOAT) {
            $$.boolVal = ($1.value.floatVal == $3.value.floatVal);
        } else if ($1.type == DOUBLE && $3.type == DOUBLE) {
            $$.boolVal = ($1.value.doubleVal == $3.value.doubleVal);
        }
    }
    | expr TOK_NE expr {
        if ($1.type == INT && $3.type == INT) {
            $$.boolVal = ($1.value.intVal != $3.value.intVal);
        } else if ($1.type == FLOAT && $3.type == FLOAT) {
            $$.boolVal = ($1.value.floatVal != $3.value.floatVal);
        } else if ($1.type == DOUBLE && $3.type == DOUBLE) {
            $$.boolVal = ($1.value.doubleVal != $3.value.doubleVal);
        }
    }
    | condition TOK_AND condition { $$.boolVal = ($1.boolVal && $3.boolVal); }
    | condition TOK_OR condition { $$.boolVal = ($1.boolVal || $3.boolVal); }
    ;



/*expr:
    TOK_NUMBER_INT { 
        $$.type = INT;
        $$.value.intVal = $1;
    }
    | TOK_NUMBER_FLOAT {
        $$.type = FLOAT;
        $$.value.floatVal = $1;
    }
    | TOK_NUMBER_DOUBLE {
        $$.type = DOUBLE;
        $$.value.doubleVal = $1;
    }
    | TOK_ID {
        auto it = symbolTable.find($1);
        if(it != symbolTable.end()) {
            if(!it->second.initialized) {
                sprintf(msg,"%d:%d Eroare semantica: Se utilizeaza o variabila neinitializata %s!", @1.first_line, @1.first_column, $1);
                yyerror(msg);
                //yyerror("Use of uninitialized variable");
            }
            switch(it->second.type) {
                case INT:
                    $$.type = INT;
                    $$.value.intVal = it->second.value.intVal;
                    break;
                case FLOAT:
                    $$.type = FLOAT;
                    $$.value.floatVal = it->second.value.floatVal;
                    break;
                case DOUBLE:
                    $$.type = DOUBLE;
                    $$.value.doubleVal = it->second.value.doubleVal;
                    break;
            }
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Variabila nu a fost declarata %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
            //yyerror("Variable not declared");
        }
    }
    | expr TOK_PLUS expr
    | expr TOK_MINUS expr
    | expr TOK_MULTIPLY expr
    | expr TOK_DIVIDE expr
    | TOK_LEFT expr TOK_RIGHT { $$ = $2; }
    ;
    */

expr:
    TOK_NUMBER_INT { 
        $$.type = INT;
        $$.value.intVal = $1;
    }
    | TOK_NUMBER_FLOAT {
        $$.type = FLOAT;
        $$.value.floatVal = $1;
    }
    | TOK_NUMBER_DOUBLE {
        $$.type = DOUBLE;
        $$.value.doubleVal = $1;
    }
    | TOK_ID {
        auto it = symbolTable.find($1);
        if(it != symbolTable.end()) {
            if(!it->second.initialized) {
                sprintf(msg,"%d:%d Eroare semantica: Se utilizeaza o variabila neinitializata %s!", @1.first_line, @1.first_column, $1);
                yyerror(msg);
            }
            switch(it->second.type) {
                case INT:
                    $$.type = INT;
                    $$.value.intVal = it->second.value.intVal;
                    break;
                case FLOAT:
                    $$.type = FLOAT;
                    $$.value.floatVal = it->second.value.floatVal;
                    break;
                case DOUBLE:
                    $$.type = DOUBLE;
                    $$.value.doubleVal = it->second.value.doubleVal;
                    break;
            }
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Variabila nu a fost declarata %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        }
    }
    | expr TOK_PLUS expr {
        // Type promotion rules for addition
        if($1.type == DOUBLE || $3.type == DOUBLE) {
            $$.type = DOUBLE;
            double val1 = ($1.type == INT) ? $1.value.intVal : 
                         ($1.type == FLOAT) ? $1.value.floatVal : $1.value.doubleVal;
            double val2 = ($3.type == INT) ? $3.value.intVal : 
                         ($3.type == FLOAT) ? $3.value.floatVal : $3.value.doubleVal;
            $$.value.doubleVal = val1 + val2;
        }
        else if($1.type == FLOAT || $3.type == FLOAT) {
            $$.type = FLOAT;
            float val1 = ($1.type == INT) ? $1.value.intVal : $1.value.floatVal;
            float val2 = ($3.type == INT) ? $3.value.intVal : $3.value.floatVal;
            $$.value.floatVal = val1 + val2;
        }
        else {
            $$.type = INT;
            $$.value.intVal = $1.value.intVal + $3.value.intVal;
        }
    }
    | expr TOK_MINUS expr {
        // Type promotion rules for subtraction
        if($1.type == DOUBLE || $3.type == DOUBLE) {
            $$.type = DOUBLE;
            double val1 = ($1.type == INT) ? $1.value.intVal : 
                         ($1.type == FLOAT) ? $1.value.floatVal : $1.value.doubleVal;
            double val2 = ($3.type == INT) ? $3.value.intVal : 
                         ($3.type == FLOAT) ? $3.value.floatVal : $3.value.doubleVal;
            $$.value.doubleVal = val1 - val2;
        }
        else if($1.type == FLOAT || $3.type == FLOAT) {
            $$.type = FLOAT;
            float val1 = ($1.type == INT) ? $1.value.intVal : $1.value.floatVal;
            float val2 = ($3.type == INT) ? $3.value.intVal : $3.value.floatVal;
            $$.value.floatVal = val1 - val2;
        }
        else {
            $$.type = INT;
            $$.value.intVal = $1.value.intVal - $3.value.intVal;
        }
    }
    | expr TOK_MULTIPLY expr {
        // Type promotion rules for multiplication
        if($1.type == DOUBLE || $3.type == DOUBLE) {
            $$.type = DOUBLE;
            double val1 = ($1.type == INT) ? $1.value.intVal : 
                         ($1.type == FLOAT) ? $1.value.floatVal : $1.value.doubleVal;
            double val2 = ($3.type == INT) ? $3.value.intVal : 
                         ($3.type == FLOAT) ? $3.value.floatVal : $3.value.doubleVal;
            $$.value.doubleVal = val1 * val2;
        }
        else if($1.type == FLOAT || $3.type == FLOAT) {
            $$.type = FLOAT;
            float val1 = ($1.type == INT) ? $1.value.intVal : $1.value.floatVal;
            float val2 = ($3.type == INT) ? $3.value.intVal : $3.value.floatVal;
            $$.value.floatVal = val1 * val2;
        }
        else {
            $$.type = INT;
            $$.value.intVal = $1.value.intVal * $3.value.intVal;
        }
    }
    | expr TOK_DIVIDE expr {
        // Check for division by zero
        bool isZero = false;
        switch($3.type) {
            case INT: isZero = ($3.value.intVal == 0); break;
            case FLOAT: isZero = ($3.value.floatVal == 0.0f); break;
            case DOUBLE: isZero = ($3.value.doubleVal == 0.0); break;
        }
        if(isZero) {
            sprintf(msg, "%d:%d Eroare semantica: Impartire la zero!", @2.first_line, @2.first_column);
            yyerror(msg);
            YYERROR;
        }

        // Type promotion rules for division
        if($1.type == DOUBLE || $3.type == DOUBLE) {
            $$.type = DOUBLE;
            double val1 = ($1.type == INT) ? $1.value.intVal : 
                         ($1.type == FLOAT) ? $1.value.floatVal : $1.value.doubleVal;
            double val2 = ($3.type == INT) ? $3.value.intVal : 
                         ($3.type == FLOAT) ? $3.value.floatVal : $3.value.doubleVal;
            $$.value.doubleVal = val1 / val2;
        }
        else if($1.type == FLOAT || $3.type == FLOAT) {
            $$.type = FLOAT;
            float val1 = ($1.type == INT) ? $1.value.intVal : $1.value.floatVal;
            float val2 = ($3.type == INT) ? $3.value.intVal : $3.value.floatVal;
            $$.value.floatVal = val1 / val2;
        }
        else {
            $$.type = INT;
            $$.value.intVal = $1.value.intVal / $3.value.intVal;
        }
    }
    | TOK_LEFT expr TOK_RIGHT { 
        $$ = $2; 
    }
    | TOK_CAST_INT expr {
        $$.type = INT;
        switch($2.type) {
            case INT: $$.value.intVal = $2.value.intVal; break;
            case FLOAT: $$.value.intVal = (int)$2.value.floatVal; break;
            case DOUBLE: $$.value.intVal = (int)$2.value.doubleVal; break;
        }
    }
    | TOK_CAST_FLOAT expr {
        $$.type = FLOAT;
        switch($2.type) {
            case INT: $$.value.floatVal = (float)$2.value.intVal; break;
            case FLOAT: $$.value.floatVal = $2.value.floatVal; break;
            case DOUBLE: $$.value.floatVal = (float)$2.value.doubleVal; break;
        }
    }
    | TOK_CAST_DOUBLE expr {
        $$.type = DOUBLE;
        switch($2.type) {
            case INT: $$.value.doubleVal = (double)$2.value.intVal; break;
            case FLOAT: $$.value.doubleVal = (double)$2.value.floatVal; break;
            case DOUBLE: $$.value.doubleVal = $2.value.doubleVal; break;
        }
    }
    ;


%%


int yyerror(const char *s) {
    printf("Error: %s\n", s);
    return 1;
}

int main(int argc, char *argv[])
{
    if(argc>1)
    {
        FILE *file=fopen(argv[1],"r");
        if(!file)
        {
            printf("Cannot open the file: %s!\n",argv[1]);
            return 1;
        }
        yyin=file;
    }
    yyparse();
    return 0;
}
