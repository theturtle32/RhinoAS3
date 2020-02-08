package java.lang
{
	import org.unicode.utils.UnicodeCategory

	// http://docs.oracle.com/javase/7/docs/api/java/lang/Character.html
	public class Character
	{
        public static const UNASSIGNED:uint = UnicodeCategory.NOT_ASSIGNED_OTHER;
        public static const UPPERCASE_LETTER:uint = UnicodeCategory.UPPERCASE_LETTER;
        public static const LOWERCASE_LETTER:uint = UnicodeCategory.LOWERCASE_LETTER;
        public static const TITLECASE_LETTER:uint = UnicodeCategory.TITLECASE_LETTER;
        public static const MODIFIER_LETTER:uint = UnicodeCategory.MODIFIER_LETTER;
        public static const OTHER_LETTER:uint = UnicodeCategory.OTHER_LETTER;
        public static const NON_SPACING_MARK:uint = UnicodeCategory.NON_SPACING_MARK;
        public static const ENCLOSING_MARK:uint = UnicodeCategory.ENCLOSING_MARK;
        public static const COMBINING_SPACING_MARK:uint = UnicodeCategory.COMBINING_SPACING_MARK;
        public static const DECIMAL_DIGIT_NUMBER:uint = UnicodeCategory.DECIMAL_NUMBER;
        public static const LETTER_NUMBER:uint = UnicodeCategory.LETTER_NUMBER;
        public static const OTHER_NUMBER:uint = UnicodeCategory.OTHER_NUMBER;
        public static const SPACE_SEPARATOR:uint = UnicodeCategory.SPACE_SEPARATOR;
        public static const LINE_SEPARATOR:uint = UnicodeCategory.LINE_SEPARATOR;
        public static const PARAGRAPH_SEPARATOR:uint = UnicodeCategory.PARAGRAPH_SEPARATOR;
        public static const CONTROL:uint = UnicodeCategory.CONTROL_OTHER;
        public static const FORMAT:uint = UnicodeCategory.FORMAT_OTHER;
        public static const PRIVATE_USE:uint = UnicodeCategory.PRIVATE_USE_OTHER;
        public static const SURROGATE:uint = UnicodeCategory.SURROGATE_OTHER;
        public static const DASH_PUNCTUATION:uint = UnicodeCategory.DASH_PUNCTUATION;
        public static const START_PUNCTUATION:uint = UnicodeCategory.OPEN_PUNCTUATION;
        public static const END_PUNCTUATION:uint = UnicodeCategory.CLOSE_PUNCTUATION;
        public static const CONNECTOR_PUNCTUATION:uint = UnicodeCategory.CONNECTOR_PUNCTUATION;
        public static const OTHER_PUNCTUATION:uint = UnicodeCategory.OTHER_PUNCTUATION;
        public static const MATH_SYMBOL:uint = UnicodeCategory.MATH_SYMBOL;
        public static const CURRENCY_SYMBOL:uint = UnicodeCategory.CURRENCY_SYMBOL;
        public static const MODIFIER_SYMBOL:uint = UnicodeCategory.MODIFIER_SYMBOL;
        public static const OTHER_SYMBOL:uint = UnicodeCategory.OTHER_SYMBOL;
        public static const INITIAL_QUOTE_PUNCTUATION:uint = UnicodeCategory.INITIAL_QUOTE_PUNCTUATION;
        public static const FINAL_QUOTE_PUNCTUATION:uint = UnicodeCategory.FINAL_QUOTE_PUNCTUATION;
		
		public static const ERROR:uint = 0xFFFFFFFF;

		public static const JAVA_UNICODE_MAP:Object = {
			'Cn': UNASSIGNED,
			'Lu': UPPERCASE_LETTER,
			'Ll': LOWERCASE_LETTER,
			'Lt': TITLECASE_LETTER,
			'Lm': MODIFIER_LETTER,
			'Lo': OTHER_LETTER,
			'Mn': NON_SPACING_MARK,
			'Me': ENCLOSING_MARK,
			'Mc': COMBINING_SPACING_MARK,
			'Nd': DECIMAL_DIGIT_NUMBER,
			'Nl': LETTER_NUMBER,
			'No': OTHER_NUMBER,
			'Zs': SPACE_SEPARATOR,
			'Zl': LINE_SEPARATOR,
			'Zp': PARAGRAPH_SEPARATOR,
			'Cc': CONTROL,
			'Cf': FORMAT,
			'Co': PRIVATE_USE,
			'Cs': SURROGATE,
			'Pd': DASH_PUNCTUATION,
			'Ps': START_PUNCTUATION,
			'Pe': END_PUNCTUATION,
			'Pc': CONNECTOR_PUNCTUATION,
			'Po': OTHER_PUNCTUATION,
			'Sm': MATH_SYMBOL,
			'Sc': CURRENCY_SYMBOL,
			'Sk': MODIFIER_SYMBOL,
			'So': OTHER_SYMBOL,
			'Pi': INITIAL_QUOTE_PUNCTUATION,
			'Pf': FINAL_QUOTE_PUNCTUATION
		};
		
		public static const ASCII_MAP:Array = ["Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Zs","Po","Po","Po","Sc","Po","Po","Po","Ps","Pe","Po","Sm","Po","Pd","Po","Po","Nd","Nd","Nd","Nd","Nd","Nd","Nd","Nd","Nd","Nd","Po","Po","Sm","Sm","Sm","Po","Po","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Ps","Po","Pe","Sk","Pc","Sk","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ps","Sm","Pe","Sm","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Cc","Zs","Po","Sc","Sc","Sc","Sc","So","Po","Sk","So","Lo","Pi","Sm","Cf","So","Sk","So","Sm","No","No","Sk","Ll","Po","Po","Sk","No","Lo","Pf","No","No","No","Po","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Sm","Lu","Lu","Lu","Lu","Lu","Lu","Lu","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Sm","Ll","Ll","Ll","Ll","Ll","Ll","Ll","Ll"];
		public static var map:Array = [15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,12,24,24,24,26,24,24,24,21,22,24,25,24,20,24,24,9,9,9,9,9,9,9,9,9,9,24,24,25,25,25,24,24,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,21,24,22,27,23,27,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,21,25,22,25,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,12,24,26,26,26,26,28,24,27,28,5,29,25,16,28,27,28,25,11,11,27,2,24,24,27,11,5,30,11,11,11,24,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,25,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,25,2,2,2,2,2,2,2,2];
		
		
		public function Character()
		{
		}
		
		public static function isLetter(codePoint:int):Boolean {
			switch (getType(codePoint)) {
				case UPPERCASE_LETTER:
				case LOWERCASE_LETTER:
				case TITLECASE_LETTER:
				case MODIFIER_LETTER:
				case OTHER_LETTER:
					return true;
				default:
					return false;
			}
		}
		
		public static function isDigit(codePoint:int):Boolean {
			return getType(codePoint) === DECIMAL_DIGIT_NUMBER;
		}
		
		public static function getType(codePoint:int):int {
			return UnicodeCategory.fromCharCode(codePoint)
		}
		
		public static function isJavaIdentifierStart(codePoint:int):Boolean {
			if (isLetter(codePoint)) { return true; }
			var type:int = getType(codePoint);
			return type === LETTER_NUMBER || type === CURRENCY_SYMBOL || type === CONNECTOR_PUNCTUATION;
		}
		
		public static function isJavaIdentifierPart(codePoint:int):Boolean {
			switch (getType(codePoint)) {
				case UPPERCASE_LETTER:
				case LOWERCASE_LETTER:
				case TITLECASE_LETTER:
				case MODIFIER_LETTER:
				case OTHER_LETTER:
				case CURRENCY_SYMBOL:
				case CONNECTOR_PUNCTUATION:
				case DECIMAL_DIGIT_NUMBER:
				case LETTER_NUMBER:
				case COMBINING_SPACING_MARK:
					return true;
				default:
					return false;
			}
		}
		
		private static function classConstruct():Boolean {
			return true;
		}
		
		public static var classConstructed:Boolean = classConstruct();
	}
}