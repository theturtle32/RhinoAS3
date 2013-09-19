package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.NodeIterator;
	import org.mozilla.javascript.Token;

	public class Scope extends Jump
	{
		// Use LinkedHashMap so that the iteration order is the insertion order
		protected var symbolTable:Object;
		protected var parentScope:Scope;
		protected var top:ScriptNode;	// current script or function scop
		
		private var childScopes:Vector.<Scope>;
		
		public function Scope(pos:int = -1, len:int = -1)
		{
			this.type = Token.BLOCK;
			if (pos !== -1) {
				this.position = pos;
			}
			if (len !== -1) {
				this.length = len;
			}
		}
		
		public function getParentScope():Scope {
			return parentScope;
		}
		
		/**
		 * Sets parent scope
		 */
		public function setParentScope(parentScope:Scope):void {
			this.parentScope = parentScope;
			this.top = parentScope === null ? ScriptNode(this) : parentScope.top;
		}
		
		/**
		 * Used only for code generation.
		 */
		public function clearParentScope():void {
			this.parentScope = null;
		}
		
		/**
		 * Return a list of the scopes whose parent is this scope.
		 * @return the list of scopes we enclose, or {@code null} if none
		 */
		public function getChildScopes():Vector.<Scope> {
			return childScopes;
		}
		
		/**
		 * Add a scope to our list of child scopes.
		 * Sets the child's parent scope to this scope.
		 * @throws IllegalStateException if the child's parent scope is
		 * non-{@code null}
		 */
		public function addChildScope(child:Scope):void {
			if (childScopes === null) {
				childScopes = new Vector.<Scope>();
			}
			childScopes.push(child);
			child.setParentScope(this);
		}
		
		/**
		 * Used by the parser; not intended for typical use.
		 * Changes the parent-scope links for this scope's child scopes
		 * to the specified new scope.  Copies symbols from this scope
		 * into new scope.
		 *
		 * @param newScope the scope that will replace this one on the
		 *        scope stack.
		 */
		public function replaceWith(newScope:Scope):void {
			if (childScopes !== null) {
				for each (var kid:Scope in childScopes) {
					newScope.addChildScope(kid);  // sets kid's parent
				}
				childScopes = null;
			}
			if (symbolTable !== null && getObjectKeyCount(symbolTable) !== 0) {
				joinScopes(this, newScope);
			}
		}
		
		/**
		 * Returns current script or function scope
		 */
		public function getTop():ScriptNode {
			return top;
		}
		
		/**
		 * Sets top current script or function scope
		 */
		public function setTop(top:ScriptNode):void {
			this.top = top;
		}
		
		/**
		 * Creates a new scope node, moving symbol table information
		 * from "scope" to the new node, and making "scope" a nested
		 * scope contained by the new node.
		 * Useful for injecting a new scope in a scope chain.
		 */
		public static function splitScope(scope:Scope):Scope {
			var result:Scope = new Scope(scope.getType());
			result.symbolTable = scope.symbolTable;
			scope.symbolTable = null;
			result.parent = scope.parent;
			result.setParentScope(scope.getParentScope());
			result.setParentScope(result);
			scope.parent = result;
			result.top = scope.top;
			return result;
		}
		
		/**
		 * Copies all symbols from source scope to dest scope.
		 */
		public static function joinScopes(source:Scope, dest:Scope):void {
			var src:Object = source.ensureSymbolTable();
			var dst:Object = dest.ensureSymbolTable();
			var disjoint:Boolean = true;
			for (var key:String in src) {
				if (key in dst) {
					disjoint = false;
				}
				var sym:Symbol = Symbol(src[key])
				sym.setContainingTable(dest);
				dst[key] = sym;
			}
			if (disjoint) {
				codeBug();
			}
		}

		
		private function getObjectKeyCount(obj:Object):int {
			var count:int = 0;
			for (var s:* in obj) {
				count ++;
			}
			return count;
		}
		
		/**
		 * Returns the scope in which this name is defined
		 * @param name the symbol to look up
		 * @return this {@link Scope}, one of its parent scopes, or {@code null} if
		 * the name is not defined any this scope chain
		 */
		public function getDefiningScope(name:String):Scope {
			for (var s:Scope = this; s !== null; s = s.parentScope) {
				var symbolTable:Object = s.getSymbolTable();
        // We prepend "?" so that we can use reserved attribute names
        // like "hasOwnProperty"
				if (symbolTable !== null && ("?" + name) in symbolTable) {
					return s;
				}
			}
			return null;
		}
		
		/**
		 * Looks up a symbol in this scope.
		 * @param name the symbol name
		 * @return the Symbol, or {@code null} if not found
		 */
		public function getSymbol(name:String):Symbol {
      // We prepend "?" so that we can use reserved attribute names
      // like "hasOwnProperty"
      return symbolTable === null ? null : symbolTable["?" + name];
		}
		
		/**
		 * Enters a symbol into this scope.
		 */
		public function putSymbol(symbol:Symbol):void {
			if (symbol.getName() === null)
				throw new ArgumentError("null symbol name");
			ensureSymbolTable();
      // We prepend "?" so that we can use reserved attribute names
      // like "hasOwnProperty"
			symbolTable["?" + symbol.getName()] = symbol;
			symbol.setContainingTable(this);
			top.addSymbol(symbol);
		}
			
		/**
		 * Returns the symbol table for this scope.
		 * @return the symbol table.  May be {@code null}.
		 */
		public function getSymbolTable():Object {
			return symbolTable;
		}
		
		/**
		 * Sets the symbol table for this scope.  May be {@code null}.
		 */
		public function setSymbolTable(table:Object):void {
			symbolTable = table;
		}
		
		public function ensureSymbolTable():Object {
			if (symbolTable === null) {
				symbolTable = {};
			}
			return symbolTable;
		}
		
		/**
		 * Returns a copy of the child list, with each child cast to an
		 * {@link AstNode}.
		 * @throws ClassCastException if any non-{@code AstNode} objects are
		 * in the child list, e.g. if this method is called after the code
		 * generator begins the tree transformation.
		 */
		public function getStatements():Vector.<AstNode> {
			var stmts:Vector.<AstNode> = new Vector.<AstNode>();
			var n:Node = getFirstChild();
			while (n !== null)  {
				stmts.push(AstNode(n));
				n = n.getNext();
			}
			return stmts;
		}
		
		override public function toSource(depth:int = 0):String {
			var sb:String = "";
			sb += makeIndent(depth);
			sb += "{\n";
			var i:NodeIterator = iterator();
			while (i.hasNext()) {
				var kid:Node = i.next();
				sb += AstNode(kid).toSource(depth+1);
			}
			sb += (makeIndent(depth) + "}\n");
			return sb;
		}
		
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				var i:NodeIterator = iterator();
				while (i.hasNext()) {
					AstNode(i.next()).visit(v);
				}
			}
		}
	}
}