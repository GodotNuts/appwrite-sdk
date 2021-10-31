class_name StorageTask
extends Reference

signal completed(task_response)

enum Task {
	CREATE_FILE,
	LIST_FILES,
	GET_FILE,
	GET_FILE_VIEW,
	GET_FILE_PREVIEW,
	UPDATE_FILE,
	DELETE_FILE,
	DOWNLOAD_FILE,
}

var _code : int
var _method : int
var _endpoint : String
var _headers : PoolStringArray
var _payload : Dictionary
var _bytepayload : PoolByteArray

# EXPOSED VARIABLES ---------------------------------------------------------
var response : Dictionary
var error : Dictionary
# ---------------------------------------------------------------------------

var _handler : HTTPRequest

func _init(code : int, endpoint : String, headers : PoolStringArray,  payload : Dictionary = {}, bytepayload: PoolByteArray = []):
	_code = code
	_endpoint = endpoint
	_headers = headers
	_payload = payload
	_bytepayload = bytepayload
	_method = match_code(code)

func match_code(code : int) -> int:
	match code:
		Task.CREATE_FILE:
			return HTTPClient.METHOD_POST
		Task.DELETE_FILE:
			return HTTPClient.METHOD_DELETE
		Task.UPDATE_FILE: 
			return HTTPClient.METHOD_PUT
		Task.UPDATE_FILE:
			return HTTPClient.METHOD_PATCH
		_: return HTTPClient.METHOD_GET

func push_request(httprequest : HTTPRequest) -> void:
	_handler = httprequest
	httprequest.connect("request_completed", self, "_on_task_completed")
	if not _bytepayload.empty():
		var err = httprequest.request(_endpoint, _headers, true, _method, _bytepayload.get_string_from_ascii())
	else:
		httprequest.request(_endpoint, _headers, true, _method, to_json(_payload))

func _on_task_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
	var validate: String = validate_json(body.get_string_from_utf8())
	var result_body: Dictionary = parse_json(body.get_string_from_utf8()) if not validate else {error = validate}
	if response_code in [200, 201, 204]:
		if _code in [Task.DOWNLOAD_FILE, Task.GET_FILE_VIEW, Task.GET_FILE_PREVIEW]:
			var file_name: String = get_header_value("Content-Disposition: ", headers)
			result_body = { 
			file_name = file_name.split('"')[1] if file_name!="" else "",
			file_binary = body,
			file_text = body.get_string_from_utf8(),
			file_type = get_header_value("Content-Type: ", headers)
			}
		complete(result_body)
	else:
		complete({}, result_body)

func complete(_result: Dictionary = response,  _error : Dictionary = error) -> void:
	response = _result
	error = _error
	if _handler : _handler.queue_free()
	emit_signal("completed", TaskResponse.new(response, error))


func get_header_value(_header: String, headers : PoolStringArray) -> String:
	for header in headers:
		if header.begins_with(_header):
			return header.trim_prefix(_header)
	return ""
