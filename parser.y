%{
    using namespace std;
    #include<iostream>
    #include <stdio.h>
    #include <string.h>
    #include<map>
    #include<vector>
    #include"enum.h"
    extern int yylineno;
    extern char *yytext;
    int yylex();
    int yyerror(const char *msg);
    int EsteCorecta = 1;
    char msg[500];

    //enum Type {INT, FLOAT, DOUBLE};



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

}
    
%token TOK_INT TOK_FLOAT TOK_DOUBLE
%token TOK_IF TOK_ELSE TOK_WHILE TOK_DO TOK_FOR
%token TOK_PRINTF TOK_SCANF TOK_COMMA
%token TOK_PLUS TOK_MINUS TOK_MULTIPLY TOK_DIVIDE
%token TOK_LEFT TOK_RIGHT TOK_LBRACE TOK_RBRACE
%token TOK_GT TOK_LT TOK_GE TOK_LE TOK_EQ TOK_NE
%token TOK_ERROR


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

%start program


%%


program:
        | program statement
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
            yyerror("Variable already declared");
        }
    }
    | TOK_INT TOK_ID '=' expr {
        if(symbolTable.find($2) == symbolTable.end()) {
            symbolTable[$2] = {INT, {.intVal = $4.value.intVal}, true};
        } else {
            yyerror("Variable already declared");
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
            yyerror("Variable already declared");
            YYERROR;
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
            yyerror("Variable already declared");
            YYERROR;
        }
    }
    ;




declaration_double:
    TOK_ID {
        if(symbolTable.find($1) == symbolTable.end()) {
            symbolTable[$1] = {DOUBLE, {.doubleVal = 0.0}, false};
        } else {
            yyerror("Variable already declared");
            YYERROR;
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
            yyerror("Variable already declared");
            YYERROR;
        }
    }
    ;




assignment:
    TOK_ID '=' expr {
        auto it = symbolTable.find($1);
        if(it == symbolTable.end()) {
            yyerror("Variable not declared");
            YYERROR;
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




if_statement:
    TOK_IF TOK_LEFT condition TOK_RIGHT statement %prec LOWER_THAN_ELSE
    | TOK_IF TOK_LEFT condition TOK_RIGHT statement TOK_ELSE statement 
    ;




while_statement:
    TOK_WHILE TOK_LEFT condition TOK_RIGHT statement
    ;




io_statement:
    TOK_PRINTF TOK_LEFT TOK_STRING TOK_RIGHT {

        printf("%s", $3);
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
    | TOK_SCANF TOK_LEFT TOK_STRING TOK_COMMA '&' TOK_ID TOK_RIGHT {
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
            yyerror("Variable not declared");
        }
    }
    ;







condition:
    expr TOK_GT expr
    | expr TOK_LT expr
    | expr TOK_GE expr
    | expr TOK_LE expr
    | expr TOK_EQ expr
    | expr TOK_NE expr
    ;

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
                yyerror("Use of uninitialized variable");
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
            yyerror("Variable not declared");
        }
    }
    | expr TOK_PLUS expr
    | expr TOK_MINUS expr
    | expr TOK_MULTIPLY expr
    | expr TOK_DIVIDE expr
    | TOK_LEFT expr TOK_RIGHT { $$ = $2; }
    ;

%%


int yyerror(const char *s) {
    //printf("Error: %s\n", s);
    printf("Eroare la linia %d: %s at %s\n",yylineno,s,yytext);
    return 1;
}



int main()
{

    yyparse();
    return 0;

}
