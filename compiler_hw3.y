/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_hw_common.h" //Extern variables that communicate with lex
    #include <string.h>
    #define scope_len 10
    #define size 100
    // #define YYDEBUG 1
    // int yydebug = 1;

    // Define data type of symbol table
    typedef struct Node {
        int index;
        int addr;
        int linenum;
        char name[100];
        char type[20];
        char sig[20];
    } Node;
    struct Node table[scope_len][size];
    

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Used to generate code */
    /* As printf; the usage: CODEGEN("%d - %s\n", 100, "Hello world"); */
    /* We do not enforce the use of this macro */
    #define CODEGEN(...) \
        do { \
            for (int i = 0; i < g_indent_cnt; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)

    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void insert_symbol();
    static void lookup_symbol();
    static void dump_symbol();

    static void push();             // Put the node in the symbol table
    static Node* find_node();       // Give the address, return the match node
    static char type_first_char();  // Give the type, return the "single alpha" imply each type

    /* Global variables */
    bool HAS_ERROR = false;
    FILE *fout = NULL;
    int g_indent_cnt = 0;

    // HW2
    int cur_scope = 0, address = 0;
    int para_len = 0;
    char para_str[10];

    // HW3
    int tmp_address = -1;           // which variable we are deal with ---> very usful & important
    int goal_num = -1;              // e.g. x = y + 3 ---> goal_num = address of x
    int label_num = 0;
    int switch_start = 0;
    int switch_number = 0;
    int switch_list[20];

    int debug_flag = 0;
%}

// %error-verbose
%union {
    int i_val;
    bool b_val;
    float f_val;
    char *s_val;
}

/* Token without return */
%token VAR NEWLINE NOT
%token INT FLOAT BOOL STRING
%token INC DEC GEQ LOR LAND
%token EQL NEQ GTR LSS LEQ
%token ADD SUB MUL QUO REM ASSIGN
%token ADD_ASSIGN SUB_ASSIGN
%token MUL_ASSIGN QUO_ASSIGN REM_ASSIGN
%token IF ELSE FOR SWITCH CASE
%token PRINT PRINTLN PACKAGE FUNC 
%token DEFAULT RETURN

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <f_val> FLOAT_LIT
%token <s_val> STRING_LIT IDENT
%token <b_val> TRUE FALSE

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type PrintStmt 
%type <s_val> ReturnType Literal ConversionExpr
%type <s_val> add_op cmp_op unary_op mul_op 
%type <s_val> ParameterList FunctionDeclStmt
%type <s_val> Expression AssignExpr LORExpr LANDExpr EqExpr RelaExpr
%type <s_val> ADDExpr MULExpr CastExpr UnaryExpr PostExpr PrimaryExpr Operand
%type <s_val> assign_op Condition ReturnStmt ForClause

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : GlobalStatementList
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | GlobalStatement
;

GlobalStatement
    : PackageStmt NEWLINE
    | FunctionDeclStmt
    | NEWLINE
;

PackageStmt
    : PACKAGE IDENT {
        CODEGEN(".source hw3.j\n");
        CODEGEN(".class public Main\n");
        CODEGEN(".super java/lang/Object\n");
        printf("package: %s\n", $2);
    }
;
Type 
    : INT    { $$ = "int32"; }
    | FLOAT  { $$ = "float32"; }
    | STRING { $$ = "string"; }
    | BOOL   { $$ = "bool"; }
;
ReturnType   
    : INT    { $$ = "I"; }
    | FLOAT  { $$ = "F"; }
    | STRING { $$ = "S"; }
    | BOOL   { $$ = "B"; }
    |        { $$ = "V"; }
;
ParameterList 
    : { $$ = ""; }
    | IDENT Type {
        char tmp = $2[0] - 32;
        printf("param %s, type: %c\n", $1, tmp);
        insert_symbol($1, cur_scope+1, address);
        push(cur_scope+1, $1, $2, yylineno+1, "-", address);
        para_str[para_len] = tmp;
        para_len++;
        strcpy($$, para_str);

    }
    | ParameterList ',' IDENT Type { // As same as above
        char tmp = $4[0] - 32;
        printf("param %s, type: %c\n", $3, tmp);
        insert_symbol($3, cur_scope+1, address);
        push(cur_scope+1, $3, $4, yylineno+1, "-", address);
        para_str[para_len] = tmp;
        para_len++;
        strcpy($$, para_str);
    }
