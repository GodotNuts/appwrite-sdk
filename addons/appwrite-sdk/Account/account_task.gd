class_name AccountTask
extends Reference

signal completed(task)

enum Task {
    CREATE,
    CREATE_SESSION
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
        Task.CREATE, Task.CREATE_SESSION:
            return HTTPClient.METHOD_POST
        _:
            return HTTPClient.METHOD_GET
#        Task.UPDATE:
#            return HTTPClient.METHOD_PUT
#        _, Task.USER:
#            return HTTPClient.METHOD_GET

func push_request(httprequest : HTTPRequest) -> void:
    _handler = httprequest
    _handler.connect("request_completed", self, "_on_task_completed")
    _handler.request(_endpoint, _headers, true, _method, to_json(_payload))

func _on_task_completed(result : int, response_code : int, headers : PoolStringArray, body : PoolByteArray) -> void:
    var result_body : Dictionary = JSON.parse(body.get_string_from_utf8()).result if body.get_string_from_utf8() else {}
    match response_code:
        201:
            match _code:
                Task.CREATE:
                    complete(result_body, {})
                Task.CREATE_SESSION:
                    get_auth_cookie(headers)
                    complete(result_body, {})
                _:
                    complete()
        0, 204:
            match _code:
                Task.LOGOUT, Task.USER:
                    complete()
        _:
            if result_body == null : result_body = {}
            complete({}, result_body)

func get_auth_cookie(cookies : PoolStringArray) -> void:
    for cookie in cookies:
        if cookie.begins_with("X-Fallback-Cookies:"):
            self.cookies.append(parse_json(cookie.lstrip("X-Fallback-Cookies: ")))

func complete(_response : Dictionary = {}, _error : Dictionary = {}) -> void:
    response = _response
    error = _error
    emit_signal("completed", self)

        
