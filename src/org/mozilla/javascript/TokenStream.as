package org.mozilla.javascript
{
	import flash.errors.IOError;
	
	import java.lang.Character;
	
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
	public class TokenStream
	{
		/*
		* For chars - because we need something out-of-range
		* to check.  (And checking EOF by exception is annoying.)
		* Note distinction from EOF token type!
		*/
		private static const EOF_CHAR:int = -1;
		
		private static const BYTE_ORDER_MARK:int = 0xFEFF;
		
		// Instance variables
		
		// stuff other than whitespace since start of line
		private var dirtyLine:Boolean;
		
		public var regExpFlags:String;
		
		// Set this to an initial non-null value so that the Parser has
		// something to retrieve even if an error has occurred and no
		// string is found.  Fosters one class of error, but saves lots of
		// code.
		private var string:String;
		private var number:Number;
		private var isOctal:Boolean;

		// delimiter for last string literal scanned
		private var quoteChar:int;
		
		private var stringBuffer:Vector.<int> = new Vector.<int>(128);
		private var stringBufferTop:int;
		// Brian: for now, use a simpler structure until we figure out what the
		// hell this allStrings object is for.  (?!?)
		private var allStrings:Object = new Object();
		
		// Room to backtrace from to < on failed match of the last - in <!--
		private var ungetBuffer:Vector.<int> = new Vector.<int>(3);
		private var ungetCursor:int;
		
		private var hitEOF:Boolean = false;
		
		private var lineStart:int = 0;
		private var lineEndChar:int = -1;
		public var lineno:int;
		
		private var sourceString:String;
		private var sourceReader:Reader;
		private var sourceBuffer:Vector.<int>;
		private var sourceEnd:int;
		
		// sourceCursor is an index into a small buffer that keeps a
		// sliding window of the source stream
		public var sourceCursor:int;
		
		// cursor is a monotonically increasing index into the original
		// source stream, tracking exactly how far scanning has progressed.
		// Its value is the index of the next character to be scanned.
		public var cursor:int;
		
		// Record start and end positions of last scanned token.
		public var tokenBeg:int;
		public var tokenEnd:int;
		
		// Type of last comment scanned
		public var commentType:int;
		
		// for xml tokenizer
		private var xmlIsAttribute:Boolean;
		private var xmlIsTagContent:Boolean;
		private var xmlOpenTagsCount:int;
		
		private var parser:Parser;
		
		private var commentPrefix:String = "";
		private var commentCursor:int = -1;
		
		public function TokenStream(parser:Parser, sourceReader:Reader, sourceString:String, lineno:int)
		{
			this.parser = parser;
			this.lineno = lineno;
			if (sourceReader !== null) {
				if (sourceString !== null) Kit.codeBug();
				this.sourceReader = sourceReader;
				this.sourceBuffer = new Vector.<int>(512);
				this.sourceEnd = 0;
			}
			else {
				if (sourceString === null) Kit.codeBug();
				this.sourceString = sourceString;
				this.sourceEnd = sourceString.length;
			}
			this.sourceCursor = this.cursor = 0;
		}
		
		/* This function uses the cached op, string and number fields in
		* TokenStream; if getToken has been called since the passed token
		* was scanned, the op or string printed may be incorrect.
		*/
		public function tokenToString(token:int):String {
			if (Token.printTrees) {
				var name:String = Token.name(token);
				
				switch(token) {
					case Token.STRING:
					case Token.REGEXP:
					case Token.NAME:
						return name+ " `" + this.string + "'";
						
					case Token.NUMBER:
						return "NUMBER " + this.number;
				}
				
				return name;
			}
			return "";
		}
		
		public static function isKeyword(s:String):Boolean {
			return Token.EOF !== stringToKeyword(s);
		}
		
		private static function stringToKeyword(name:String):int {
			// #string_id_map#
			// The following assumes that Token.EOF == 0
			const
				Id_break:int         = Token.BREAK,
				Id_case:int          = Token.CASE,
				Id_continue:int      = Token.CONTINUE,
				Id_default:int       = Token.DEFAULT,
				Id_delete:int        = Token.DELPROP,
				Id_do:int            = Token.DO,
				Id_else:int          = Token.ELSE,
				Id_export:int        = Token.RESERVED,
				Id_false:int         = Token.FALSE,
				Id_for:int           = Token.FOR,
				Id_function:int      = Token.FUNCTION,
				Id_if:int            = Token.IF,
				Id_in:int            = Token.IN,
				Id_let:int           = Token.LET,  // reserved ES5 strict
				Id_new:int           = Token.NEW,
				Id_null:int          = Token.NULL,
				Id_return:int        = Token.RETURN,
				Id_switch:int        = Token.SWITCH,
				Id_this:int          = Token.THIS,
				Id_true:int          = Token.TRUE,
				Id_typeof:int        = Token.TYPEOF,
				Id_var:int           = Token.VAR,
				Id_void:int          = Token.VOID,
				Id_while:int         = Token.WHILE,
				Id_with:int          = Token.WITH,
				Id_yield:int         = Token.YIELD,  // reserved ES5 strict
				
				// the following are #ifdef RESERVE_JAVA_KEYWORDS in jsscan.c
				Id_abstract:int      = Token.RESERVED,  // ES3 only
				Id_boolean:int       = Token.RESERVED,  // ES3 only
				Id_byte:int          = Token.RESERVED,  // ES3 only
				Id_catch:int         = Token.CATCH,
				Id_char:int          = Token.RESERVED,  // ES3 only
				Id_class:int         = Token.RESERVED,
				Id_const:int         = Token.CONST,     // reserved
				Id_debugger:int      = Token.DEBUGGER,
				Id_double:int        = Token.RESERVED,  // ES3 only
				Id_enum:int          = Token.RESERVED,
				Id_extends:int       = Token.RESERVED,
				Id_final:int         = Token.RESERVED,  // ES3 only
				Id_finally:int       = Token.FINALLY,
				Id_float:int         = Token.RESERVED,  // ES3 only
				Id_goto:int          = Token.RESERVED,  // ES3 only
				Id_implements:int    = Token.RESERVED,  // ES3, ES5 strict
				Id_import:int        = Token.RESERVED,
				Id_instanceof:int    = Token.INSTANCEOF,
				Id_int:int           = Token.RESERVED,  // ES3
				Id_interface:int     = Token.RESERVED,  // ES3, ES5 strict
				Id_long:int          = Token.RESERVED,  // ES3 only
				Id_native:int        = Token.RESERVED,  // ES3 only
				Id_package:int       = Token.RESERVED,  // ES3, ES5 strict
				Id_private:int       = Token.RESERVED,  // ES3, ES5 strict
				Id_protected:int     = Token.RESERVED,  // ES3, ES5 strict
				Id_public:int        = Token.RESERVED,  // ES3, ES5 strict
				Id_short:int         = Token.RESERVED,  // ES3 only
				Id_static:int        = Token.RESERVED,  // ES3, ES5 strict
				Id_super:int         = Token.RESERVED,
				Id_synchronized:int  = Token.RESERVED,  // ES3 only
				Id_throw:int         = Token.THROW,
				Id_throws:int        = Token.RESERVED,  // ES3 only
				Id_transient:int     = Token.RESERVED,  // ES3 only
				Id_try:int           = Token.TRY,
				Id_volatile:int      = Token.RESERVED;  // ES3 only
			
			var id:int;
			var s:String = name;
			// #generated# Last update: 2007-04-18 13:53:30 PDT
			L0: { id = 0; var X:String = null; var c:String;
				L: switch (s.length) {
					case 2: c=s.charAt(1);
						if (c==='f') { if (s.charAt(0)==='i') {id=Id_if; break L0;} }
						else if (c==='n') { if (s.charAt(0)==='i') {id=Id_in; break L0;} }
						else if (c==='o') { if (s.charAt(0)==='d') {id=Id_do; break L0;} }
						break L;
					case 3: switch (s.charAt(0)) {
						case 'f': if (s.charAt(2)==='r' && s.charAt(1)==='o') {id=Id_for; break L0;} break L;
						case 'i': if (s.charAt(2)==='t' && s.charAt(1)==='n') {id=Id_int; break L0;} break L;
						case 'l': if (s.charAt(2)==='t' && s.charAt(1)==='e') {id=Id_let; break L0;} break L;
						case 'n': if (s.charAt(2)==='w' && s.charAt(1)==='e') {id=Id_new; break L0;} break L;
						case 't': if (s.charAt(2)==='y' && s.charAt(1)==='r') {id=Id_try; break L0;} break L;
						case 'v': if (s.charAt(2)==='r' && s.charAt(1)==='a') {id=Id_var; break L0;} break L;
					} break L;
					case 4: switch (s.charAt(0)) {
						case 'b': X="byte";id=Id_byte; break L;
						case 'c': c=s.charAt(3);
							if (c==='e') { if (s.charAt(2)==='s' && s.charAt(1)==='a') {id=Id_case; break L0;} }
							else if (c==='r') { if (s.charAt(2)==='a' && s.charAt(1)==='h') {id=Id_char; break L0;} }
							break L;
						case 'e': c=s.charAt(3);
							if (c==='e') { if (s.charAt(2)==='s' && s.charAt(1)==='l') {id=Id_else; break L0;} }
							else if (c==='m') { if (s.charAt(2)==='u' && s.charAt(1)==='n') {id=Id_enum; break L0;} }
							break L;
						case 'g': X="goto";id=Id_goto; break L;
						case 'l': X="long";id=Id_long; break L;
						case 'n': X="null";id=Id_null; break L;
						case 't': c=s.charAt(3);
							if (c=='e') { if (s.charAt(2)==='u' && s.charAt(1)==='r') {id=Id_true; break L0;} }
							else if (c=='s') { if (s.charAt(2)==='i' && s.charAt(1)==='h') {id=Id_this; break L0;} }
							break L;
						case 'v': X="void";id=Id_void; break L;
						case 'w': X="with";id=Id_with; break L;
					} break L;
					case 5: switch (s.charAt(2)) {
						case 'a': X="class";id=Id_class; break L;
						case 'e': c=s.charAt(0);
							if (c==='b') { X="break";id=Id_break; }
							else if (c==='y') { X="yield";id=Id_yield; }
							break L;
						case 'i': X="while";id=Id_while; break L;
						case 'l': X="false";id=Id_false; break L;
						case 'n': c=s.charAt(0);
							if (c==='c') { X="const";id=Id_const; }
							else if (c==='f') { X="final";id=Id_final; }
							break L;
						case 'o': c=s.charAt(0);
							if (c==='f') { X="float";id=Id_float; }
							else if (c==='s') { X="short";id=Id_short; }
							break L;
						case 'p': X="super";id=Id_super; break L;
						case 'r': X="throw";id=Id_throw; break L;
						case 't': X="catch";id=Id_catch; break L;
					} break L;
					case 6: switch (s.charAt(1)) {
						case 'a': X="native";id=Id_native; break L;
						case 'e': c=s.charAt(0);
							if (c==='d') { X="delete";id=Id_delete; }
							else if (c==='r') { X="return";id=Id_return; }
							break L;
						case 'h': X="throws";id=Id_throws; break L;
						case 'm': X="import";id=Id_import; break L;
						case 'o': X="double";id=Id_double; break L;
						case 't': X="static";id=Id_static; break L;
						case 'u': X="public";id=Id_public; break L;
						case 'w': X="switch";id=Id_switch; break L;
						case 'x': X="export";id=Id_export; break L;
						case 'y': X="typeof";id=Id_typeof; break L;
					} break L;
					case 7: switch (s.charAt(1)) {
						case 'a': X="package";id=Id_package; break L;
						case 'e': X="default";id=Id_default; break L;
						case 'i': X="finally";id=Id_finally; break L;
						case 'o': X="boolean";id=Id_boolean; break L;
						case 'r': X="private";id=Id_private; break L;
						case 'x': X="extends";id=Id_extends; break L;
					} break L;
					case 8: switch (s.charAt(0)) {
						case 'a': X="abstract";id=Id_abstract; break L;
						case 'c': X="continue";id=Id_continue; break L;
						case 'd': X="debugger";id=Id_debugger; break L;
						case 'f': X="function";id=Id_function; break L;
						case 'v': X="volatile";id=Id_volatile; break L;
					} break L;
					case 9: c=s.charAt(0);
						if (c==='i') { X="interface";id=Id_interface; }
						else if (c==='p') { X="protected";id=Id_protected; }
						else if (c==='t') { X="transient";id=Id_transient; }
						break L;
					case 10: c=s.charAt(1);
						if (c==='m') { X="implements";id=Id_implements; }
						else if (c==='n') { X="instanceof";id=Id_instanceof; }
						break L;
					case 12: X="synchronized";id=Id_synchronized; break L;
				}
				if (X !== null && X !== s) id = 0;
			}
			// #/generated#
			// #/string_id_map#
			if (id === 0) { return Token.EOF; }
			return id & 0xff;
		}
		
		public function getSourceString():String { return sourceString; }
		
		public function getLineno():int { return lineno; }
		
		public function getString():String { return string; }
		
		public function getQuoteChar():int { return quoteChar; }
		
		public function getNumber():Number { return number; }
		
		public function isNumberOctal():Boolean { return isOctal; }
		
		public function eof():Boolean { return hitEOF; }
		
		public function getToken():int {
			var c:int;
			
			retry:
			for(;;) {
				// Eat whitespace, possibly sensitive to newlines.
				for(;;) {
					c = getChar();
					if (c === EOF_CHAR) {
						tokenBeg = cursor - 1;
						tokenEnd = cursor;
						return Token.EOF;
					}
					else if (c === 10) { // '\n'
						dirtyLine = false;
						tokenBeg = cursor - 1;
						tokenEnd = cursor;
						return Token.EOL;
					}
					else if (!isJSSpace(c)) {
						if (c !== 45) { // '-'
							dirtyLine = true;
						}
						break;
					}
				}
				
				tokenBeg = cursor - 1;
				tokenEnd = cursor;
				
				if (c === 64) return Token.XMLATTR; // 64 = @
				
				// identifier/keyword/instanceof?
				// watch out for starting with a <backslash>
				var identifierStart:Boolean;
				var isUnicodeEscapeStart:Boolean = false;
				if (c === 92) { // 92 = \ (backslash)
					c = getChar();
					if (c === 0x75) { // 0x63 = u
						identifierStart = true;
						isUnicodeEscapeStart = true;
						stringBufferTop = 0;
					} else {
						identifierStart = false;
						ungetChar(c);
						c = 92; // 92 = \ (backslash)
					}
				} else {
					identifierStart = Character.isJavaIdentifierStart(c);
					if (identifierStart) {
						stringBufferTop = 0;
						addToString(c);
					}
				}
				
				if (identifierStart) {
					var containsEscape:Boolean = isUnicodeEscapeStart;
					for (;;) {
						if (isUnicodeEscapeStart) {
							// strictly speaking we should probably push-back
							// all the bad characters if the <backslash>uXXXX
							// sequence is malformed. But since there isn't a
							// correct context(is there?) for a bad Unicode
							// escape sequence in an identifier, we can report
							// an error here.
							var escapeVal:int = 0;
							for (var i:int = 0; i !== 4; ++i) {
								c = getChar();
								escapeVal = Kit.xDigitToInt(c, escapeVal);
								// Next check takes care about c < 0 and bad escape
								if (escapeVal < 0) { break; }
							}
							if (escapeVal < 0) {
								parser.addError("msg.invalid.escape");
								return Token.ERROR;
							}
							addToString(escapeVal);
							isUnicodeEscapeStart = false;
						} else {
							c = getChar();
							if (c === 0x5c /* \ */) {
								c = getChar();
								if (c === 0x75 /* u */) {
									isUnicodeEscapeStart = true;
									containsEscape = true;
								} else {
									parser.addError("msg.illegal.character");
									return Token.ERROR;
								}
							} else {
								if (c === EOF_CHAR || c === BYTE_ORDER_MARK
									|| !Character.isJavaIdentifierPart(c))
								{
									break;
								}
								addToString(c);
							}
						}
					}
					ungetChar(c);
					
					var str:String = getStringFromBuffer();
					if (!containsEscape) {
						// OPT we shouldn't have to make a string (object!) to
						// check if it's a keyword.
						
						// Return the corresponding token if it's a keyword
						var result:int = stringToKeyword(str);
						if (result !== Token.EOF) {
							if ((result === Token.LET || result === Token.YIELD) &&
								parser.compilerEnv.getLanguageVersion()
								< Context.VERSION_1_7)
							{
								// LET and YIELD are tokens only in 1.7 and later
								string = result == Token.LET ? "let" : "yield";
								result = Token.NAME;
							}
							// Save the string in case we need to use in
							// object literal definitions.
							
							allStrings[str] = 0;
							this.string = str;
							if (result != Token.RESERVED) {
								return result;
							} else if (!parser.compilerEnv.
								isReservedKeywordAsIdentifier())
							{
								return result;
							}
						}
					} else if (isKeyword(str)) {
						// If a string contains unicodes, and converted to a keyword,
						// we convert the last character back to unicode
						str = convertLastCharToHex(str);
					}
					allStrings[str] = 0;
					this.string = str;
					return Token.NAME;
				}
				
				// is it a number?
				if (isDigit(c) || (c === 0x2e /* . */ && isDigit(peekChar()))) {
					isOctal = false;
					stringBufferTop = 0;
					var base:int = 10;
					
					if (c === 0x30 /* 0 */) {
						c = getChar();
						if (c === 0x78 /* x */ || c === 0x58 /* X */) {
							base = 16;
							c = getChar();
						} else if (isDigit(c)) {
							base = 8;
							isOctal = true;
						} else {
							addToString(0x30 /* 0 */);
						}
					}
					
					if (base === 16) {
						while (0 <= Kit.xDigitToInt(c, 0)) {
							addToString(c);
							c = getChar();
						}
					} else {
						while (0x30 /* 0 */ <= c && c <= 0x39 /* 9 */) {
							/*
							* We permit 08 and 09 as decimal numbers, which
							* makes our behavior a superset of the ECMA
							* numeric grammar.  We might not always be so
							* permissive, so we warn about it.
							*/
							if (base === 8 && c >= 0x38 /* 8 */) {
								parser.addWarning("msg.bad.octal.literal",
												  String.fromCharCode(c));
								base = 10;
							}
							addToString(c);
							c = getChar();
						}
					}
					
					var isInteger:Boolean = true;
					if (base === 10 && (c === 0x2e /* . */ || c === 0x65 /* e */ || c === 0x45 /* E */)) {
						isInteger = false;
						if (c === 0x2e) {
							do {
								addToString(c);
								c = getChar();
							} while (isDigit(c));
						}
						if (c === 0x65 /* e */ || c === 0x45 /* E */) {
							addToString(c);
							c = getChar();
							if (c === 0x2b /* + */ || c === 0x2d /* - */) {
								addToString(c);
								c = getChar();
							}
							if (!isDigit(c)) {
								parser.addError("msg.missing.exponent");
								return Token.ERROR;
							}
							do {
								addToString(c);
								c = getChar();
							} while (isDigit(c));
						}
					}
					ungetChar(c);
					var numString:String = getStringFromBuffer();
					this.string = numString;
					
					var dval:Number;
					if (base === 10 && !isInteger) {
						dval = parseFloat(numString);
						if (isNaN(dval)) {
							parser.addError("msg.caught.nfe");
							return Token.ERROR;
						}
					} else {
//						dval = ScriptRuntime.stringToNumber(numString, 0, base);
						// ... lets just use parseInt, shall we?
						dval = parseInt(numString, base);
					}
					
					this.number = dval;
					return Token.NUMBER;
				}
				
				// is it a string?
				if (c === 0x22 /* " */ || c === 0x27 /* ' */) {
					// We attempt to accumulate a string the fast way, by
					// building it directly out of the reader.  But if there
					// are any escaped characters in the string, we revert to
					// building it out of a StringBuffer.
					
					quoteChar = c;
					stringBufferTop = 0;
					
					c = getChar(false);
					strLoop: while (c !== quoteChar) {
						if (c === 0x0A /* \n */ || c === EOF_CHAR) {
							ungetChar(c);
							tokenEnd = cursor;
							parser.addError("msg.unterminated.string.lit");
							return Token.ERROR;
						}
						
						if (c === 0x5c /* \ */) {
							// We've hit an escaped character
//							var escapeVal:int; // already defined above
							
							c = getChar();
							switch(String.fromCharCode(c)) {
							case 'b': c = 0x08 /* backspace */; break;
							case 'f': c = 0x0C /* form feed */; break;
							case 'n': c = 0x0A /* line break */; break;
							case 'r': c = 0x0D /* carriage return */; break;
							case 't': c = 0x09 /* horizontal tab */; break;
							
							// \v a late addition to the ECMA spec,
							// it is not in Java, so use 0xb
							case 'v': c = 0x0b /* line tabulation */; break;
							
							case 'u':
								// Get 4 hex digits; if the u escape is not
								// followed by 4 hex digits, use 'u' + the
								// literal character sequence that follows.
								var escapeStart:int = stringBufferTop;
								addToString(0x75 /* u */);
								escapeVal = 0;
								for (i = 0; i != 4; ++i) {
									c = getChar();
									escapeVal = Kit.xDigitToInt(c, escapeVal);
									if (escapeVal< 0) {
										continue strLoop;
									}
									addToString(c);
								}
								// prepare for replace of stored 'u' sequence
								// by escape value
								stringBufferTop = escapeStart;
								c = escapeVal;
								break;
							case 'x':
								// Get 2 hex digits, defaulting to 'x'+literal
								// sequence, as above.
								c = getChar();
								escapeVal = Kit.xDigitToInt(c, 0);
								if (escapeVal < 0) {
									addToString(0x78 /* x */);
									continue strLoop;
								} else {
									var c1:int = c;
									c = getChar();
									escapeVal = Kit.xDigitToInt(c, escapeVal);
									if (escapeVal < 0) {
										addToString(0x78 /* x */);
										addToString(c1);
										continue strLoop;
									} else {
										// got 2 hex digits
										c = escapeVal;
									}
								}
								break;
							
							case '\n':
								// Remove line terminator after escape to follow
								// SpiderMonkey and C/C++
								c = getChar();
								continue strLoop;
								
							default:
								if (0x30 /* 0 */ <= c && c <= 0x38 /* 8 */) {
									var val:int = c - 0x30 /* 0 */;
									c = getChar();
									if (0x30 /* 0 */ <= c && c <= 0x38 /* 8 */) {
										val = 8 * val + c - 0x30 /* 0 */;
										c = getChar();
										if (0x30 /* 0 */ <= c && c < 0x38 /* 8 */ && val <= 037) {
											// c is 3rd char of octal sequence only
											// if the resulting val <= 0377
											val = 8 * val + c - 0x30 /* 0 */;
											c = getChar();
										}
									}
									ungetChar(c);
									c = val;
								}
							}
						}
						addToString(c);
						c = getChar(false);
					}
					
					str = getStringFromBuffer();
					allStrings[str] = 0;
					this.string = str;
					return Token.STRING;
				}
				
				switch (String.fromCharCode(c)) {
					case ';': return Token.SEMI;
					case '[': return Token.LB;
					case ']': return Token.RB;
					case '{': return Token.LC;
					case '}': return Token.RC;
					case '(': return Token.LP;
					case ')': return Token.RP;
					case ',': return Token.COMMA;
					case '?': return Token.HOOK;
					case ':':
						if (matchChar(0x3A /* : */)) {
							return Token.COLONCOLON;
						} else {
							return Token.COLON;
						}
					case '.':
						if (matchChar(0x2E /* . */)) {
							return Token.DOTDOT;
						} else if (matchChar(0x28 /* ( */)) {
							return Token.DOTQUERY;
						} else {
							return Token.DOT;
						}
						
					case '|':
						if (matchChar(0x7c /* | */)) {
							return Token.OR;
						} else if (matchChar(0x3d /* = */)) {
							return Token.ASSIGN_BITOR;
						} else {
							return Token.BITOR;
						}
						
					case '^':
						if (matchChar(0x3d /* = */)) {
							return Token.ASSIGN_BITXOR;
						} else {
							return Token.BITXOR;
						}
						
					case '&':
						if (matchChar(0x26 /* & */)) {
							return Token.AND;
						} else if (matchChar(0x3d /* = */)) {
							return Token.ASSIGN_BITAND;
						} else {
							return Token.BITAND;
						}
					
					case '=':
						if (matchChar(0x3d /* = */)) {
							if (matchChar(0x3d /* = */)) {
								return Token.SHEQ;
							} else {
								return Token.EQ;
							}
						} else {
							return Token.ASSIGN;
						}
					
					case '!':
						if (matchChar(0x3d /* = */)) {
							if (matchChar(0x3d /* = */)) {
								return Token.SHNE;
							} else {
								return Token.NE;
							}
						} else {
							return Token.NOT;
						}
					
					case '<':
						/* NB:treat HTML begin-comment as comment-till-eol */
						if (matchChar(0x21 /* ! */)) {
							if (matchChar(0x2d /* - */)) {
								if (matchChar(0x2d /* - */)) {
									tokenBeg = cursor - 4;
									skipLine();
									commentType = Token.COMMENT_TYPE_HTML;
									return Token.COMMENT;
								}
								ungetCharIgnoreLineEnd(0x2d);
							}
							ungetCharIgnoreLineEnd(0x21);
						}
						if (matchChar(0x3c /* < */)) {
							if (matchChar(0x3d /* = */)) {
								return Token.ASSIGN_LSH;
							} else {
								return Token.LSH;
							}
						} else {
							if (matchChar(0x3d /* = */)) {
								return Token.LE;
							} else {
								return Token.LT;
							}
						}
						
					case '>':
						if (matchChar(0x3e /* > */)) {
							if (matchChar(0x3e /* > */)) {
								if (matchChar(0x3d /* = */)) {
									return Token.ASSIGN_URSH;
								} else {
									return Token.URSH;
								}
							} else {
								if (matchChar(0x3d /* = */)) {
									return Token.ASSIGN_RSH;
								} else {
									return Token.RSH;
								}
							}
						} else {
							if (matchChar(0x3d /* = */)) {
								return Token.GE;
							} else {
								return Token.GT;
							}
						}
						
					case '*':
						if (matchChar(0x3d /* = */)) {
							return Token.ASSIGN_MUL;
						} else {
							return Token.MUL;
						}
						
					case '/':
						markCommentStart();
						// is it a // comment?
						if (matchChar(0x2f /* / */)) {
							tokenBeg = cursor - 2;
							skipLine();
							commentType = Token.COMMENT_TYPE_LINE;
							return Token.COMMENT;
						}
						// is it a /* or /** comment?
						if (matchChar(0x2a /* * */)) {
							var lookForSlash:Boolean = false;
							tokenBeg = cursor - 2;
							if (matchChar(0x2a /* * */)) {
								lookForSlash = true;
								commentType = Token.COMMENT_TYPE_JSDOC;
							} else {
								commentType = Token.COMMENT_TYPE_BLOCK_COMMENT;
							}
							for (;;) {
								c = getChar();
								if (c === EOF_CHAR) {
									tokenEnd = cursor - 1;
									parser.addError("msg.unterminated.comment");
									return Token.COMMENT;
								} else if (c === 0x2a /* * */) {
									lookForSlash = true;
								} else if (c === 0x2f /* / */) {
									if (lookForSlash) {
										tokenEnd = cursor;
										return Token.COMMENT;
									}
								} else {
									lookForSlash = false;
									tokenEnd = cursor;
								}
							}
						}
						
						if (matchChar(0x3d /* = */)) {
							return Token.ASSIGN_DIV;
						} else {
							return Token.DIV;
						}
						
					case '%':
						if (matchChar(0x3d /* = */)) {
							return Token.ASSIGN_MOD;
						} else {
							return Token.MOD;
						}
						
					case '~':
						return Token.BITNOT;
						
					case '+':
						if (matchChar(0x3d /* = */)) {
							return Token.ASSIGN_ADD;
						} else if (matchChar(0x2b /* + */)) {
							return Token.INC;
						} else {
							return Token.ADD;
						}
						
					case '-':
						if (matchChar(0x3d /* = */)) {
							c = Token.ASSIGN_SUB;
						} else if (matchChar(0x2d /* - */)) {
							if (!dirtyLine) {
								// treat HTML end-comment after possible whitespace
								// after line start as comment-until-eol
								if (matchChar(0x3e /* > */)) {
									markCommentStart("--");
									skipLine();
									commentType = Token.COMMENT_TYPE_HTML;
									return Token.COMMENT;
								}
							}
							c = Token.DEC;
						} else {
							c = Token.SUB;
						}
						dirtyLine = true;
						return c;
						
					default:
						parser.addError("msg.illegal.character");
						return Token.ERROR;
				}
			}
		}
		
		public static function isAlpha(c:int):Boolean {
			if (c <= 0x5a /* Z */) {
				return 0x41 /* A */ <= c;
			}
			else {
				return 0x61 /* a */ <= c && c <= 0x7a /* z */;
			}
		}
		
		public static function isDigit(c:int):Boolean {
			return 0x30 /* 0 */ <= c && c <= 0x39 /* 9 */;
		}
		
		/* As defined in ECMA.  jsscan.c uses C isspace() (which allows
		* \v, I think.)  note that code in getChar() implicitly accepts
		* '\r' == \u000D as well.
		*/
		public static function isJSSpace(c:int):Boolean {
			if (c <= 127) {
				return c === 0x20 || c === 0x9 || c === 0xC || c === 0xB;
			}
			else {
				return c === 0xA0 || c === BYTE_ORDER_MARK || Character.getType(c) === Character.SPACE_SEPARATOR;
			}
		}
		
		public static function isJSFormatChar(c:int):Boolean {
			return c > 127 && Character.getType(c) === Character.FORMAT; 
		}
		
		/**
		 * Parser calls the method when it gets / or /= in literal context.
		 */
		// throws IOError
		public function readRegExp(startToken:int):void {
			var start:int = tokenBeg;
			stringBufferTop = 0;
			if (startToken === Token.ASSIGN_DIV) {
				// Mis-scanned /=
				addToString(0x3d); /* 0x3d = '=' */
			}
			else {
				if (startToken !== Token.DIV) Kit.codeBug();
			}
			
			var inCharSet:Boolean = false; // true if inside a '['..']' pair
			var c:int;
			while ((c = getChar()) !== 0x2f /* / */ || inCharSet) {
				if (c === 0x0A /* \n */ || c === EOF_CHAR) {
					ungetChar(c);
					tokenEnd = cursor - 1;
					this.string = System.intVectorToString(stringBuffer, 0, stringBufferTop);
					parser.reportError("msg.unterminated.re.lit");
					return;
				}
				if (c === 0x5C /* \ */) {
					addToString(c);
					c = getChar();
				} else if (c === 0x5B /* [ */) {
					inCharSet = true;
				} else if (c === 0x5D /* ] */) {
					inCharSet = false;
				}
				addToString(c);
			}
			var reEnd:int = stringBufferTop;
			
			while (true) {
				if (matchChar(0x67 /* g */))
					addToString(0x67 /* g */);
				else if (matchChar(0x69 /* i */))
					addToString(0x69 /* i */);
				else if (matchChar(0x6D /* m */))
					addToString(0x6D /* m */);
				else if (matchChar(0x79 /* y */))
					addToString(0x79 /* y */);
				else
					break;
			}
			tokenEnd = start + stringBufferTop + 2;
			
			if (isAlpha(peekChar())) {
				parser.reportError('msg.invalid.re.flag');
			}
			
			this.string = System.intVectorToString(stringBuffer, 0, reEnd);
			this.regExpFlags = System.intVectorToString(stringBuffer, reEnd, stringBufferTop - reEnd);
		}
		
		public function readAndClearRegExpFlags():String {
			var flags:String = this.regExpFlags;
			this.regExpFlags = null;
			return flags;
		}
		
		public function isXMLAttribute():Boolean {
			return xmlIsAttribute;
		}
		
		// Throws IOError
		public function getFirstXMLToken():int {
			xmlOpenTagsCount = 0;
			xmlIsAttribute = false;
			xmlIsTagContent = false;
			if (!canUngetChar())
				return Token.ERROR;
			ungetChar(60); // '<' = 60
			return getNextXMLToken();
		}
		
		// Throws IOError
		public function getNextXMLToken():int {
			tokenBeg = cursor;
			stringBufferTop = 0; // remember the XML
			
			for (var c:int = getChar(); c !== EOF_CHAR; c = getChar()) {
				if (xmlIsTagContent) {
					switch (c) {
						case 0x3E /* > */:
							addToString(c);
							xmlIsTagContent = false;
							xmlIsAttribute = false;
							break;
						case 0x2F /* / */:
							addToString(c);
							if (peekChar() === 0x3E /* > */) {
								c = getChar();
								addToString(c);
								xmlIsTagContent = false;
								xmlOpenTagsCount--;
							}
							break;
						case 0x7B /* { */:
							ungetChar(c);
							this.string = getStringFromBuffer();
							return Token.XML;
						case 0x27 /* ' */:
						case 0x22 /* " */:
							addToString(c);
							if (!readQuotedString(c)) return Token.ERROR;
							break;
						case 0x3D /* = */:
							addToString(c);
							xmlIsAttribute = true;
							break;
						case 0x20 /* <space> */:
						case 0x09 /* <tab> */:
						case 0x0D /* <cr> */:
						case 0x0A /* <lf> */:
							addToString(c);
							break;
						default:
							addToString(c);
							xmlIsAttribute = false;
							break;
					}
					
					if (!xmlIsTagContent && xmlOpenTagsCount == 0) {
						this.string = getStringFromBuffer();
						return Token.XMLEND;
					}
				} else {
					switch (c) {
						case 0x3C /* < */:
							addToString(c);
							c = peekChar();
							switch (c) {
								case 0x21 /* ! */:
									c = getChar(); // Skip !
									addToString(c);
									c = peekChar();
									switch (c) {
										case 0x2D /* - */:
											c = getChar(); // Skip -
											addToString(c);
											c = getChar();
											if (c === 0x2D /* - */) {
												addToString(c);
												if(!readXmlComment()) return Token.ERROR;
											} else {
												// throw away the string in progress
												stringBufferTop = 0;
												this.string = null;
												parser.addError("msg.XML.bad.form");
												return Token.ERROR;
											}
											break;
										case 0x5B /* [ */:
											c = getChar(); // Skip [
											addToString(c);
											if (getChar() === 0x43 /* C */ &&
												getChar() === 0x44 /* D */ &&
												getChar() === 0x41 /* A */ &&
												getChar() === 0x54 /* T */ &&
												getChar() === 0x41 /* A */ &&
												getChar() === 0x5B /* [ */)
											{
												addToString(0x43 /* C */);
												addToString(0x44 /* D */);
												addToString(0x41 /* A */);
												addToString(0x54 /* T */);
												addToString(0x41 /* A */);
												addToString(0x5B /* [ */);
												if (!readCDATA()) return Token.ERROR;
												
											} else {
												// throw away the string in progress
												stringBufferTop = 0;
												this.string = null;
												parser.addError("msg.XML.bad.form");
												return Token.ERROR;
											}
											break;
										default:
											if(!readEntity()) return Token.ERROR;
											break;
									}
									break;
								case 0x3F /* ? */:
									c = getChar(); // Skip ?
									addToString(c);
									if (!readPI()) return Token.ERROR;
									break;
								case 0x2F /* / */:
									// End tag
									c = getChar(); // Skip /
									addToString(c);
									if (xmlOpenTagsCount == 0) {
										// throw away the string in progress
										stringBufferTop = 0;
										this.string = null;
										parser.addError("msg.XML.bad.form");
										return Token.ERROR;
									}
									xmlIsTagContent = true;
									xmlOpenTagsCount--;
									break;
								default:
									// Start tag
									xmlIsTagContent = true;
									xmlOpenTagsCount++;
									break;
							}
							break;
						case 0x7B /* { */:
							ungetChar(c);
							this.string = getStringFromBuffer();
							return Token.XML;
						default:
							addToString(c);
							break;
					}
				}
			}
			
			tokenEnd = cursor;
			stringBufferTop = 0; // throw away the string in progress
			this.string = null;
			parser.addError("msg.XML.bad.form");
			return Token.ERROR;
		}
		
		// Throws IOError
		private function readQuotedString(quote:int):Boolean {
			for (var c:int = getChar(); c !== EOF_CHAR; c = getChar()) {
				addToString(c);
				if (c === quote) return true;
			}
			
			stringBufferTop = 0; // throw away the string in progress
			this.string = null;
			parser.addError("msg.XML.bad.form");
			return false;
		}
		
		private function readXmlComment():Boolean {
			for (var c:int = getChar(); c !== EOF_CHAR;) {
				addToString(c);
				if (c === 0x2D /* - */ && peekChar() === 0x2D /* - */) {
					c = getChar();
					addToString(c);
					if (peekChar() === 0x3E /* > */) {
						c = getChar(); // Skip >
						addToString(c);
						return true;
					} else {
						continue;
					}
				}
				c = getChar();
			}
			
			stringBufferTop = 0; // throw away the string in progress
			this.string = null;
			parser.addError("msg.XML.bad.form");
			return false;
		}
		
		private function readCDATA():Boolean {
			for (var c:int = getChar(); c !== EOF_CHAR;) {
				addToString(c);
				if (c === 0x5D /* ] */ && peekChar() === 0x5D) {
					c = getChar();
					addToString(c);
					if (peekChar() === 0x3E /* > */) {
						c = getChar(); // Skip >
						addToString(c);
						return true;
					} else {
						continue;
					}
				}
				c = getChar();
			}
			
			stringBufferTop = 0; // throw away the string in progress
			this.string = null;
			parser.addError("msg.XML.bad.form");
			return false;
		}
		
		private function readEntity():Boolean {
			var declTags:int = 1;
			for (var c:int = getChar(); c !== EOF_CHAR; c = getChar()) {
				addToString(c);
				switch (c) {
					case 0x3C /* < */:
						declTags++;
						break;
					case 0x3E /* > */:
						declTags--;
						if (declTags == 0) return true;
						break;
				}
			}
			
			stringBufferTop = 0; // throw away the string in progress
			this.string = null;
			parser.addError("msg.XML.bad.form");
			return false;
		}
		
		/**
		 * @throws IOError
		 */
		private function readPI():Boolean {
			for (var c:int = getChar(); c !== EOF_CHAR; c = getChar()) {
				addToString(c);
				if (c === 0x3F /* ? */ && peekChar() === 0x3E /* > */) {
					c = getChar(); // Skip >
					addToString(c);
					return true;
				}
			}
			
			stringBufferTop = 0; // throw away the string in progress
			this.string = null;
			parser.addError("msg.XML.bad.form");
			return false;
		}
		
		private function getStringFromBuffer():String {
			tokenEnd = cursor;
			return System.intVectorToString(stringBuffer, 0, stringBufferTop);
		}
		
		private function addToString(c:int):void {
			var N:int = stringBufferTop;
			if (N === stringBuffer.length) {
				var tmp:Vector.<int> = new Vector.<int>(stringBuffer.length * 2);
				System.intVectorCopy(stringBuffer, 0, tmp, 0, N);
				stringBuffer = tmp;
			}
			stringBuffer[N] = c;
			stringBufferTop = N + 1;
		}
		
		private function canUngetChar():Boolean {
			return ungetCursor === 0 || ungetBuffer[ungetCursor - 1] !== 0x0A;
		}
		
		private function ungetChar(c:int):void {
			// can not unread past across line boundary
			if (ungetCursor !== 0 && ungetBuffer[ungetCursor - 1] === 0x0A) {
				Kit.codeBug();
			}
			ungetBuffer[ungetCursor++] = c;
			cursor --;
		}
		
		// Throws IOError
		private function matchChar(test:int):Boolean {
			var c:int = getCharIgnoreLineEnd();
			if (c === test) {
				tokenEnd = cursor;
				return true;
			}
			else {
				ungetCharIgnoreLineEnd(c);
				return false;
			}
		}
		
		// Throws IOError
		private function peekChar():int {
			var c:int = getChar();
			ungetChar(c);
			return c;
		}
		
		// Throws IOError
		private function getChar(skipFormattingChars:Boolean = true):int {
			if (ungetCursor !== 0) {
				cursor++;
				return ungetBuffer[--ungetCursor];
			}
			
			for(;;) {
				var c:int;
				if (sourceString !== null) {
					if (sourceCursor === sourceEnd) {
						hitEOF = true;
						return EOF_CHAR;
					}
					cursor++;
					c = sourceString.charCodeAt(sourceCursor++);
				}
				else {
					if (sourceCursor === sourceEnd) {
						if (!fillSourceBuffer()) {
							hitEOF = true;
							return EOF_CHAR;
						}
					}
					cursor++;
					c = sourceBuffer[sourceCursor++];
				}
				
				if (lineEndChar >= 0) {
					if (lineEndChar === 13 && c === 10) { // '\r' = 13, '\n' = 10
						lineEndChar = 10;
						continue;
					}
					lineEndChar = -1;
					lineStart = sourceCursor - 1;
					lineno++;
				}
				
				if (c <= 127) {
					if (c === 10 || c === 13) { // '\r' = 13, '\n' = 10
						lineEndChar = c;
						c = 10;
					}
				}
				else {
					if (c === BYTE_ORDER_MARK) return c; // BOM is considered whitespace
					if (skipFormattingChars && isJSFormatChar(c)) {
						continue;
					}
					if (ScriptRuntime.isJSLineTerminator(c)) {
						lineEndChar = c;
						c = 10;
					}
				}
				return c;
			}
		}
		
		// Throws IOError
		private function getCharIgnoreLineEnd():int {
			if (ungetCursor !== 0) {
				cursor ++;
				return ungetBuffer[--ungetCursor];
			}
			
			for(;;) {
				var c:int;
				if (sourceString !== null) {
					if (sourceCursor === sourceEnd) {
						hitEOF = true;
						return EOF_CHAR;
					}
					cursor ++;
					c = sourceString.charCodeAt(sourceCursor++);
				}
				else {
					if (sourceCursor === sourceEnd) {
						if (!fillSourceBuffer()) {
							hitEOF = true;
							return EOF_CHAR;
						}
					}
					cursor ++;
					c = sourceBuffer[sourceCursor++];
				}

				if (c <= 127) {
					if (c === 10 || c === 13) { // '\n' = 10, '\r' = 13
						lineEndChar = c;
						c = 10; // '\n' = 10
					}
				}
				else {
					if (c === BYTE_ORDER_MARK) return c; // BOM is considered whitespace
					if (isJSFormatChar(c)) {
						continue;
					}
					if (ScriptRuntime.isJSLineTerminator(c)) {
						lineEndChar = c;
						c = 10; // '\n' = 10
					}
				}
				return c;
			}
		}
		
		private function ungetCharIgnoreLineEnd(c:int):void {
			ungetBuffer[ungetCursor++] = c;
			cursor--;
		}
		
		// Throws IOError
		private function skipLine():void {
			// skip to end of line
			var c:int;
			while((c = getChar()) !== EOF_CHAR && c !== 10) { } // '\n' = 10
			ungetChar(c);
			tokenEnd = cursor;
		}
		
		/**
		 * Returns the offset into the current line.
		 */
		public final function getOffset():int {
			var n:int = sourceCursor - lineStart;
			if (lineEndChar >= 0) { --n; }
			return n;
		}
		
		public final function getLine():String {
			var c:int;
			if (sourceString !== null) {
				// String case
				var lineEnd:int = sourceCursor;
				if (lineEndChar >= 0) {
					--lineEnd;
				}
				else {
					for (; lineEnd !== sourceEnd; ++lineEnd) {
						c = sourceString.charCodeAt(lineEnd);
						if (ScriptRuntime.isJSLineTerminator(c)) {
							break;
						}
					}
				}
				return sourceString.substring(lineStart, lineEnd);
			}
			else {
				// Reader case
				var lineLength:int = sourceCursor - lineStart;
				if (lineEndChar >= 0) {
					--lineLength;
				}
				else {
					// Read until the end of line
					for (;; ++lineLength) {
						var i:int = lineStart + lineLength;
						if (i === sourceEnd) {
							try {
								if (!fillSourceBuffer()) { break; }
							}
							catch(e:IOError) {
								// ignore it, we're already displaying an error...
								break;
							}
							// i recalculation as fillSourceBuffer can move saved
							// line buffer and change lineStart
							i = lineStart + lineLength;
						}
						c = sourceBuffer[i];
						if (ScriptRuntime.isJSLineTerminator(c)) {
							break;
						}
					}
				}
				return TokenStream.bufferToString(sourceBuffer, lineStart, lineLength);
			}
		}
		
		// Throws IOError
		private function fillSourceBuffer():Boolean {
			if (sourceString !== null) Kit.codeBug();
			if (sourceEnd === sourceBuffer.length) {
				if (lineStart !== 0 && !isMarkingComment()) {
					org.mozilla.javascript.System.intVectorCopy(sourceBuffer, lineStart, sourceBuffer, 0, sourceEnd - lineStart);
					sourceEnd -= lineStart;
					sourceCursor -= lineStart;
					lineStart = 0;
				}
				else {
					var tmp:Vector.<int> = new Vector.<int>(sourceBuffer.length * 2);
					org.mozilla.javascript.System.intVectorCopy(sourceBuffer, 0, tmp, 0, sourceEnd);
					sourceBuffer = tmp;
				}
			}
			var n:int = sourceReader.read(sourceBuffer, sourceEnd,
										  sourceBuffer.length - sourceEnd);
			if (n < 0) {
				return false;
			}
			sourceEnd += n;
			return true;
		}
		
		public static function bufferToString(buf:Vector.<int>, start:int, end:int):String {
			var s:String = "";
			for (; start < end; start++) {
				s += String.fromCharCode(buf[start]);
			}
			return s;
		}
		
		/**
		 * Return the current position of the scanner cursor
		 */
		public function getCursor():int {
			return cursor;
		}
		
		/**
		 * Return the absolute source offset of the last scanned token.
		 */
		public function getTokenBeg():int {
			return tokenBeg;
		}
		
		/**
		 * Return the absolute source end-offset of the last scanned token.
		 */
		public function getTokenEnd():int {
			return tokenEnd;
		}
		
		/**
		 * Return tokenEnd - tokenBeg
		 */
		public function getTokenLength():int {
			return tokenEnd - tokenBeg;
		}
		
		/**
		 * Return the type of the last scanned comment.
		 * @return type of last scanned comment, or 0 if none have been scanned.
		 */
		public function getCommentType():int {
			return commentType;
		}
		
		private function markCommentStart(prefix:String = ""):void {
			if (parser.compilerEnv.isRecordingComments() && sourceReader !== null) {
				commentPrefix = prefix;
				commentCursor = sourceCursor - 1;
			}
		}
		
		private function isMarkingComment():Boolean {
			return commentCursor !== -1;
		}
		
		public final function getAndResetCurrentComment():String {
			if (sourceString !== null) {
				if (isMarkingComment()) Kit.codeBug();
				return sourceString.substring(tokenBeg, tokenEnd);
			} else { }
			
			throw new Error("Unimplemented: non-string source");
			// Original Java Source:
//			if (!isMarkingComment()) Kit.codeBug();
//			StringBuilder comment = new StringBuilder(commentPrefix);
//			comment.append(sourceBuffer, commentCursor,
//				getTokenLength() - commentPrefix.length());
//			commentCursor = -1;
//			return comment.toString();
//			}
		}
		
		public final function convertLastCharToHex(str:String):String {
			var lastIndex:int = str.length - 1;
			var buf:String = str.substring(0, lastIndex) + "\\u";
			var hexCode:String = str.charCodeAt(lastIndex).toString(16);
			for (var i:int = 0; i < 4-hexCode.length; ++i) {
				buf += '0';
			}
			buf += hexCode;
			return buf;
		}
	}
}