%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"
#include <dirent.h>
char* subAliases(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return aliasTable.word[i];
        }
    }
    return name;
}
bool ifAlias(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return true;
        }
    }
    return false;
}
bool subVar(char** toReturn, char* name) {
  if(name[0] != '$' || name[1] != '{' || name[strlen(name)-1]!='}')
    return false;
  for (int i = 0; i < varIndex; i++)
  {
    if(strncmp(varTable.var[i], name+2, strlen(name)-3) == 0) {
      *toReturn = (char*) malloc(strlen(varTable.word[i]));
      sprintf(*toReturn, "%s", varTable.word[i]);
      return true;
    }
  }
  return false;
}

%}
%array
%option noyywrap
%x string_condition

CHAR            [\}\{:$.A-Za-z0-9!\/_-][\}\{:$.A-Za-z0-9!\/_-]*
ANYCHAR            [)(\}\{*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(\}\{*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*

%%

<string_condition>{ANYCHAR}+     { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

[ ]		          {            }
bye             { return BYE; }
cd		          { return CD; }
alias		        { return ALIAS; }
printenv        { return PRINTENV; }
setenv          { return SETENV; }
unalias         { return UNALIAS; }
&               { return AMPERSAND; }
"|"             { return PIPE; }
"\n"		        { return END; }
\<              { return INREDIRECT; }
>>|>             { yylval.string = strdup(yytext); return REDIRECT; }
[\"]            { BEGIN(string_condition); }
{CHAR}+             {
                      char * temp;
                      if(ifAlias(yytext)) {
                          printf("yytext: %s\n", yytext);
                          //source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                             char *yycopy = strdup( subAliases(yytext) );
                             for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                                 unput( yycopy[i] );
                             free( yycopy );
                      }
                      else if(subVar(&temp, yytext))
                      {
                        for(int i = strlen(temp)-1; i>=0; i--)
                          unput(temp[i]);
                        free(temp);
                      }
                      /*else if(inPath(&temp, yytext)){
                          yylval.string = strdup(temp);
                          printf("yytext: %s\n", temp);
                          free(temp);
                          return MYFILE;
                      }*/
                      else {
                          printf("yytext: %s\n", yytext);
                          yylval.string = strdup(yytext);
                          return STRING;
                      };
                    }
%%