;
ReturnStmt 
    : RETURN {
        printf("return\n");
        $$ = "return";
    }
    | RETURN Expression {
        printf("ireturn\n");    // here can be better
        $$ = "return";
    }
;
FuncBlock 
    : '{'{
        cur_scope++;
    } StatementList '}' {
        dump_symbol();
        cur_scope--;
    } 
;
FunctionDeclStmt
    : FUNC IDENT {
        printf("func: %s\n", $2);
        create_symbol(cur_scope+1);
        strcpy(para_str, "");
        para_len = 0;
    } '(' ParameterList ')' ReturnType {
        char sig[20];
        strcpy(sig, "(");
        strcat(sig, $5);
        strcat(sig, ")");
        strcat(sig, $7);
        printf("func_signature: (%s)%s\n", $5, $7);
        strcpy(para_str, "");

        lookup_symbol($2);
        insert_symbol($2, cur_scope, -2);       // For every function address 
        push(cur_scope, $2, "func", yylineno+1, sig, -2);

        // Put function in Jasmin
        if( strcmp($2, "main") == 0 ){
            CODEGEN(".method public static main([Ljava/lang/String;)V\n");
            CODEGEN(".limit stack 100\n");
            CODEGEN(".limit locals 100\n");
        }
        else{
            CODEGEN(".method public static %s%s\n", $2, sig);
            CODEGEN(".limit stack 20\n");
            CODEGEN(".limit locals 20\n");
        }
        g_indent_cnt++;
    } FuncBlock {
        if( strcmp($7, "V") == 0 ){
            CODEGEN("return\n");
        }
        else {
            CODEGEN("%creturn\n", $7[0] - 'A' + 'a');
        }
        g_indent_cnt--;
        CODEGEN(".end method\n\n");
    }
; 

unary_op 
    : ADD { $$ = "pos"; } 
    | SUB { $$ = "neg"; }
    | NOT { $$ = "not"; }
;
mul_op 
    : MUL { $$ = "mul"; }
    | QUO { $$ = "div"; }
    | REM { $$ = "rem"; }
;
add_op 
    : ADD { $$ = "add"; }
    | SUB { $$ = "sub"; }
;
cmp_op 
    : EQL { $$ = "EQL"; } 
    | NEQ { $$ = "NEQ"; } 
    | GTR { $$ = "GTR"; } 
    | LSS { $$ = "LSS"; } 
    | GEQ { $$ = "GEQ"; } 
    | LEQ { $$ = "LEQ"; } 
;
assign_op 
    : ASSIGN     { $$ = "ASSIGN"; goal_num = tmp_address; }
    | ADD_ASSIGN { $$ = "add"; goal_num = tmp_address; }
    | SUB_ASSIGN { $$ = "sub"; goal_num = tmp_address; }
    | MUL_ASSIGN { $$ = "mul"; goal_num = tmp_address; }
    | QUO_ASSIGN { $$ = "div"; goal_num = tmp_address; }
    | REM_ASSIGN { $$ = "rem"; goal_num = tmp_address; }
;

Literal 
    : INT_LIT {
        CODEGEN("ldc %d\n", $1);
        printf("INT_LIT %d\n", $1);
        $$ = "int32";
    } 
    | FLOAT_LIT {
        CODEGEN("ldc %f\n", $1);
        printf("FLOAT_LIT %f\n", $1);
        $$ = "float32";
    } 
    | TRUE {
        CODEGEN("iconst_1\n");
        printf("TRUE 1\n");
        $$ = "bool";
    }
    | FALSE {
        CODEGEN("iconst_0\n");
        printf("FALSE 0\n");
        $$ = "bool";
    }
    | '"' STRING_LIT '"'{
        CODEGEN("ldc \"%s\"\n", $2);
        printf("STRING_LIT %s\n", $2);
        $$ = "string";
    }
