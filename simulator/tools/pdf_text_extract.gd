extends SceneTree

# Extrator rudimentar de texto de PDF (streams FlateDecode + operadores
# Tj/TJ), suficiente para procurar palavras-chave nas Normas ABNT.
# Uso: godot --headless --path simulator --script res://tools/pdf_text_extract.gd -- <pdf> <saida_txt>

func _initialize():
	var args = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("uso: -- <pdf> <saida_txt>")
		quit()
		return
	extract(args[0], args[1])
	quit()

func extract(pdf_path, out_path):
	var bytes = FileAccess.get_file_as_bytes(pdf_path)
	if bytes.is_empty():
		push_error("não li o pdf: " + pdf_path)
		return
	var marker = "stream".to_utf8_buffer()
	var endmarker = "endstream".to_utf8_buffer()
	var all_text = ""
	var pos = 0
	var extracted = 0
	while true:
		pos = find_bytes(bytes, marker, pos)
		if pos < 0:
			break
		var data_start = pos + marker.size()
		# pula \r\n ou \n após "stream"
		while data_start < bytes.size() and (bytes[data_start] == 13 or bytes[data_start] == 10):
			data_start += 1
		var data_end = find_bytes(bytes, endmarker, data_start)
		if data_end < 0:
			break
		var chunk = bytes.slice(data_start, data_end)
		var inflated = chunk.decompress_dynamic(16 * 1024 * 1024, FileAccess.COMPRESSION_DEFLATE)
		if inflated.size() > 0:
			extracted += 1
			all_text += inflated.get_string_from_ascii()
		pos = data_end + endmarker.size()
	print("streams extraídos: ", extracted)

	# pega strings entre parênteses seguidas de Tj/TJ (texto mostrado)
	var regex = RegEx.new()
	regex.compile("\\(((?:[^()\\\\]|\\\\.)*)\\)\\s*T[jJ]")
	var shown = ""
	for m in regex.search_all(all_text):
		shown += m.get_string(1) + " "
	# também captura arrays TJ: [(a)-12(b)] TJ
	var regex2 = RegEx.new()
	regex2.compile("\\[((?:[^\\[\\]\\\\]|\\\\.)*)\\]\\s*TJ")
	for m in regex2.search_all(all_text):
		var inner = m.get_string(1)
		var regex3 = RegEx.new()
		regex3.compile("\\(((?:[^()\\\\]|\\\\.)*)\\)")
		for m2 in regex3.search_all(inner):
			shown += m2.get_string(1)
		shown += " "

	var f = FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(shown)
	f.close()
	print("texto visível: ", shown.length(), " chars -> ", out_path)

# Busca uma sequência de bytes a partir de "from" (PackedByteArray não
# tem find de subarray).
func find_bytes(haystack, needle, from):
	var n = needle.size()
	var limit = haystack.size() - n
	var first = needle[0]
	var i = from
	while i <= limit:
		if haystack[i] == first:
			var match_found = true
			for j in range(1, n):
				if haystack[i + j] != needle[j]:
					match_found = false
					break
			if match_found:
				return i
		i += 1
	return -1
