package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	public class NumberLiteral extends AstNode
	{
		private var value:String;
		private var number:Number;
		
		/**
		 * Constructor.  Sets the length to the length of the {@code value} string.
		 */
		public function NumberLiteral(pos:int=-1, len:int=-1, value:String=null, number:Number=NaN)
		{
			super(pos, len);
			type = Token.NUMBER;
			if (value !== null) {
				setValue(value);
				setLength(value.length);
				if (!(isNaN(number))) {
					setDouble(number);
				}
			}
			else if (!(isNaN(number))) {
				setDouble(number);
				setValue(number.toString());
			}
		}
		
		/**
		 * Returns the node's string value (the original source token)
		 */
		public function getValue():String {
			return value;
		}
		
		/**
		 * Sets the node's value
		 * @throws IllegalArgumentException} if value is {@code null}
		 */
		public function setValue(value:String):void {
			assertNotNull(value);
			this.value = value;
		}
		
		/**
		 * Gets the {@code double} value.
		 */
		public function getNumber():Number {
			return number;
		}

		/**
		 * Sets the node's {@code double} value.
		 */
		public function setNumber(value:Number):void {
			number = value;
		}
		
		override public function toSource(depth:int = 0):String {
			return makeIndent(depth) + (value === null ? "<null>" : value);
		}
		
		/**
		 * Visits this node.  There are no children to visit.
		 */
		override public function visit(v:NodeVisitor):void {
			v.visit(this);
		}
	}
}