;
Operand 
    : Literal { 
        $$ = $1; 
    }
    | IDENT {
        int counter = 0, tmp_scope;
        bool flag = 0;

        for( tmp_scope = cur_scope; tmp_scope >= 0; tmp_scope--){
            counter = 0;

            while( table[tmp_scope][counter].index != -1 ){
                if( strcmp(table[tmp_scope][counter].name, $1) == 0 ){
                    flag = 1;
                    break;
                }
                counter++;
            }
            if( flag ) break;
        }
        // ------------------
        if( flag ){
            Node *node = &table[tmp_scope][counter];
            CODEGEN("%cload %d\n", type_first_char(node->type) , node->addr);
            if( strcmp(node->type, "bool") == 0 ){
                CODEGEN("ifne Label_%d\n", label_num++);
                CODEGEN("ldc \"false\"\n");
                CODEGEN("goto Label_%d\n", label_num++);
                CODEGEN("\nLabel_%d:\n", label_num - 2);
                CODEGEN("ldc \"true\"\n");
                CODEGEN("\nLabel_%d:\n", label_num - 1);
            }
            tmp_address = node->addr;

            printf("IDENT (name=%s, address=%d)\n", $1, node->addr);
            $$ = node->type ;
        }
        else{
            printf("error:%d: undefined: %s\n", yylineno+1, $1);
            HAS_ERROR = true;
            $$ = "ERROR";
        }
        if( debug_flag ){
            printf("\tIdent: %s\n", $1);
        }
    
    }
    | IDENT '(' Expression ')' { // Function mode
        // As same as above
        int counter = 0, tmp_scope;
        bool flag = 0;
        for( tmp_scope = cur_scope; tmp_scope >= 0; tmp_scope--){
            counter = 0;

            while( table[tmp_scope][counter].index != -1 ){
                if( strcmp(table[tmp_scope][counter].name, $1) == 0 ){
                    flag = 1;
                    break;
                }
                counter++;
            }
            if( flag ) break;
        }
        // ----------------

        if( flag ){
            printf("call: %s%s\n", table[tmp_scope][counter].name, table[tmp_scope][counter].sig);
            $$ = table[tmp_scope][counter].type ;
            CODEGEN("invokestatic Main/%s%s\n", $1, table[tmp_scope][counter].sig);
        }
        else{
            printf("error:%d: undefined function: %s\n", yylineno+1, $1);
            HAS_ERROR = true;
            $$ = "ERROR";
        }
        if( debug_flag ){
            printf("\tIdent: %s\n", $1);
        }
    }
    | IDENT '(' ')' {
        CODEGEN("invokestatic Main/%s()V\n", $1);
        printf("call: %s()V\n", $1);
        $$ = "function";
    }
    | '(' Expression ')' {$$ = $2;}
;

// Useless grammer
ConversionExpr 
    : Type '(' Expression ')' {
        if( debug_flag ){
            printf("\tConversion -> Type (Expr)\n");
        }
        $$ = $1;
    }
;

PrimaryExpr 
    : Operand {
        if( debug_flag ) printf("\tPrim -> Oper\n");
        $$ = $1;
    }
    | ConversionExpr {
        $$ = $1;
    }
;
PostExpr
    : PrimaryExpr {
        $$ = $1;
        if( debug_flag ) printf("\tPost -> Prim\n");
    }
    | PostExpr INC{
        if($1[0] == 'f') CODEGEN("ldc 1.000000\n");
        else CODEGEN("ldc 1\n");
        CODEGEN("%cadd\n", $1[0]);
        CODEGEN("%cstore %d\n", type_first_char($1), tmp_address);
        printf("INC\n");
        $$ = $1;
    }
    | PostExpr DEC{
        if($1[0] == 'f') CODEGEN("ldc 1.000000\n");
        else CODEGEN("ldc 1\n");
        CODEGEN("%csub\n", $1[0]);
        CODEGEN("%cstore %d\n", type_first_char($1), tmp_address);
        printf("DEC\n");
        $$ = $1;
    }
