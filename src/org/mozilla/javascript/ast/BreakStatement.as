package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.Token;
	
	/**
	 * A break statement.  Node type is {@link Token#BREAK}.<p>
	 *
	 * <pre><i>BreakStatement</i> :
	 *   <b>break</b> [<i>no LineTerminator here</i>] [Identifier] ;</pre>
	 */
	public class BreakStatement extends Jump
	{
		private var breakLabel:Name;
		private var target:AstNode;
		
		public function BreakStatement(pos:int=-1, len:int=-1)
		{
			// can't call super (Jump) for historical reasons
			position = pos;
			length = len;
			type = Token.BREAK;
		}
		
		/**
		 * Returns the intended label of this break statement
		 * @return the break label.  {@code null} if the source code did
		 * not specify a specific break label via "break &lt;target&gt;".
		 */
		public function getBreakLabel():Name {
			return breakLabel;
		}
		
		/**
		 * Sets the intended label of this break statement, e.g.  'foo'
		 * in "break foo". Also sets the parent of the label to this node.
		 * @param label the break label, or {@code null} if the statement is
		 * just the "break" keyword by itself.
		 */
		public function setBreakLabel(label:Name):void {
			breakLabel = label;
			if (label !== null)
				label.setParent(this);
		}
		
		/**
		 * Returns the statement to break to
		 * @return the break target.  Only {@code null} if the source
		 * code has an error in it.
		 */
		public function getBreakTarget():AstNode {
			return target;
		}
		
		/**
		 * Sets the statement to break to.
		 * @param target the statement to break to
		 * @throws IllegalArgumentException if target is {@code null}
		 */
		public function setBreakTarget(target:Jump):void {
			assertNotNull(target);
			this.target = target;
			setJumpStatement(target);
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth) +
							"break";
			if (breakLabel !== null) {
				sb += (" " + breakLabel.toSource(0));
			}
			sb += ";\n";
			return sb;
		}
		
		/**
		 * Visits this node, then visits the break label if non-{@code null}.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this) && breakLabel !== null) {
				breakLabel.visit(v);
			}
		}
	}
}