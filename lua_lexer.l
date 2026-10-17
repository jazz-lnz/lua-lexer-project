/* DEFINITIONS SECTION */

%{
#include <stdio.h>
#include <string.h>

/* Counters updated during scanning */
int token_count = 0;
int error_count = 0;
int line_number  = 1;

/* ANSI color codes for visual formatting the terminal output */
#define RESET   "\033[0m"
#define BOLD    "\033[1m"
#define RED     "\033[31m"
#define GREEN   "\033[32m"
#define YELLOW  "\033[33m"
#define BLUE    "\033[34m"
#define MAGENTA "\033[35m"
#define CYAN    "\033[36m"
#define GRAY    "\033[90m"
#define ORANGE  "\033[38;5;214m"

/* Buffer used to accumulate multi-line content (long strings/comments) */
#define MLBUF_SIZE 4096
static char mlbuf[MLBUF_SIZE];
static int  mllen = 0;

static void ml_append(char c) {
    if (mllen < MLBUF_SIZE - 2)
        mlbuf[mllen++] = c;
}

/* Helper to format and print the output for each detected token */
void print_token(const char *type, const char *value, const char *color) {
    char display[48];
    if (strlen(value) > 45) {
        strncpy(display, value, 42);
        display[42] = '\0';
        strcat(display, "...");
    } else {
        strncpy(display, value, 47);
        display[47] = '\0';
    }
    printf("%s%-12s%s | %-45s | line %d\n",
           color, type, RESET, display, line_number);
    token_count++;
}

void print_error(const char *msg) {
    printf("%s%-12s%s | %-45s | line %d\n",
           RED, "ERROR", RESET, msg, line_number);
    error_count++;
}

/* Minimal yywrap to avoid linking libfl on macOS */
#undef yywrap
int yywrap(void) { return 1; } /* Signal EOF (End Of File) handling */
%}

%option noyywrap

/* Exclusive start conditions */
%x IN_BLOCK_COMMENT
%x IN_LONG_STRING

/* regular expressions */
KEYWORD   ("and"|"break"|"do"|"else"|"elseif"|"end"|"for"|"function"|"goto"|"if"|"in"|"local"|"not"|"or"|"repeat"|"return"|"then"|"until"|"while")
IDENT     [A-Za-z_][A-Za-z0-9_]*
DIGIT     [0-9]
INTEGER   {DIGIT}+
EXPONENT  [eE][+-]?{DIGIT}+
FLOAT     {DIGIT}+\.{DIGIT}*{EXPONENT}?|{DIGIT}+{EXPONENT}|\.{DIGIT}+{EXPONENT}?
HEXDIGIT  [0-9A-Fa-f]
HEX       0[xX]{HEXDIGIT}+
STR_DQ    \"(\\.|[^\"\\])*\"
STR_SQ    \'(\\.|[^\'\\])*\'
OPERATOR  ("..."|".."|"//"|"<<"|">>"|"=="|"~="|"<="|">="|"+"|"-"|"*"|"/"|"%"|"^"|"#"|"&"|"|"|"~"|"<"|">"|"=")
DELIMITER ("::"|"("|")"|"["|"]"|"{"|"}"|","|";"|":"|".")

/* RULES SECTION */

%%

"--[["   {
    mllen = 0;
    ml_append('-'); ml_append('-');
    ml_append('['); ml_append('[');
    BEGIN(IN_BLOCK_COMMENT);
}
<IN_BLOCK_COMMENT>"]]"    { mlbuf[mllen] = '\0'; ml_append(']'); ml_append(']'); print_token("COMMENT", mlbuf, GRAY); BEGIN(INITIAL); }
<IN_BLOCK_COMMENT>\n      { line_number++; ml_append('\n'); }
<IN_BLOCK_COMMENT>.       { ml_append(yytext[0]); }
<IN_BLOCK_COMMENT><<EOF>> { print_error("Unterminated block comment"); BEGIN(INITIAL); }

"--"[^\n]*   { print_token("COMMENT", yytext, GRAY); }

"[["   { mllen = 0; ml_append('['); ml_append('['); BEGIN(IN_LONG_STRING); }
<IN_LONG_STRING>"]]"    { ml_append(']'); ml_append(']'); mlbuf[mllen] = '\0'; print_token("LONG_STR", mlbuf, BLUE); BEGIN(INITIAL); }
<IN_LONG_STRING>\n      { line_number++; ml_append('\n'); }
<IN_LONG_STRING>.       { ml_append(yytext[0]); }
<IN_LONG_STRING><<EOF>> { print_error("Unterminated long string"); BEGIN(INITIAL); }

{KEYWORD} { print_token("KEYWORD", yytext, CYAN); }

"true"    { print_token("BOOLEAN", yytext, MAGENTA); }
"false"   { print_token("BOOLEAN", yytext, MAGENTA); }
"nil"     { print_token("NIL",     yytext, YELLOW);  }

{IDENT}   { print_token("IDENTIFIER", yytext, "\033[37m"); }

{HEX}     { print_token("HEX",     yytext, GREEN); }
{FLOAT}   { print_token("FLOAT",   yytext, GREEN); }
{INTEGER} { print_token("INTEGER", yytext, GREEN); }

{STR_DQ} { print_token("STRING", yytext, BLUE); }
{STR_SQ} { print_token("STRING", yytext, BLUE); }

\"[^\"\n]*$   { char m[256]; snprintf(m,sizeof(m),"Unterminated string: %s",yytext); print_error(m); }
\'[^\'\n]*$   { char m[256]; snprintf(m,sizeof(m),"Unterminated string: %s",yytext); print_error(m); }

{OPERATOR} { print_token("OPERATOR", yytext, ORANGE); }

{DELIMITER} { print_token("DELIMITER", yytext, "\033[37m"); }

[ \t\r]+   { /* ignored */ }
\n         { line_number++; }

.   { char m[64]; snprintf(m, sizeof(m), "Unknown character: '%s'", yytext); print_error(m); }

%%

/* USER CODE SECTION */

int main(int argc, char *argv[]) {
    /* File handling logic */
    FILE *fp = NULL;
    if (argc > 1) {
        fp = fopen(argv[1], "r");
        if (!fp) { fprintf(stderr, RED "Error: cannot open '%s'\n" RESET, argv[1]); return 1; }
        yyin = fp;
    } else { printf("No file given - reading from stdin (Ctrl+D to finish):\n\n"); yyin = stdin; }

    printf(BOLD "\n%-12s | %-45s | %s\n" RESET, "TOKEN TYPE", "VALUE", "LINE");
    printf("%-12s-+-%-45s-+---------\n", "------------", "---------------------------------------------");

    yylex(); /* start the lexer */

    /* Print summary */
    printf("%-12s-+-%-45s-+---------\n", "------------", "---------------------------------------------");
    printf(BOLD "\nSummary\n" RESET);
    printf("  Tokens : %s%d%s\n", GREEN, token_count, RESET);
    printf("  Lines  : %s%d%s\n", CYAN,  line_number, RESET);
    printf("  Errors : %s%d%s\n", error_count ? RED : GREEN, error_count, RESET);

    if (error_count == 0) printf(GREEN "\n  Input is lexically valid Lua.\n\n" RESET);
    else printf(RED "\n  %d lexical error(s) found.\n\n" RESET, error_count);

    if (fp) fclose(fp);
        return error_count > 0 ? 1 : 0;
    }