;
UnaryExpr 
    : PostExpr {
        $$ = $1;
        if( debug_flag ) printf("\tUnary -> Post\n");
    }
    | INC UnaryExpr {$$ = $2;}
    | DEC UnaryExpr {$$ = $2;}
    | unary_op UnaryExpr {
        if( debug_flag ) printf("\tUnary -> u_op Unary\n");
        
        if( strcmp($1, "neg") == 0 )
            CODEGEN("%c%s\n", $2[0], $1);
        else if( strcmp($1, "not") == 0 ) { // Not b -> true xor b
            CODEGEN("iconst_1\n");
            CODEGEN("ixor\n");
        }
        printf("%s\n", $1);
        $$ = $2;
    } 
;

CastExpr
    : UnaryExpr {
        $$ = $1;
        if( debug_flag ) printf("\tCast -> Unary\n");
    }
    | Type '(' CastExpr ')' {       // cannot change original type

        if( debug_flag ) {
            Node *node = find_node(tmp_address);
            printf("\tCast -> Type Case\n");
            printf("Node: %s with %s(%s)\n\n", node->name, $1, $3);
        }
        CODEGEN("%c2%c\n", $3[0], $1[0]);
        printf("%c2%c\n", $3[0], $1[0]);
        $$ = $1;
    }
;
MULExpr
    : CastExpr {
        $$ = $1;
        if( debug_flag ) printf("\tMul -> Cast\n");
    }
    | MULExpr mul_op CastExpr {
        if( $2[0] == 'R' ){
            if( $1[0] != 'i' || $3[0] != 'i' ){
                printf("error:%d: invalid operation: (operator %s not defined on float32)\n", yylineno, $2);
                HAS_ERROR = true;
            }
        }
        else if( $1[0] != $3[0] ){
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", yylineno, $2, $1, $3);
            HAS_ERROR = true;
        }
        CODEGEN("%c%s\n", $1[0], $2);
        printf("%s\n", $2);
        $$ = $1;
    }
;
ADDExpr 
    : MULExpr {
        $$ = $1;
        if( debug_flag ) printf("\tADD -> MUL\n");
    }
    | ADDExpr add_op MULExpr{
        if( $1[0] != $3[0] ){
            if(debug_flag) {
                Node *node1 = find_node(goal_num);
                Node *node2 = find_node(tmp_address);
                printf("ADD -> ADD a_op MUL\n");
                printf(" Node1: %s, type=%s || Node2 %s, type=%s\n", node1->name, node1->type, node2->name, node2->type);
                printf(" Now type are %s, %s\n", $1, $3);
            }

            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", yylineno, $2, $1, $3);
            HAS_ERROR = true;
        }
        CODEGEN("%c%s\n", $1[0], $2);
        printf("%s\n", $2);
        $$ = $1;
    }
;
RelaExpr
    : ADDExpr {$$ = $1;}
    | RelaExpr cmp_op ADDExpr{
        if( $1[0] != $3[0] ){
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", yylineno+1, $2, $1, $3);
            HAS_ERROR = true;
        }
        printf("%s\n", $2);
        $$ = "bool";

        if( strcmp($2, "GTR") == 0 ){
            if( strcmp($1, "int32") == 0 ) CODEGEN("isub\n");
            else if( strcmp($1, "float32") == 0 ) CODEGEN("fcmpl\n");
            CODEGEN("ifgt Label_%d\n", label_num++);
            CODEGEN("iconst_0\n");
            CODEGEN("goto Label_%d\n", label_num++);
            CODEGEN("\nLabel_%d:\n", label_num - 2);      // Label 1 : true
            CODEGEN("iconst_1\n");
            CODEGEN("\nLabel_%d:\n", label_num - 1);      // Label 2 : false
        }
        else if( strcmp($2, "EQL") == 0 ){
            if( strcmp($1, "int32") == 0 ) CODEGEN("isub\n");
            else if( strcmp($1, "float32") == 0 ) CODEGEN("fcmpl\n");
            CODEGEN("ifeq Label_%d\n", label_num++);
            CODEGEN("iconst_0\n");
            CODEGEN("goto Label_%d\n", label_num++);
            CODEGEN("\nLabel_%d:\n", label_num - 2);      // Label 1 : true
            CODEGEN("iconst_1\n");
            CODEGEN("\nLabel_%d:\n", label_num - 1);      // Label 2 : false
        }
        else{
            // CODEGEN("testing\n");
        }
    }
