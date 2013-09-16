package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.Token;

	/**
	 * A list of one or more var, const or let declarations.
	 * Node type is {@link Token#VAR}, {@link Token#CONST} or
	 * {@link Token#LET}.<p>
	 *
	 * If the node is for {@code var} or {@code const}, the node position
	 * is the beginning of the {@code var} or {@code const} keyword.
	 * For {@code let} declarations, the node position coincides with the
	 * first {@link VariableInitializer} child.<p>
	 *
	 * A standalone variable declaration in a statement context returns {@code true}
	 * from its {@link #isStatement()} method.
	 */
	public class VariableDeclaration extends AstNode
	{
		private var variables:Vector.<VariableInitializer> = new Vector.<VariableInitializer>();
		private var _isStatement:Boolean;
		
		public function VariableDeclaration(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.VAR;
		}
		
		/**
		 * Returns variable list.  Never {@code null}.
		 */
		public function getVariables():Vector.<VariableInitializer> {
			return variables;
		}
		
		/**
		 * Sets variable list
		 * @throws IllegalArgumentException if variables list is {@code null}
		 */
		public function setVariables(variables:Vector.<VariableInitializer>):void {
			assertNotNull(variables);
			this.variables = variables;
			for each (var vi:VariableInitializer in this.variables) {
				vi.setParent(this);
			}
		}
		
		/**
		 * Adds a variable initializer node to the child list.
		 * Sets initializer node's parent to this node.
		 * @throws IllegalArgumentException if v is {@code null}
		 */
		public function addVariable(v:VariableInitializer):void {
			assertNotNull(v);
			variables.push(v);
			v.setParent(this);
		}
		
		/**
		 * Sets the node type and returns this node.
		 * @throws IllegalArgumentException if {@code declType} is invalid
		 */
		override public function setType(type:int):Node {
			if (type !== Token.VAR
				&& type !== Token.CONST
				&& type !== Token.LET)
				throw new ArgumentError("invalid decl type: " + type);
			return super.setType(type);
		}
		
		/**
		 * Returns true if this is a {@code var} (not
		 * {@code const} or {@code let}) declaration.
		 * @return true if {@code declType} is {@link Token#VAR}
		 */
		public function isVar():Boolean {
			return type === Token.VAR;
		}
		
		/**
		 * Returns true if this is a {@link Token#CONST} declaration.
		 */
		public function isConst():Boolean {
			return type === Token.CONST;
		}
		
		/**
		 * Returns true if this is a {@link Token#LET} declaration.
		 */
		public function isLet():Boolean {
			return type === Token.LET;
		}
		
		/**
		 * Returns true if this node represents a statement.
		 */
		public function isStatement():Boolean {
			return _isStatement;
		}
		
		/**
		 * Set or unset the statement flag.
		 */
		public function setIsStatement(isStatement:Boolean):void {
			_isStatement = isStatement;
		}
		
		private function declTypeName():String {
			return Token.typeToName(type).toLowerCase();
		}
		
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			sb += declTypeName();
			sb += " ";
			var items:Vector.<AstNode> = new Vector.<AstNode>();
			for each (var item:VariableInitializer in variables) {
				items.push(item);
			}
			sb += printList(items);
			if (isStatement()) {
				sb += ";\n";
			}
			return sb;
		}
		
		/**
		 * Visits this node, then each {@link VariableInitializer} child.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				for each (var variable:AstNode in variables) {
					variable.visit(v);
				}
			}
		}
	}
}