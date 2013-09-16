package org.mozilla.javascript.ast
{
	import org.mozilla.javascript.Token;

	/**
	 * Abstract base type for components that comprise an {@link XmlLiteral}
	 * object. Node type is {@link Token#XML}.<p>
	 */
	public class XmlFragment extends AstNode
	{
		public function XmlFragment(pos:int=-1, len:int=-1)
		{
			super(pos, len);
			type = Token.XML;
		}
	}
}