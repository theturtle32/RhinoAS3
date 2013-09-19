package org.mozilla.javascript
{
	public class EvaluatorException extends RhinoException
	{
		public function EvaluatorException(detail:String=null, sourceName:String=null, lineNumber:int=-1, lineSource:String=null, columnNumber:int=-1)
		{
			super(detail);
		}
	}
}