;
EqExpr
    : RelaExpr {
        $$ = $1;
    }
    | EqExpr cmp_op RelaExpr {
        if( $1[0] != $3[0] ){
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", yylineno, $2, $1, $3);
            HAS_ERROR = true;
        }
        $$ = "bool";
    }
;
LANDExpr
    : EqExpr {$$ = $1;}
    | LANDExpr LAND EqExpr {
        if( $1[0] == 'i' || $3[0] == 'i' ){
            printf("error:%d: invalid operation: (operator LAND not defined on int32)\n", yylineno);
            HAS_ERROR = true;
        }
        CODEGEN("iand\n");

        printf("LAND\n");
        $$ = $3;
    }
;
LORExpr 
    : LANDExpr {
        $$ = $1;
    }
    | LORExpr LOR LANDExpr {
        if( $1[0] == 'i' || $3[0] == 'i' ){
            printf("error:%d: invalid operation: (operator LOR not defined on int32)\n", yylineno);
            HAS_ERROR = true;
        }
        CODEGEN("ior\n");

        // if ne
        CODEGEN("ifne Label_%d\n", label_num++);
        CODEGEN("ldc \"false\"\n");
        CODEGEN("goto Label_%d\n", label_num++);
        CODEGEN("\nLabel_%d:\n", label_num - 2);      // Label 1 : true
        CODEGEN("ldc \"true\"\n");
        CODEGEN("\nLabel_%d:\n", label_num - 1);      // Label 2 : false

        printf("LOR\n");
        $$ = $3;
    }
;
AssignExpr
    : LORExpr {
        $$ = $1;
    }
    | UnaryExpr assign_op AssignExpr {
        if( $2[0] == 'R' ){
            if( $1[0] == 'i' && $3[0] == 'i' ){
            }
            else{
                printf("error:%d: invalid operation: (operator %s not defined on float)\n", yylineno, $2);
                HAS_ERROR = true;
            }
        }
        else if( $1[0] != $3[0] ){
            printf("error:%d: invalid operation: %s (mismatched types %s and %s)\n", yylineno, $2, $1, $3);
            HAS_ERROR = true;
        }

        if( strcmp($2, "ASSIGN") == 0 ){
            CODEGEN("%cstore %d\n", type_first_char($1), goal_num);
        }else{
            CODEGEN("%cload %d\n", type_first_char($1), goal_num);
            CODEGEN("swap\n");
            CODEGEN("%c%s\n", type_first_char($1), $2);
            CODEGEN("%cstore %d\n", type_first_char($1), goal_num);
        }

        printf("%s\n", $2);
        $$ = $1;
    }
;
Expression
    : AssignExpr {
        $$ = $1;
    }
    | Expression ',' AssignExpr {
        $$ = $1;
    }
;
ExpressionStmt 
    : Expression
;

// Statement : 
// "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");
DeclarationStmt 
    : VAR IDENT Type {
        lookup_symbol($2);
        insert_symbol($2, cur_scope, address);

        // Initialize
        switch(type_first_char($3)){
            case 'i':
                CODEGEN("ldc 0\n");
                break;
            case 'f':
                CODEGEN("ldc 0.000000\n");
                break;
            case 'a':
                CODEGEN("ldc \"\"\n");
                break;
            default :
                CODEGEN("ERROR\n");
                HAS_ERROR = true;
                break;
        }
        CODEGEN("%cstore %d\n", type_first_char($3), address);
        push(cur_scope, $2, $3, yylineno, "-", address);
    }
    | VAR IDENT Type ASSIGN Expression{
        lookup_symbol($2);
        insert_symbol($2, cur_scope, address);
        CODEGEN("%cstore %d\n", type_first_char($3), address);
        push(cur_scope, $2, $3, yylineno, "-", address);
    }
;

AssignmentStmt 
    : Expression assign_op Expression{
        printf("%s\n", $1);
    }
;
IncDecStmt 
    : Expression INC {
        printf("INC\n");
    }
    | Expression DEC {
        printf("DEC\n");
    }
