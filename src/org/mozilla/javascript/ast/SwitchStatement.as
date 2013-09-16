package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;
	
	/**
	 * Switch statement AST node type.
	 * Node type is {@link Token#SWITCH}.<p>
	 *
	 * <pre><i>SwitchStatement</i> :
	 *        <b>switch</b> ( Expression ) CaseBlock
	 * <i>CaseBlock</i> :
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
	public class SwitchStatement extends Jump
	{
		private static const NO_CASES:Vector.<SwitchCase> = new Vector.<SwitchCase>(0);
		
		private var expression:AstNode;
		private var cases:Vector.<SwitchCase>;
		private var lp:int = -1;
		private var rp:int = -1;
		
		public function SwitchStatement(pos:int=-1, len:int=-1)
		{
			// can't call super (Jump) for historical reasons
			type = Token.SWITCH;
			position = pos;
			length = len;
		}
		
		/**
		 * Returns the switch discriminant expression
		 */
		public function getExpression():AstNode {
			return expression;
		}
		
		/**
		 * Sets the switch discriminant expression, and sets its parent
		 * to this node.
		 * @throws IllegalArgumentException} if expression is {@code null}
		 */
		public function setExpression(expression:AstNode):void {
			assertNotNull(expression);
			this.expression = expression;
			expression.setParent(this);
		}
		
		/**
		 * Returns case statement list.  If there are no cases,
		 * returns an immutable empty list.
		 */
		public function getCases():Vector.<SwitchCase> {
			return cases != null ? cases : NO_CASES;
		}
		
		/**
		 * Sets case statement list, and sets the parent of each child
		 * case to this node.
		 * @param cases list, which may be {@code null} to remove all the cases
		 */
		public function setCases(cases:Vector.<SwitchCase>):void {
			this.cases = cases;
			if (this.cases !== null) {
				for each (var sc:SwitchCase in this.cases) {
					assertNotNull(sc);
					sc.setParent(this);
				}
			}
		}
		
		/**
		 * Adds a switch case statement to the end of the list.
		 * @throws IllegalArgumentException} if switchCase is {@code null}
		 */
		public function addCase(switchCase:SwitchCase):void {
			assertNotNull(switchCase);
			if (cases == null) {
				cases = new Vector.<SwitchCase>();
			}
			cases.push(switchCase);
			switchCase.setParent(this);
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
			var sb:String = pad + "switch (" +
							expression.toSource(0) +
							") {\n";
			for each (var sc:SwitchCase in cases) {
				sb += sc.toSource(depth + 1);
			}
			sb += (pad + "}\n");
			return sb;
		}
		
		/**
		 * Visits this node, then the switch-expression, then the cases
		 * in lexical order.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				expression.visit(v);
				for each (var sc:SwitchCase in getCases()) {
					sc.visit(v);
				}
			}
		}
	}
}