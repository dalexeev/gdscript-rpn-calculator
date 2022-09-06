extends Reference

const _PRIORITIES = {
	'**': 4,
	'u+': 3,
	'u-': 3,
	'*':  2,
	'/':  2,
	'+':  1,
	'-':  1,
}

var _re := RegEx.new()

func _init() -> void:
	var _e := _re.compile('\\d+(?:\\.\\d+)?|\\+|-|\\*\\*?|/|\\(|\\)|(.)')

func evalute(string: String) -> float:
	return _evalute_rpn(_to_rpn(_tokenize(string)))

func _tokenize(string: String) -> Array:
	var a := []
	for m in _re.search_all(string.replace(' ', '')):
		if m.strings[1]:
			return []
		a.append(m.strings[0])
	return a

func _to_rpn(tokens: Array) -> Array:
	var rpn := []
	var op_stack := []
	var prev_is_operand := false
	
	for token in tokens:
		if token.is_valid_float():
			prev_is_operand = true
			rpn.append(token.to_float())
			continue
		
		if (token in ['+', '-']) && !prev_is_operand:
			token = 'u' + token
		
		prev_is_operand = false
		
		if token == '(':
			op_stack.append('(')
			continue
		
		if token == ')':
			prev_is_operand = true
			var pos := op_stack.find_last('(')
			if pos == -1:
				return []
			var i := op_stack.size() - 1
			while i > pos:
				rpn.append(op_stack.pop_back())
				i -= 1
			op_stack.pop_back()
			continue
		
		while true:
			if op_stack.empty() || op_stack.back() == '(':
				break
			var pd = _PRIORITIES[op_stack.back()] - _PRIORITIES[token]
			if pd < 0:
				break
			if pd == 0 && token in ['**', 'u+', 'u-']: # Not left-associative.
				break
			# TODO: `2**-3`.
			rpn.append(op_stack.pop_back())
		
		op_stack.append(token)
	
	if op_stack.has('('):
		return []
	op_stack.invert()
	rpn.append_array(op_stack)
	
	return rpn

func _evalute_rpn(rpn: Array) -> float:
	var operands := []
	
	for x in rpn:
		var a := 0.0
		var b := 0.0
		
		if x in ['u+', 'u-']:
			if operands.empty():
				return NAN
			a = operands.pop_back()
		elif x in ['**', '*', '/', '+', '-']:
			if operands.size() < 2:
				return NAN
			b = operands.pop_back()
			a = operands.pop_back()
		
		match x:
			'**': operands.append(pow(a, b))
			'u+': operands.append(+a)
			'u-': operands.append(-a)
			'*':  operands.append(a * b)
			'/':  operands.append(a / b if b != 0.0 else NAN)
			'+':  operands.append(a + b)
			'-':  operands.append(a - b)
			_:    operands.append(x)
	
	return operands[0] if operands.size() == 1 else NAN
