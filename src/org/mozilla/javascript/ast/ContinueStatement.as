package org.mozilla.javascript.ast
{
	/**
	 * A continue statement.
	 * Node type is {@link Token#CONTINUE}.<p>
	 *
	 * <pre><i>ContinueStatement</i> :
	 *   <b>continue</b> [<i>no LineTerminator here</i>] [Identifier] ;</pre>
	 */
	public class ContinueStatement extends Jump
	{
		private var label:Name;
		private var target:Loop;
		
		public function ContinueStatement(pos:int=-1, len:int=-1, label:Name=null)
		{
			// can't call super (Jump) for historical reasons
			position = pos;
			length = len;
			if (label !== null)
				setLabel(label);
		}
		
		/**
		 * Returns continue target
		 */
		public function getTarget():Loop {
			return target;
		}
		
		/**
		 * Sets continue target.  Does NOT set the parent of the target node:
		 * the target node is an ancestor of this node.
		 * @param target continue target
		 * @throws IllegalArgumentException if target is {@code null}
		 */
		public function setTarget(target:Loop):void {
			assertNotNull(target);
			this.target = target;
			setJumpStatement(target);
		}
		
		/**
		 * Returns the intended label of this continue statement
		 * @return the continue label.  Will be {@code null} if the statement
		 * consisted only of the keyword "continue".
		 */
		public function getLabel():Name {
			return label;
		}
		
		/**
		 * Sets the intended label of this continue statement.
		 * Only applies if the statement was of the form "continue &lt;label&gt;".
		 * @param label the continue label, or {@code null} if not present.
		 */
		public function setLabel(label:Name):void {
			this.label = label;
			if (label !== null)
				label.setParent(this);
		}
		
		override public function toSource(depth:int=0):String {
			var sb:String = makeIndent(depth) +
							"continue";
			if (label !== null) {
				sb += (" " + label.toSource(0));
			}
			sb += ";\n";
			return sb;
		}
		
		/**
		 * Visits this node, then visits the label if non-{@code null}.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this) && label !== null) {
				label.visit(v);
			}
		}
	}
}