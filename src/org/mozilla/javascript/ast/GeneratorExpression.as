package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	public class GeneratorExpression extends Scope
	{
		private var result:AstNode;
		private var loops:Vector.<GeneratorExpressionLoop> = new Vector.<GeneratorExpressionLoop>();
		private var filter:AstNode;
		private var ifPosition:int = -1;
		private var lp:int = -1;
		private var rp:int = -1;
		
		public function GeneratorExpression(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.GENEXPR;
		}
		
		/**
		 * Returns result expression node (just after opening bracket)
		 */
		public function getResult():AstNode {
			return result;
		}
		
		/**
		 * Sets result expression, and sets its parent to this node.
		 * @throws IllegalArgumentException if result is {@code null}
		 */
		public function setResult(result:AstNode):void {
			assertNotNull(result);
			this.result = result;
			result.setParent(this);
		}
		
		/**
		 * Returns loop list
		 */
		public function getLoops():Vector.<GeneratorExpressionLoop> {
			return loops;
		}
		
		/**
		 * Sets loop list
		 * @throws IllegalArgumentException if loops is {@code null}
		 */
		public function setLoops(loops:Vector.<GeneratorExpressionLoop>):void {
			this.loops = loops;
			if (this.loops !== null) {
				for each (var l:GeneratorExpressionLoop in this.loops) {
					l.setParent(this);
				}
			}
		}
		
		/**
		 * Adds a child loop node, and sets its parent to this node.
		 * @throws IllegalArgumentException if acl is {@code null}
		 */
		public function addLoop(acl:GeneratorExpressionLoop):void {
			assertNotNull(acl);
			loops.push(acl);
			acl.setParent(this);
		}
		
		/**
		 * Returns filter expression, or {@code null} if not present
		 */
		public function getFilter():AstNode {
			return filter;
		}
		
		/**
		 * Sets filter expression, and sets its parent to this node.
		 * Can be {@code null}.
		 */
		public function setFilter(filter:AstNode):void {
			this.filter = filter;
			if (filter !== null)
				filter.setParent(this);
		}
		
		/**
		 * Returns position of 'if' keyword, -1 if not present
		 */
		public function getIfPosition():int {
			return ifPosition;
		}
		
		/**
		 * Sets position of 'if' keyword
		 */
		public function setIfPosition(ifPosition:int):void {
			this.ifPosition = ifPosition;
		}
		
		/**
		 * Returns filter left paren position, or -1 if no filter
		 */
		public function getFilterLp():int {
			return lp;
		}
		
		/**
		 * Sets filter left paren position, or -1 if no filter
		 */
		public function setFilterLp(lp:int):void {
			this.lp = lp;
		}
		
		/**
		 * Returns filter right paren position, or -1 if no filter
		 */
		public function getFilterRp():int {
			return rp;
		}
		
		/**
		 * Sets filter right paren position, or -1 if no filter
		 */
		public function setFilterRp(rp:int):void {
			this.rp = rp;
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = "(" + result.toSource(0);
			for each (var loop:GeneratorExpressionLoop in loops) {
				sb += loop.toSource(0);
			}
			if (filter !== null) {
				sb += (" if (" + filter.toSource(0) + ")");
			}
			sb += ")";
			return sb;
		}
		
		/**
		 * Visits this node, the result expression, the loops, and the optional
		 * filter.
		 */
		override public function visit(v:NodeVisitor):void {
			if (!v.visit(this)) {
				return;
			}
			result.visit(v);
			for each (var loop:ArrayComprehensionLoop in loops) {
				loop.visit(v);
			}
			if (filter !== null) {
				filter.visit(v);
			}
		}
	}
}