package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Node;
	import org.mozilla.javascript.Token;
	import org.mozilla.javascript.exception.UnsupportedOperationError;

	public class Jump extends AstNode
	{
		public var target:Node;
		private var target2:Node;
		private var jumpNode:Jump;
		
		public function Jump(type:int = -1, child:Node = null, lineno:int = -1)
		{
			if (type !== -1) {
				this.type = type;
			}
			if (child !== null) {
				addChildToBack(child);
			}
			if (lineno !== -1) {
				setLineno(lineno);
			}
		}
		
		public function getJumpStatement():Jump {
			if (type !== Token.BREAK && type !== Token.CONTINUE) codeBug();
			return jumpNode;
		}
		
		public function setJumpStatement(jumpStatement:Jump):void {
			if (type !== Token.BREAK && type !== Token.CONTINUE) codeBug();
			if (jumpStatement === null) codeBug();
			if (this.jumpNode !== null) codeBug(); //only once
			this.jumpNode = jumpStatement; 
		}
		
		public function getDefault():Node {
			if (type !== Token.SWITCH) codeBug();
			return target2;
		}

		public function setDefault(defaultTarget:Node):void {
			if (type !== Token.SWITCH) codeBug();
			if (defaultTarget.getType() !== Token.TARGET) codeBug();
			if (target2 !== null) codeBug(); //only once
			target2 = defaultTarget;
		}
		
		public function getFinally():Node {
			if (type !== Token.TRY) codeBug();
			return target2;
		}
		
		public function setFinally(finallyTarget:Node):void {
			if (type !== Token.TRY) codeBug();
			if (finallyTarget.getType() !== Token.TARGET) codeBug();
			if (target2 !== null) codeBug(); //only once
			target2 = finallyTarget;
		}
		
		public function getLoop():Jump {
			if (type !== Token.LABEL) codeBug();
			return jumpNode;
		}
		
		public function setLoop(loop:Jump):void {
			if (type !== Token.LABEL) codeBug();
			if (loop === null) codeBug();
			if (jumpNode !== null) codeBug(); //only once
			jumpNode = loop;
		}
		
		public function getContinue():Node {
			if (type !== Token.LOOP) codeBug();
			return target2;
		}
		
		public function setContinue(continueTarget:Node):void {
			if (type !== Token.LOOP) codeBug();
			if (continueTarget.getType() !== Token.TARGET) codeBug();
			if (target2 !== null) codeBug(); //only once
			target2 = continueTarget;
		}
		
		override public function visit(visitor:NodeVisitor):void {
			throw new UnsupportedOperationError(this.toString());
		}
		
		override public function toSource(depth:int = 0):String {
			throw new UnsupportedOperationError(this.toString());
		}
	}
}