;
SimpleStmt 
    : AssignmentStmt 
    | ExpressionStmt 
    | IncDecStmt{
        printf("INC,DEC\n");
    }
;

Block 
    : '{'{
        cur_scope++;
        create_symbol(cur_scope);
    } StatementList '}'{
        dump_symbol();
        cur_scope--;
    }
;
StatementList 
    : 
    | Statement StatementList
;
Condition 
    : Expression {
        if( strcmp($1, "bool") != 0 ){
            printf("error:%d: non-bool (type %s) used as for condition\n", yylineno+1, $1);
            HAS_ERROR = true;
        }
    }
;

ForClause
    : InitStmt ';' Condition ';' PostStmt
;
InitStmt 
    : SimpleStmt
;
PostStmt 
    : SimpleStmt
;

ForStmt 
    : FOR {
        CODEGEN("\nL_for_begin:\n");
    } Condition {
        CODEGEN("ifeq L_for_exit\n");
    } Block {
        CODEGEN("goto L_for_begin\n");
        CODEGEN("\nL_for_exit:\n");
    }
    | FOR {
        CODEGEN("\nL_for_begin:\n");
    } ForClause {
        CODEGEN("ifeq L_for_exit\n");
    } Block {
        CODEGEN("goto L_for_begin\n");
        CODEGEN("\nL_for_exit:\n");
    }
;

IfStmt 
    : IF Condition Block 
    | IF Condition Block ELSE IfStmt
    | IF Condition Block ELSE Block
;
SwitchStmt 
    : SWITCH Expression {
        CODEGEN("goto L_switch_begin_%d\n", switch_number);
        switch_start = label_num;
    } Block {
        CODEGEN("\nL_switch_begin_%d:", switch_number);
        CODEGEN("\nlookupswitch\n");
        for(int i=switch_start;i<label_num;i++){
            CODEGEN("%d: L_case_%d\n", switch_list[i], i);
        }
        CODEGEN("default: L_case_%d", label_num++);
        CODEGEN("\nL_switch_end_%d:\n", switch_number++);
    }
;
CaseStmt 
    : CASE INT_LIT {
        CODEGEN("\nL_case_%d:\n", label_num);
        switch_list[label_num] = $2;
        label_num++;
        printf("case %d\n", $2);
    } ':' Block {
        CODEGEN("goto L_switch_end_%d\n", switch_number);
    }
    | DEFAULT {
        CODEGEN("\nL_case_%d:\n", label_num);
    } ':' Block {
        CODEGEN("goto L_switch_end_%d\n", switch_number);
    }
;
PrintStmt 
    : PRINT '(' Expression ')'{
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        if( strcmp($3, "bool") == 0 || strcmp($3, "string") == 0 ) {
            CODEGEN("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
        }else{
            CODEGEN("invokevirtual java/io/PrintStream/print(%c)V\n", $3[0] + 'A' - 'a');
        }
        
        printf("PRINT %s\n", $3);
    }
    | PRINTLN '(' Expression ')'{
        CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        CODEGEN("swap\n");
        if( strcmp($3, "bool") == 0 || strcmp($3, "string") == 0 ) {
            CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        }else{
            CODEGEN("invokevirtual java/io/PrintStream/println(%c)V\n", $3[0] + 'A' - 'a');
        }
        printf("PRINTLN %s\n", $3);
    }
;

Statement 
    : DeclarationStmt NEWLINE
    | Expression NEWLINE
    | SimpleStmt NEWLINE
    | Block
    | IfStmt
    | ForStmt
    | SwitchStmt
    | CaseStmt
    | PrintStmt NEWLINE
    | ReturnStmt NEWLINE
    | NEWLINE
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } 
    else {
        yyin = stdin;
    }
    if (!yyin) {
        printf("file `%s` doesn't exists or cannot be opened\n", argv[1]);
        exit(1);
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");

    /* Symbol table init */
    yylineno = 0;
    for(int i=0;i<scope_len;i++){
	    memset(table[i], 0, sizeof(table[i]));
        for(int j=0;j<size;j++){
            table[i][j].index = -1;
            strcpy(table[i][j].name, "-");
            strcpy(table[i][j].type, "-");
            table[i][j].addr = -2;
            table[i][j].linenum = -1;
            strcpy(table[i][j].sig, "-");
        }
    }
    for(int i=0;i<20;i++) switch_list[i] = 0;
        
    /* Main function code */
    create_symbol(cur_scope);
    yyparse();
    dump_symbol();
    
	printf("Total lines: %d\n", yylineno);
    fclose(fout);
    fclose(yyin);

    if (HAS_ERROR) {
        remove(bytecode_filename);
    }
    return 0;
}

