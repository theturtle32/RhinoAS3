package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	public class Name extends AstNode
	{
		private var identifier:String;
		private var scope:Scope;
		
		public function Name(pos:int=-1, len:int=-1, name:String = null)
		{
			super(pos, len);
			type = Token.NAME;
			if (name !== null) {
				setIdentifier(name);
				if (len === -1) {
					setLength(name.length)
				}
			}
		}
		
		/**
		 * Returns the node's identifier
		 */
		public function getIdentifier():String {
			return identifier;
		}
		
		/**
		 * Sets the node's identifier
		 * @throws ArgumentError if identifier is null
		 */
		public function setIdentifier(identifier:String):void {
			assertNotNull(identifier);
			this.identifier = identifier;
			setLength(identifier.length);
		}
		
		/**
		 * Set the {@link Scope} associated with this node.  This method does not
		 * set the scope's ast-node field to this node.  The field exists only
		 * for temporary storage by the code generator.  Not every name has an
		 * associated scope - typically only function and variable names (but not
		 * property names) are registered in a scope.
		 *
		 * @param s the scope.  Can be null.  Doesn't set any fields in the
		 * scope.
		 */
		override public function setScope(s:Scope):void {
			scope = s;
		}
		
		/**
		 * Return the {@link Scope} associated with this node.  This is
		 * <em>only</em> used for (and set by) the code generator, so it will always
		 * be null in frontend AST-processing code.  Use {@link #getDefiningScope}
		 * to find the lexical {@code Scope} in which this {@code Name} is defined,
		 * if any.
		 */
		override public function getScope():Scope {
			return scope;
		}
		
		/**
		 * Returns the {@link Scope} in which this {@code Name} is defined.
		 * @return the scope in which this name is defined, or {@code null}
		 * if it's not defined in the current lexical scope chain
		 */
		public function getDefiningScope():Scope {
			var enclosing:Scope = getEnclosingScope();
			var name:String = getIdentifier();
			return enclosing === null ? null : enclosing.getDefiningScope(name);
		}
		
		/**
		 * Return true if this node is known to be defined as a symbol in a
		 * lexical scope other than the top-level (global) scope.
		 *
		 * @return {@code true} if this name appears as local variable, a let-bound
		 * variable not in the global scope, a function parameter, a loop
		 * variable, the property named in a {@link PropertyGet}, or in any other
		 * context where the node is known not to resolve to the global scope.
		 * Returns {@code false} if the node is defined in the top-level scope
		 * (i.e., its defining scope is an {@link AstRoot} object), or if its
		 * name is not defined as a symbol in the symbol table, in which case it
		 * may be an external or built-in name (or just an error of some sort.)
		 */
		public function isLocalName():Boolean {
			var scope:Scope = getDefiningScope();
			return scope !== null && scope.getParentScope() !== null;
		}
		
		/**
		 * Return the length of this node's identifier, to let you pretend
		 * it's a {@link String}.  Don't confuse this method with the
		 * {@link AstNode#getLength} method, which returns the range of
		 * characters that this node overlaps in the source input.
		 */
		public function get length():int {
			return identifier === null ? 0 : identifier.length;
		}
		
		override public function toSource(depth:int=0):String {
			return makeIndent(depth) + (identifier === null ? "<null>" : identifier);
		}
		
		/**
		 * Visits this node.  There are no children to visit.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}
	}
}