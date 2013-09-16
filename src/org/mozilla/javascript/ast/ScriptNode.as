package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.NodeIterator;
	import org.mozilla.javascript.Token;
	import org.mozilla.javascript.exception.IllegalStateError;

	public class ScriptNode extends Scope
	{
		private var encodedSourceStart:int = -1;
		private var encodedSourceEnd:int = -1;
		private var sourceName:String;
		private var encodedSource:String;
		private var endLineno:int = -1;
		
		private var functions:Vector.<FunctionNode>;
		private var regexps:Vector.<RegExpLiteral>;
		private const EMPTY_LIST:Vector.<FunctionNode> = new Vector.<FunctionNode>();
		
		private var symbols:Vector.<Symbol> = new Vector.<Symbol>(4);
		private var paramCount:int = 0;
		private var variableNames:Vector.<String>;
		private var isConsts:Vector.<Boolean>;
		
		private var compilerData:Object;
		private var tempNumber:int = 0;
		
		public function ScriptNode(pos:int = -1)
		{
			super(pos);
			top = this;
			type = Token.SCRIPT;
		}
		
		/**
		 * Returns the URI, path or descriptive text indicating the origin
		 * of this script's source code.
		 */
		public function getSourceName():String {
			return sourceName;
		}
		
		/**
		 * Sets the URI, path or descriptive text indicating the origin
		 * of this script's source code.
		 */
		public function setSourceName(sourceName:String):void {
			this.sourceName = sourceName;
		}
		
		/**
		 * Returns the start offset of the encoded source.
		 * Only valid if {@link #getEncodedSource} returns non-{@code null}.
		 */
		public function getEncodedSourceStart():int {
			return encodedSourceStart;
		}
		
		/**
		 * Used by code generator.
		 * @see #getEncodedSource
		 */
		public function setEncodedSourceStart(start:int):void {
			this.encodedSourceStart = start;
		}

		/**
		 * Returns the end offset of the encoded source.
		 * Only valid if {@link #getEncodedSource} returns non-{@code null}.
		 */
		public function getEncodedSourceEnd():int {
			return encodedSourceEnd;
		}
		
		/**
		 * Used by code generator.
		 * @see #getEncodedSource
		 */
		public function setEncodedSourceEnd(end:int):void {
			this.encodedSourceEnd = end;
		}
		
		/**
		 * Used by code generator.
		 * @see #getEncodedSource
		 */
		public function setEncodedSourceBounds(start:int, end:int):void {
			this.encodedSourceStart = start;
			this.encodedSourceEnd = end;
		}
		
		/**
		 * Used by the code generator.
		 * @see #getEncodedSource
		 */
		public function setEncodedSource(encodedSource:String):void {
			this.encodedSource = encodedSource;
		}
		
		/**
		 * Returns a canonical version of the source for this script or function,
		 * for use in implementing the {@code Object.toSource} method of
		 * JavaScript objects.  This source encoding is only recorded during code
		 * generation.  It must be passed back to
		 * {@link org.mozilla.javascript.Decompiler#decompile} to construct the
		 * human-readable source string.<p>
		 *
		 * Given a parsed AST, you can always convert it to source code using the
		 * {@link AstNode#toSource} method, although it's not guaranteed to produce
		 * exactly the same results as {@code Object.toSource} with respect to
		 * formatting, parenthesization and other details.
		 *
		 * @return the encoded source, or {@code null} if it was not recorded.
		 */
		public function getEncodedSource():String {
			return encodedSource;
		}
		
		public function getBaseLineno():int {
			return lineno;
		}
		
		/**
		 * Sets base (starting) line number for this script or function.
		 * This is a one-time operation, and throws an exception if the
		 * line number has already been set.
		 */
		public function setBaseLineno(lineno:int):void {
			if (lineno < 0 || this.lineno >= 0) codeBug();
			this.lineno = lineno;
		}
		
		public function getEndLineno():int {
			return endLineno;
		}
		
		public function setEndLineno(lineno:int):void {
			// One time action
			if (lineno < 0 || endLineno >= 0) codeBug();
			endLineno = lineno;
		}
		
		public function getFunctionCount():int {
			return functions === null ? 0 : functions.length;
		}
		
		public function getFunctionNode(i:int):FunctionNode {
			return functions[i];
		}
		
		public function getFunctions():Vector.<FunctionNode> {
			return functions === null ? EMPTY_LIST : functions;
		}
		
		/**
		 * Adds a {@link FunctionNode} to the functions table for codegen.
		 * Does not set the parent of the node.
		 * @return the index of the function within its parent
		 */
		public function addFunction(fnNode:FunctionNode):int {
			if (fnNode === null) codeBug();
			if (functions === null)
				functions = new Vector.<FunctionNode>();
			functions.push(fnNode);
			return functions.length - 1;
		}
		
		public function getRegexpCount():int {
			return regexps === null ? 0 : regexps.length;
		}
		
		public function getRegexpString(index:int):String {
			return regexps[index].getValue();
		}
		
		public function getRegexpFlags(index:int):String {
			return regexps[index].getFlags();
		}
		
		/**
		 * Called by IRFactory to add a RegExp to the regexp table.
		 */
		public function addRegExp(re:RegExpLiteral):void {
			if (re === null) codeBug();
			if (regexps === null)
				regexps = new Vector.<RegExpLiteral>();
			regexps.push(re);
			re.putIntProp(REGEXP_PROP, regexps.length - 1);
		}
		
		public function getIndexForNameNode(nameNode:Node):int {
			if (variableNames === null) codeBug();
			var node:Scope = nameNode.getScope();
			var symbol:Symbol = node === null
				? null
				: node.getSymbol(Name(nameNode).getIdentifier());
			return (symbol === null) ? -1 : symbol.getIndex();
		}
		
		public function getParamOrVarName(index:int):String {
			if (variableNames === null) codeBug();
			return variableNames[index];
		}
		
		public function getParamCount():int {
			return paramCount;
		}
		
		public function getParamAndVarCount():int {
			if (variableNames === null) codeBug();
			return symbols.length;
		}
		
		public function getParamAndVarNames():Vector.<String> {
			if (variableNames === null) codeBug();
			return variableNames;
		}
		
		public function getParamAndVarConst():Vector.<Boolean> {
			if (variableNames === null) codeBug();
			return isConsts;
		}
		
		public function addSymbol(symbol:Symbol):void {
			if (variableNames !== null) codeBug();
			if (symbol.getDeclType() === Token.LP) {
				paramCount ++;
			}
			symbols.push(symbol);
		}
		
		public function getSymbols():Vector.<Symbol> {
			return symbols;
		}
		
		public function setSymbols(symbols:Vector.<Symbol>):void {
			this.symbols = symbols;
		}
		
		/**
		 * Assign every symbol a unique integer index. Generate arrays of variable
		 * names and constness that can be indexed by those indices.
		 *
		 * @param flattenAllTables if true, flatten all symbol tables,
		 * included nested block scope symbol tables. If false, just flatten the
		 * script's or function's symbol table.
		 */
		public function flattenSymbolTable(flattenAllTables:Boolean):void {
			if (!flattenAllTables) {
				var newSymbols:Vector.<Symbol> = new Vector.<Symbol>();
				if (this.symbolTable !== null) {
					// Just replace "symbols" with the symbols in this object's
					// symbol table. Can't just work from symbolTable map since
					// we need to retain duplicate parameters.
					for (var i:int = 0; i < symbols.length; i++) {
						var symbol:Symbol = symbols[i];
						if (symbol.getContainingTable() === this) {
							newSymbols.push(symbol);
						}
					}
				}
				symbols = newSymbols;
			}
			variableNames = new Vector.<String>(symbols.length);
			isConsts = new Vector.<Boolean>(symbols.length);
			for (i=0; i < symbols.length; i++) {
				symbol = symbols[i];
				variableNames[i] = symbol.getName();
				isConsts[i] = symbol.getDeclType() === Token.CONST;
				symbol.setIndex(i);
			}
		}
		
		public function getCompilerData():Object {
			return compilerData;
		}
		
		public function setCompilerData(data:Object):void {
			assertNotNull(data);
			// Can only call once
			if (compilerData !== null)
				throw new IllegalStateError();
			compilerData = data;
		}
		
		public function getNextTempName():String {
			return "$" + tempNumber++;
		}
		
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				var i:NodeIterator = iterator();
				while (i.hasNext()) {
					var kid:Node = i.next();
					AstNode(kid).visit(v);
				}
			}
		}
	}
}