static void push(int cur_scope, char *name, char *type, int lineno, char *sig, int addr){
    int counter = 0;
    while( table[cur_scope][counter].index != -1 ) counter++;
    if( addr == -2 )
        addr = -1;      // For function address
    else
        address++;

    /* printf("addr : %d, address : %d \n", addr, address); */
    table[cur_scope][counter].index = counter;
    strcpy(table[cur_scope][counter].name, name);
    strcpy(table[cur_scope][counter].type, type);
    table[cur_scope][counter].addr = addr;
    table[cur_scope][counter].linenum = lineno;
    strcpy(table[cur_scope][counter].sig, sig);

}
static void create_symbol(int cur_scope) {
    if( cur_scope < 0 ) {
        printf("Error : cur_scope = %d \n", cur_scope);
        return ;
    }
    printf("> Create symbol table (scope level %d)\n", cur_scope);
}

static void insert_symbol(char *str, int cur_scope, int addr) {
    if( addr == -2 )
        addr = -1;
    if( cur_scope < 0 ) {
        printf("Error : cur_scope = %d \n", cur_scope);
        return ;
    }
    printf("> Insert `%s` (addr: %d) to scope level %d\n", str, addr, cur_scope);
}

static void lookup_symbol(char *name) {     // check whether the variable name is repeat
    int counter = 0;
    if( cur_scope < 0 ) {
        printf("Error : cur_scope = %d \n", cur_scope);
        return ;
    }
    while( table[cur_scope][counter].index != -1 ){
        if( counter >= 10 ) {
            printf("out of size\n");
            break;
        }
        if( strcmp(table[cur_scope][counter].name, name) == 0 ){
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", yylineno, name, table[cur_scope][counter].linenum );
            HAS_ERROR = true;
            break;
        }
        counter++;
    }
}
static void dump_symbol() {
    if( cur_scope < 0 ) {
        printf("Error : cur_scope = %d \n", cur_scope);
        return ;
    }
    printf("\n> Dump symbol table (scope level: %d)\n", cur_scope);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s\n",
           "Index", "Name", "Type", "Addr", "Lineno", "Func_sig");
    struct Node node;
    for(int i=0; table[cur_scope][i].index != -1;i++){
        node = table[cur_scope][i];
        printf("%-10d%-10s%-10s%-10d%-10d%-10s\n",
                node.index , node.name, node.type, node.addr, node.linenum, node.sig);
        
        // clean the scope data
        table[cur_scope][i].index = -1;
        strcpy(table[cur_scope][i].name, "-");
        strcpy(table[cur_scope][i].type, "-");
        table[cur_scope][i].addr = -2;
        table[cur_scope][i].linenum = -1;
        strcpy(table[cur_scope][i].sig, "-");
    }
    printf("\n");
}

static char type_first_char(char *name){
    if( strcmp(name, "int32") == 0 )
        return 'i';
    else if ( strcmp(name, "float32") == 0 )
        return 'f';
    else if ( strcmp(name, "bool") == 0 )
        return 'i';
    else if ( strcmp(name, "string") == 0 )
        return 'a';
    else {
        CODEGEN("ERRORRRRRRRRRRRRR\n");
        return 'i';
    }
}

/* Through the address to find the matching node */
/* Just for debug */
static Node* find_node(int dest_addr){      
    for(int sp = cur_scope; sp >= 0; sp-- ){
        for(int counter = 0; counter < address; counter++){
            if( table[sp][counter].addr == dest_addr ){
                return &table[sp][counter];
            }
        }
    }
    printf("ERROR: No match node\n");
    return NULL;
}