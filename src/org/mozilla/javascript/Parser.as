package org.mozilla.javascript
{
	import flash.errors.IOError;
	import flash.errors.StackOverflowError;
	
	import org.as3commons.collections.StringSet;
	import org.as3commons.collections.framework.ISet;
	import org.mozilla.javascript.ast.ArrayComprehension;
	import org.mozilla.javascript.ast.ArrayComprehensionLoop;
	import org.mozilla.javascript.ast.ArrayLiteral;
	import org.mozilla.javascript.ast.Assignment;
	import org.mozilla.javascript.ast.AstNode;
	import org.mozilla.javascript.ast.AstRoot;
	import org.mozilla.javascript.ast.Block;
	import org.mozilla.javascript.ast.BreakStatement;
	import org.mozilla.javascript.ast.CatchClause;
	import org.mozilla.javascript.ast.Comment;
	import org.mozilla.javascript.ast.ConditionalExpression;
	import org.mozilla.javascript.ast.ContinueStatement;
	import org.mozilla.javascript.ast.DoLoop;
	import org.mozilla.javascript.ast.ElementGet;
	import org.mozilla.javascript.ast.EmptyExpression;
	import org.mozilla.javascript.ast.EmptyStatement;
	import org.mozilla.javascript.ast.ErrorNode;
	import org.mozilla.javascript.ast.ExpressionStatement;
	import org.mozilla.javascript.ast.ForInLoop;
	import org.mozilla.javascript.ast.ForLoop;
	import org.mozilla.javascript.ast.FunctionCall;
	import org.mozilla.javascript.ast.FunctionNode;
	import org.mozilla.javascript.ast.GeneratorExpression;
	import org.mozilla.javascript.ast.GeneratorExpressionLoop;
	import org.mozilla.javascript.ast.IDestructuringForm;
	import org.mozilla.javascript.ast.IfStatement;
	import org.mozilla.javascript.ast.InfixExpression;
	import org.mozilla.javascript.ast.Jump;
	import org.mozilla.javascript.ast.KeywordLiteral;
	import org.mozilla.javascript.ast.Label;
	import org.mozilla.javascript.ast.LabeledStatement;
	import org.mozilla.javascript.ast.LetNode;
	import org.mozilla.javascript.ast.Loop;
	import org.mozilla.javascript.ast.Name;
	import org.mozilla.javascript.ast.NewExpression;
	import org.mozilla.javascript.ast.NumberLiteral;
	import org.mozilla.javascript.ast.ObjectLiteral;
	import org.mozilla.javascript.ast.ObjectProperty;
	import org.mozilla.javascript.ast.ParenthesizedExpression;
	import org.mozilla.javascript.ast.PropertyGet;
	import org.mozilla.javascript.ast.RegExpLiteral;
	import org.mozilla.javascript.ast.ReturnStatement;
	import org.mozilla.javascript.ast.Scope;
	import org.mozilla.javascript.ast.ScriptNode;
	import org.mozilla.javascript.ast.StringLiteral;
	import org.mozilla.javascript.ast.SwitchCase;
	import org.mozilla.javascript.ast.SwitchStatement;
	import org.mozilla.javascript.ast.Symbol;
	import org.mozilla.javascript.ast.ThrowStatement;
	import org.mozilla.javascript.ast.TryStatement;
	import org.mozilla.javascript.ast.UnaryExpression;
	import org.mozilla.javascript.ast.VariableDeclaration;
	import org.mozilla.javascript.ast.VariableInitializer;
	import org.mozilla.javascript.ast.WhileLoop;
	import org.mozilla.javascript.ast.WithStatement;
	import org.mozilla.javascript.ast.XmlDotQuery;
	import org.mozilla.javascript.ast.XmlElemRef;
	import org.mozilla.javascript.ast.XmlExpression;
	import org.mozilla.javascript.ast.XmlLiteral;
	import org.mozilla.javascript.ast.XmlMemberGet;
	import org.mozilla.javascript.ast.XmlPropRef;
	import org.mozilla.javascript.ast.XmlRef;
	import org.mozilla.javascript.ast.XmlString;
	import org.mozilla.javascript.ast.Yield;
	import org.mozilla.javascript.exception.IllegalStateError;
	import org.mozilla.javascript.exception.ParserError;
	
	public class Parser
	{
		/**
		 * Maximum number of allowed function or constructor arguments,
		 * to follow SpiderMonkey.
		 */
		public static const ARGC_LIMIT:int = 1 << 16;
		
		// TokenInformation flags : currentFlaggedToken stores them together
		// with token type
		public static const
			CLEAR_TI_MASK:int  = 0xFFFF,  // mask to clear token information bits
			TI_AFTER_EOL:int   = 1 << 16, // first token of the source line
			TI_CHECK_LABEL:int = 1 << 17; // indicates to check for label

		public static const PROP_ENTRY:int = 1;
		public static const GET_ENTRY:int = 2;
		public static const SET_ENTRY:int = 4;
			
		public var compilerEnv:CompilerEnvirons;
		private var errorReporter:ErrorReporter;
		private var errorCollector:IdeErrorReporter;
		private var sourceURI:String;
		private var sourceChars:Vector.<int>;
		
		public var calledByCompileFunction:Boolean;  // ugly - set directly by Context
		private var parseFinished:Boolean;  // set when finished to prevent reuse
		
		// FIXME: This should be made private
		public var ts:TokenStream;
		private var currentFlaggedToken:int = Token.EOF;
		private var currentToken:int;
		private var syntaxErrorCount:int;
		
		private var scannedComments:Vector.<Comment>;
		private var currentJsDocComment:Comment;
		
		protected var nestingOfFunction:int;
		private var currentLabel:LabeledStatement;
		private var inDestructuringAssignment:Boolean;
		protected var inUseStrictDirective:Boolean;
		
		// The following are per function variables and should be saved/restored
		// during function parsing.  See PerFunctionVariables class below.
		public var currentScriptOrFn:ScriptNode;
		public var currentScope:Scope;
		public var endFlags:int;
		public var inForInit:Boolean;  //bound temporarily during forStatement()
		public var labelSet:Object; // java type: Map<String,LabeledStatement>
		public var loopSet:Vector.<Loop>; // java type List<Loop>
		public var loopAndSwitchSet:Vector.<Jump>; // java type List<Jump>
		// end of per function variables
		
		// Lacking 2-token lookahead, labels become a problem.
		// These vars store the token info of the last matched name,
		// iff it wasn't the last matched token.
		private var prevNameTokenStart:int;
		private var prevNameTokenString:String = "";
		private var prevNameTokenLineno:int;
		
		
		public function Parser(compilerEnv:CompilerEnvirons=null, errorReporter:ErrorReporter=null)
		{
			if (compilerEnv === null) {
				compilerEnv = new CompilerEnvirons();
			}
			if (errorReporter === null) {
				errorReporter = compilerEnv.getErrorReporter();
			}
			this.compilerEnv = compilerEnv;
			this.errorReporter = errorReporter;
			if (errorReporter is IdeErrorReporter) {
				errorCollector = IdeErrorReporter(errorReporter);
			}
		}
		
		protected function addStrictWarning(messageId:String, messageArg:String, position:int = -1, length:int = -1):void {
			if (compilerEnv.isStrictMode())
				addWarning(messageId, messageArg, position, length);
		}
		
		public function addError(messageId:String, messageArg:String = null, position:int = -1, length:int = -1):void {
			if (position === -1 && length === -1) {
				position = ts.tokenBeg;
				length = ts.tokenEnd - ts.tokenBeg;
			}
			++syntaxErrorCount;
			var message:String = lookupMessage(messageId, messageArg);
			trace("addError not yet implemented. Args: " + [messageId, messageArg, position, length].join(' - '));
		}
		
		public function addWarning(messageId:String, messageArg:String = null, position:int = -1, length:int = -1):void {
			if (position === -1 && length === -1 && ts !== null) {
				position = ts.tokenBeg;
				length = ts.tokenEnd - ts.tokenBeg;
			}
			trace("addWarning not yet implemented. Args: " + [messageId, messageArg, position, length].join(' - '));
		}
		
		public function lookupMessage(messageId:String, messageArg:String=null):String {
			return messageArg === null
				? ScriptRuntime.getMessage0(messageId)
				: ScriptRuntime.getMessage1(messageId, messageArg);
		}
		
		public function reportError(messageId:String, messageArg:String = null, position:int = -1, length:int = -1):void {
			if (position === -1 && length === -1) {
				if (ts === null) { // happens in some regression tests
					position = 1;
					length = 1;
				}
				else {
					position = ts.tokenBeg;
					length = ts.tokenEnd - ts.tokenBeg;
				}
			}
			
			addError(messageId, null, position, length);
			
			if (!compilerEnv.recoverFromErrors()) {
				throw new ParserError();
			}
		}
		
		// Computes the absolute end offset of node N.
		// Use with caution!  Assumes n.getPosition() is -absolute-, which
		// is only true before the node is added to its parent.
		private function getNodeEnd(n:AstNode):int {
			return n.getPosition() + n.getLength();
		}
		
		private function recordComment(lineno:int, comment:String):void {
			if (scannedComments === null) {
				scannedComments = new Vector.<Comment>();
			}
			var commentNode:Comment = new Comment(ts.tokenBeg,
												  ts.getTokenLength(),
												  ts.commentType,
												  comment);
			if (ts.commentType === Token.COMMENT_TYPE_JSDOC &&
				compilerEnv.isRecordingLocalJsDocComments()) {
				currentJsDocComment = commentNode;
			}
			commentNode.setLineno(lineno);
			scannedComments.push(commentNode);
		}
		
		private function getAndResetJsDoc():Comment {
			var saved:Comment = currentJsDocComment;
			currentJsDocComment = null;
			return saved;
		}
		
		private function getNumberOfEols(comment:String):int {
			var lines:int = 0;
			for (var i:int = comment.length-1; i >= 0; i --) {
				if (comment.charAt(i) === "\n") {
					lines ++;
				}
			}
			return lines;
		}
		
		// Returns the next token without consuming it.
		// If previous token was consumed, calls scanner to get new token.
		// If previous token was -not- consumed, returns it (idempotent).
		//
		// This function will not return a newline (Token.EOL - instead, it
		// gobbles newlines until it finds a non-newline token, and flags
		// that token as appearing just after a newline.
		//
		// This function will also not return a Token.COMMENT.  Instead, it
		// records comments in the scannedComments list.  If the token
		// returned by this function immediately follows a jsdoc comment,
		// the token is flagged as such.
		//
		// Note that this function always returned the un-flagged token!
		// The flags, if any, are saved in currentFlaggedToken.
		//
		// Throws IOError
		private function peekToken():int
		{
			// By far the most common case:  last token hasn't been consumed,
			// so return already-peeked token.
			if (currentFlaggedToken !== Token.EOF) {
				return currentToken;
			}
			
			var lineno:int = ts.getLineno();
			var tt:int = ts.getToken();
			var sawEOL:Boolean = false;
			
			// process comments and whitespace
			while (tt === Token.EOL || tt === Token.COMMENT) {
				if (tt === Token.EOL) {
					lineno++;
					sawEOL = true;
				} else {
					if (compilerEnv.isRecordingComments()) {
						var comment:String = ts.getAndResetCurrentComment();
						recordComment(lineno, comment);
						// Comments may contain multiple lines, get the number
						// of EoLs and increase the lineno
						lineno += getNumberOfEols(comment);
					}
				}
				tt = ts.getToken();
			}
			
			currentToken = tt;
			currentFlaggedToken = tt | (sawEOL ? TI_AFTER_EOL : 0);
			return currentToken;  // return unflagged token
		}
		
		// throws IOError
		private function peekFlaggedToken():int {
			peekToken();
			return currentFlaggedToken;
		}
		
		private function consumeToken():void {
			currentFlaggedToken = Token.EOF;
		}
		
		// throws IOError
		private function nextToken():int {
			var tt:int = peekToken();
			consumeToken();
			return tt;
		}
		
		private function nextFlaggedToken():int {
			peekToken();
			var ttFlagged:int = currentFlaggedToken;
			consumeToken();
			return ttFlagged;
		}
		
		// throws IOError
		private function matchToken(toMatch:int):Boolean {
			if (peekToken() !== toMatch) {
				return false;
			}
			consumeToken();
			return true;
		}
		
		/**
		 * Returns Token.EOL if the current token follows a newline, else returns
		 * the current token.  Used in situations where we don't consider certain
		 * token types valid if they are preceded by a newline.  One example is the
		 * postfix ++ or -- operator, which has to be on the same line as its
		 * operand.
		 * 
		 * @throws IOError
		 */
		private function peekTokenOrEOL():int {
			var tt:int = peekToken();
			// Check for last peeked token flags
			if ((currentFlaggedToken & TI_AFTER_EOL) !== 0) {
				tt = Token.EOL;
			}
			return tt;
		}
		
		private function mustMatchToken(toMatch:int, messageId:String, pos:int = -1, len:int = -1):Boolean {
			if (pos === -1) {
				pos = ts.tokenBeg;
			}
			if (len === -1) {
				len = ts.tokenEnd - ts.tokenBeg;
			}
			if (matchToken(toMatch)) {
				return true;
			}
			reportError(messageId, null, pos, len);
			return true;
		}
		
		private function mustHaveXML():void {
			if (!compilerEnv.isXmlAvailable()) {
				reportError("msg.XML.not.available");
			}
		}
		
		public function pushScope(scope:Scope):void {
			var parent:Scope = scope.getParentScope();
			// During codegen, parent scope chain may already be initialized,
			// in which case we just need to set currentScope variable.
			if (parent !== null) {
				if (parent !== currentScope)
					codeBug();
			} else {
				currentScope.addChildScope(scope);
			}
			currentScope = scope;
		}
		
		public function popScope():void {
			currentScope = currentScope.getParentScope();
		}
		
		private function enterLoop(loop:Loop):void {
			if (loopSet === null)
				loopSet = new Vector.<Loop>();
			loopSet.push(loop);
			if (loopAndSwitchSet === null)
				loopAndSwitchSet = new Vector.<Jump>();
			loopAndSwitchSet.push(loop);
			pushScope(loop);
			if (currentLabel !== null) {
				currentLabel.setStatement(loop);
				currentLabel.getFirstLabel().setLoop(loop);
				// This is the only time during parsing that we set a node's parent
				// before parsing the children.  In order for the child node offsets
				// to be correct, we adjust the loop's reported position back to an
				// absolute source offset, and restore it when we call exitLoop().
				loop.setRelative(-currentLabel.getPosition());
			}
		}
		
		private function exitLoop():void {
			var loop:Loop = loopSet.pop();
			loopAndSwitchSet.pop();
			if (loop.getParent() !== null) {  // see comment in enterLoop
				loop.setRelative(loop.getParent().getPosition());
			}
			popScope();
		}
		
		private function enterSwitch(node:SwitchStatement):void {
			if (loopAndSwitchSet === null)
				loopAndSwitchSet = new Vector.<Jump>();
			loopAndSwitchSet.push(node);
		}
		
		private function exitSwitch():void {
			loopAndSwitchSet.pop();
		}
		
		/**
		 * Builds a parse tree from the given source string.
		 *
		 * @return an {@link AstRoot} object representing the parsed program.  If
		 * the parse fails, {@code null} will be returned.  (The parse failure will
		 * result in a call to the {@link ErrorReporter} from
		 * {@link CompilerEnvirons}.)
		 */
		public function parseString(sourceString:String, sourceURI:String, lineno:int):AstRoot {
			if (parseFinished) throw new IllegalStateError("parser reused");
			this.sourceURI = sourceURI;
			if (compilerEnv.isIdeMode()) {
				// TODO: Do we really need this?  What on earth is this for?
//				this.sourceChars = sourceString.toCharArray();
			}
			this.ts = new TokenStream(this, null, sourceString, lineno);
			var result:AstRoot;
			try {
				result = parse();
			} catch (iox:IOError) {
				// Should never happen
				throw new IllegalStateError();
			} finally {
				parseFinished = true;
			}
			return result;
		}
		
		/**
		 * Builds a parse tree from the given sourcereader.
		 * @see #parse(String,String,int)
		 * @throws IOException if the {@link Reader} encounters an error
		 */
		public function parseReader(sourceReader:Reader, sourceURI:String, lineno:int):AstRoot {
			if (parseFinished) throw new IllegalStateError("parser reused");
			if (compilerEnv.isIdeMode()) {
				throw new Error("Unimpmlemented: ideMode");
			}
			var result:AstRoot;
			try {
				this.sourceURI = sourceURI;
				ts = new TokenStream(this, sourceReader, null, lineno);
				result = parse();
			} finally {
				parseFinished = true;
			}
			return result;
		}
		
		// throws IOException
		private function parse():AstRoot {
			var pos:int = 0;
			var root:AstRoot = new AstRoot(pos);
			currentScope = currentScriptOrFn = root;
			
			var baseLineno:int = ts.lineno;  // line number where source starts
			var end:int = pos;  //in case source is empty
			
			var inDirectivePrologue:Boolean = true;
			var savedStrictMode:Boolean = inUseStrictDirective;
			// TODO: eval code should get strict mode from invoking code
			inUseStrictDirective = false;
			
			try {
				for (;;) {
					var tt:int = peekToken();
					if (tt <= Token.EOF) {
						break;
					}
					
					var n:AstNode;
					if (tt === Token.FUNCTION) {
						consumeToken();
						try {
							n = parseFunction(calledByCompileFunction
											  ? FunctionNode.FUNCTION_EXPRESSION
											  : FunctionNode.FUNCTION_STATEMENT);
						} catch (e:ParserError) {
							break;
						}
					} else {
						n = statement();
						if (inDirectivePrologue) {
							var directive:String = getDirective(n);
							if (directive === null) {
								inDirectivePrologue = false;
							} else if (directive === 'use strict') {
								inUseStrictDirective = true;
								root.setInStrictMode(true);
							}
						}
					
					}
					end = getNodeEnd(n);
					root.addChildToBack(n);
					n.setParent(root);
				}
			} catch(ex:StackOverflowError) {
				var msg:String = lookupMessage("msg.too.deep.parser.recursion");
				if (!compilerEnv.isIdeMode())
					throw Context.reportRuntimeError(msg /* sourceURI, ts.lineno, null, 0 */);
			} finally {
				inUseStrictDirective = savedStrictMode;
			}
			
			if (this.syntaxErrorCount !== 0) {
				msg = this.syntaxErrorCount.toString(10);
				msg = lookupMessage("msg.got.syntax.errors", msg);
				if (!compilerEnv.isIdeMode())
					throw errorReporter.runtimeError(msg, sourceURI, baseLineno, null, 0);
			}
			
			// add comments to root in lexical order
			if (scannedComments !== null) {
				// If we find a comment beyond end of our last statement or
				// function, extend the root bounds to the end of that comment.
				var last:int = scannedComments.length - 1;
				end = Math.max(end, getNodeEnd(scannedComments[scannedComments.length-1]));
				for each (var c:Comment in scannedComments) {
					root.addComment(c);
				}
			}
			
			root.setLength(end - pos);
			root.setSourceName(sourceURI);
			root.setBaseLineno(baseLineno);
			root.setEndLineno(ts.lineno);
			return root;
		}
		
		/**
		 * @throws IOError
		 */
		private function parseFunctionBody():AstNode {
			var isExpressionClosure:Boolean = false;
			if (!matchToken(Token.LC)) {
				if (compilerEnv.getLanguageVersion() < Context.VERSION_1_8) {
					reportError("msg.no.brace.body");
				} else {
					isExpressionClosure = true;
				}
			}
			++nestingOfFunction;
			var pos:int = ts.tokenBeg;
			var pn:Block = new Block(pos);  // starts at LC position
			
			var inDirectivePrologue:Boolean = true;
			var savedStrictMode:Boolean = inUseStrictDirective;
			// Don't set 'inUseStrictDirective' to false: inherit strict mode.
			
			pn.setLineno(ts.lineno);
			try {
				if (isExpressionClosure) {
					var rs:ReturnStatement = new ReturnStatement(ts.lineno);
					rs.setReturnValue(assignExpr());
					// expression closure flag is required on both nodes
					rs.putProp(Node.EXPRESSION_CLOSURE_PROP, true);
					pn.putProp(Node.EXPRESSION_CLOSURE_PROP, true);
					pn.addStatement(rs);
				} else {
					bodyLoop: for (;;) {
						var n:AstNode;
						var tt:int = peekToken();
						switch (tt) {
							case Token.ERROR:
							case Token.EOF:
							case Token.RC:
								break bodyLoop;
							
							case Token.FUNCTION:
								consumeToken();
								n = parseFunction(FunctionNode.FUNCTION_STATEMENT);
								break;
							default:
							n = statement();
							if (inDirectivePrologue) {
								var directive:String = getDirective(n);
								if (directive == null) {
									inDirectivePrologue = false;
								} else if (directive === "use strict") {
									inUseStrictDirective = true;
								}
							}
							break;
						}
						pn.addStatement(n);
					}
				}
			} catch (e:ParserError) {
				// Ignore it
			} finally {
				--nestingOfFunction;
				inUseStrictDirective = savedStrictMode;
			}
			
			var end:int = ts.tokenEnd;
			getAndResetJsDoc();
			if (!isExpressionClosure && mustMatchToken(Token.RC, "msg.no.brace.after.body"))
				end = ts.tokenEnd;
			pn.setLength(end - pos);
			return pn;
		}
		
		private function getDirective(n:AstNode):String {
			if (n is ExpressionStatement) {
				var e:AstNode = ExpressionStatement(n).getExpression();
				if (e is StringLiteral) {
					return StringLiteral(e).getValue();
				}
			}
			return null;
		}
		
		/**
		 * @private
		 * @throws IOError
		 */
		private function parseFunctionParams(fnNode:FunctionNode):void {
			if (matchToken(Token.RP)) {
				fnNode.setRp(ts.tokenBeg - fnNode.getPosition());
				return;
			}
			// Would prefer not to call createDestructuringAssignment until codegen,
			// but the symbol definitions have to happen now, before body is parsed.
			var destructuring:Object = null; // Map<String, Node>
			var paramNames:ISet = new StringSet(); // HashSet<String>
			do {
				var tt:int = peekToken();
				if (tt === Token.LB || tt === Token.LC) {
					var expr:AstNode = destructuringPrimaryExpr();
					markDestructuring(expr);
					fnNode.addParam(expr);
					// Destructuring assignment for parameters: add a dummy
					// parameter name, and add a statement to the body to initialize
					// variables from the destructuring assignment
					if (destructuring === null) {
						destructuring = {};
					}
					var pname:String = currentScriptOrFn.getNextTempName();
					defineSymbol(Token.LP, pname, false);
					destructuring[pname] = expr;
				} else {
					if (mustMatchToken(Token.NAME, "msg.no.parm")) {
						fnNode.addParam(createNameNode());
						var paramName:String = ts.getString();
						defineSymbol(Token.LP, paramName);
						if (this.inUseStrictDirective) {
							if ("eval" === paramName ||
								"arguments" === paramName)
							{
								reportError("msg.bad.id.strict", paramName);
							}
							if (paramNames.has(paramName))
								addError("msg.dup.param.strict", paramName);
							paramNames.add(paramName);
						}
					} else {
						fnNode.addParam(makeErrorNode());
					}
				}
			} while (matchToken(Token.COMMA));
			
			if (destructuring !== null) {
				var destructuringNode:Node = new Node(Token.COMMA);
				// Add assignment helper for each destructuring parameter
				for (var key:String in destructuring) {
					var value:Node = destructuring[key];
					var assign:Node = createDestructuringAssignment(Token.VAR,
						value, createName(key));
					destructuringNode.addChildToBack(assign);
				}
				fnNode.putProp(Node.DESTRUCTURING_PARAMS, destructuringNode);
			}
			
			if (mustMatchToken(Token.RP, "msg.no.paren.after.parms")) {
				fnNode.setRp(ts.tokenBeg - fnNode.getPosition());
			}
		}
		
		private function parseFunction(type:int):FunctionNode {
			var syntheticType:int = type;
			var baseLineno:int = ts.lineno;  // line number where source starts
			var functionSourceStart:int = ts.tokenBeg;  // start of "function" kwd
			var name:Name = null;
			var memberExprNode:AstNode = null;
			
			if (matchToken(Token.NAME)) {
				name = createNameNode(true, Token.NAME);
				if (inUseStrictDirective) {
					var id:String = name.getIdentifier();
					if ("eval" === id || "arguments" === id) {
						reportError("msg.bad.id.strict", id);
					}
				}
				if (!matchToken(Token.LP)) {
					if (compilerEnv.isAllowMemberExprAsFunctionName()) {
						var memberExprHead:AstNode = name;
						name = null;
						memberExprNode = memberExprTail(false, memberExprHead);
					}
					mustMatchToken(Token.LP, "msg.no.paren.parms");
				}
			} else if (matchToken(Token.LP)) {
				// Anonymous function:  leave name as null
			} else {
				if (compilerEnv.isAllowMemberExprAsFunctionName()) {
					// Note tha memberExpr can not start with '(' like
					// in function (1+2).toString(), because 'function (' already
					// processed as anonymous function
					memberExprNode = memberExpr(false);
				}
				mustMatchToken(Token.LP, "msg.no.paren.parms");
			}
			var lpPos:int = currentToken === Token.LP ? ts.tokenBeg : -1;
			
			if (memberExprNode !== null) {
				syntheticType = FunctionNode.FUNCTION_EXPRESSION;
			}
			
			if (syntheticType !== FunctionNode.FUNCTION_EXPRESSION
				&& name !== null && name.length > 0) {
				// Function statements define a symbol in the enclosing scope
				defineSymbol(Token.FUNCTION, name.getIdentifier());
			}
			
			var fnNode:FunctionNode = new FunctionNode(functionSourceStart, name);
			fnNode.setFunctionType(type);
			if (lpPos !== -1)
				fnNode.setLp(lpPos - functionSourceStart);
			
			fnNode.setJsDocNode(getAndResetJsDoc());
			
			var savedVars:PerFunctionVariables = new PerFunctionVariables(this, fnNode);
			try {
				parseFunctionParams(fnNode);
				fnNode.setBody(parseFunctionBody());
				fnNode.setEncodedSourceBounds(functionSourceStart, ts.tokenEnd);
				fnNode.setLength(ts.tokenEnd - functionSourceStart);
				
				if (compilerEnv.isStrictMode()
					&& !fnNode.getBody().hasConsistentReturnUsage()) {
					var msg:String = (name !== null && name.length > 0)
						? "msg.no.return.value"
						: "msg.anon.no.return.value";
					addStrictWarning(msg, name === null ? "" : name.getIdentifier());
				}
			} finally {
				savedVars.restore()
			}
			
			if (memberExprNode !== null) {
				// TODO(stevey): fix missing functionality
				Kit.codeBug();
				fnNode.setMemberExprNode(memberExprNode);  // rewrite later
				/* old code:
				if (memberExprNode != null) {
					pn = nf.createAssignment(Token.ASSIGN, memberExprNode, pn);
					if (functionType != FunctionNode.FUNCTION_EXPRESSION) {
						// XXX check JScript behavior: should it be createExprStatement?
						pn = nf.createExprStatementNoReturn(pn, baseLineno);
					}
				}
				*/
			}
			
			fnNode.setSourceName(sourceURI);
			fnNode.setBaseLineno(baseLineno);
			fnNode.setEndLineno(ts.lineno);
			
			// Set the parent scope.  Needed for finding undeclared vars.
			// Have to wait until after parsing the function to set its parent
			// scope, since defineSymbol needs the defining-scope check to stop
			// at the function boundary when checking for redeclarations.
			if (compilerEnv.isIdeMode()) {
				fnNode.setParentScope(currentScope);
			}
			return fnNode;
		}


		// This function does not match the closing RC: the caller matches
		// the RC so it can provide a suitable error message if not matched.
		// This means it's up to the caller to set the length of the node to
		// include the closing RC.  The node start pos is set to the
		// absolute buffer start position, and the caller should fix it up
		// to be relative to the parent node.  All children of this block
		// node are given relative start positions and correct lengths.
		/**
		 * @throws IOError
		 */
		private function statements(parent:AstNode=null):AstNode {
			if (currentToken !== Token.LC  // assertion can be invalid in bad code
				&& !compilerEnv.isIdeMode()) codeBug();
			var pos:int = ts.tokenBeg;
			var block:AstNode = parent !== null ? parent : new Block(pos);
			block.setLineno(ts.lineno);
			
			var tt:int;
			while ((tt = peekToken()) > Token.EOF && tt !== Token.RC) {
				block.addChild(statement());
			}
			block.setLength(ts.tokenBeg - pos);
			return block;
		}
		
		// parse aand return a parenthesized expression
		private function condition():ConditionData {
			var data:ConditionData = new ConditionData();
			
			if (mustMatchToken(Token.LP, "msg.no.paren.cond"))
				data.lp = ts.tokenBeg;
				
			data.condition = expr();
			
			if (mustMatchToken(Token.RP, "msg.no.paren.after.cond"))
				data.rp = ts.tokenBeg;
			
			// Report strict warning on code like "if (a = 7) ...". Suppress the
			// warning if the condition is parenthesized, like "if ((a = 7)) ...".
			if (data.condition is Assignment) {
				addStrictWarning("msg.equal.as.assign", "",
								 data.condition.getPosition(),
								 data.condition.getLength());
			}
			return data;
		}
		
		private function statement():AstNode {
			var pos:int = ts.tokenBeg;
			try {
				var pn:AstNode = statementHelper();
				if (pn !== null) {
					if (compilerEnv.isStrictMode() && !pn.hasSideEffects()) {
						var beg:int = pn.getPosition();
						beg = Math.max(beg, lineBeginningFor(beg));
						addStrictWarning(pn is EmptyStatement
										 ? "msg.extra.trailing.semi"
										 : "msg.no.side.effects",
										 "", beg, nodeEnd(pn) - beg);
					}
					return pn;
				}
			} catch(e:ParserError) {
				// an ErrorNode was added to the ErrorReporter
			}
			
			// error:  skip ahead to a probable statement boundary
			guessingStatementEnd: for(;;) {
				var tt:int = peekTokenOrEOL();
				consumeToken();
				switch (tt) {
					case Token.ERROR:
					case Token.EOF:
					case Token.EOL:
					case Token.SEMI:
						break guessingStatementEnd;
				}
			}
			// We don't make error nodes explicitly part of the tree;
			// they get added to the ErrorReporter.  May need to do
			// something different here.
			return new EmptyStatement(pos, ts.tokenBeg - pos);
		}
		
		/**
		 * @throws IOError
		 */
		private function statementHelper():AstNode {
			// If the statement is set, then it's been told its label by now.
			if (currentLabel != null && currentLabel.getStatement() != null)
				currentLabel = null;
			
			var pn:AstNode = null;
			var tt:int = peekToken(), pos:int = ts.tokenBeg;
			
			switch (tt) {
				case Token.IF:
					return ifStatement();
					
				case Token.SWITCH:
					return switchStatement();
					
				case Token.WHILE:
					return whileLoop();
					
				case Token.DO:
					return doLoop();
					
				case Token.FOR:
					return forLoop();
					
				case Token.TRY:
					return tryStatement();
					
				case Token.THROW:
					pn = throwStatement();
					break;
				
				case Token.BREAK:
					pn = breakStatement();
					break;
				
				case Token.CONTINUE:
					pn = continueStatement();
					break;
				
				case Token.WITH:
					if (this.inUseStrictDirective) {
						reportError("msg.no.with.strict");
					}
					return withStatement();
					
				case Token.CONST:
				case Token.VAR:
					consumeToken();
					var lineno:int = ts.lineno;
					pn = variables(currentToken, ts.tokenBeg, true);
					pn.setLineno(lineno);
					break;
				
				case Token.LET:
					pn = letStatement();
					if (pn is VariableDeclaration
						&& peekToken() == Token.SEMI)
						break;
					return pn;
					
				case Token.RETURN:
				case Token.YIELD:
					pn = returnOrYield(tt, false);
					break;
				
				case Token.DEBUGGER:
					consumeToken();
					pn = new KeywordLiteral(ts.tokenBeg,
						ts.tokenEnd - ts.tokenBeg, tt);
					pn.setLineno(ts.lineno);
					break;
				
				case Token.LC:
					return block();
					
				case Token.ERROR:
					consumeToken();
					return makeErrorNode();
					
				case Token.SEMI:
					consumeToken();
					pos = ts.tokenBeg;
					pn = new EmptyStatement(pos, ts.tokenEnd - pos);
					pn.setLineno(ts.lineno);
					return pn;
					
				case Token.FUNCTION:
					consumeToken();
					return parseFunction(FunctionNode.FUNCTION_EXPRESSION_STATEMENT);
					
				case Token.DEFAULT :
					pn = defaultXmlNamespace();
					break;
				
				case Token.NAME:
					pn = nameOrLabel();
					if (pn is ExpressionStatement)
						break;
					return pn;  // LabeledStatement
				
				default:
					lineno = ts.lineno;
					pn = new ExpressionStatement(-1, -1, expr(), !insideFunction());
					pn.setLineno(lineno);
					break;
			}
			
			autoInsertSemicolon(pn);
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function autoInsertSemicolon(pn:AstNode):void {
			var ttFlagged:int = peekFlaggedToken();
			var pos:int = pn.getPosition();
			switch (ttFlagged & CLEAR_TI_MASK) {
				case Token.SEMI:
					// Consume ';' as part of expression
					consumeToken();
					// extend the node bounds to include the semicolon.
					pn.setLength(ts.tokenEnd - pos);
					break;
				case Token.ERROR:
				case Token.EOF:
				case Token.RC:
					// Autoinsert ;
					warnMissingSemi(pos, nodeEnd(pn));
					break;
				default:
					if ((ttFlagged & TI_AFTER_EOL) === 0) {
						// Report error if no EOL or autoinsert ; otherwise
						reportError("msg.no.semi.stmt");
					} else {
						warnMissingSemi(pos, nodeEnd(pn));
					}
					break;
			}
		}
		
		/**
		 * @throws IOError
		 */
		private function ifStatement():IfStatement {
			if (currentToken !== Token.IF) codeBug();
			consumeToken();
			var pos:int = ts.tokenBeg, lineno:int = ts.lineno, elsePos:int = -1;
			var data:ConditionData = condition();
			var ifTrue:AstNode = statement(), ifFalse:AstNode = null;
			if (matchToken(Token.ELSE)) {
				elsePos = ts.tokenBeg - pos;
				ifFalse = statement();
			}
			var end:int = getNodeEnd(ifFalse != null ? ifFalse : ifTrue);
			var pn:IfStatement = new IfStatement(pos, end - pos);
			pn.setCondition(data.condition);
			pn.setParens(data.lp - pos, data.rp - pos);
			pn.setThenPart(ifTrue);
			pn.setElsePart(ifFalse);
			pn.setElsePosition(elsePos);
			pn.setLineno(lineno);
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function switchStatement():SwitchStatement 
		{
			if (currentToken !== Token.SWITCH) codeBug();
			consumeToken();
			var pos:int = ts.tokenBeg;
			
			var pn:SwitchStatement = new SwitchStatement(pos);
			if (mustMatchToken(Token.LP, "msg.no.paren.switch"))
				pn.setLp(ts.tokenBeg - pos);
			pn.setLineno(ts.lineno);
			
			var discriminant:AstNode = expr();
			pn.setExpression(discriminant);
			enterSwitch(pn);
			
			try {
				if (mustMatchToken(Token.RP, "msg.no.paren.after.switch"))
					pn.setRp(ts.tokenBeg - pos);
				
				mustMatchToken(Token.LC, "msg.no.brace.switch");
				
				var hasDefault:Boolean = false;
				var tt:int;
				switchLoop: for (;;) {
					tt = nextToken();
					var casePos:int = ts.tokenBeg;
					var caseLineno:int = ts.lineno;
					var caseExpression:AstNode = null;
					switch (tt) {
						case Token.RC:
							pn.setLength(ts.tokenEnd - pos);
							break switchLoop;
						
						case Token.CASE:
							caseExpression = expr();
							mustMatchToken(Token.COLON, "msg.no.colon.case");
							break;
						
						case Token.DEFAULT:
							if (hasDefault) {
								reportError("msg.double.switch.default");
							}
							hasDefault = true;
							caseExpression = null;
							mustMatchToken(Token.COLON, "msg.no.colon.case");
							break;
						
						default:
							reportError("msg.bad.switch");
							break switchLoop;
					}
					
					var caseNode:SwitchCase = new SwitchCase(casePos);
					caseNode.setExpression(caseExpression);
					caseNode.setLength(ts.tokenEnd - pos);  // include colon
					caseNode.setLineno(caseLineno);
					
					while ((tt = peekToken()) !== Token.RC
						   && tt !== Token.CASE
						   && tt !== Token.DEFAULT
						   && tt !== Token.EOF)
					{
						caseNode.addStatement(statement());  // updates length
					}
					pn.addCase(caseNode);
				}
			} finally {
				exitSwitch();
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function whileLoop():WhileLoop
		{
			if (currentToken !== Token.WHILE) codeBug();
			consumeToken();
			var pos:int = ts.tokenBeg;
			var pn:WhileLoop = new WhileLoop(pos);
			pn.setLineno(ts.lineno);
			enterLoop(pn);
			try {
				var data:ConditionData = condition();
				pn.setCondition(data.condition);
				pn.setParens(data.lp - pos, data.rp - pos);
				var body:AstNode = statement();
				pn.setLength(getNodeEnd(body) - pos);
				pn.setBody(body);
			} finally {
				exitLoop();
			}
			return pn;
		}

		/**
		 * @throws IOError
		 */
		private function doLoop():DoLoop {
			if (currentToken !== Token.DO) codeBug();
			consumeToken();
			var pos:int = ts.tokenBeg, end:int;
			var pn:DoLoop = new DoLoop(pos);
			pn.setLineno(ts.lineno);
			enterLoop(pn);
			try {
				var body:AstNode = statement();
				mustMatchToken(Token.WHILE, "msg.no.while.do");
				pn.setWhilePosition(ts.tokenBeg - pos);
				var data:ConditionData = condition();
				pn.setCondition(data.condition);
				pn.setParens(data.lp - pos, data.rp - pos);
				end = getNodeEnd(body);
				pn.setBody(body);
			} finally {
				exitLoop();
			}
			// Always auto-insert semicolon to follow SpiderMonkey:
			// It is required by ECMAScript but is ignored by the rest of
			// world, see bug 238945
			if (matchToken(Token.SEMI)) {
				end = ts.tokenEnd;
			}
			pn.setLength(end - pos);
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function forLoop():Loop
		{
			if (currentToken !== Token.FOR) codeBug();
			consumeToken();
			var forPos:int = ts.tokenBeg, lineno:int = ts.lineno;
			var isForEach:Boolean = false, isForIn:Boolean = false;
			var eachPos:int = -1, inPos:int = -1, lp:int = -1, rp:int = -1;
			var init:AstNode = null;  // init is also foo in 'foo in object'
			var cond:AstNode = null;  // cond is also object in 'foo in object'
			var incr:AstNode = null;
			var pn:Loop = null;
			
			var tempScope:Scope = new Scope();
			pushScope(tempScope);  // decide below what AST class to use
			try {
				// See if this is a for each () instead of just a for ()
				if (matchToken(Token.NAME)) {
					if ("each" === ts.getString()) {
						isForEach = true;
						eachPos = ts.tokenBeg - forPos;
					} else {
						reportError("msg.no.paren.for");
					}
				}
				
				if (mustMatchToken(Token.LP, "msg.no.paren.for"))
					lp = ts.tokenBeg - forPos;
				var tt:int = peekToken();
				
				init = forLoopInit(tt);
				
				if (matchToken(Token.IN)) {
					isForIn = true;
					inPos = ts.tokenBeg - forPos;
					cond = expr();  // object over which we're iterating
				} else {  // ordinary for-loop
					mustMatchToken(Token.SEMI, "msg.no.semi.for");
					if (peekToken() === Token.SEMI) {
						// no loop condition
						cond = new EmptyExpression(ts.tokenBeg, 1);
						cond.setLineno(ts.lineno);
					} else {
						cond = expr();
					}
					
					mustMatchToken(Token.SEMI, "msg.no.semi.for.cond");
					var tmpPos:int = ts.tokenEnd;
					if (peekToken() === Token.RP) {
						incr = new EmptyExpression(tmpPos, 1);
						incr.setLineno(ts.lineno);
					} else {
						incr = expr();
					}
				}
				
				if (mustMatchToken(Token.RP, "msg.no.paren.for.ctrl"))
					rp = ts.tokenBeg - forPos;
				
				if (isForIn) {
					var fis:ForInLoop = new ForInLoop(forPos);
					if (init is VariableDeclaration) {
						// check that there was only one variable given
						if (VariableDeclaration(init).getVariables().length > 1) {
							reportError("msg.mult.index");
						}
					}
					fis.setIterator(init);
					fis.setIteratedObject(cond);
					fis.setInPosition(inPos);
					fis.setIsForEach(isForEach);
					fis.setEachPosition(eachPos);
					pn = fis;
				} else {
					var fl:ForLoop = new ForLoop(forPos);
					fl.setInitializer(init);
					fl.setCondition(cond);
					fl.setIncrement(incr);
					pn = fl;
				}
				
				// replace temp scope with the new loop object
				currentScope.replaceWith(pn);
				popScope();
				
				// We have to parse the body -after- creating the loop node,
				// so that the loop node appears in the loopSet, allowing
				// break/continue statements to find the enclosing loop.
				enterLoop(pn);
				try {
					var body:AstNode = statement();
					pn.setLength(getNodeEnd(body) - forPos);
					pn.setBody(body);
				} finally {
					exitLoop();
				}
				
			} finally {
				if (currentScope === tempScope) {
					popScope();
				}
			}
			pn.setParens(lp, rp);
			pn.setLineno(lineno);
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function forLoopInit(tt:int):AstNode {
			try {
				inForInit = true;  // checked by variables() and relExpr()
				var init:AstNode = null;
				if (tt === Token.SEMI) {
					init = new EmptyExpression(ts.tokenBeg, 1);
					init.setLineno(ts.lineno);
				} else if (tt === Token.VAR || tt === Token.LET) {
					consumeToken();
					init = variables(tt, ts.tokenBeg, false);
				} else {
					init = expr();
					markDestructuring(init);
				}
				return init;
			} finally {
				inForInit = false;
			}
			return null;
		}

		/**
		 * @throws IOError
		 */
		private function tryStatement():TryStatement {
			if (currentToken !== Token.TRY) codeBug();
			consumeToken();
			
			// Pull out JSDoc info and reset it before recursing.
			var jsdocNode:Comment = getAndResetJsDoc();
			
			var tryPos:int = ts.tokenBeg, lineno:int = ts.lineno, finallyPos:int = -1;
			if (peekToken() !== Token.LC) {
				reportError("msg.no.brace.try");
			}
			var tryBlock:AstNode = statement();
			var tryEnd:int = getNodeEnd(tryBlock);
			
			var clauses:Vector.<CatchClause> = null;
			
			var sawDefaultCatch:Boolean = false;
			var peek:int = peekToken();
			if (peek === Token.CATCH) {
				while (matchToken(Token.CATCH)) {
					var catchLineNum:int = ts.lineno;
					if (sawDefaultCatch) {
						reportError("msg.catch.unreachable");
					}
					var catchPos:int = ts.tokenBeg, lp:int = -1, rp:int = -1, guardPos:int = -1;
					if (mustMatchToken(Token.LP, "msg.no.paren.catch"))
						lp = ts.tokenBeg;
					
					mustMatchToken(Token.NAME, "msg.bad.catchcond");
					var varName:Name = createNameNode();
					var varNameString:String = varName.getIdentifier();
					if (inUseStrictDirective) {
						if ("eval" === varNameString ||
							"arguments" === varNameString)
						{
							reportError("msg.bad.id.strict", varNameString);
						}
					}
					
					var catchCond:AstNode = null;
					if (matchToken(Token.IF)) {
						guardPos = ts.tokenBeg;
						catchCond = expr();
					} else {
						sawDefaultCatch = true;
					}
					
					if (mustMatchToken(Token.RP, "msg.bad.catchcond"))
						rp = ts.tokenBeg;
					mustMatchToken(Token.LC, "msg.no.brace.catchblock");
					
					var catchBlock:Block = Block(statements());
					tryEnd = getNodeEnd(catchBlock);
					var catchNode:CatchClause = new CatchClause(catchPos);
					catchNode.setVarName(varName);
					catchNode.setCatchCondition(catchCond);
					catchNode.setBody(catchBlock);
					if (guardPos !== -1) {
						catchNode.setIfPosition(guardPos - catchPos);
					}
					catchNode.setParens(lp, rp);
					catchNode.setLineno(catchLineNum);
					
					if (mustMatchToken(Token.RC, "msg.no.brace.after.body"))
						tryEnd = ts.tokenEnd;
					catchNode.setLength(tryEnd - catchPos);
					if (clauses === null)
						clauses = new Vector.<CatchClause>();
					clauses.push(catchNode);
				}
			} else if (peek !== Token.FINALLY) {
				mustMatchToken(Token.FINALLY, "msg.try.no.catchfinally");
			}
			
			var finallyBlock:AstNode = null;
			if (matchToken(Token.FINALLY)) {
				finallyPos = ts.tokenBeg;
				finallyBlock = statement();
				tryEnd = getNodeEnd(finallyBlock);
			}
			
			var pn:TryStatement = new TryStatement(tryPos, tryEnd - tryPos);
			pn.setTryBlock(tryBlock);
			pn.setCatchClauses(clauses);
			pn.setFinallyBlock(finallyBlock);
			if (finallyPos !== -1) {
				pn.setFinallyPosition(finallyPos - tryPos);
			}
			pn.setLineno(lineno);
			
			if (jsdocNode !== null) {
				pn.setJsDocNode(jsdocNode);
			}
			
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function throwStatement():ThrowStatement {
			if (currentToken !== Token.THROW) codeBug();
			consumeToken();
			var pos:int = ts.tokenBeg, lineno:int = ts.lineno;
			if (peekTokenOrEOL() == Token.EOL) {
				// ECMAScript does not allow new lines before throw expression,
				// see bug 256617
				reportError("msg.bad.throw.eol");
			}
			var exprNode:AstNode = expr();
			var pn:ThrowStatement = new ThrowStatement(pos, getNodeEnd(exprNode), exprNode);
			pn.setLineno(lineno);
			return pn;
		}
		
		// If we match a NAME, consume the token and return the statement
		// with that label.  If the name does not match an existing label,
		// reports an error.  Returns the labeled statement node, or null if
		// the peeked token was not a name.  Side effect:  sets scanner token
		// information for the label identifier (tokenBeg, tokenEnd, etc.)
		
		/**
		 * @throws IOError
		 */
		private function matchJumpLabelName():LabeledStatement
		{
			var label:LabeledStatement = null;
			
			if (peekTokenOrEOL() === Token.NAME) {
				consumeToken();
				if (labelSet !== null) {
					label = labelSet[ts.getString()];
				}
				if (label === null) {
					reportError("msg.undef.label");
				}
			}
			
			return label;
		}

		/**
		 * @throws IOError
		 */
		private function breakStatement():BreakStatement {
			if (currentToken != Token.BREAK) codeBug();
			consumeToken();
			var lineno:int = ts.lineno, pos:int = ts.tokenBeg, end:int = ts.tokenEnd;
			var breakLabel:Name = null;
			if (peekTokenOrEOL() === Token.NAME) {
				breakLabel = createNameNode();
				end = getNodeEnd(breakLabel);
			}
			
			// matchJumpLabelName only matches if there is one
			var labels:LabeledStatement = matchJumpLabelName();
			// always use first label as target
			var breakTarget:Jump = labels === null ? null : labels.getFirstLabel();
			
			if (breakTarget === null && breakLabel === null) {
				if (loopAndSwitchSet === null || loopAndSwitchSet.length == 0) {
					if (breakLabel === null) {
						reportError("msg.bad.break", "", pos, end - pos);
					}
				} else {
					breakTarget = loopAndSwitchSet[loopAndSwitchSet.length - 1];
				}
			}
			
			var pn:BreakStatement = new BreakStatement(pos, end - pos);
			pn.setBreakLabel(breakLabel);
			// can be null if it's a bad break in error-recovery mode
			if (breakTarget !== null)
				pn.setBreakTarget(breakTarget);
			pn.setLineno(lineno);
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function continueStatement():ContinueStatement
		{
			if (currentToken !== Token.CONTINUE) codeBug();
			consumeToken();
			var lineno:int = ts.lineno, pos:int = ts.tokenBeg, end:int = ts.tokenEnd;
			var label:Name = null;
			if (peekTokenOrEOL() === Token.NAME) {
				label = createNameNode();
				end = getNodeEnd(label);
			}
			
			// matchJumpLabelName only matches if there is one
			var labels:LabeledStatement = matchJumpLabelName();
			var target:Loop = null;
			if (labels === null && label === null) {
				if (loopSet === null || loopSet.length === 0) {
					reportError("msg.continue.outside");
				} else {
					target = loopSet[loopSet.length - 1];
				}
			} else {
				if (labels === null || !(labels.getStatement() is Loop)) {
					reportError("msg.continue.nonloop", "", pos, end - pos);
				}
				target = labels === null ? null : Loop(labels.getStatement());
			}
			
			var pn:ContinueStatement = new ContinueStatement(pos, end - pos);
			if (target !== null)  // can be null in error-recovery mode
				pn.setTarget(target);
			pn.setLabel(label);
			pn.setLineno(lineno);
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function withStatement():WithStatement
		{
			if (currentToken !== Token.WITH) codeBug();
			consumeToken();
			
			var withComment:Comment = getAndResetJsDoc();
			
			var lineno:int = ts.lineno, pos:int = ts.tokenBeg, lp:int = -1, rp:int = -1;
			if (mustMatchToken(Token.LP, "msg.no.paren.with"))
				lp = ts.tokenBeg;
			
			var obj:AstNode = expr();
			
			if (mustMatchToken(Token.RP, "msg.no.paren.after.with"))
				rp = ts.tokenBeg;
			
			var body:AstNode = statement();
			
			var pn:WithStatement = new WithStatement(pos, getNodeEnd(body) - pos);
			pn.setJsDocNode(withComment);
			pn.setExpression(obj);
			pn.setStatement(body);
			pn.setParens(lp, rp);
			pn.setLineno(lineno);
			return pn;
		}
		
		private function letStatement():AstNode {
			if (currentToken !== Token.LET) codeBug();
			consumeToken();
			var lineno:int = ts.lineno, pos:int = ts.tokenBeg;
			var pn:AstNode;
			if (peekToken() === Token.LP) {
				pn = let(true, pos);
			} else {
				pn = variables(Token.LET, pos, true);  // else, e.g.: let x=6, y=7;
			}
			pn.setLineno(lineno);
			return pn;
		}
		
		/**
		 * Returns whether or not the bits in the mask have changed to all set.
		 * @param before bits before change
		 * @param after bits after change
		 * @param mask mask for bits
		 * @return {@code true} if all the bits in the mask are set in "after"
		 *          but not in "before"
		 */
		private static function nowAllSet(before:int, after:int, mask:int):Boolean {
			return ((before & mask) !== mask) && ((after & mask) === mask);
		}

		/**
		 * @throws IOError
		 */
		private function returnOrYield(tt:int, exprContext:Boolean):AstNode {
			if (!insideFunction()) {
				reportError(tt === Token.RETURN ? "msg.bad.return"
												: "msg.bad.yield");
			}
			consumeToken();
			var lineno:int = ts.lineno, pos:int = ts.tokenBeg, end:int = ts.tokenEnd;
			
			var e:AstNode = null;
			// This is ugly, but we don't want to require a semicolon.
			switch (peekTokenOrEOL()) {
				case Token.SEMI: case Token.RC:  case Token.RB:    case Token.RP:
				case Token.EOF:  case Token.EOL: case Token.ERROR: case Token.YIELD:
					break;
				default:
					e = expr();
					end = getNodeEnd(e);
			}
			
			var before:int = endFlags;
			var ret:AstNode;
			
			if (tt === Token.RETURN) {
				endFlags |= e === null ? Node.END_RETURNS : Node.END_RETURNS_VALUE;
				ret = new ReturnStatement(pos, end - pos, e);
				
				// see if we need a strict mode warning
				if (nowAllSet(before, endFlags,
						Node.END_RETURNS|Node.END_RETURNS_VALUE))
					addStrictWarning("msg.return.inconsistent", "", pos, end - pos);
			} else {
				if (!insideFunction())
					reportError("msg.bad.yield");
				endFlags |= Node.END_YIELDS;
				ret = new Yield(pos, end - pos, e);
				setRequiresActivation();
				setIsGenerator();
				if (!exprContext) {
					ret = new ExpressionStatement(-1, -1, ret);
				}
			}
			
			// see if we are mixing yields and value returns.
			if (insideFunction()
				&& nowAllSet(before, endFlags,
						Node.END_YIELDS|Node.END_RETURNS_VALUE)) {
				var name:Name = FunctionNode(currentScriptOrFn).getFunctionName();
				if (name == null || name.length === 0)
					addError("msg.anon.generator.returns", "");
				else
					addError("msg.generator.returns", name.getIdentifier());
			}
			
			ret.setLineno(lineno);
			return ret;
		}
		
		/**
		 * @throws IOError
		 */
		private function block():AstNode {
			if (currentToken !== Token.LC) codeBug();
			consumeToken();
			var pos:int = ts.tokenBeg;
			var block:Scope = new Scope(pos);
			block.setLineno(ts.lineno);
			pushScope(block);
			try {
				statements(block);
				mustMatchToken(Token.RC, "msg.no.brace.block");
				block.setLength(ts.tokenEnd - pos);
				return block;
			} finally {
				popScope();
			}
			return null;
		}
		
		/**
		 * @throws IOError
		 */
		private function defaultXmlNamespace():AstNode
		{
			if (currentToken !== Token.DEFAULT) codeBug();
			consumeToken();
			mustHaveXML();
			setRequiresActivation();
			var lineno:int = ts.lineno, pos:int = ts.tokenBeg;
			
			if (!(matchToken(Token.NAME) && "xml" === ts.getString())) {
				reportError("msg.bad.namespace");
			}
			if (!(matchToken(Token.NAME) && "namespace" === ts.getString())) {
				reportError("msg.bad.namespace");
			}
			if (!matchToken(Token.ASSIGN)) {
				reportError("msg.bad.namespace");
			}
			
			var e:AstNode = expr();
			var dxmln:UnaryExpression = new UnaryExpression(pos, getNodeEnd(e) - pos);
			dxmln.setOperator(Token.DEFAULTNAMESPACE);
			dxmln.setOperand(e);
			dxmln.setLineno(lineno);
			
			var es:ExpressionStatement = new ExpressionStatement(-1, -1, dxmln, true);
			return es;
		}
		
		/**
		 * @throws IOError
		 */
		private function recordLabel(label:Label, bundle:LabeledStatement):void {
			// current token should be colon that primaryExpr left untouched
			if (peekToken() !== Token.COLON) codeBug();
			consumeToken();
			var name:String = label.getName();
			if (labelSet === null) {
				labelSet = {};
			} else {
				var ls:LabeledStatement = labelSet[name];
				if (ls !== null) {
					if (compilerEnv.isIdeMode()) {
						var dup:Label = ls.getLabelByName(name);
						reportError("msg.dup.label", "",
							dup.getAbsolutePosition(), dup.getLength());
					}
					reportError("msg.dup.label", "",
						label.getPosition(), label.getLength());
				}
			}
			bundle.addLabel(label);
			labelSet[name] = bundle;
		}
		
		/**
		 * Found a name in a statement context.  If it's a label, we gather
		 * up any following labels and the next non-label statement into a
		 * {@link LabeledStatement} "bundle" and return that.  Otherwise we parse
		 * an expression and return it wrapped in an {@link ExpressionStatement}.
		 * 
		 * @throws IOError
		 */
		private function nameOrLabel():AstNode
		{
			if (currentToken !== Token.NAME) throw codeBug();
			var pos:int = ts.tokenBeg;
			
			// set check for label and call down to primaryExpr
			currentFlaggedToken |= TI_CHECK_LABEL;
			var exprNode:AstNode = expr();
			
			if (exprNode.getType() !== Token.LABEL) {
				var n:AstNode = new ExpressionStatement(-1, -1, exprNode, !insideFunction());
				n.setLineno(exprNode.getLineno());
				return n;
			}
			
			var bundle:LabeledStatement = new LabeledStatement(pos);
			recordLabel(Label(exprNode), bundle);
			bundle.setLineno(ts.lineno);
			// look for more labels
			var stmt:AstNode = null;
			while (peekToken() === Token.NAME) {
				currentFlaggedToken |= TI_CHECK_LABEL;
				exprNode = expr();
				if (exprNode.getType() !== Token.LABEL) {
					stmt = new ExpressionStatement(-1, -1, exprNode, !insideFunction());
					autoInsertSemicolon(stmt);
					break;
				}
				recordLabel(Label(exprNode), bundle);
			}
			
			// no more labels; now parse the labeled statement
			try {
				currentLabel = bundle;
				if (stmt === null) {
					stmt = statementHelper();
				}
			} finally {
				currentLabel = null;
				// remove the labels for this statement from the global set
				for each (var lb:Label in bundle.getLabels()) {
					delete labelSet[lb.getName()];
				}
			}
			
			// If stmt has parent assigned its position already is relative
			// (See bug #710225)
			bundle.setLength(stmt.getParent() == null
						? getNodeEnd(stmt) - pos
						: getNodeEnd(stmt));
			bundle.setStatement(stmt);
			return bundle;
		}
		
		/**
		 * @throws IOError
		 */
		private function expr():AstNode {
			var pn:AstNode = assignExpr();
			var pos:int = pn.getPosition();
			while (matchToken(Token.COMMA)) {
				var opPos:int = ts.tokenBeg;
				if (compilerEnv.isStrictMode() && !pn.hasSideEffects())
					addStrictWarning("msg.no.side.effects", "",
									 pos, nodeEnd(pn) - pos);
				if (peekToken() === Token.YIELD)
					reportError("msg.yield.parenthesized");
				pn = new InfixExpression(-1, -1, Token.COMMA, pn, assignExpr(), opPos);
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function assignExpr():AstNode {
			var tt:int = peekToken();
			if (tt === Token.YIELD) {
				return returnOrYield(tt, true);
			}
			var pn:AstNode = condExpr();
			tt = peekToken();
			if (Token.FIRST_ASSIGN <= tt && tt <= Token.LAST_ASSIGN) {
				consumeToken();
				
				// Pull out JSDoc info and reset it before recursing.
				var jsdocNode:Comment = getAndResetJsDoc();
				
				markDestructuring(pn);
				var opPos:int = ts.tokenBeg;
				
				pn = new Assignment(-1, -1, tt, pn, assignExpr(), opPos);
				
				if (jsdocNode !== null) {
					pn.setJsDocNode(jsdocNode);
				}
			} else if (tt === Token.SEMI) {
				// This may be dead code add intentionally, for JSDoc purposes.
				// For example: /** @type Number */ C.prototype.x;
				if (currentJsDocComment !== null) {
					pn.setJsDocNode(getAndResetJsDoc());
				}
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function condExpr():AstNode {
			var pn:AstNode = orExpr();
			if (matchToken(Token.HOOK)) {
				var line:int = ts.lineno;
				var qmarkPos:int = ts.tokenBeg, colonPos:int = -1;
				/*
				 * Always accept the 'in' operator in the middle clause of a ternary,
				 * where it's unambiguous, even if we might be parsing the init of a
				 * for statement
				 */
				var wasInForInit:Boolean = inForInit;
				inForInit = false;
				var ifTrue:AstNode;
				try {
					ifTrue = assignExpr();
				} finally {
					inForInit = wasInForInit;
				}
				if (mustMatchToken(Token.COLON, "msg.no.colon.cond"))
					colonPos = ts.tokenBeg;
				var ifFalse:AstNode = assignExpr();
				var beg:int = pn.getPosition(), len:int = getNodeEnd(ifFalse) - beg;
				var ce:ConditionalExpression = new ConditionalExpression(beg, len);
				ce.setLineno(line);
				ce.setTestExpression(pn);
				ce.setTrueExpression(ifTrue);
				ce.setFalseExpression(ifFalse);
				ce.setQuestionMarkPosition(qmarkPos - beg);
				ce.setColonPosition(colonPos - beg);
				pn = ce;
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function orExpr():AstNode {
			var pn:AstNode = andExpr();
			if (matchToken(Token.OR)) {
				var opPos:int = ts.tokenBeg;
				pn = new InfixExpression(-1, -1, Token.OR, pn, orExpr(), opPos);
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function andExpr():AstNode {
			var pn:AstNode = bitOrExpr();
			if (matchToken(Token.AND)) {
				var opPos:int= ts.tokenBeg;
				pn = new InfixExpression(-1, -1, Token.AND, pn, andExpr(), opPos);
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function bitOrExpr():AstNode {
			var pn:AstNode = bitXorExpr();
			while (matchToken(Token.BITOR)) {
				var opPos:int = ts.tokenBeg;
				pn = new InfixExpression(-1, -1, Token.BITOR, pn, bitXorExpr(), opPos);
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function bitXorExpr():AstNode {
			var pn:AstNode = bitAndExpr();
			while (matchToken(Token.BITXOR)) {
				var opPos:int = ts.tokenBeg;
				pn = new InfixExpression(-1, -1, Token.BITXOR, pn, bitAndExpr(), opPos);
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function bitAndExpr():AstNode {
			var pn:AstNode = eqExpr();
			while(matchToken(Token.BITAND)) {
				var opPos:int = ts.tokenBeg;
				pn = new InfixExpression(-1, -1, Token.BITAND, pn, eqExpr(), opPos);
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function eqExpr():AstNode {
			var pn:AstNode = relExpr();
			for (;;) {
				var tt:int = peekToken(), opPos:int = ts.tokenBeg;
				switch(tt) {
					case Token.EQ:
					case Token.NE:
					case Token.SHEQ:
					case Token.SHNE:
						consumeToken();
						var parseToken:int = tt;
						if (compilerEnv.getLanguageVersion() === Context.VERSION_1_2) {
							// JavaScript 1.2 uses shallow equality for == and != .
							if (tt === Token.EQ)
								parseToken = Token.SHEQ;
							else if (tt === Token.NE)
								parseToken = Token.SHNE;
						}
						pn = new InfixExpression(-1, -1, parseToken, pn, relExpr(), opPos);
						continue;
				}
				break;
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function relExpr():AstNode {
			var pn:AstNode = shiftExpr();
			for (;;) {
				var tt:int = peekToken(), opPos:int = ts.tokenBeg;
				switch (tt) {
					case Token.IN:
						if (inForInit)
							break;
						// fall through
					case Token.INSTANCEOF:
					case Token.LE:
					case Token.LT:
					case Token.GE:
					case Token.GT:
						consumeToken();
						pn = new InfixExpression(-1, -1, tt, pn, shiftExpr(), opPos);
						continue;
				}
				break;
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function shiftExpr():AstNode {
			var pn:AstNode = addExpr();
			for (;;) {
				var tt:int = peekToken(), opPos:int = ts.tokenBeg;
				switch(tt) {
					case Token.LSH:
					case Token.URSH:
					case Token.RSH:
						consumeToken();
						pn = new InfixExpression(-1, -1, tt, pn, addExpr(), opPos);
						continue
				}
				break;
			}
			return pn;
		}
		
		/**
		 * @throws IOException
		 */
		private function addExpr():AstNode {
			var pn:AstNode = mulExpr();
			for (;;) {
				var tt:int = peekToken(), opPos:int = ts.tokenBeg;
				if (tt === Token.ADD || tt === Token.SUB) {
					consumeToken();
					pn = new InfixExpression(-1, -1, tt, pn, mulExpr(), opPos);
					continue;
				}
				break;
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function mulExpr():AstNode {
			var pn:AstNode = unaryExpr();
			for (;;) {
				var tt:int = peekToken(), opPos:int = ts.tokenBeg;
				switch (tt) {
					case Token.MUL:
					case Token.DIV:
					case Token.MOD:
						consumeToken();
						pn = new InfixExpression(-1, -1, tt, pn, unaryExpr(), opPos);
						continue;
				}
				break;
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function unaryExpr():AstNode {
			var node:AstNode;
			var tt:int = peekToken();
			var line:int = ts.lineno;
			
			switch(tt) {
				case Token.VOID:
				case Token.NOT:
				case Token.BITNOT:
				case Token.TYPEOF:
					consumeToken();
					node = new UnaryExpression(-1, -1, tt, ts.tokenBeg, unaryExpr());
					node.setLineno(line);
					return node;
					
				case Token.ADD:
					consumeToken();
					// Convert to special POS token in parse tree
					node = new UnaryExpression(-1, -1, Token.POS, ts.tokenBeg, unaryExpr());
					node.setLineno(line);
					return node;
					
				case Token.SUB:
					consumeToken();
					// Convert to special NEG token in parse tree
					node = new UnaryExpression(-1, -1, Token.NEG, ts.tokenBeg, unaryExpr());
					node.setLineno(line);
					return node;
					
				case Token.INC:
				case Token.DEC:
					consumeToken();
					var expr:UnaryExpression = new UnaryExpression(-1, -1, tt, ts.tokenBeg,
															   memberExpr(true));
					expr.setLineno(line);
					checkBadIncDec(expr);
					return expr;
					
				case Token.DELPROP:
					consumeToken();
					node = new UnaryExpression(-1, -1, tt, ts.tokenBeg, unaryExpr());
					node.setLineno(line);
					return node;
					
				case Token.ERROR:
					consumeToken();
					return makeErrorNode();
					
				case Token.LT:
					// XML stream encountered in expression.
					if (compilerEnv.isXmlAvailable()) {
						consumeToken();
						return memberExprTail(true, xmlInitializer());
					}
					// Fall thru to the default handling of RELOP
					
				default:
					var pn:AstNode = memberExpr(true);
					// Don't look across a newline boundary for a postfix incop.
					tt = peekTokenOrEOL();
					if (!(tt === Token.INC || tt === Token.DEC)) {
						return pn;
					}
					consumeToken();
					var uexpr:UnaryExpression =
							new UnaryExpression(-1, -1, tt, ts.tokenBeg, pn, true);
					uexpr.setLineno(line);
					checkBadIncDec(uexpr);
					return uexpr;
			}
		}
		
		/**
		 * @throws IOError
		 */
		private function xmlInitializer():AstNode {
			if (currentToken !== Token.LT) codeBug();
			var pos:int = ts.tokenBeg, tt:int = ts.getFirstXMLToken();
			if (tt !== Token.XML && tt !== Token.XMLEND) {
				reportError("msg.syntax");
				return makeErrorNode();
			}
			
			var pn:XmlLiteral = new XmlLiteral(pos);
			pn.setLineno(ts.lineno);
			
			for (;;tt = ts.getNextXMLToken()) {
				switch (tt) {
					case Token.XML:
						pn.addFragment(new XmlString(ts.tokenBeg, ts.getString()));
						mustMatchToken(Token.LC, "msg.syntax");
						var beg:int = ts.tokenBeg;
						var exprNode:AstNode = (peekToken() == Token.RC)
										   ? new EmptyExpression(beg, ts.tokenEnd - beg)
										   : expr();
						mustMatchToken(Token.RC, "msg.syntax");
						var xexpr:XmlExpression = new XmlExpression(beg, -1, exprNode);
						xexpr.setIsXmlAttribute(ts.isXMLAttribute());
						xexpr.setLength(ts.tokenEnd - beg);
						pn.addFragment(xexpr);
						break;
					
					case Token.XMLEND:
						pn.addFragment(new XmlString(ts.tokenBeg, ts.getString()));
						return pn;
						
					default:
						reportError("msg.syntax");
						return makeErrorNode();
				}
			}
		}
		
		private function argumentList():Vector.<AstNode> {
			if (matchToken(Token.RP))
				return null;
			
			var result:Vector.<AstNode> = new Vector.<AstNode>();
			var wasInForInit:Boolean = inForInit;
			inForInit = false;
			try {
				do {
					if (peekToken() === Token.YIELD) {
						reportError("msg.yield.parenthesized");
					}
					var en:AstNode = assignExpr();
					if (peekToken() === Token.FOR) {
						try {
							result.push(generatorExpression(en, 0, true));
						}
						catch(ex:IOError) {
							// #TODO
						}
					}
					else {
						result.push(en);
					}
				} while (matchToken(Token.COMMA));
			} finally {
				inForInit = wasInForInit;
			}
			
			mustMatchToken(Token.RP, "msg.no.paren.arg");
			return result;
		}
		
		/**
		 * Parse a new-expression, or if next token isn't {@link Token#NEW},
		 * a primary expression.
		 * @param allowCallSyntax passed down to {@link #memberExprTail}
		 */
		private function memberExpr(allowCallSyntax:Boolean):AstNode {
			var tt:int = peekToken(), lineno:int = ts.lineno;
			var pn:AstNode;
			
			if (tt !== Token.NEW) {
				pn = primaryExpr();
			} else {
				consumeToken();
				var pos:int = ts.tokenBeg;
				var nx:NewExpression = new NewExpression(pos);
				
				var target:AstNode = memberExpr(false);
				var end:int = getNodeEnd(target);
				nx.setTarget(target);
				
				var lp:int = -1;
				if (matchToken(Token.LP)) {
					lp = ts.tokenBeg;
					var args:Vector.<AstNode> = argumentList();
					if (args !== null && args.length > ARGC_LIMIT)
						reportError("msg.too.many.constructor.args");
					var rp:int = ts.tokenBeg;
					end = ts.tokenEnd;
					if (args !== null)
						nx.setArguments(args);
					nx.setParens(lp - pos, rp - pos);
				}
				
				// Experimental syntax: allow an object literal to follow a new
				// expression, which will mean a kind of anonymous class built with
				// the JavaAdapter.  the object literal will be passed as an
				// additional argument to the constructor.
				if (matchToken(Token.LC)) {
					var initializer:ObjectLiteral = objectLiteral();
					end = getNodeEnd(initializer);
					nx.setInitializer(initializer);
				}
				nx.setLength(end - pos);
				pn = nx;
			}
			pn.setLineno(lineno);
			var tail:AstNode = memberExprTail(allowCallSyntax, pn);
			return tail;
		}
		
		/**
		 * Parse any number of "(expr)", "[expr]" ".expr", "..expr",
		 * or ".(expr)" constructs trailing the passed expression.
		 * @param pn the non-null parent node
		 * @return the outermost (lexically last occurring) expression,
		 * which will have the passed parent node as a descendant
		 * @throws IOException
		 */
		private function memberExprTail(allowCallSyntax:Boolean, pn:AstNode):AstNode {
			// we no longer return null for errors, so this won't be null
			if (pn === null) codeBug();
			var pos:int = pn.getPosition();
			var lineno:int;
			tailLoop:
			for (;;) {
				var tt:int = peekToken();
				switch (tt) {
					case Token.DOT:
					case Token.DOTDOT:
						lineno = ts.lineno;
						pn = propertyAccess(tt, pn);
						pn.setLineno(lineno);
						break;
					
					case Token.DOTQUERY:
						consumeToken();
						var opPos:int = ts.tokenBeg, rp:int = -1;
						lineno = ts.lineno;
						mustHaveXML();
						setRequiresActivation();
						var filter:AstNode = expr();
						var end:int = getNodeEnd(filter);
						if (mustMatchToken(Token.RP, "msg.no.paren")) {
							rp = ts.tokenBeg;
							end = ts.tokenEnd;
						}
						var q:XmlDotQuery = new XmlDotQuery(pos, end - pos);
						q.setLeft(pn);
						q.setRight(filter);
						q.setOperatorPosition(opPos);
						q.setRp(rp - pos);
						q.setLineno(lineno);
						pn = q;
						break;
					
					case Token.LB:
						consumeToken();
						var lb:int = ts.tokenBeg, rb:int = -1;
						lineno = ts.lineno;
						var exprNode:AstNode = expr();
						end = getNodeEnd(exprNode);
						if (mustMatchToken(Token.RB, "msg.no.bracket.index")) {
							rb = ts.tokenBeg;
							end = ts.tokenEnd;
						}
						var g:ElementGet = new ElementGet(pos, end - pos);
						g.setTarget(pn);
						g.setElement(exprNode);
						g.setParens(lb, rb);
						g.setLineno(lineno);
						pn = g;
						break;
					
					case Token.LP:
						if (!allowCallSyntax) {
							break tailLoop;
						}
						lineno = ts.lineno;
						consumeToken();
						checkCallRequiresActivation(pn);
						var f:FunctionCall = new FunctionCall(pos);
						f.setTarget(pn);
						// Assign the line number for the function call to where
						// the paren appeared, not where the name expression started.
						f.setLineno(lineno);
						f.setLp(ts.tokenBeg - pos);
						var args:Vector.<AstNode> = argumentList();
						if (args !== null && args.length > ARGC_LIMIT)
							reportError("msg.too.many.function.args");
						f.setArguments(args);
						f.setRp(ts.tokenBeg - pos);
						f.setLength(ts.tokenEnd - pos);
						pn = f;
						break;
					
					default:
						break tailLoop;
				}
			}
			return pn;
		}
		
		/**
		 * Handles any construct following a "." or ".." operator.
		 * @param pn the left-hand side (target) of the operator.  Never null.
		 * @return a PropertyGet, XmlMemberGet, or ErrorNode
		 * @throws IOError
		 */
		private function propertyAccess(tt:int, pn:AstNode):AstNode	{
			if (pn === null) codeBug();
			var memberTypeFlags:int = 0, lineno:int = ts.lineno, dotPos:int = ts.tokenBeg;
			consumeToken();
			
			if (tt === Token.DOTDOT) {
				mustHaveXML();
				memberTypeFlags = Node.DESCENDANTS_FLAG;
			}
			
			if (!compilerEnv.isXmlAvailable()) {
				var maybeName:int = nextToken();
				if (maybeName != Token.NAME
					&& !(compilerEnv.isReservedKeywordAsIdentifier()
						&& TokenStream.isKeyword(ts.getString()))) {
					reportError("msg.no.name.after.dot");
				}
				
				var nameNode:Name = createNameNode(true, Token.GETPROP);
				var pg:PropertyGet = new PropertyGet(-1, -1, pn, nameNode, dotPos);
				pg.setLineno(lineno);
				return pg;
			}
			
			var ref:AstNode = null;  // right side of . or .. operator
			
			var token:int = nextToken();
			switch (token) {
				case Token.THROW:
					// needed for generator.throw();
					saveNameTokenData(ts.tokenBeg, "throw", ts.lineno);
					ref = propertyName(-1, "throw", memberTypeFlags);
					break;
				
				case Token.NAME:
					// handles: name, ns::name, ns::*, ns::[expr]
					ref = propertyName(-1, ts.getString(), memberTypeFlags);
					break;
				
				case Token.MUL:
					// handles: *, *::name, *::*, *::[expr]
					saveNameTokenData(ts.tokenBeg, "*", ts.lineno);
					ref = propertyName(-1, "*", memberTypeFlags);
					break;
				
				case Token.XMLATTR:
					// handles: '@attr', '@ns::attr', '@ns::*', '@ns::*',
					//          '@::attr', '@::*', '@*', '@*::attr', '@*::*'
					ref = attributeAccess();
					break;
				
				default:
					if (compilerEnv.isReservedKeywordAsIdentifier()) {
						// allow keywords as property names, e.g. ({if: 1})
						var name:String = Token.keywordToName(token);
						if (name != null) {
							saveNameTokenData(ts.tokenBeg, name, ts.lineno);
							ref = propertyName(-1, name, memberTypeFlags);
							break;
						}
					}
					reportError("msg.no.name.after.dot");
					return makeErrorNode();
			}
			
			var xml:Boolean = ref is XmlRef;
			var result:InfixExpression = xml ? new XmlMemberGet() : new PropertyGet();
			if (xml && tt === Token.DOT)
				result.setType(Token.DOT);
			var pos:int = pn.getPosition();
			result.setPosition(pos);
			result.setLength(getNodeEnd(ref) - pos);
			result.setOperatorPosition(dotPos - pos);
			result.setLineno(pn.getLineno());
			result.setLeft(pn);  // do this after setting position
			result.setRight(ref);
			return result;
		}

		/**
		 * Xml attribute expression:<p>
		 *   {@code @attr}, {@code @ns::attr}, {@code @ns::*}, {@code @ns::*},
		 *   {@code @*}, {@code @*::attr}, {@code @*::*}, {@code @ns::[expr]},
		 *   {@code @*::[expr]}, {@code @[expr]} <p>
		 * Called if we peeked an '@' token.
		 * @throws IOError
		 */
		private function attributeAccess():AstNode {
			var tt:int = nextToken(), atPos:int = ts.tokenBeg;
			
			switch (tt) {
				// handles: @name, @ns::name, @ns::*, @ns::[expr]
				case Token.NAME:
					return propertyName(atPos, ts.getString(), 0);
					
					// handles: @*, @*::name, @*::*, @*::[expr]
				case Token.MUL:
					saveNameTokenData(ts.tokenBeg, "*", ts.lineno);
					return propertyName(atPos, "*", 0);
					
					// handles @[expr]
				case Token.LB:
					return xmlElemRef(atPos, null, -1);
					
				default:
					reportError("msg.no.name.after.xmlAttr");
					return makeErrorNode();
			}
		}
		
		/**
		 * Check if :: follows name in which case it becomes a qualified name.
		 *
		 * @param atPos a natural number if we just read an '@' token, else -1
		 *
		 * @param s the name or string that was matched (an identifier, "throw" or
		 * "*").
		 *
		 * @param memberTypeFlags flags tracking whether we're a '.' or '..' child
		 *
		 * @return an XmlRef node if it's an attribute access, a child of a
		 * '..' operator, or the name is followed by ::.  For a plain name,
		 * returns a Name node.  Returns an ErrorNode for malformed XML
		 * expressions.  (For now - might change to return a partial XmlRef.)
		 * 
		 * @throws IOError
		 */
		private function propertyName(atPos:int, s:String, memberTypeFlags:int):AstNode {
			var pos:int = atPos != -1 ? atPos : ts.tokenBeg, lineno:int = ts.lineno;
			var colonPos:int = -1;
			var name:Name = createNameNode(true, currentToken);
			var ns:Name = null;
			
			if (matchToken(Token.COLONCOLON)) {
				ns = name;
				colonPos = ts.tokenBeg;
				
				switch (nextToken()) {
					// handles name::name
					case Token.NAME:
						name = createNameNode();
						break;
					
					// handles name::*
					case Token.MUL:
						saveNameTokenData(ts.tokenBeg, "*", ts.lineno);
						name = createNameNode(false, -1);
						break;
					
					// handles name::[expr] or *::[expr]
					case Token.LB:
						return xmlElemRef(atPos, ns, colonPos);
						
					default:
						reportError("msg.no.name.after.coloncolon");
						return makeErrorNode();
				}
			}
			
			if (ns == null && memberTypeFlags == 0 && atPos == -1) {
				return name;
			}
			
			var ref:XmlPropRef = new XmlPropRef(pos, getNodeEnd(name) - pos);
			ref.setAtPos(atPos);
			ref.setNamespace(ns);
			ref.setColonPos(colonPos);
			ref.setPropName(name);
			ref.setLineno(lineno);
			return ref;
		}
		
		/**
		 * Parse the [expr] portion of an xml element reference, e.g.
		 * @[expr], @*::[expr], or ns::[expr].
		 * 
		 * @throws IOError
		 */
		private function xmlElemRef(atPos:int, nameSpace:Name, colonPos:int):XmlElemRef {
			var lb:int = ts.tokenBeg, rb:int = -1, pos:int = atPos != -1 ? atPos : lb;
			var exprNode:AstNode = expr();
			var end:int = getNodeEnd(exprNode);
			if (mustMatchToken(Token.RB, "msg.no.bracket.index")) {
				rb = ts.tokenBeg;
				end = ts.tokenEnd;
			}
			var ref:XmlElemRef = new XmlElemRef(pos, end - pos);
			ref.setNamespace(nameSpace);
			ref.setColonPos(colonPos);
			ref.setAtPos(atPos);
			ref.setExpression(exprNode);
			ref.setBrackets(lb, rb);
			return ref;
		}
		
		/**
		 * @throws IOError, ParserError
		 */
		private function destructuringPrimaryExpr():AstNode {
			try {
				inDestructuringAssignment = true;
				return primaryExpr();
			} finally {
				inDestructuringAssignment = false;
			}
			return null;
		}
		
		/**
		 * @throws IOError
		 */
		private function primaryExpr():AstNode {
			var ttFlagged:int = nextFlaggedToken();
			var tt:int = ttFlagged & CLEAR_TI_MASK;
			
			switch(tt) {
				case Token.FUNCTION:
					return parseFunction(FunctionNode.FUNCTION_EXPRESSION);
					
				case Token.LB:
					return arrayLiteral();
					
				case Token.LC:
					return objectLiteral();
					
				case Token.LET:
					return let(false, ts.tokenBeg);
					
				case Token.LP:
					return parenExpr();
				
				case Token.XMLATTR:
					mustHaveXML();
					return attributeAccess();
					
				case Token.NAME:
					return name(ttFlagged, tt);
					
				case Token.NUMBER: {
					var s:String = ts.getString();
					if (this.inUseStrictDirective && ts.isNumberOctal()) {
						reportError("msg.no.octal.strict");
					}
					return new NumberLiteral(ts.tokenBeg, -1,
						s,
						ts.getNumber());
				}
					
				case Token.STRING:
					return createStringLiteral();
					
				case Token.DIV:
				case Token.ASSIGN_DIV:
					// Got / or /= which in this context means a regexp
					ts.readRegExp(tt);
					var pos:int = ts.tokenBeg, end:int = ts.tokenEnd;
					var re:RegExpLiteral = new RegExpLiteral(pos, end - pos);
					re.setValue(ts.getString());
					re.setFlags(ts.readAndClearRegExpFlags());
					return re;
					
				case Token.NULL:
				case Token.THIS:
				case Token.FALSE:
				case Token.TRUE:
					pos = ts.tokenBeg; end = ts.tokenEnd;
					return new KeywordLiteral(pos, end - pos, tt);
					
				case Token.RESERVED:
					reportError("msg.reserved.id");
					break;
				
				case Token.ERROR:
					// the scanner or one of its subroutines reported the error.
					break;
				
				case Token.EOF:
					reportError("msg.unexpected.eof");
					break;
				
				default:
					reportError("msg.syntax");
					break;
			}
			// should only be reachable in IDE/error-recovery mode
			return makeErrorNode();
		}
		
		/**
		 * @throws IOError
		 */
		private function parenExpr():AstNode {
			var wasInForInit:Boolean = inForInit;
			inForInit = false;
			try {
				var jsdocNode:Comment = getAndResetJsDoc();
				var lineno:int = ts.lineno;
				var begin:int = ts.tokenBeg;
				var e:AstNode = expr();
				if (peekToken() === Token.FOR) {
					return generatorExpression(e, begin);
				}
				var pn:ParenthesizedExpression = new ParenthesizedExpression(-1, -1, e);
				if (jsdocNode === null) {
					jsdocNode = getAndResetJsDoc();
				}
				if (jsdocNode !== null) {
					pn.setJsDocNode(jsdocNode);
				}
				mustMatchToken(Token.RP, "msg.no.paren");
				pn.setLength(ts.tokenEnd - pn.getPosition());
				pn.setLineno(lineno);
				return pn;
			} finally {
				inForInit = wasInForInit;
			}
			return null;
		}
		
		/**
		 * @throws IOError
		 */
		private function name(ttFlagged:int, tt:int):AstNode {
			var nameString:String = ts.getString();
			var namePos:int = ts.tokenBeg, nameLineno:int = ts.lineno;
			if (0 !== (ttFlagged & TI_CHECK_LABEL) && peekToken() === Token.COLON) {
				// Do not consume colon.  It is used as an unwind indicator
				// to return to statementHelper.
				var label:Label = new Label(namePos, ts.tokenEnd - namePos);
				label.setName(nameString);
				label.setLineno(ts.lineno);
				return label;
			}
			// Not a label.  Unfortunately peeking the next token to check for
			// a colon has biffed ts.tokenBeg, ts.tokenEnd.  We store the name's
			// bounds in instance vars and createNameNode uses them.
			saveNameTokenData(namePos, nameString, nameLineno);
			
			if (compilerEnv.isXmlAvailable()) {
				return propertyName(-1, nameString, 0);
			} else {
				return createNameNode(true, Token.NAME);
			}
		}
		
		/**
		 * May return an {@link ArrayLiteral} or {@link ArrayComprehension}.
		 * 
		 * @throws IOError
		 */
		private function arrayLiteral():AstNode {
			if (currentToken !== Token.LB) codeBug();
			var pos:int = ts.tokenBeg, end:int = ts.tokenEnd;
			var elements:Vector.<AstNode> = new Vector.<AstNode>();
			var pn:ArrayLiteral = new ArrayLiteral(pos);
			var after_lb_or_comma:Boolean = true;
			var afterComma:int = -1;
			var skipCount:int = 0;
			for (;;) {
				var tt:int = peekToken();
				if (tt === Token.COMMA) {
					consumeToken();
					afterComma = ts.tokenEnd;
					if (!after_lb_or_comma) {
						after_lb_or_comma = true;
					} else {
						elements.push(new EmptyExpression(ts.tokenBeg, 1));
						skipCount++;
					}
				} else if (tt === Token.RB) {
					consumeToken();
					// for ([a,] in obj) is legal, but for ([a] in obj) is
					// not since we have both key and value supplied. The
					// trick is that [a,] and [a] are equivalent in other
					// array literal contexts. So we calculate a special
					// length value just for destructuring assignment.
					end = ts.tokenEnd;
					pn.setDestructuringLength(elements.length +
											  (after_lb_or_comma ? 1 : 0));
					pn.setSkipCount(skipCount);
					if (afterComma !== -1)
						warnTrailingComma(pos, elements, afterComma);
					break;
				} else if (tt === Token.FOR && !after_lb_or_comma
						   && elements.length === 1) {
					return arrayComprehension(elements[0], pos);
				} else if (tt === Token.EOF) {
					reportError("msg.no.bracket.arg");
					break;
				} else {
					if (!after_lb_or_comma) {
						reportError("msg.no.bracket.arg");
					}
					elements.push(assignExpr());
					after_lb_or_comma = false;
					afterComma = -1;
				}
			}
			for each (var e:AstNode in elements) {
				pn.addElement(e);
			}
			pn.setLength(end - pos);
			return pn;
		}
		
		/**
		 * Parse a JavaScript 1.7 Array comprehension.
		 * @param result the first expression after the opening left-bracket
		 * @param pos start of LB token that begins the array comprehension
		 * @return the array comprehension or an error node
		 * 
		 * @throws IOError
		 */
		private function arrayComprehension(result:AstNode, pos:int):AstNode
		{
			var loops:Vector.<ArrayComprehensionLoop> =
				new Vector.<ArrayComprehensionLoop>();
			while (peekToken() === Token.FOR) {
				loops.push(arrayComprehensionLoop());
			}
			var ifPos:int = -1;
			var data:ConditionData = null;
			if (peekToken() === Token.IF) {
				consumeToken();
				ifPos = ts.tokenBeg - pos;
				data = condition();
			}
			mustMatchToken(Token.RB, "msg.no.bracket.arg");
			var pn:ArrayComprehension = new ArrayComprehension(pos, ts.tokenEnd - pos);
			pn.setResult(result);
			pn.setLoops(loops);
			if (data !== null) {
				pn.setIfPosition(ifPos);
				pn.setFilter(data.condition);
				pn.setFilterLp(data.lp - pos);
				pn.setFilterRp(data.rp - pos);
			}
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function arrayComprehensionLoop():ArrayComprehensionLoop {
			if (nextToken() !== Token.FOR) codeBug();
			var pos:int = ts.tokenBeg;
			var eachPos:int = -1, lp:int = -1, rp:int = -1, inPos:int = -1;
			var pn:ArrayComprehensionLoop = new ArrayComprehensionLoop(pos);
			
			pushScope(pn);
			try {
				if (matchToken(Token.NAME)) {
					if (ts.getString() === "each") {
						eachPos = ts.tokenBeg - pos;
					} else {
						reportError("msg.no.paren.for");
					}
				}
				if (mustMatchToken(Token.LP, "msg.no.paren.for")) {
					lp = ts.tokenBeg - pos;
				}
				
				var iter:AstNode = null;
				switch (peekToken()) {
					case Token.LB:
					case Token.LC:
						// handle destructuring assignment
						iter = destructuringPrimaryExpr();
						markDestructuring(iter);
						break;
					case Token.NAME:
						consumeToken();
						iter = createNameNode();
						break;
					default:
						reportError("msg.bad.var");
				}
				
				// Define as a let since we want the scope of the variable to
				// be restricted to the array comprehension
				if (iter.getType() === Token.NAME) {
					defineSymbol(Token.LET, ts.getString(), true);
				}
				
				if (mustMatchToken(Token.IN, "msg.in.after.for.name"))
					inPos = ts.tokenBeg - pos;
				var obj:AstNode = expr();
				if (mustMatchToken(Token.RP, "msg.no.paren.for.ctrl"))
					rp = ts.tokenBeg - pos;
				
				pn.setLength(ts.tokenEnd - pos);
				pn.setIterator(iter);
				pn.setIteratedObject(obj);
				pn.setInPosition(inPos);
				pn.setEachPosition(eachPos);
				pn.setIsForEach(eachPos !== -1);
				pn.setParens(lp, rp);
				return pn;
			} finally {
				popScope();
			}
			return null;
		}

		/**
		 * @throws IOError
		 */
		private function generatorExpression(result:AstNode, pos:int, inFunctionParams:Boolean = false):AstNode {
			var loops:Vector.<GeneratorExpressionLoop> =
				new Vector.<GeneratorExpressionLoop>();
			while (peekToken() === Token.FOR) {
				loops.push(generatorExpressionLoop());
			}
			var ifPos:int = -1;
			var data:ConditionData = null;
			if (peekToken() === Token.IF) {
				consumeToken();
				ifPos = ts.tokenBeg - pos;
				data = condition();
			}
			if(!inFunctionParams) {
				mustMatchToken(Token.RP, "msg.no.paren.let");
			}
			var pn:GeneratorExpression = new GeneratorExpression(pos, ts.tokenEnd - pos);
			pn.setResult(result);
			pn.setLoops(loops);
			if (data !== null) {
				pn.setIfPosition(ifPos);
				pn.setFilter(data.condition);
				pn.setFilterLp(data.lp - pos);
				pn.setFilterRp(data.rp - pos);
			}
			return pn;
		}
		
		private function generatorExpressionLoop():GeneratorExpressionLoop {
			if (nextToken() !== Token.FOR) codeBug();
			var pos:int = ts.tokenBeg;
			var lp:int = -1, rp:int = -1, inPos:int = -1;
			var pn:GeneratorExpressionLoop = new GeneratorExpressionLoop(pos);
			
			pushScope(pn);
			try {
				if (mustMatchToken(Token.LP, "msg.no.paren.for")) {
					lp = ts.tokenBeg - pos;
				}
				
				var iter:AstNode = null;
				switch (peekToken()) {
					case Token.LB:
					case Token.LC:
						// handle destructuring assignment
						iter = destructuringPrimaryExpr();
						markDestructuring(iter);
						break;
					case Token.NAME:
						consumeToken();
						iter = createNameNode();
						break;
					default:
						reportError("msg.bad.var");
				}
				
				// Define as a let since we want the scope of the variable to
				// be restricted to the array comprehension
				if (iter.getType() === Token.NAME) {
					defineSymbol(Token.LET, ts.getString(), true);
				}
				
				if (mustMatchToken(Token.IN, "msg.in.after.for.name"))
					inPos = ts.tokenBeg - pos;
				var obj:AstNode = expr();
				if (mustMatchToken(Token.RP, "msg.no.paren.for.ctrl"))
					rp = ts.tokenBeg - pos;
				
				pn.setLength(ts.tokenEnd - pos);
				pn.setIterator(iter);
				pn.setIteratedObject(obj);
				pn.setInPosition(inPos);
				pn.setParens(lp, rp);
				return pn;
			} finally {
				popScope();
			}
			return null;
		}
		
		/**
		 * @throws IOError
		 */
		private function objectLiteral():ObjectLiteral {
			var pos:int = ts.tokenBeg, lineno:int = ts.lineno;
			var afterComma:int = -1;
			var elems:Vector.<ObjectProperty> = new Vector.<ObjectProperty>();
			var getterNames:StringSet = null;
			var setterNames:StringSet = null;
			if (this.inUseStrictDirective) {
				getterNames = new StringSet();
				setterNames = new StringSet();
			}
			var objJsdocNode:Comment = getAndResetJsDoc();
			var astNodeElems:Vector.<AstNode>;
			var pname:AstNode;
			
			commaLoop:
			for (;;) {
				var propertyName:String = null;
				var entryKind:int = PROP_ENTRY;
				var tt:int = peekToken();
				var jsdocNode:Comment = getAndResetJsDoc();
				switch(tt) {
					case Token.NAME:
						var name:Name = createNameNode();
						propertyName = ts.getString();
						var ppos:int = ts.tokenBeg;
						consumeToken();
						
						// This code path needs to handle both destructuring object
						// literals like:
						// var {get, b} = {get: 1, b: 2};
						// and getters like:
						// var x = {get 1() { return 2; };
						// So we check a whitelist of tokens to check if we're at the
						// first case. (Because of keywords, the second case may be
						// many tokens.)
						var peeked:int = peekToken();
						var maybeGetterOrSetter:Boolean =
							"get" === propertyName || "set" === propertyName;
						if (maybeGetterOrSetter
							&& peeked !== Token.COMMA
							&& peeked !== Token.COLON
							&& peeked !== Token.RC)
						{
							var isGet:Boolean = "get" === propertyName;
							entryKind = isGet ? GET_ENTRY : SET_ENTRY;
							pname = objliteralProperty();
							if (pname === null) {
								propertyName = null;
							} else {
								propertyName = ts.getString();
								var objectProp:ObjectProperty = getterSetterProperty(
										ppos, pname, isGet);
								pname.setJsDocNode(jsdocNode);
								elems.push(objectProp);
							}
						} else {
							name.setJsDocNode(jsdocNode);
							elems.push(plainProperty(name, tt));
						}
						break;
					
					case Token.RC:
						if (afterComma !== -1) {
							astNodeElems = new Vector.<AstNode>();
							for each (var e:ObjectProperty in elems) {
								astNodeElems.push(e);
							}
							warnTrailingComma(pos, astNodeElems, afterComma);
						}
						break commaLoop;
					
					default:
						pname = objliteralProperty();
						if (pname === null) {
							propertyName = null;
						} else {
							propertyName = ts.getString();
							pname.setJsDocNode(jsdocNode);
							elems.push(plainProperty(pname, tt));
						}
						break;
				}
				
				if (this.inUseStrictDirective && propertyName !== null) {
					switch (entryKind) {
						case PROP_ENTRY:
							if (getterNames.has(propertyName)
								|| setterNames.has(propertyName)) {
								addError("msg.dup.obj.lit.prop.strict", propertyName);
							}
							getterNames.add(propertyName);
							setterNames.add(propertyName);
							break;
						case GET_ENTRY:
							if (getterNames.has(propertyName)) {
								addError("msg.dup.obj.lit.prop.strict", propertyName);
							}
							getterNames.add(propertyName);
							break;
						case SET_ENTRY:
							if (setterNames.has(propertyName)) {
								addError("msg.dup.obj.lit.prop.strict", propertyName);
							}
							setterNames.add(propertyName);
							break;
					}
				}
				
				// Eat any dangling jsdoc in the property.
				getAndResetJsDoc();
				
				if (matchToken(Token.COMMA)) {
					afterComma = ts.tokenEnd;
				} else {
					break commaLoop;
				}
			}
			
			mustMatchToken(Token.RC, "msg.no.brace.prop");
			var pn:ObjectLiteral = new ObjectLiteral(pos, ts.tokenEnd - pos);
			if (objJsdocNode !== null) {
				pn.setJsDocNode(objJsdocNode);
			}
			pn.setElements(elems);
			pn.setLineno(lineno);
			return pn;
		}
		
		/**
		 * @throws IOError
		 */
		private function objliteralProperty():AstNode {
			var pname:AstNode;
			var tt:int = peekToken();
			switch(tt) {
				case Token.NAME:
					pname = createNameNode();
					break;
				
				case Token.STRING:
					pname = createStringLiteral();
					break;
				
				case Token.NUMBER:
					pname = new NumberLiteral(
						ts.tokenBeg, -1, ts.getString(), ts.getNumber());
					break;
				
				default:
					if (compilerEnv.isReservedKeywordAsIdentifier()
						&& TokenStream.isKeyword(ts.getString())) {
						// convert keyword to property name, e.g. ({if: 1})
						pname = createNameNode();
						break;
					}
					reportError("msg.bad.prop");
					return null;
			}
			
			consumeToken();
			return pname;
		}
		
		/**
		 * @throws IOError
		 */
		private function plainProperty(property:AstNode, ptt:int):ObjectProperty
		{
			// Support, e.g., |var {x, y} = o| as destructuring shorthand
			// for |var {x: x, y: y} = o|, as implemented in spidermonkey JS 1.8.
			var tt:int = peekToken();
			var pn:ObjectProperty;
			if ((tt === Token.COMMA || tt === Token.RC) && ptt === Token.NAME
				&& compilerEnv.getLanguageVersion() >= Context.VERSION_1_8) {
				if (!inDestructuringAssignment) {
					reportError("msg.bad.object.init");
				}
				var nn:AstNode = new Name(property.getPosition(), -1, property.getString());
				pn = new ObjectProperty();
				pn.putProp(Node.DESTRUCTURING_SHORTHAND, true);
				pn.setLeftAndRight(property, nn);
				return pn;
			}
			mustMatchToken(Token.COLON, "msg.no.colon.prop");
			pn = new ObjectProperty();
			pn.setOperatorPosition(ts.tokenBeg);
			pn.setLeftAndRight(property, assignExpr());
			return pn;
		}
		
		private function getterSetterProperty(pos:int, propName:AstNode, isGetter:Boolean):ObjectProperty
		{
			var fn:FunctionNode = parseFunction(FunctionNode.FUNCTION_EXPRESSION);
				// We've already parsed the function name, so fn should be anonymous.
				var name:Name = fn.getFunctionName();
			if (name !== null && name.length !== 0) {
				reportError("msg.bad.prop");
			}
			var pn:ObjectProperty = new ObjectProperty(pos);
			if (isGetter) {
				pn.setIsGetter();
			} else {
				pn.setIsSetter();
			}
			var end:int = getNodeEnd(fn);
			pn.setLeft(propName);
			pn.setRight(fn);
			pn.setLength(end - pos);
			return pn;
		}
		
		/**
		 * Create a {@code Name} node using the token info from the
		 * last scanned name.  In some cases we need to either synthesize
		 * a name node, or we lost the name token information by peeking.
		 * If the {@code token} parameter is not {@link Token#NAME}, then
		 * we use token info saved in instance vars.
		 */
		private function createNameNode(checkActivation:Boolean=false, token:int=Token.NAME):Name {
			var beg:int = ts.tokenBeg;
			var s:String = ts.getString();
			var lineno:int = ts.lineno;
			if ("" !== prevNameTokenString) {
				beg = prevNameTokenStart;
				s = prevNameTokenString;
				lineno = prevNameTokenLineno;
				prevNameTokenStart = 0;
				prevNameTokenString = "";
				prevNameTokenLineno = 0;
			}
			if (s === null) {
				if (compilerEnv.isIdeMode()) {
					s = "";
				} else {
					codeBug();
				}
			}
			var name:Name = new Name(beg, -1, s);
			name.setLineno(lineno);
			if (checkActivation) {
				checkActivationName(s, token);
			}
			return name;
		}
		
		private function createStringLiteral():StringLiteral {
			var pos:int = ts.tokenBeg, end:int = ts.tokenEnd;
			var s:StringLiteral = new StringLiteral(pos, end - pos);
			s.setLineno(ts.lineno);
			s.setValue(ts.getString());
			s.setQuoteCharacter(String.fromCharCode(ts.getQuoteChar()));
			return s;
		}
		
		protected function createName(name:String=null, child:Node=null, type:int=-1):Node {
			if (name === null) throw new ArgumentError("name cannot be null.");
			checkActivationName(name, Token.NAME);
			var result:Node = Node.newString(name, Token.NAME);
			if (type === -1 && child === null) {
				return result;
			}
			else if (type !== -1) {
				result.setType(type);
				if (child !== null)
					result.addChildToBack(child);
				return result;
			}
			throw new ArgumentError("Invalid invocation.");
			return null;
		}
		
		protected function createNumber(number:Number):Node {
			return Node.newNumber(number);
		}
		
		protected function createScopeNode(token:int, lineno:int):Scope {
			var scope:Scope = new Scope();
			scope.setType(token);
			scope.setLineno(lineno);
			return scope;
		}
		
		// Quickie tutorial for some of the interpreter bytecodes.
		//
		// GETPROP - for normal foo.bar prop access; right side is a name
		// GETELEM - for normal foo[bar] element access; rhs is an expr
		// SETPROP - for assignment when left side is a GETPROP
		// SETELEM - for assignment when left side is a GETELEM
		// DELPROP - used for delete foo.bar or foo[bar]
		//
		// GET_REF, SET_REF, DEL_REF - in general, these mean you're using
		// get/set/delete on a right-hand side expression (possibly with no
		// explicit left-hand side) that doesn't use the normal JavaScript
		// Object (i.e. ScriptableObject) get/set/delete functions, but wants
		// to provide its own versions instead.  It will ultimately implement
		// Ref, and currently SpecialRef (for __proto__ etc.) and XmlName
		// (for E4X XML objects) are the only implementations.  The runtime
		// notices these bytecodes and delegates get/set/delete to the object.
		//
		// BINDNAME:  used in assignments.  LHS is evaluated first to get a
		// specific object containing the property ("binding" the property
		// to the object) so that it's always the same object, regardless of
		// side effects in the RHS.
		
		protected function simpleAssignment(left:Node, right:Node):Node {
			var nodeType:int = left.getType();
			switch (nodeType) {
				case Token.NAME:
					if (inUseStrictDirective &&
						"eval" === Name(left).getIdentifier())
					{
						reportError("msg.bad.id.strict",
							Name(left).getIdentifier());
					}
					left.setType(Token.BINDNAME);
					return new Node(Token.SETNAME, null, left, null, right);
					
					case Token.GETPROP:
					case Token.GETELEM: {
					var obj:Node, id:Node;
					// If it's a PropertyGet or ElementGet, we're in the parse pass.
					// We could alternately have PropertyGet and ElementGet
					// override getFirstChild/getLastChild and return the appropriate
					// field, but that seems just as ugly as this casting.
					if (left is PropertyGet) {
						obj = PropertyGet(left).getTarget();
						id = PropertyGet(left).getProperty();
					} else if (left is ElementGet) {
						obj = ElementGet(left).getTarget();
						id = ElementGet(left).getElement();
					} else {
						// This branch is called during IRFactory transform pass.
						obj = left.getFirstChild();
						id = left.getLastChild();
					}
					var type:int;
					if (nodeType === Token.GETPROP) {
						type = Token.SETPROP;
						// TODO(stevey) - see https://bugzilla.mozilla.org/show_bug.cgi?id=492036
						// The new AST code generates NAME tokens for GETPROP ids where the old parser
						// generated STRING nodes. If we don't set the type to STRING below, this will
						// cause java.lang.VerifyError in codegen for code like
						// "var obj={p:3};[obj.p]=[9];"
						id.setType(Token.STRING);
					} else {
						type = Token.SETELEM;
					}
					return new Node(type, null, obj, id, right);
				}
				case Token.GET_REF: {
					var ref:Node = left.getFirstChild();
					checkMutableReference(ref);
					return new Node(Token.SET_REF, null, ref, null, right);
				}
			}
			
			throw codeBug();
		}
		
		protected function checkActivationName(name:String, token:int):void {
			if (!insideFunction()) {
				return;
			}
			var activation:Boolean = false;
			if (name === "arguments"
				|| (compilerEnv.getActivationNames() !== null
					&& compilerEnv.getActivationNames().has(name) !== -1))
			{
				activation = true
			} else if (name === "length") {
				if (token === Token.GETPROP
					&& compilerEnv.getLanguageVersion() === Context.VERSION_1_2)
				{
					// Use of "length" in 1.2 requires an activation object.
					activation = true;
				}
			}
			if (activation) {
				setRequiresActivation();
			}
		}
		
		protected function checkMutableReference(n:Node):void {
			var memberTypeFlags:int = n.getIntProp(Node.MEMBER_TYPE_PROP, 0);
			if ((memberTypeFlags & Node.DESCENDANTS_FLAG) !== 0) {
				reportError("msg.bad.assign.left");
			}
		}
		
		// remove any ParenthesizedExpression wrappers
		protected function removeParens(node:AstNode):AstNode {
			while (node is ParenthesizedExpression) {
				node = ParenthesizedExpression(node).getExpression();
			}
			return node;
		}
		
		protected function markDestructuring(node:AstNode):void {
			if (node is IDestructuringForm) {
				IDestructuringForm(node).setIsDestructuring(true);
			} else if (node is ParenthesizedExpression) {
				markDestructuring(ParenthesizedExpression(node).getExpression());
			}
		}
		
		protected function insideFunction():Boolean {
			return nestingOfFunction !== 0;
		}
		
		protected function setRequiresActivation():void {
			if (insideFunction()) {
				FunctionNode(currentScriptOrFn).setRequiresActivation();
			}
		}
		
		private function checkCallRequiresActivation(pn:AstNode):void {
			if ((pn.getType() === Token.NAME
				&& "eval" === (PropertyGet(pn).getProperty().getIdentifier()))
				|| (pn.getType() === Token.GETPROP &&
					"eval" === (PropertyGet(pn).getProperty().getIdentifier())))
				setRequiresActivation();
		}
		
		protected function setIsGenerator():void {
			if (insideFunction()) {
				FunctionNode(currentScriptOrFn).setIsGenerator();
			}
		}
		
		private function checkBadIncDec(expr:UnaryExpression):void {
			var op:AstNode = removeParens(expr.getOperand());
			var tt:int = op.getType();
			if (!(tt === Token.NAME
				  || tt === Token.GETPROP
				  || tt === Token.GETELEM
				  || tt === Token.GET_REF
				  || tt === Token.CALL))
				reportError(expr.getType() === Token.INC
					        ? "msg.bad.incr"
							: "msg.bad.decr");
		}
		
		private function makeErrorNode():ErrorNode {
			var pn:ErrorNode = new ErrorNode(ts.tokenBeg, ts.tokenEnd - ts.tokenBeg);
			pn.setLineno(ts.lineno);
			return pn;
		}
		
		// Return end of node.  Assumes node does NOT have a parent yet.
		private function nodeEnd(node:AstNode):int {
			return node.getPosition() + node.getLength();
		}
		
		private function saveNameTokenData(pos:int, name:String, lineno:int):void {
			prevNameTokenStart = pos;
			prevNameTokenString = name;
			prevNameTokenLineno = lineno;
		}
		
		/**
		 * Return the file offset of the beginning of the input source line
		 * containing the passed position.
		 *
		 * @param pos an offset into the input source stream.  If the offset
		 * is negative, it's converted to 0, and if it's beyond the end of
		 * the source buffer, the last source position is used.
		 *
		 * @return the offset of the beginning of the line containing pos
		 * (i.e. 1+ the offset of the first preceding newline).  Returns -1
		 * if the {@link CompilerEnvirons} is not set to ide-mode,
		 * and {@link #parse(java.io.Reader,String,int)} was used.
		 */
		private function lineBeginningFor(pos:int):int {
			if (sourceChars === null) {
				return -1;
			}
			if (pos <= 0) {
				return 0;
			}
			var buf:Vector.<int> = sourceChars;
			if (pos >= buf.length) {
				pos = buf.length - 1;
			}
			while (--pos >= 0) {
				var c:int = buf[pos];
				if (c === 0x0A /* \n */ || c === 0x0D /* \r */) {
					return pos + 1; // want position after the newline
				}
			}
			return 0;
		}
		
		private function warnMissingSemi(pos:int, end:int):void {
			// Should probably change this to be a CompilerEnvirons setting,
			// with an enum Never, Always, Permissive, where Permissive means
			// don't warn for 1-line functions like function (s) {return x+2}
			if (compilerEnv.isStrictMode()) {
				var beg:int = Math.max(pos, lineBeginningFor(end));
				if (end === -1)
					end = ts.cursor;
				addStrictWarning("msg.missing.semi", "",
								 beg, end - beg);
			}
		}
		
		private function warnTrailingComma(pos:int, elems:Vector.<AstNode>, commaPos:int):void {
			if (compilerEnv.getWarnTrailingComma()) {
				// back up from comma to beginning of line or array/objlit
				if (elems.length !== 0) {
					pos = AstNode(elems[0]).getPosition();
				}
				pos = Math.max(pos, lineBeginningFor(commaPos));
				addWarning("msg.extra.trailing.comma", "", pos, commaPos - pos);
			}
		}
		
		/**
		 * @throws IOError
		 */
		private function readFully(reader:Reader):String {
			throw new Error("Parser#readFully() not yet implemented.");
		}
		
		/**
		 * Given a destructuring assignment with a left hand side parsed
		 * as an array or object literal and a right hand side expression,
		 * rewrite as a series of assignments to the variables defined in
		 * left from property accesses to the expression on the right.
		 * @param type declaration type: Token.VAR or Token.LET or -1
		 * @param left array or object literal containing NAME nodes for
		 *        variables to assign
		 * @param right expression to assign from
		 * @return expression that performs a series of assignments to
		 *         the variables defined in left
		 */
		protected function createDestructuringAssignment(type:int, left:Node, right:Node):Node
		{
			var tempName:String = currentScriptOrFn.getNextTempName();
			var result:Node = destructuringAssignmentHelper(type, left, right,
				tempName);
			var comma:Node = result.getLastChild();
			comma.addChildToBack(createName(tempName));
			return result;
		}
		
		protected function destructuringAssignmentHelper(variableType:int, left:Node,
			right:Node, tempName:String):Node
		{
			var result:Scope = createScopeNode(Token.LETEXPR, left.getLineno());
			result.addChildToFront(new Node(Token.LET,
											createName(tempName, right, Token.NAME)));
			try {
				pushScope(result);
				defineSymbol(Token.LET, tempName, true);
			} finally {
				popScope();
			}
			var comma:Node = new Node(Token.COMMA);
			result.addChildToBack(comma);
			var destructuringNames:Vector.<String> = new Vector.<String>();
			var empty:Boolean = true;
			switch (left.getType()) {
				case Token.ARRAYLIT:
					empty = destructuringArray(ArrayLiteral(left),
						variableType, tempName, comma,
						destructuringNames);
					break;
				case Token.OBJECTLIT:
				empty = destructuringObject(ObjectLiteral(left),
					variableType, tempName, comma,
					destructuringNames);
				break;
				case Token.GETPROP:
				case Token.GETELEM:
				switch (variableType) {
					case Token.CONST:
					case Token.LET:
					case Token.VAR:
						reportError("msg.bad.assign.left");
				}
				comma.addChildToBack(simpleAssignment(left, createName(tempName)));
				break;
				default:
				reportError("msg.bad.assign.left");
			}
			if (empty) {
				// Don't want a COMMA node with no children. Just add a zero.
				comma.addChildToBack(createNumber(0));
			}
			result.putProp(Node.DESTRUCTURING_NAMES, destructuringNames);
			return result;
		}
		
		protected function destructuringArray(array:ArrayLiteral,
			variableType:int,
			tempName:String,
			parent:Node,
			destructuringNames:Vector.<String>):Boolean
		{
			var empty:Boolean = true;
			var setOp:int = variableType === Token.CONST
				? Token.SETCONST : Token.SETNAME;
			var index:int = 0;
			for each (var n:AstNode in array.getElements()) {
				if (n.getType() === Token.EMPTY) {
					index++;
					continue;
				}
				var rightElem:Node = new Node(Token.GETELEM, null,
											  createName(tempName),
											  null,
											  createNumber(index));
				if (n.getType() === Token.NAME) {
					var name:String = n.getString();
					parent.addChildToBack(new Node(setOp, null,
												  createName(name, null, Token.BINDNAME),
												  null,
												  rightElem));
					if (variableType !== -1) {
						defineSymbol(variableType, name, true);
						destructuringNames.push(name);
					}
				} else {
					parent.addChildToBack
						(destructuringAssignmentHelper
						 (variableType, n,
						  rightElem,
						  currentScriptOrFn.getNextTempName()));
				}
				index++;
				empty = false;
			}
			return empty;
		}
		
		// have to pass in 'let' kwd position to compute kid offsets properly
		/**
		 * @throws IOError
		 */
		private function let(isStatement:Boolean, pos:int):AstNode
		{
			var pn:LetNode = new LetNode(pos);
			pn.setLineno(ts.lineno);
			if (mustMatchToken(Token.LP, "msg.no.paren.after.let"))
				pn.setLp(ts.tokenBeg - pos);
			pushScope(pn);
			try {
				var vars:VariableDeclaration = variables(Token.LET, ts.tokenBeg, isStatement);
				pn.setVariables(vars);
				if (mustMatchToken(Token.RP, "msg.no.paren.let")) {
					pn.setRp(ts.tokenBeg - pos);
				}
				if (isStatement && peekToken() === Token.LC) {
					// let statement
					consumeToken();
					var beg:int = ts.tokenBeg;  // position stmt at LC
					var stmt:AstNode = statements();
					mustMatchToken(Token.RC, "msg.no.curly.let");
					stmt.setLength(ts.tokenEnd - beg);
					pn.setLength(ts.tokenEnd - pos);
					pn.setBody(stmt);
					pn.setType(Token.LET);
				} else {
					// let expression
					var exprNode:AstNode = expr();
					pn.setLength(getNodeEnd(exprNode) - pos);
					pn.setBody(exprNode);
					if (isStatement) {
						// let expression in statement context
						var es:ExpressionStatement =
							new ExpressionStatement(-1, -1, pn, !insideFunction());
						es.setLineno(pn.getLineno());
						return es;
					}
				}
			} finally {
				popScope();
			}
			return pn;
		}
		
		protected function destructuringObject(node:ObjectLiteral,
			variableType:int,
			tempName:String,
			parent:Node,
			destructuringNames:Vector.<String>):Boolean
		{
			var empty:Boolean = true;
			var setOp:int = variableType === Token.CONST
				? Token.SETCONST : Token.SETNAME;
			
			for each (var prop:ObjectProperty in node.getElements()) {
				var lineno:int = 0;
				// This function is sometimes called from the IRFactory when
				// when executing regression tests, and in those cases the
				// tokenStream isn't set.  Deal with it.
				if (ts !== null) {
					lineno = ts.lineno;
				}
				var id:AstNode = prop.getLeft();
				var rightElem:Node = null;
				var s:Node;
				if (id is Name) {
					s = Node.newString(Name(id).getIdentifier());
					rightElem = new Node(Token.GETPROP, null, createName(tempName), null, s);
				} else if (id is StringLiteral) {
					s = Node.newString(StringLiteral(id).getValue());
					rightElem = new Node(Token.GETPROP, null, createName(tempName), null, s);
				} else if (id is NumberLiteral) {
					s = createNumber(int(NumberLiteral(id).getNumber()));
					rightElem = new Node(Token.GETELEM, null, createName(tempName), null, s);
				} else {
					throw codeBug();
				}
				rightElem.setLineno(lineno);
				var value:AstNode = prop.getRight();
				if (value.getType() === Token.NAME) {
					var name:String = Name(value).getIdentifier();
					parent.addChildToBack(new Node(setOp, null,
												  createName(name, null, Token.BINDNAME),
												  null,
												  rightElem));
					if (variableType !== -1) {
						defineSymbol(variableType, name, true);
						destructuringNames.push(name);
					}
				} else {
					parent.addChildToBack
						(destructuringAssignmentHelper
							(variableType, value, rightElem,
								currentScriptOrFn.getNextTempName()));
				}
				empty = false;
			}
			return empty;
		}
		
		/**
		 * Parse a 'var' or 'const' statement, or a 'var' init list in a for
		 * statement.
		 * @param declType A token value: either VAR, CONST, or LET depending on
		 * context.
		 * @param pos the position where the node should start.  It's sometimes
		 * the var/const/let keyword, and other times the beginning of the first
		 * token in the first variable declaration.
		 * @return the parsed variable list
		 * @throws IOError
		 */
		private function variables(declType:int, pos:int, isStatement:Boolean):VariableDeclaration {
			var end:int;
			var pn:VariableDeclaration = new VariableDeclaration(pos);
			pn.setType(declType);
			pn.setLineno(ts.lineno);
			var varjsdocNode:Comment = getAndResetJsDoc();
			if (varjsdocNode !== null) {
				pn.setJsDocNode(varjsdocNode);
			}
			// Example:
			// var foo = {a: 1, b: 2}, bar = [3, 4];
			// var {b: s2, a: s1} = foo, x = 6, y, [s3, s4] = bar;
			for (;;) {
				var destructuring:AstNode = null;
				var name:Name = null;
				var tt:int = peekToken(), kidPos:int = ts.tokenBeg;
				end = ts.tokenEnd;
				
				if (tt === Token.LB || tt === Token.LC) {
					// Destructuring assignment, e.g., var [a,b] = ...
					destructuring = destructuringPrimaryExpr();
					end = getNodeEnd(destructuring);
					if (!(destructuring is IDestructuringForm))
						reportError("msg.bad.assign.left", "", kidPos, end - kidPos);
					markDestructuring(destructuring);
				} else {
					// Simple variable name
					mustMatchToken(Token.NAME, "msg.bad.var");
					name = createNameNode();
					name.setLineno(ts.getLineno());
					if (inUseStrictDirective) {
						var id:String = ts.getString();
						if ("eval" === id || "arguments" === id)
						{
							reportError("msg.bad.id.strict", id);
						}
					}
					defineSymbol(declType, ts.getString(), inForInit);
				}
				
				var lineno:int = ts.lineno;
				
				var jsdocNode:Comment = getAndResetJsDoc();
				
				var init:AstNode = null;
				if (matchToken(Token.ASSIGN)) {
					init = assignExpr();
					end = getNodeEnd(init);
				}
				
				var vi:VariableInitializer = new VariableInitializer(kidPos, end - kidPos);
				if (destructuring !== null) {
					if (init == null && !inForInit) {
						reportError("msg.destruct.assign.no.init");
					}
					vi.setTarget(destructuring);
				} else {
					vi.setTarget(name);
				}
				vi.setInitializer(init);
				vi.setType(declType);
				vi.setJsDocNode(jsdocNode);
				vi.setLineno(lineno);
				pn.addVariable(vi);
				
				if (!matchToken(Token.COMMA))
					break;
			}
			pn.setLength(end - pos);
			pn.setIsStatement(isStatement);
			return pn;
		}
		
		protected function defineSymbol(declType:int, name:String, ignoreNotInBlock:Boolean = false):void {
			if (name === null) {
				if (compilerEnv.isIdeMode()) {  // be robust in IDE-mode
					return;
				} else {
					codeBug();
				}
			}
			var definingScope:Scope = currentScope.getDefiningScope(name);
			var symbol:Symbol = definingScope !== null
				? definingScope.getSymbol(name)
				: null;
			var symDeclType:int = symbol !== null ? symbol.getDeclType() : -1;
			if (symbol != null
				&& (symDeclType === Token.CONST
					|| declType === Token.CONST
					|| (definingScope === currentScope && symDeclType === Token.LET)))
			{
				addError(symDeclType === Token.CONST ? "msg.const.redecl" :
					symDeclType === Token.LET ? "msg.let.redecl" :
					symDeclType === Token.VAR ? "msg.var.redecl" :
					symDeclType === Token.FUNCTION ? "msg.fn.redecl" :
					"msg.parm.redecl", name);
				return;
			}
			switch (declType) {
				case Token.LET:
					if (!ignoreNotInBlock &&
						((currentScope.getType() === Token.IF) ||
							currentScope is Loop)) {
						addError("msg.let.decl.not.in.block");
						return;
					}
					currentScope.putSymbol(new Symbol(declType, name));
					return;
					
				case Token.VAR:
				case Token.CONST:
				case Token.FUNCTION:
					if (symbol !== null) {
						if (symDeclType === Token.VAR)
							addStrictWarning("msg.var.redecl", name);
						else if (symDeclType === Token.LP) {
							addStrictWarning("msg.var.hides.arg", name);
						}
					} else {
						currentScriptOrFn.putSymbol(new Symbol(declType, name));
					}
					return;
					
				case Token.LP:
					if (symbol !== null) {
						// must be duplicate parameter. Second parameter hides the
						// first, so go ahead and add the second parameter
						addWarning("msg.dup.parms", name);
					}
					currentScriptOrFn.putSymbol(new Symbol(declType, name));
					return;
					
				default:
					codeBug();
			}
		}

		private function codeBug():void {
			throw Kit.codeBug("ts.cursor=" + ts.cursor
							  + ", ts.tokenBeg=" + ts.tokenBeg
							  + ", currentToken=" + currentToken);
		}
	}
}

import org.as3commons.collections.Map;
import org.mozilla.javascript.Parser;
import org.mozilla.javascript.ast.AstNode;
import org.mozilla.javascript.ast.FunctionNode;
import org.mozilla.javascript.ast.Jump;
import org.mozilla.javascript.ast.Loop;
import org.mozilla.javascript.ast.Scope;
import org.mozilla.javascript.ast.ScriptNode;

// helps reduce clutter in the already-large function() method
class PerFunctionVariables
{
	private var savedCurrentScriptOrFn:ScriptNode;
	private var savedCurrentScope:Scope;
	private var savedEndFlags:int;
	private var savedInForInit:Boolean;
	private var savedLabelSet:Object;
	private var savedLoopSet:Vector.<Loop>;
	private var savedLoopAndSwitchSet:Vector.<Jump>;
	
	public var parser:Parser;
	
	public function PerFunctionVariables(parser:Parser, fnNode:FunctionNode) {
		this.parser = parser;
		savedCurrentScriptOrFn = parser.currentScriptOrFn;
		parser.currentScriptOrFn = fnNode;
		
		savedCurrentScope = parser.currentScope;
		parser.currentScope = fnNode;
		
		savedLabelSet = parser.labelSet;
		parser.labelSet = null;
		
		savedLoopAndSwitchSet = parser.loopAndSwitchSet;
		parser.loopAndSwitchSet = null;
		
		savedEndFlags = parser.endFlags;
		parser.endFlags = 0;
		
		savedInForInit = parser.inForInit;
		parser.inForInit = false;
	}
	
	public function restore():void {
		parser.currentScriptOrFn = savedCurrentScriptOrFn;
		parser.currentScope = savedCurrentScope;
		parser.labelSet = savedLabelSet;
		parser.loopSet = savedLoopSet;
		parser.loopAndSwitchSet = savedLoopAndSwitchSet;
		parser.endFlags = savedEndFlags;
		parser.inForInit = savedInForInit;
	}
}

class ConditionData {
	var condition:AstNode;
	var lp:int = -1;
	var rp:int = -1;
}
