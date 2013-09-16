package org.mozilla.javascript
{
	import org.mozilla.javascript.exception.IllegalStateError;

	/**
	 * This class implements the JavaScript scanner.
	 *
	 * It is based on the C source files jsscan.c and jsscan.h
	 * in the jsref package.
	 *
	 * @see org.mozilla.javascript.Parser
	 *
	 * @author Mike McCabe
	 * @author Brendan Eich
	 */
	public class Token
	{
		// debug flags
		public static var printTrees:Boolean = true;
		public static var printICode:Boolean = true;
		public static var printNames:Boolean = printTrees || printICode;
		
		public static const COMMENT_TYPE_LINE:int = 0;
		public static const COMMENT_TYPE_BLOCK_COMMENT:int = 1;
		public static const COMMENT_TYPE_JSDOC:int = 2;
		public static const COMMENT_TYPE_HTML:int = 3;
		
		public static const
		// start enum			
			ERROR:int          = -1, // well-known as the only code < EOF
			EOF:int            = 0,    // end of file token - (not EOF_CHAR)
			EOL:int            = 1,    // end of line
			
			// Interpreter reuses the following as bytecodes
			FIRST_BYTECODE_TOKEN:int = 2,
			
			ENTERWITH:int      = 2,
			LEAVEWITH:int      = 3,
			RETURN:int         = 4,
			GOTO:int           = 5,
			IFEQ:int           = 6,
			IFNE:int           = 7,
			SETNAME:int        = 8,
			BITOR:int          = 9,
			BITXOR:int         = 10,
			BITAND:int         = 11,
			EQ:int             = 12,
			NE:int             = 13,
			LT:int             = 14,
			LE:int             = 15,
			GT:int             = 16,
			GE:int             = 17,
			LSH:int            = 18,
			RSH:int            = 19,
			URSH:int           = 20,
			ADD:int            = 21,
			SUB:int            = 22,
			MUL:int            = 23,
			DIV:int            = 24,
			MOD:int            = 25,
			NOT:int            = 26,
			BITNOT:int         = 27,
			POS:int            = 28,
			NEG:int            = 29,
			NEW:int            = 30,
			DELPROP:int        = 31,
			TYPEOF:int         = 32,
			GETPROP:int        = 33,
			GETPROPNOWARN:int  = 34,
			SETPROP:int        = 35,
			GETELEM:int        = 36,
			SETELEM:int        = 37,
			CALL:int           = 38,
			NAME:int           = 39,
			NUMBER:int         = 40,
			STRING:int         = 41,
			NULL:int           = 42,
			THIS:int           = 43,
			FALSE:int          = 44,
			TRUE:int           = 45,
			SHEQ:int           = 46,   // shallow equality (===)
			SHNE:int           = 47,   // shallow inequality (!==)
			REGEXP:int         = 48,
			BINDNAME:int       = 49,
			THROW:int          = 50,
			RETHROW:int        = 51, // rethrow caught exception: catch (e if ) use it
			IN:int             = 52,
			INSTANCEOF:int     = 53,
			LOCAL_LOAD:int     = 54,
			GETVAR:int         = 55,
			SETVAR:int         = 56,
			CATCH_SCOPE:int    = 57,
			ENUM_INIT_KEYS:int = 58,
			ENUM_INIT_VALUES:int = 59,
			ENUM_INIT_ARRAY:int= 60,
			ENUM_NEXT:int      = 61,
			ENUM_ID:int        = 62,
			THISFN:int         = 63,
			RETURN_RESULT:int  = 64, // to return previously stored return result
			ARRAYLIT:int       = 65, // array literal
			OBJECTLIT:int      = 66, // object literal
			GET_REF:int        = 67, // *reference
			SET_REF:int        = 68, // *reference    = something
			DEL_REF:int        = 69, // delete reference
			REF_CALL:int       = 70, // f(args)    = something or f(args)++
			REF_SPECIAL:int    = 71, // reference for special properties like __proto
			YIELD:int          = 72,  // JS 1.7 yield pseudo keyword
			STRICT_SETNAME:int = 73,
			
			// For XML support:
			DEFAULTNAMESPACE:int = 74, // default xml namespace =
			ESCXMLATTR:int     = 75,
			ESCXMLTEXT:int     = 76,
			REF_MEMBER:int     = 77, // Reference for x.@y, x..y etc.
			REF_NS_MEMBER:int  = 78, // Reference for x.ns::y, x..ns::y etc.
			REF_NAME:int       = 79, // Reference for @y, @[y] etc.
			REF_NS_NAME:int    = 80; // Reference for ns::y, @ns::y@[y] etc.

			//End of interpreter bytecodes
		public static const
			LAST_BYTECODE_TOKEN:int    = REF_NS_NAME,
			
			TRY:int            = 81,
			SEMI:int           = 82,  // semicolon
			LB:int             = 83,  // left and right brackets
			RB:int             = 84,
			LC:int             = 85,  // left and right curlies (braces)
			RC:int             = 86,
			LP:int             = 87,  // left and right parentheses
			RP:int             = 88,
			COMMA:int          = 89,  // comma operator
			
			ASSIGN:int         = 90,  // simple assignment  (=)
			ASSIGN_BITOR:int   = 91,  // |=
			ASSIGN_BITXOR:int  = 92,  // ^=
			ASSIGN_BITAND:int  = 93,  // |=
			ASSIGN_LSH:int     = 94,  // <<=
			ASSIGN_RSH:int     = 95,  // >>=
			ASSIGN_URSH:int    = 96,  // >>>=
			ASSIGN_ADD:int     = 97,  // +=
			ASSIGN_SUB:int     = 98,  // -=
			ASSIGN_MUL:int     = 99,  // *=
			ASSIGN_DIV:int     = 100,  // /=
			ASSIGN_MOD:int     = 101;  // %=
			
		public static const
			FIRST_ASSIGN:int   = ASSIGN,
			LAST_ASSIGN:int    = ASSIGN_MOD,
			
			HOOK:int           = 102, // conditional (?:)
			COLON:int          = 103,
			OR:int             = 104, // logical or (||)
			AND:int            = 105, // logical and (&&)
			INC:int            = 106, // increment/decrement (++ --)
			DEC:int            = 107,
			DOT:int            = 108, // member operator (.)
			FUNCTION:int       = 109, // function keyword
			EXPORT:int         = 110, // export keyword
			IMPORT:int         = 111, // import keyword
			IF:int             = 112, // if keyword
			ELSE:int           = 113, // else keyword
			SWITCH:int         = 114, // switch keyword
			CASE:int           = 115, // case keyword
			DEFAULT:int        = 116, // default keyword
			WHILE:int          = 117, // while keyword
			DO:int             = 118, // do keyword
			FOR:int            = 119, // for keyword
			BREAK:int          = 120, // break keyword
			CONTINUE:int       = 121, // continue keyword
			VAR:int            = 122, // var keyword
			WITH:int           = 123, // with keyword
			CATCH:int          = 124, // catch keyword
			FINALLY:int        = 125, // finally keyword
			VOID:int           = 126, // void keyword
			RESERVED:int       = 127, // reserved keywords
			
			EMPTY:int          = 128,
			
			/* types used for the parse tree - these never get returned
			* by the scanner.
			*/
			
			BLOCK:int          = 129, // statement block
			LABEL:int          = 130, // label
			TARGET:int         = 131,
			LOOP:int           = 132,
			EXPR_VOID:int      = 133, // expression statement in functions
			EXPR_RESULT:int    = 134, // expression statement in scripts
			JSR:int            = 135,
			SCRIPT:int         = 136, // top-level node for entire script
			TYPEOFNAME:int     = 137, // for typeof(simple-name)
			USE_STACK:int      = 138,
			SETPROP_OP:int     = 139, // x.y op= something
			SETELEM_OP:int     = 140, // x[y] op= something
			LOCAL_BLOCK:int    = 141,
			SET_REF_OP:int     = 142, // *reference op= something
			
			// For XML support:
			DOTDOT:int         = 143,  // member operator (..)
			COLONCOLON:int     = 144,  // namespace::name
			XML:int            = 145,  // XML type
			DOTQUERY:int       = 146,  // .() -- e.g., x.emps.emp.(name == "terry")
			XMLATTR:int        = 147,  // @
			XMLEND:int         = 148,
			
			// Optimizer-only-tokens
			TO_OBJECT:int      = 149,
			TO_DOUBLE:int      = 150,
			
			GET:int            = 151,  // JS 1.5 get pseudo keyword
			SET:int            = 152,  // JS 1.5 set pseudo keyword
			LET:int            = 153,  // JS 1.7 let pseudo keyword
			CONST:int          = 154,
			SETCONST:int       = 155,
			SETCONSTVAR:int    = 156,
			ARRAYCOMP:int      = 157,  // array comprehension
			LETEXPR:int        = 158,
			WITHEXPR:int       = 159,
			DEBUGGER:int       = 160,
			COMMENT:int        = 161,
			GENEXPR:int        = 162,
			LAST_TOKEN:int     = 163;
		
		public function Token()
		{
		}
		
		/**
		 * Returns a name for the token.  If Rhino is compiled with certain
		 * hardcoded debugging flags in this file, it calls {@code #typeToName};
		 * otherwise it returns a string whose value is the token number.
		 */
		public static function name(token:int):String {
			if (!printNames) {
				return token.toString();
			}
			return typeToName(token);
		}
		
		/**
		 * Always returns a human-readable string for the token name.
		 * For instance, {@link #FINALLY} has the name "FINALLY".
		 * @param token the token code
		 * @return the actual name for the token code
		 */
		public static function typeToName(token:int):String {
			switch (token) {
				case ERROR:           return "ERROR";
				case EOF:             return "EOF";
				case EOL:             return "EOL";
				case ENTERWITH:       return "ENTERWITH";
				case LEAVEWITH:       return "LEAVEWITH";
				case RETURN:          return "RETURN";
				case GOTO:            return "GOTO";
				case IFEQ:            return "IFEQ";
				case IFNE:            return "IFNE";
				case SETNAME:         return "SETNAME";
				case BITOR:           return "BITOR";
				case BITXOR:          return "BITXOR";
				case BITAND:          return "BITAND";
				case EQ:              return "EQ";
				case NE:              return "NE";
				case LT:              return "LT";
				case LE:              return "LE";
				case GT:              return "GT";
				case GE:              return "GE";
				case LSH:             return "LSH";
				case RSH:             return "RSH";
				case URSH:            return "URSH";
				case ADD:             return "ADD";
				case SUB:             return "SUB";
				case MUL:             return "MUL";
				case DIV:             return "DIV";
				case MOD:             return "MOD";
				case NOT:             return "NOT";
				case BITNOT:          return "BITNOT";
				case POS:             return "POS";
				case NEG:             return "NEG";
				case NEW:             return "NEW";
				case DELPROP:         return "DELPROP";
				case TYPEOF:          return "TYPEOF";
				case GETPROP:         return "GETPROP";
				case GETPROPNOWARN:   return "GETPROPNOWARN";
				case SETPROP:         return "SETPROP";
				case GETELEM:         return "GETELEM";
				case SETELEM:         return "SETELEM";
				case CALL:            return "CALL";
				case NAME:            return "NAME";
				case NUMBER:          return "NUMBER";
				case STRING:          return "STRING";
				case NULL:            return "NULL";
				case THIS:            return "THIS";
				case FALSE:           return "FALSE";
				case TRUE:            return "TRUE";
				case SHEQ:            return "SHEQ";
				case SHNE:            return "SHNE";
				case REGEXP:          return "REGEXP";
				case BINDNAME:        return "BINDNAME";
				case THROW:           return "THROW";
				case RETHROW:         return "RETHROW";
				case IN:              return "IN";
				case INSTANCEOF:      return "INSTANCEOF";
				case LOCAL_LOAD:      return "LOCAL_LOAD";
				case GETVAR:          return "GETVAR";
				case SETVAR:          return "SETVAR";
				case CATCH_SCOPE:     return "CATCH_SCOPE";
				case ENUM_INIT_KEYS:  return "ENUM_INIT_KEYS";
				case ENUM_INIT_VALUES:return "ENUM_INIT_VALUES";
				case ENUM_INIT_ARRAY: return "ENUM_INIT_ARRAY";
				case ENUM_NEXT:       return "ENUM_NEXT";
				case ENUM_ID:         return "ENUM_ID";
				case THISFN:          return "THISFN";
				case RETURN_RESULT:   return "RETURN_RESULT";
				case ARRAYLIT:        return "ARRAYLIT";
				case OBJECTLIT:       return "OBJECTLIT";
				case GET_REF:         return "GET_REF";
				case SET_REF:         return "SET_REF";
				case DEL_REF:         return "DEL_REF";
				case REF_CALL:        return "REF_CALL";
				case REF_SPECIAL:     return "REF_SPECIAL";
				case DEFAULTNAMESPACE:return "DEFAULTNAMESPACE";
				case ESCXMLTEXT:      return "ESCXMLTEXT";
				case ESCXMLATTR:      return "ESCXMLATTR";
				case REF_MEMBER:      return "REF_MEMBER";
				case REF_NS_MEMBER:   return "REF_NS_MEMBER";
				case REF_NAME:        return "REF_NAME";
				case REF_NS_NAME:     return "REF_NS_NAME";
				case TRY:             return "TRY";
				case SEMI:            return "SEMI";
				case LB:              return "LB";
				case RB:              return "RB";
				case LC:              return "LC";
				case RC:              return "RC";
				case LP:              return "LP";
				case RP:              return "RP";
				case COMMA:           return "COMMA";
				case ASSIGN:          return "ASSIGN";
				case ASSIGN_BITOR:    return "ASSIGN_BITOR";
				case ASSIGN_BITXOR:   return "ASSIGN_BITXOR";
				case ASSIGN_BITAND:   return "ASSIGN_BITAND";
				case ASSIGN_LSH:      return "ASSIGN_LSH";
				case ASSIGN_RSH:      return "ASSIGN_RSH";
				case ASSIGN_URSH:     return "ASSIGN_URSH";
				case ASSIGN_ADD:      return "ASSIGN_ADD";
				case ASSIGN_SUB:      return "ASSIGN_SUB";
				case ASSIGN_MUL:      return "ASSIGN_MUL";
				case ASSIGN_DIV:      return "ASSIGN_DIV";
				case ASSIGN_MOD:      return "ASSIGN_MOD";
				case HOOK:            return "HOOK";
				case COLON:           return "COLON";
				case OR:              return "OR";
				case AND:             return "AND";
				case INC:             return "INC";
				case DEC:             return "DEC";
				case DOT:             return "DOT";
				case FUNCTION:        return "FUNCTION";
				case EXPORT:          return "EXPORT";
				case IMPORT:          return "IMPORT";
				case IF:              return "IF";
				case ELSE:            return "ELSE";
				case SWITCH:          return "SWITCH";
				case CASE:            return "CASE";
				case DEFAULT:         return "DEFAULT";
				case WHILE:           return "WHILE";
				case DO:              return "DO";
				case FOR:             return "FOR";
				case BREAK:           return "BREAK";
				case CONTINUE:        return "CONTINUE";
				case VAR:             return "VAR";
				case WITH:            return "WITH";
				case CATCH:           return "CATCH";
				case FINALLY:         return "FINALLY";
				case VOID:            return "VOID";
				case RESERVED:        return "RESERVED";
				case EMPTY:           return "EMPTY";
				case BLOCK:           return "BLOCK";
				case LABEL:           return "LABEL";
				case TARGET:          return "TARGET";
				case LOOP:            return "LOOP";
				case EXPR_VOID:       return "EXPR_VOID";
				case EXPR_RESULT:     return "EXPR_RESULT";
				case JSR:             return "JSR";
				case SCRIPT:          return "SCRIPT";
				case TYPEOFNAME:      return "TYPEOFNAME";
				case USE_STACK:       return "USE_STACK";
				case SETPROP_OP:      return "SETPROP_OP";
				case SETELEM_OP:      return "SETELEM_OP";
				case LOCAL_BLOCK:     return "LOCAL_BLOCK";
				case SET_REF_OP:      return "SET_REF_OP";
				case DOTDOT:          return "DOTDOT";
				case COLONCOLON:      return "COLONCOLON";
				case XML:             return "XML";
				case DOTQUERY:        return "DOTQUERY";
				case XMLATTR:         return "XMLATTR";
				case XMLEND:          return "XMLEND";
				case TO_OBJECT:       return "TO_OBJECT";
				case TO_DOUBLE:       return "TO_DOUBLE";
				case GET:             return "GET";
				case SET:             return "SET";
				case LET:             return "LET";
				case YIELD:           return "YIELD";
				case CONST:           return "CONST";
				case SETCONST:        return "SETCONST";
				case ARRAYCOMP:       return "ARRAYCOMP";
				case WITHEXPR:        return "WITHEXPR";
				case LETEXPR:         return "LETEXPR";
				case DEBUGGER:        return "DEBUGGER";
				case COMMENT:         return "COMMENT";
				case GENEXPR:         return "GENEXPR";
			}
			
			// Token without name
			throw new IllegalStateError(token.toString());
		}
		
		/**
		 * Convert a keyword token to a name string for use with the
		 * {@link Context.FEATURE_RESERVED_KEYWORD_AS_IDENTIFIER} feature.
		 * @param token A token
		 * @return the corresponding name string
		 */
		public static function keywordToName(token:int):String {
			switch (token) {
				case Token.BREAK:      return "break";
				case Token.CASE:       return "case";
				case Token.CONTINUE:   return "continue";
				case Token.DEFAULT:    return "default";
				case Token.DELPROP:    return "delete";
				case Token.DO:         return "do";
				case Token.ELSE:       return "else";
				case Token.FALSE:      return "false";
				case Token.FOR:        return "for";
				case Token.FUNCTION:   return "function";
				case Token.IF:         return "if";
				case Token.IN:         return "in";
				case Token.LET:        return "let";
				case Token.NEW:        return "new";
				case Token.NULL:       return "null";
				case Token.RETURN:     return "return";
				case Token.SWITCH:     return "switch";
				case Token.THIS:       return "this";
				case Token.TRUE:       return "true";
				case Token.TYPEOF:     return "typeof";
				case Token.VAR:        return "var";
				case Token.VOID:       return "void";
				case Token.WHILE:      return "while";
				case Token.WITH:       return "with";
				case Token.YIELD:      return "yield";
				case Token.CATCH:      return "catch";
				case Token.CONST:      return "const";
				case Token.DEBUGGER:   return "debugger";
				case Token.FINALLY:    return "finally";
				case Token.INSTANCEOF: return "instanceof";
				case Token.THROW:      return "throw";
				case Token.TRY:        return "try";
				default:               return null;
			}
		}
		
		/**
		 * Return true if passed code is a valid Token constant.
		 * @param code a potential token code
		 * @return true if it's a known token
		 */
		public static function isValidToken(code:int):Boolean {
			return code >= ERROR && code <= LAST_TOKEN;
		}
	}
}