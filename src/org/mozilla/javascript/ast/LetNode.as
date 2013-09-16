package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * AST node for let statements and expressions.
	 * Node type is {@link Token#LET} or {@link Token#LETEXPR}.<p>
	 *
	 * <pre> <i>LetStatement</i>:
	 *     <b>let</b> ( VariableDeclarationList ) Block
	 * <i>LetExpression</i>:
	 *     <b>let</b> ( VariableDeclarationList ) Expression</pre>
	 *
	 * Note that standalone let-statements with no parens or body block,
	 * such as {@code let x=6, y=7;}, are represented as a
	 * {@link VariableDeclaration} node of type {@code Token.LET},
	 * wrapped with an {@link ExpressionStatement}.<p>
	 */
	public class LetNode extends Scope
	{
		private var variables:VariableDeclaration;
		private var body:AstNode;
		private var lp:int = -1;
		private var rp:int = -1;
		
		public function LetNode(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.LETEXPR;
		}
		
		/**
		 * Returns variable list
		 */
		public function getVariables():VariableDeclaration {
			return variables;
		}
		
		/**
		 * Sets variable list.  Sets list parent to this node.
		 * @throws IllegalArgumentException if variables is {@code null}
		 */
		public function setVariables(variables:VariableDeclaration):void {
			assertNotNull(variables);
			this.variables = variables;
			variables.setParent(this);
		}
		
		/**
		 * Returns body statement or expression.  Body is {@code null} if the
		 * form of the let statement is similar to a VariableDeclaration, with no
		 * curly-brace.  (This form is used to define let-bound variables in the
		 * scope of the current block.)<p>
		 *
		 * @return the body form
		 */
		public function getBody():AstNode {
			return body;
		}
		
		/**
		 * Sets body statement or expression.  Also sets the body parent to this
		 * node.
		 * @param body the body statement or expression.  May be
		 * {@code null}.
		 */
		public function setBody(body:AstNode):void {
			this.body = body;
			if (body != null)
				body.setParent(this);
		}
		
		/**
		 * Returns left paren position, -1 if missing
		 */
		public function getLp():int {
			return lp;
		}
		
		/**
		 * Sets left paren position
		 */
		public function setLp(lp:int):void {
			this.lp = lp;
		}
		
		/**
		 * Returns right paren position, -1 if missing
		 */
		public function getRp():int {
			return rp;
		}
		
		/**
		 * Sets right paren position
		 */
		public function setRp(rp:int):void {
			this.rp = rp;
		}
		
		/**
		 * Sets both paren positions
		 */
		public function setParens(lp:int, rp:int):void {
			this.lp = lp;
			this.rp = rp;
		}
		
		override public function toSource(depth:int=0):String {
			var pad:String = makeIndent(depth);
			var sb:String = pad + "let (";
			var items:Vector.<AstNode> = new Vector.<AstNode>();
			for each (var item:VariableInitializer in variables.getVariables()) {
				items.push(item);
			}
			sb += printList(items);
			sb += ") ";
			if (body !== null) {
				sb += body.toSource(depth);
			}
			return sb;
		}
		
		/**
		 * Visits this node, the variable list, and if present, the body
		 * expression or statement.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				variables.visit(v);
				if (body !== null) {
					body.visit(v);
				}
			}
		}
	}
}