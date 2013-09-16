package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * Switch-case AST node type.  The switch case is always part of a
	 * switch statement.
	 * Node type is {@link Token#CASE}.<p>
	 *
	 * <pre><i>CaseBlock</i> :
	 *        { [CaseClauses] }
	 *        { [CaseClauses] DefaultClause [CaseClauses] }
	 * <i>CaseClauses</i> :
	 *        CaseClause
	 *        CaseClauses CaseClause
	 * <i>CaseClause</i> :
	 *        <b>case</b> Expression : [StatementList]
	 * <i>DefaultClause</i> :
	 *        <b>default</b> : [StatementList]</pre>
	 */
	public class SwitchCase extends AstNode
	{
		private var expression:AstNode;
		private var statements:Vector.<AstNode>;
		
		public function SwitchCase(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.CASE;
		}
		
		/**
		 * Returns the case expression, {@code null} for default case
		 */
		public function getExpression():AstNode {
			return expression;
		}
		
		/**
		 * Sets the case expression, {@code null} for default case.
		 * Note that for empty fall-through cases, they still have
		 * a case expression.  In {@code case 0: case 1: break;} the
		 * first case has an {@code expression} that is a
		 * {@link NumberLiteral} with value {@code 0}.
		 */
		public function setExpression(expression:AstNode):void {
			this.expression = expression;
			if (expression != null)
				expression.setParent(this);
		}
		
		/**
		 * Return true if this is a default case.
		 * @return true if {@link #getExpression} would return {@code null}
		 */
		public function isDefault():Boolean {
			return expression === null;
		}
		
		/**
		 * Returns statement list, which may be {@code null}.
		 */
		public function getStatements():Vector.<AstNode> {
			return statements;
		}
		
		/**
		 * Sets statement list.  May be {@code null}.  Replaces any existing
		 * statements.  Each element in the list has its parent set to this node.
		 */
		public function setStatements(statements:Vector.<AstNode>):void {
			if (statements === null) {
				this.statements = null;
			}
			else {
				this.statements = new Vector.<AstNode>();
				for each (var s:AstNode in statements) {
					addStatement(s);
				}
			}
		}
		
		/**
		 * Adds a statement to the end of the statement list.
		 * Sets the parent of the new statement to this node, updates
		 * its start offset to be relative to this node, and sets the
		 * length of this node to include the new child.
		 *
		 * @param statement a child statement
		 * @throws ArgumentError if statement is {@code null}
		 */
		public function addStatement(statement:AstNode):void {
			assertNotNull(statement);
			if (statements === null) {
				statements = new Vector.<AstNode>();
			}
			var end:int = statement.getPosition() + statement.getLength();
			this.setLength(end - this.getPosition());
			statements.push(statement);
			statement.setParent(this);
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth);
			if (expression === null) {
				sb += "default:\n";
			} else {
				sb += ("case " + expression.toSource(0) + ":\n");
			}
			if (statements !== null) {
				for each (var s:AstNode in statements) {
					sb += s.toSource(depth+1);
				}
			}
			return sb;
		}
		
		/**
		 * Visits this node, then the case expression if present, then
		 * each statement (if any are specified).
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				if (expression != null) {
					expression.visit(v);
				}
				if (statements != null) {
					for each (var s:AstNode in statements) {
						s.visit(v);
					}
				}
			}
		}
	}
}