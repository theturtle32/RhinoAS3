package org.mozilla.javascript.exception
{
	public class ParserError extends Error
	{
		public static var serialVersionUID:String = "5882582646773765630L"; // ?! WTF is this?
		
		public function ParserError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}