class_name TeamsTask
extends Reference

signal completed(task_response)

enum Task {
	# Client/Server
	CREATE,
	LIST,
	DELETE,
	GET,
	UPDATE,
	CREATE_MEMBERSHIP,
	GET_MEMBERSHIP,
	UPDATE_MEMBERSHIP_ROLES,
	UPDATE_MEMBERSHIP_STATUS,
	DELETE_MEMBERSHIP
}

var _code : int
var _method : int
var _endpoint : String
var _headers : PoolStringArray
var _payload : Dictionary

# EXPOSED VARIABLES ---------------------------------------------------------
var response : Dictionary
var error : Dictionary
# ---------------------------------------------------------------------------

var _handler : HTTPRequest

func _init(code : int, endpoint : String, headers : PoolStringArray, payload : Dictionary = {}):
	_code = code
	_endpoint = endpoint
	_headers = headers
	_payload = payload
	_method = match_code(code)

func match_code(code : int) -> int:
	match code:
		Task.DELETE, Task.DELETE_MEMBERSHIP:
			return HTTPClient.METHOD_DELETE
		Task.UPDATE_MEMBERSHIP_ROLES, Task.UPDATE_MEMBERSHIP_STATUS:
			return HTTPClient.METHOD_PATCH
		Task.UPDATE:
			return HTTPClient.METHOD_PUT
		Task.CREATE, Task.CREATE_MEMBERSHIP:
			return HTTPClient.METHOD_POST
		_:
			return HTTPClient.METHOD_GET


func push_request(httprequest : HTTPRequest) -> void:
	_handler = httprequest
	_handler.connect("request_completed", self, "_on_task_completed")
	_handler.request(_endpoint, _headers, true, _method, to_json(_payload))

func _on_task_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
	if result > 0: 
		complete({}, {result = result, message = "HTTP Request Error"})
		return
	var result_body : Dictionary = JSON.parse(body.get_string_from_utf8()).result if body.get_string_from_utf8() else {}
	match response_code:
		200, 201:
			match _code:
				_:
					complete(result_body, {})
		0, 204:
			match _code:
				_:
					complete()
		_:
			if result_body == null : result_body = {}
			complete({}, result_body)

func complete(_response : Dictionary = {}, _error : Dictionary = {}) -> void:
	response = _response
	error = _error
	emit_signal("completed", TaskResponse.new(response, error, []))
