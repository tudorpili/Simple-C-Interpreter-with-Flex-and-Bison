%option noyywrap
%{
    #include"enum.h"
    #include "parser.tab.h"
    #include<limits.h>
    #include<stdio.h>
    #include<stdlib.h>
    #include<float.h>
    #include<math.h>
    //#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno;
    //#include<string.h>
    int lineNo = 1;
    int colNo = 1;
%}

 //%option yylineno

%%

"int"           {colNo+=3; return TOK_INT; }

"float"         {colNo+=5; return TOK_FLOAT; }

"double"        {colNo+=6; return TOK_DOUBLE; }

"(int)"         {colNo+=5; return TOK_CAST_INT; }

"(float)"       {colNo+=7; return TOK_CAST_FLOAT; }

"(double)"      {colNo+=8; return TOK_CAST_DOUBLE; }

"return"        {colNo+=6; return TOK_RETURN; }

"if"            { colNo+=2; return TOK_IF; }

"else"          { colNo+=4; return TOK_ELSE; }

"while"         { colNo+=5; return TOK_WHILE; }

"printf"        {colNo+=6; return TOK_PRINTF; }

"scanf"         { colNo+=5; return TOK_SCANF; }

"+"             { colNo++; return TOK_PLUS; }

"-"             { colNo++; return TOK_MINUS; }

"*"             { colNo++; return TOK_MULTIPLY; }

"/"             { colNo++; return TOK_DIVIDE; }

"("             { colNo++; return TOK_LEFT; }

")"             { colNo++; return TOK_RIGHT; }

"{"             { colNo++; return TOK_LBRACE; }

"}"             { colNo++; return TOK_RBRACE; }

","             {colNo++; return TOK_COMMA; }

";"             { colNo++; return ';'; }

"="             { colNo++; return '='; }

">"             { colNo++; return TOK_GT; }

"<"             { colNo++; return TOK_LT; }

">="            { colNo+=2; return TOK_GE; }

"<="            { colNo+=2; return TOK_LE; }

"=="            { colNo+=2; return TOK_EQ; }

"!="            { colNo+=2; return TOK_NE; }

"||"            { colNo+=2; return TOK_OR; }

"&&"            { colNo+=2; return TOK_AND; }

"&"             { colNo++; return TOK_AMPERSAND; }



"//"[^\n]*      { /* Single line comment */ colNo+=strlen(yytext); }

"/*"([^*]|\*+[^*/])*\*+"/" { /* Multi-line comment */
                            for(int i=0; i<strlen(yytext); i++) {
                                if(yytext[i] == '\n') {
                                    lineNo++;
                                    colNo=1;
                                }else {
                                    colNo++;
                                }
                            }
                        }


0|[1-9][0-9]*       { yylloc.first_line = lineNo; yylloc.first_column = colNo;
                    colNo+=strlen(yytext);
                    long long value=atoll(yytext);
                    if (value > INT_MAX || value < INT_MIN) {
                        fprintf(stderr, "%d:%d Eroare lexica: Valoarea numerica %s depaseste limitele int!\n", lineNo, colNo, yytext);
                        exit(EXIT_FAILURE);
                        //return TOK_ERROR;  // Signal a lexical error and stop parsing
                    } else {
                        yylval.intVal = atoi(yytext);  // Safe to assign after range check
                        return TOK_NUMBER_INT;
                    }        
}

[0-9]+\.[0-9]+f? { yylloc.first_line = lineNo;
                    yylloc.first_column = colNo;
                    colNo+=strlen(yytext);
                    if (yytext[strlen(yytext) - 1] == 'f') {  // Float literal
        float value = strtof(yytext, NULL);   // Convert to float
        if (value > FLT_MAX || value < -FLT_MAX) {
            fprintf(stderr, "%d:%d Eroare lexica: Valoarea numerica %s depaseste limitele float!\n", lineNo, colNo, yytext);
            exit(EXIT_FAILURE);  // Terminate the program on overflow
        }
        yylval.floatVal = atof(yytext);
        return TOK_NUMBER_FLOAT;
    } else {  // Double literal
        double value = strtod(yytext, NULL);
        if (isinf(value) || fabs(value) > DBL_MAX) {  // Check for infinity or exceeding range
            fprintf(stderr, "%d:%d Eroare lexica: Valoarea numerica %s depaseste limitele double!\n", lineNo, colNo, yytext);
            exit(EXIT_FAILURE);
        }
        yylval.doubleVal = value;
        return TOK_NUMBER_DOUBLE;
    }
                    }

\"[^\"]*\"        {yylloc.first_line=lineNo;
                    yylloc.first_column=colNo;
                    colNo+=strlen(yytext);
                    yylval.sir=strdup(yytext);
                    return TOK_STRING;
                    }



[a-zA-Z][a-zA-Z0-9]* { yylloc.first_line = lineNo;
                        yylloc.first_column = colNo;
                        colNo+=strlen(yytext);
                        yylval.sir = new char[strlen(yytext)+1];
                        strcpy(yylval.sir,yytext);
                        return TOK_ID;
                        }


 /*/\*([^*]|\*+[^/*])*\*+/ {yylloc.first_line=lineNo;
                    yylloc.first_column=colNo;
                    colNo+=strlen(yytext);
                    yylval.sir=strdup(yytext);
                    return TOK_COMMENT;
                    }*/



[ ]             { colNo++; }
\r\n            { lineNo++; colNo=1;}
\n              { lineNo++; colNo=1; }
.               { colNo++; return TOK_ERROR; }

%%