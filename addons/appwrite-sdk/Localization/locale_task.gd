class_name LocaleTask
extends Reference

signal completed(task_response)

enum Task {
	# Client/Server
	GET,
	GET_COUNTRIES,
	GET_COUNTRIES_EU,
	GET_COUNTRIES_PHONES,
	GET_CONTINENTS,
	GET_LANGUAGES,
	GET_CURRENCIES
}

var _code : int
var _method : int
var _endpoint : String
var _headers : PoolStringArray

# EXPOSED VARIABLES ---------------------------------------------------------
var response : Dictionary
var error : Dictionary
# ---------------------------------------------------------------------------

var _handler : HTTPRequest

func _init(code : int, endpoint : String, headers : PoolStringArray):
	_code = code
	_endpoint = endpoint
	_headers = headers
	_method = match_code(code)


func match_code(code : int) -> int:
	match code:
		_: return HTTPClient.METHOD_GET

func push_request(httprequest : HTTPRequest) -> void:
	_handler = httprequest
	httprequest.connect("request_completed", self, "_on_task_completed")
	httprequest.request(_endpoint, _headers, true, _method)

func _on_task_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
	var result_body = JSON.parse(body.get_string_from_utf8()).result if body.get_string_from_utf8() else {}
	if response_code in [200, 201, 204]:
		complete(result_body)
	else:
		complete({}, result_body)

func complete(_result: Dictionary,  _error : Dictionary = {}) -> void:
	response = _result
	error = _error
	if _handler : _handler.queue_free()
	emit_signal("completed", TaskResponse.new(response, error))
