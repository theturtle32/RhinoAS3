package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * Try/catch/finally statement.  Node type is {@link Token#TRY}.<p>
	 *
	 * <pre><i>TryStatement</i> :
	 *        <b>try</b> Block Catch
	 *        <b>try</b> Block Finally
	 *        <b>try</b> Block Catch Finally
	 * <i>Catch</i> :
	 *        <b>catch</b> ( <i><b>Identifier</b></i> ) Block
	 * <i>Finally</i> :
	 *        <b>finally</b> Block</pre>
	 */
	public class TryStatement extends AstNode
	{
		private static const NO_CATCHES:Vector.<CatchClause> = new Vector.<CatchClause>(0);
		
		private var tryBlock:AstNode;
		private var catchClauses:Vector.<CatchClause>;
		private var finallyBlock:AstNode;
		private var finallyPosition:int = -1;
		
		public function TryStatement(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.TRY;
		}
		
		public function getTryBlock():AstNode {
			return tryBlock;
		}
		
		/**
		 * Sets try block.  Also sets its parent to this node.
		 * @throws IllegalArgumentException} if {@code tryBlock} is {@code null}
		 */
		public function setTryBlock(tryBlock:AstNode):void {
			assertNotNull(tryBlock);
			this.tryBlock = tryBlock;
			tryBlock.setParent(this);
		}
		
		/**
		 * Returns list of {@link CatchClause} nodes.  If there are no catch
		 * clauses, returns an immutable empty list.
		 */
		public function getCatchClauses():Vector.<CatchClause> {
			return catchClauses !== null ? catchClauses : NO_CATCHES;
		}
		
		/**
		 * Sets list of {@link CatchClause} nodes.  Also sets their parents
		 * to this node.  May be {@code null}.  Replaces any existing catch
		 * clauses for this node.
		 */
		public function setCatchClauses(catchClauses:Vector.<CatchClause>):void {
			this.catchClauses = catchClauses;
			if (catchClauses !== null) {
				for each (var cc:CatchClause in catchClauses) {
					cc.setParent(this);
				}
			}
		}
		
		/**
		 * Add a catch-clause to the end of the list, and sets its parent to
		 * this node.
		 * @throws IllegalArgumentException} if {@code clause} is {@code null}
		 */
		public function addCatchClause(clause:CatchClause):void {
			assertNotNull(clause);
			if (catchClauses === null) {
				catchClauses = new Vector.<CatchClause>();
			}
			catchClauses.push(clause);
			clause.setParent(this);
		}
		
		/**
		 * Returns finally block, or {@code null} if not present
		 */
		public function getFinallyBlock():AstNode {
			return finallyBlock;
		}
		
		/**
		 * Sets finally block, and sets its parent to this node.
		 * May be {@code null}.
		 */
		public function setFinallyBlock(finallyBlock:AstNode):void {
			this.finallyBlock = finallyBlock;
			if (finallyBlock !== null)
				finallyBlock.setParent(this);
		}
		
		/**
		 * Returns position of {@code finally} keyword, if present, or -1
		 */
		public function getFinallyPosition():int {
			return finallyPosition;
		}
		
		/**
		 * Sets position of {@code finally} keyword, if present, or -1
		 */
		public function setFinallyPosition(finallyPosition:int):void {
			this.finallyPosition = finallyPosition;
		}

		private function trim(s:String):String {
			// FIXME: Using Regexp for trim since AS3 has no trim function
			return (s === null) ? null : s.replace(/^\s+|\s+$/g, '');
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth) +
							"try " +
							trim(tryBlock.toSource(depth));
			for each (var cc:CatchClause in catchClauses) {
				sb += cc.toSource(depth);
			}
			if (finallyBlock !== null) {
				sb += (" finally " +
					   finallyBlock.toSource(depth));
			}
			return sb;
		}
		
		/**
		 * Visits this node, then the try-block, then any catch clauses,
		 * and then any finally block.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				tryBlock.visit(v);
				for each (var cc:CatchClause in catchClauses) {
					cc.visit(v);
				}
				if (finallyBlock !== null) {
					finallyBlock.visit(v);
				}
			}
		}
	}
}