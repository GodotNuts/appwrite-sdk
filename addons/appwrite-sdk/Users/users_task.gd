class_name UsersTask
extends Reference

signal completed(task_response)

enum Task {
	# Client
	GET,
	CREATE,
	DELETE,
	GET_SESSION,
	GET_SESSIONS,
	CREATE_SESSION,
	CREATE_SESSION_OAUTH2,
	CREATE_ANONYMOUS_SESSION,
	CREATE_MAGIC_LINK,
	UPDATE_MAGIC_LINK,
	CREATE_JWT,
	DELETE_SESSION,
	DELETE_SESSIONS,
	GET_PREFS,
	GET_LOGS,
	UPDATE_NAME,
	UPDATE_EMAIL,  
	UPDATE_PASSWORD,
	UPDATE_PREFS,
	CREATE_PWD_RECOVERY,
	UPDATE_PWD_RECOVERY,
	CREATE_EMAIL_VERIFICATION,
	UPDATE_EMAIL_VERIFICATION
}

var _code : int
var _method : int
var _endpoint : String
var _headers : PoolStringArray
var _payload : Dictionary

# EXPOSED VARIABLES ---------------------------------------------------------
var response : Dictionary
var error : Dictionary
var cookies : Array
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
		Task.DELETE, Task.DELETE_SESSION, Task.DELETE_SESSIONS:
			return HTTPClient.METHOD_DELETE
		Task.UPDATE_NAME, Task.UPDATE_EMAIL, Task.UPDATE_PASSWORD, Task.UPDATE_PREFS:
			return HTTPClient.METHOD_PATCH
		Task.UPDATE_MAGIC_LINK,  Task.UPDATE_PWD_RECOVERY, Task.UPDATE_EMAIL_VERIFICATION:
			return HTTPClient.METHOD_PUT
		Task.CREATE, Task.CREATE_JWT, Task.CREATE_SESSION, Task.CREATE_SESSION_OAUTH2, Task.CREATE_ANONYMOUS_SESSION, Task.CREATE_MAGIC_LINK, Task.CREATE_PWD_RECOVERY, Task.CREATE_EMAIL_VERIFICATION:
			return HTTPClient.METHOD_POST
		_:
			return HTTPClient.METHOD_GET


func push_request(httprequest : HTTPRequest) -> void:
	_handler = httprequest
	_handler.connect("request_completed", self, "_on_task_completed")
	_handler.request(_endpoint, _headers, true, _method, to_json(_payload))

func _on_task_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
	var result_body : Dictionary = JSON.parse(body.get_string_from_utf8()).result if body.get_string_from_utf8() else {}
	match response_code:
		200:
			match _code:
				_:
					complete(result_body, {})
		201:
			match _code:
				Task.CREATE_SESSION, Task.CREATE_ANONYMOUS_SESSION:
					get_cookies(headers)
			complete(result_body, {})
		0, 204:
			match _code:
				Task.LOGOUT, Task.USER:
					complete()
		_:
			if result_body == null : result_body = {}
			complete({}, result_body)

func get_cookies(cookies : PoolStringArray) -> void:
	for cookie in cookies:
		if cookie.to_lower().begins_with("X-Fallback-Cookies:".to_lower()):
			self.cookies.append(cookie)
			return

func complete(_response : Dictionary = {}, _error : Dictionary = {}) -> void:
	response = _response
	error = _error
	emit_signal("completed", TaskResponse.new(response, error, cookies))

		
