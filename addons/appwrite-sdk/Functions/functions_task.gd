class_name FunctionsTask
extends Reference

signal completed(task_response)

enum Task {
    # Client
    CREATE_EXECUTION,
    LIST_EXECUTIONS,
    GET_EXECUTION,
    # Server
    CREATE,
    LIST,
    DELETE,
    GET,
    UPDATE_TAG,
    CREATE_TAG,
    LIST_TAGS,
    GET_TAG,
    DELETE_TAG
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
        Task.DELETE, Task.DELETE_TAG:
            return HTTPClient.METHOD_DELETE
        Task.UPDATE_TAG:
            return HTTPClient.METHOD_PATCH
        Task.UPDATE_FUNCTION:
            return HTTPClient.METHOD_PUT
        Task.CREATE, Task.CREATE_TAG, Task.CREATE_EXECUTION:
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
