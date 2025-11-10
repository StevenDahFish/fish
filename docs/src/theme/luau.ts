(function (Prism) {
	var OPENING_LONG_BRACKET = /\[=*\[/;
	var CLOSING_LONG_BRACKET = /\]=*\]/;

	var BUILT_INS = [
		'_G',
		'_VERSION',
		'__index',
		'__newindex',
		'__mode',
		'__call',
		'__metatable',
		'__tostring',
		'__len',
		'__gc',
		'__add',
		'__sub',
		'__mul',
		'__div',
		'__mod',
		'__pow',
		'__concat',
		'__unm',
		'__eq',
		'__lt',
		'__le',
		'assert',
		'__idiv',
		'__iter',
		'newproxy',
		'rawlen',
		'collectgarbage',
		'error',
		'getfenv',
		'getmetatable',
		'ipairs',
		'loadstring',
		'module',
		'next',
		'pairs',
		'pcall',
		'print',
		'rawequal',
		'rawget',
		'rawset',
		'require',
		'select',
		'setfenv',
		'setmetatable',
		'tonumber',
		'tostring',
		'export',
		'type',
		'typeof',
		'unpack',
		'xpcall',
		'self',
		'coroutine',
		'resume',
		'yield',
		'status',
		'wrap',
		'create',
		'running',
		'debug',
		'traceback',
		'math',
		'log',
		'max',
		'acos',
		'huge',
		'ldexp',
		'pi',
		'cos',
		'tanh',
		'pow',
		'deg',
		'tan',
		'cosh',
		'sinh',
		'random',
		'randomseed',
		'frexp',
		'ceil',
		'floor',
		'rad',
		'abs',
		'sqrt',
		'modf',
		'asin',
		'min',
		'mod',
		'fmod',
		'log10',
		'atan2',
		'exp',
		'sin',
		'atan',
		'os',
		'date',
		'difftime',
		'time',
		'clock',
		'string',
		'sub',
		'upper',
		'len',
		'rep',
		'find',
		'match',
		'char',
		'gmatch',
		'reverse',
		'byte',
		'format',
		'gsub',
		'lower',
		'table',
		'insert',
		'getn',
		'foreachi',
		'maxn',
		'foreach',
		'concat',
		'sort',
		'remove'
	];

	var BUILT_IN_PATTERN = new RegExp('\\b(?:' + BUILT_INS.join('|') + ')\\b');

	Prism.languages.luau = {
		'comment': [
			{
				// long comments: --[=[ ... ]=]
				pattern: new RegExp(
					'--' + OPENING_LONG_BRACKET.source + '[\\s\\S]*?' + CLOSING_LONG_BRACKET.source
				),
				greedy: true
			},
			{
				// line comments: -- ... (but not long bracket)
				pattern: /--(?!\[=*\[).*/,
				greedy: true
			}
		],

		'string': [
			{
				// backtick strings (with simple interpolation)
				pattern: /`(?:\\[\s\S]|[^\\`])*`/,
				greedy: true,
				inside: {
					'string-interpolation': {
						pattern: /`\{[\s\S]*?}`/,
						inside: {
							'punctuation': /`{|\}`/
							// you can set another `inside` here to highlight the expression
						}
					}
				}
			},
			{
				// normal Lua/Luau strings
				pattern: /(["'])(?:\\[\s\S]|(?!\1)[^\\])*\1/,
				greedy: true
			}
		],

		'number': /\b0x[\da-fA-F]+|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b/,

		'keyword': /\b(?:and|break|do|else|elseif|end|for|if|in|local|not|or|repeat|return|then|until|while)\b/,

		'boolean': /\b(?:true|false)\b/,

		'nil': {
			pattern: /\bnil\b/,
			alias: 'constant'
		},

		// built-in globals, libraries, methods
		'builtin': {
			pattern: BUILT_IN_PATTERN
		},

		// function definitions: function Foo.Bar:baz(...)
		'function-definition': {
			pattern: /\bfunction\b\s+[_a-zA-Z]\w*(?:\.[_a-zA-Z]\w*)*(?::[_a-zA-Z]\w*)?(?=\s*\()/,
			inside: {
				'keyword': /\bfunction\b/,

				// last identifier before the "(" is the function name
				'function': {
					pattern: /[_a-zA-Z]\w*$/,
				},

				'punctuation': /[.:]/,
			}
		},

		// function calls: Foo.Bar:baz(...)
		'function-call': {
			pattern: /\b[_a-zA-Z]\w*(?:\.[_a-zA-Z]\w*)*(?::[_a-zA-Z]\w*)?(?=\s*\()/,
			greedy: false,
			inside: {
				'function': {
					pattern: /[_a-zA-Z]\w*$/,
				},
				'punctuation': /[.:]/,
			}
		},

		'punctuation': /[{}()[\],:]/,
		'operator': /[-+*/%^#=<>~]|\.{2,3}/
	};
}(Prism));
