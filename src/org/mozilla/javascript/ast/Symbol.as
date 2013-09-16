package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.Token;

	public class Symbol
	{
		// One of Token.FUNCTION, Token.LP (for parameters), Token.VAR,
		// Token.LET, or Token.CONST
		private var declType:int;
		private var index:int = -1;
		private var name:String;
		private var node:Node;
		private var containingTable:Scope;
		
		public function Symbol(declType:int = -1, name:String = null)
		{
			if (name !== null) {
				setName(name);
			}
			if (declType !== -1) {
				setDeclType(declType);
			}
		}
		
		/**
		 * Returns symbol declaration type
		 */
		public function getDeclType():int {
			return declType;
		}
		
		/**
		 * Sets symbol declaration type
		 */
		public function setDeclType(declType:int):void {
			if (!(declType == Token.FUNCTION
				|| declType == Token.LP
				|| declType == Token.VAR
				|| declType == Token.LET
				|| declType == Token.CONST))
				throw new ArgumentError("Invalid declType: " + declType);
			this.declType = declType;
		}
		
		/**
		 * Returns symbol name
		 */
		public function getName():String {
			return name;
		}
		
		/**
		 * Sets symbol name
		 */
		public function setName(name:String):void {
			this.name = name;
		}
		
		/**
		 * Returns the node associated with this identifier
		 */
		public function getNode():Node {
			return node;
		}
		
		/**
		 * Returns symbol's index in its scope
		 */
		public function getIndex():int {
			return index;
		}
		
		/**
		 * Sets symbol's index in its scope
		 */
		public function setIndex(index:int):void {
			this.index = index;
		}
		
		/**
		 * Sets the node associated with this identifier
		 */
		public function setNode(node:Node):void {
			this.node = node;
		}
		
		/**
		 * Returns the Scope in which this symbol is entered
		 */
		public function getContainingTable():Scope {
			return containingTable;
		}
		
		/**
		 * Sets this symbol's Scope
		 */
		public function setContainingTable(containingTable:Scope):void {
			this.containingTable = containingTable;
		}
		
		public function getDeclTypeName():String {
			return Token.typeToName(declType);
		}
		
		public function toString():String {
			var result:String =
				"Symbol (" +
				getDeclTypeName() +
				") name=" +
				name;
			if (node !== null) {
				result += " line =";
				result += node.getLineno();
			}
			return result;
		}
	}
}