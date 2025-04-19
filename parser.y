%{
    using namespace std;
    #include<iostream>
    #include <stdio.h>
    #include <string.h>
    #include<map>
    #include<vector>
    #include"enum.h"
    #include<limits.h>
    #include<float.h>
    #include<stack>
    #include<sstream>

    extern FILE *yyin;
    int yylex();
    int yyerror(const char *msg);
    int EsteCorecta = 1;
    char msg[500];
    int execute_flag=1;
    int execute_else_flag=1;
    int is_interactive=0;


    void enterScope();
    void exitScope();

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

stack<map<string,Variable>> symbolTableStack;


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
            bool boolVal;
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
%type <boolVal> condition



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
        //| TOK_LBRACE program TOK_RBRACE
        | compound_statement
        //| if_block
        ;
/*
compound_statement:
    start_scope program end_scope
    ;
*/
compound_statement:
    TOK_LBRACE 
    {
        printf("Am intrat in scope");
        enterScope();
    }
    program 
    TOK_RBRACE
    {
        printf("Am iesit din scope");
        exitScope();
    }
    ;

/*
start_scope:
    TOK_LBRACE {
        printf("Am intrat in scope");
        enterScope();  // Enter a new scope
    }
    ;

end_scope:
    TOK_RBRACE {
        printf("Am iesit din scope");
        exitScope();  // Exit the current scope
    }
    ;
*/
declaration:
    TOK_INT TOK_ID {
        if(execute_flag==1)
        {
            map<string, Variable> *currentTable = nullptr;

            if (!symbolTableStack.empty()) {
                currentTable = &symbolTableStack.top();
                // Proceed with currentTable
            } else {
                fprintf(stderr, "Error: No active scope found.\n");
            }
        if(currentTable->find($2) == currentTable->end()) {
            (*currentTable)[$2] = {INT, {.intVal = 0}, false};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $2);
            yyerror(msg);
        }
        }
    }
    | TOK_INT TOK_ID '=' expr {
        if(execute_flag==1)
        {
            map<string, Variable> *currentTable = nullptr;

            if (!symbolTableStack.empty()) {
                currentTable = &symbolTableStack.top();
                // Proceed with currentTable
            } else {
                fprintf(stderr, "Error: No active scope found.\n");
            }
        if(currentTable->find($2) == currentTable->end()) {
            long long value=$4.value.intVal;
            if(value > INT_MAX || value < INT_MIN) {
                    sprintf(msg, "%d:%d Eroare: Valoarea depaseste limitele int pentru variabila %s!", @1.first_line, @1.first_column, $2);
                    yyerror(msg);
                } else {
                    (*currentTable)[$2] = {INT, {.intVal = $4.value.intVal}, true};
                }
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $2);
            yyerror(msg);
        }
        }
    }
    | TOK_FLOAT declaration_float
    | TOK_DOUBLE declaration_double
    ;


declaration_float:
    TOK_ID {
        if(execute_flag==1)
        {
            map<string, Variable> *currentTable = nullptr;

            if (!symbolTableStack.empty()) {
                currentTable = &symbolTableStack.top();
                // Proceed with currentTable
            } else {
                fprintf(stderr, "Error: No active scope found.\n");
            }
        if(currentTable->find($1) == currentTable->end()) {
            (*currentTable)[$1] = {FLOAT, {.floatVal = 0.0f}, false};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        }
        }
    }
    | TOK_ID '=' expr {
        if(execute_flag==1)
        {
            map<string, Variable> *currentTable = nullptr;

            if (!symbolTableStack.empty()) {
                currentTable = &symbolTableStack.top();
                // Proceed with currentTable
            } else {
                fprintf(stderr, "Error: No active scope found.\n");
            }
        if(currentTable->find($1) == currentTable->end()) {
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
            if(value > FLT_MAX || value < -FLT_MAX) {
                    sprintf(msg, "%d:%d Eroare: Valoarea depaseste limitele float pentru variabila %s!", @1.first_line, @1.first_column, $1);
                    yyerror(msg);
                } else {
                    (*currentTable)[$1] = {FLOAT, {.floatVal = value}, true};
                }
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        
        }
        }
    }
    ;

