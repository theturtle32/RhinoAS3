package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;
	import org.mozilla.javascript.ast.AstNode;
	
	public class LabeledStatement extends AstNode
	{
		private var labels:Vector.<Label> = new Vector.<Label>();
		private var statement:AstNode;
		
		public function LabeledStatement(pos:int = -1, len:int = -1)
		{
			super(pos, len);
			type = Token.EXPR_VOID;
		}
		
		public function getLabels():Vector.<Label> {
			return labels;
		}
		
		public function setLabels(labels:Vector.<Label>):void {
			assertNotNull(labels);
			this.labels = labels;
		}
		
		public function addLabel(label:Label):void {
			assertNotNull(label);
			labels.push(label);
			label.setParent(this);
		}
		
		public function getStatement():AstNode {
			return statement;
		}
		
		/**
		 * Returns label with specified name from the label list for
		 * this labeled statement.  Returns {@code null} if there is no
		 * label with that name in the list.
		 */
		public function getLabelByName(name:String):Label {
			for each (var label:Label in labels) {
				if (label.getName() === name) {
					return label;
				}
			}
			return null;
		}
		
		/**
		 * Sets the labeled statement, and sets its parent to this node.
		 * @throws IllegalArgumentException if {@code statement} is {@code null}
		 */
		public function setStatement(statement:AstNode):void {
			assertNotNull(statement);
			this.statement = statement;
			statement.setParent(this);
		}
		
		public function getFirstLabel():Label {
			return labels[0];
		}
		
		override public function hasSideEffects():Boolean {
			// just to avoid the default case for EXPR_VOID in AstNode
			return true;
		}
		
		override public function toSource(depth:int = 0):String {
			var sb:String = "";
			for each (var label:Label in labels) {
				sb += label.toSource(depth);
			}
			sb += statement.toSource(depth + 1);
			return sb;
		}
		
		/**
		 * Visits this node, then each label in the label-list, and finally the
		 * statement.
		 */
		override public function visit(v:NodeVisitor):void {
			if (v.visit(this)) {
				for each (var label:Label in labels) {
					label.visit(v);
				}
				statement.visit(v);
			}
		}
	}
}