declaration_double:
    TOK_ID {
        if(execute_flag==1)
        {
            map<string, Variable> *currentTable = nullptr;

            if (!symbolTableStack.empty()) {
                currentTable = &symbolTableStack.top();
                // Proceed with currentTable
            } else {
                fprintf(stderr, "Error: No active scope found.\n");
            }
        if(currentTable->find($1) == currentTable->end()) {
            (*currentTable)[$1] = {DOUBLE, {.doubleVal = 0.0}, false};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        }
        }
    }
    | TOK_ID '=' expr {
        if(execute_flag==1)
        {
            map<string, Variable> *currentTable = nullptr;

            if (!symbolTableStack.empty()) {
                currentTable = &symbolTableStack.top();
                // Proceed with currentTable
            } else {
                fprintf(stderr, "Error: No active scope found.\n");
            }
        if(currentTable->find($1) == currentTable->end()) {
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
            (*currentTable)[$1] = {DOUBLE, {.doubleVal = value}, true};
        } else {
            sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", @1.first_line, @1.first_column, $1);
            yyerror(msg);
        }
        }
    }
    ;

assignment:
    TOK_ID '=' expr {
        if(execute_flag==1)
        {
            map<string, Variable> *currentTable = nullptr;

            if (!symbolTableStack.empty()) {
                currentTable = &symbolTableStack.top();
                // Proceed with currentTable
            } else {
                fprintf(stderr, "Error: No active scope found.\n");
            }
        auto it = currentTable->find($1);
        if(it == currentTable->end()) {
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
    }
    ;

/*
if_statement:
     TOK_IF TOK_LEFT condition TOK_RIGHT statement
    {
        execute_flag = !execute_flag;  // Toggle flag before the else block
    }
    TOK_ELSE statement
    {
        execute_flag = 1;  // Reset execute_flag after the else block
    }
    |TOK_IF TOK_LEFT condition TOK_RIGHT statement %prec LOWER_THAN_ELSE
    {
        execute_flag = 1;  // Reset execute_flag after the if block
    }
    ;
*/
/*
// Add a new rule for if block that doesn't create a new scope
if_block:
    TOK_LBRACE program TOK_RBRACE  // No scope creation for if blocks
    ;

// Modify the if_statement rule to use if_block instead of statement
if_statement:
    TOK_IF TOK_LEFT condition TOK_RIGHT if_block
    {
        execute_flag = !execute_flag;  // Toggle flag before the else block
    }
    TOK_ELSE if_block
    {
        execute_flag = 1;  // Reset execute_flag after the else block
    }
    | TOK_IF TOK_LEFT condition TOK_RIGHT if_block %prec LOWER_THAN_ELSE
    {
        execute_flag = 1;  // Reset execute_flag after the if block
    }
    ;
*/
/*
if_statement:
    TOK_IF TOK_LEFT condition TOK_RIGHT TOK_LBRACE program TOK_RBRACE
    {
        execute_flag = !execute_flag;  // Toggle flag before the else block
    }
    TOK_ELSE TOK_LBRACE program TOK_RBRACE
    {
        execute_flag = 1;  // Reset execute_flag after the else block
    }
    | TOK_IF TOK_LEFT condition TOK_RIGHT TOK_LBRACE program TOK_RBRACE %prec LOWER_THAN_ELSE
    {
        execute_flag = 1;  // Reset execute_flag after the if block
    }
    ;
*/


if_statement:
    TOK_IF TOK_LEFT condition TOK_RIGHT block
    {
        execute_flag = !execute_flag;  // Toggle flag before the else block
    }
    TOK_ELSE block
    {
        execute_flag = 1;  // Reset execute_flag after the else block
    }
    | TOK_IF TOK_LEFT condition TOK_RIGHT block %prec LOWER_THAN_ELSE
    {
        execute_flag = 1;  // Reset execute_flag after the if block
    }
    ;

block:
    TOK_LBRACE program TOK_RBRACE
    ;


while_statement:
    TOK_WHILE TOK_LEFT condition TOK_RIGHT statement
    ;


//io_statement:
       /*
    TOK_PRINTF TOK_LEFT TOK_STRING TOK_RIGHT {
        if(execute_flag==1)
        {
        printf("%s",$3);
    }
    }
    | TOK_PRINTF TOK_LEFT TOK_STRING TOK_COMMA expr TOK_RIGHT {
        // Handle different format specifiers based on expr type
        if(execute_flag==1)
        {
            printf("%s",$3);
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
    }*/

    io_statement:
    TOK_PRINTF TOK_LEFT TOK_STRING TOK_RIGHT {
        if (execute_flag == 1) {
            // Remove the first and last characters (quotes) from the string
            int len = strlen($3);
            if (len >= 2) {
                char temp[len - 1];  // Create a new string without quotes
                strncpy(temp, $3 + 1, len - 2);  // Copy the string excluding first and last character
                temp[len - 2] = '\0';  // Null-terminate the string
                printf("%s\n", temp);  // Print the modified string
            } else {
                printf("\n");  // If the string is too short, just print a newline
            }
        }
    }
    | TOK_PRINTF TOK_LEFT TOK_STRING TOK_COMMA expr TOK_RIGHT {
        if (execute_flag == 1) {
            // Remove the first and last characters (quotes) from the string
            int len = strlen($3);
            char temp[len - 1];
            if (len >= 2) {
                strncpy(temp, $3 + 1, len - 2);
                temp[len - 2] = '\0';
            }

            // Print the string with the variable
            switch ($5.type) {
                case INT:
                    printf(temp, $5.value.intVal);
                    break;
                case FLOAT:
                    printf(temp, $5.value.floatVal);
                    break;
                case DOUBLE:
                    printf(temp, $5.value.doubleVal);
                    break;
                default:
                    printf("Unknown type\n");
                    break;
            }
            printf("\n");  // Add a newline for better output formatting
        }
    }
    | TOK_SCANF TOK_LEFT TOK_STRING TOK_COMMA TOK_AMPERSAND TOK_ID TOK_RIGHT {
        if(execute_flag==1)
        {
            map<string, Variable> *currentTable = nullptr;

            if (!symbolTableStack.empty()) {
                currentTable = &symbolTableStack.top();
                // Proceed with currentTable
            } else {
                fprintf(stderr, "Error: No active scope found.\n");
            }
        auto it = currentTable->find($6);
        if(it != currentTable->end()) {
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
    }
    ;




condition:
    expr TOK_GT expr {
        if ($1.type == $3.type) {
            switch ($1.type) {
                case INT:    $$ = ($1.value.intVal > $3.value.intVal); break;
                case FLOAT:  $$ = ($1.value.floatVal > $3.value.floatVal); break;
                case DOUBLE: $$ = ($1.value.doubleVal > $3.value.doubleVal); break;
            }
        } else {
            sprintf(msg, "%d:%d Eroare semantica: Comparatie intre tipuri incompatibile!", @2.first_line, @2.first_column);
            yyerror(msg);
            $$ = false;
        }
        if (!$$) execute_flag = 0;  // Set execute_flag to 0 if the condition is false
    }
    | expr TOK_LT expr {
        if ($1.type == $3.type) {
            switch ($1.type) {
                case INT:    $$ = ($1.value.intVal < $3.value.intVal); break;
                case FLOAT:  $$ = ($1.value.floatVal < $3.value.floatVal); break;
                case DOUBLE: $$ = ($1.value.doubleVal < $3.value.doubleVal); break;
            }
        } else {
            sprintf(msg, "%d:%d Eroare semantica: Comparatie intre tipuri incompatibile!", @2.first_line, @2.first_column);
            yyerror(msg);
            $$ = false;
        }
        if (!$$) execute_flag = 0;  // Set execute_flag to 0 if the condition is false
    }
    | expr TOK_GE expr {
        if ($1.type == $3.type) {
            switch ($1.type) {
                case INT:    $$ = ($1.value.intVal >= $3.value.intVal); break;
                case FLOAT:  $$ = ($1.value.floatVal >= $3.value.floatVal); break;
                case DOUBLE: $$ = ($1.value.doubleVal >= $3.value.doubleVal); break;
            }
        } else {
            sprintf(msg, "%d:%d Eroare semantica: Comparatie intre tipuri incompatibile!", @2.first_line, @2.first_column);
            yyerror(msg);
            $$ = false;
        }
        if (!$$) execute_flag = 0;  // Set execute_flag to 0 if the condition is false
    }
    | expr TOK_LE expr {
        if ($1.type == $3.type) {
            switch ($1.type) {
                case INT:    $$ = ($1.value.intVal <= $3.value.intVal); break;
                case FLOAT:  $$ = ($1.value.floatVal <= $3.value.floatVal); break;
                case DOUBLE: $$ = ($1.value.doubleVal <= $3.value.doubleVal); break;
            }
        } else {
            sprintf(msg, "%d:%d Eroare semantica: Comparatie intre tipuri incompatibile!", @2.first_line, @2.first_column);
            yyerror(msg);
            $$ = false;
        }
        if (!$$) execute_flag = 0;  // Set execute_flag to 0 if the condition is false
    }
    | expr TOK_EQ expr {
        if ($1.type == $3.type) {
            switch ($1.type) {
                case INT:    $$ = ($1.value.intVal == $3.value.intVal); break;
                case FLOAT:  $$ = ($1.value.floatVal == $3.value.floatVal); break;
                case DOUBLE: $$ = ($1.value.doubleVal == $3.value.doubleVal); break;
            }
        } else {
            sprintf(msg, "%d:%d Eroare semantica: Comparatie intre tipuri incompatibile!", @2.first_line, @2.first_column);
            yyerror(msg);
            $$ = false;
        }
        if (!$$) execute_flag = 0;  // Set execute_flag to 0 if the condition is false
    }
    | expr TOK_NE expr {
        if ($1.type == $3.type) {
            switch ($1.type) {
                case INT:    $$ = ($1.value.intVal != $3.value.intVal); break;
                case FLOAT:  $$ = ($1.value.floatVal != $3.value.floatVal); break;
                case DOUBLE: $$ = ($1.value.doubleVal != $3.value.doubleVal); break;
            }
        } else {
            sprintf(msg, "%d:%d Eroare semantica: Comparatie intre tipuri incompatibile!", @2.first_line, @2.first_column);
            yyerror(msg);
            $$ = false;
        }
        if (!$$) execute_flag = 0;  // Set execute_flag to 0 if the condition is false
    }
    | condition TOK_AND condition { $$ = ($1 && $3); if (!$$) execute_flag = 0;}  // Set execute_flag to 0 if the condition is false}
    | condition TOK_OR condition { $$ = ($1 || $3); if (!$$) execute_flag = 0; } // Set execute_flag to 0 if the condition is false}
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
        map<string, Variable> *currentTable = nullptr;

            if (!symbolTableStack.empty()) {
                currentTable = &symbolTableStack.top();
                // Proceed with currentTable
            } else {
                fprintf(stderr, "Error: No active scope found.\n");
            }
        auto it = currentTable->find($1);
        if(it != currentTable->end()) {
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


void enterScope() {
    symbolTableStack.push(std::map<std::string, Variable>());
}

void exitScope() {
    if (!symbolTableStack.empty()) {
        symbolTableStack.pop();
    }
    else 
    {
        printf("No scope remaineed");
    }
}

// Find a variable in the current and outer scopes
bool findVariable(const std::string &name, Variable &symbol) {
    // Search from the top of the stack to the bottom
    std::stack<std::map<std::string, Variable>> tempStack = symbolTableStack;
    while (!tempStack.empty()) {
        auto &currentTable = tempStack.top();
        auto it = currentTable.find(name);
        if (it != currentTable.end()) {
            symbol = it->second;
            return true;
        }
        tempStack.pop();
    }
    return false;  // Variable not found in any scope
}

// Add a variable to the current scope
bool addVariable(const std::string &name, Variable symbol) {
    if (symbolTableStack.empty()) {
        fprintf(stderr, "Error: No scope to add variable.\n");
        return false;
    }
    auto &currentTable = symbolTableStack.top();
    if (currentTable.find(name) == currentTable.end()) {
        currentTable[name] = symbol;
        return true;
    }
    return false;  // Variable already exists in the current scope
}



int yyerror(const char *s) {
    printf("Error: %s\n", s);
    if(is_interactive==0)
    {
        exit(1);
    }
    return 1;
}

void runScript(const std::string &filename) {
    FILE *file = fopen(filename.c_str(), "r");
    if (!file) {
        std::cerr << "Error: Cannot open file " << filename << "!" << std::endl;
        return;
    }

    yyin = file;
    yyparse();
    fclose(file);
}

void runInteractive() {
    std::string input;
    std::cout << "Interactive Mode: Enter your commands (type 'exit' to quit):" << std::endl;

    enterScope();  // Automatically create a global scope

    while (true) {
        std::cout << "> ";
        std::getline(std::cin, input);

        if (input == "exit") {
            std::cout << "Exiting interactive mode." << std::endl;
            break;
        }

        // Create a string stream for parsing
        yyin = fmemopen((void*)input.c_str(), input.size(), "r");
        
        if (!yyin) {
            std::cerr << "Error: Failed to create input stream!" << std::endl;
            continue;
        }

        yyparse();
        fclose(yyin);
    }

    exitScope();  // Close the global scope when exiting
}

int main() {
    int choice;
    std::string filename;

    std::cout << "=========================" << std::endl;
    std::cout << "   Simple C Interpreter  " << std::endl;
    std::cout << "=========================" << std::endl;
    std::cout << "Choose an option:" << std::endl;
    std::cout << "1. Run commands interactively" << std::endl;
    std::cout << "2. Run a script from a file" << std::endl;
    std::cout << "Enter your choice: ";
    std::cin >> choice;
    std::cin.ignore();  // Clear newline character from input buffer

    switch (choice) {
        case 1:
            is_interactive=1;
            runInteractive();
            break;
        case 2:
            std::cout << "Enter the script file name: ";
            std::getline(std::cin, filename);
            runScript(filename);
            break;
        default:
            std::cout << "Invalid choice. Exiting." << std::endl;
            return 1;
    }

    return 0;
}