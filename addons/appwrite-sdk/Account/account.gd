class_name AppwriteAccount
extends Node

class Providers:
    const APPLE := "apple"
    const BITBUCKET := "bitbucket"
    const DISCORD := "discord"
    const FACEBOOK := "facebook"
    const GITHUB := "github"
    const GITLAB := "gitlab"
    const GOOGLE := "google"
    const TWITTER := "twitter"

var _cookies : PoolStringArray = []

signal task_response(task_response)

signal got(user)
signal created(user)
signal got_prefs(prefs)
signal got_logs(logs)
signal got_session(session)
signal got_sessions(sessions)
signal session_created(session)

func _init():
    pass

func _ready():
    pass


# function builder
func __match_resource(type: int, param: String = "") -> String:
    var resource : String = ""
    match type:
        AccountTask.Task.GET, AccountTask.Task.CREATE, AccountTask.Task.DELETE: resource = "/account"
        AccountTask.Task.GET_SESSIONS: resource = "/account/sessions"
        AccountTask.Task.CREATE_SESSION_OAUTH2: resource = "/account/sessions/oauth2/"+param
        AccountTask.Task.CREATE_MAGIC_URL, AccountTask.Task.UPDATE_MAGIC_URL: resource = "/account/sessions/magic-url"
        AccountTask.Task.CREATE_ANONYMOUS_SESSION: resource = "/account/sessions/anonymous"
        AccountTask.Task.CREATE_JWT: resource = "/account/jwt"
        AccountTask.Task.GET_LOGS: resource = "/account/logs"
        AccountTask.Task.GET_SESSION, AccountTask.Task.DELETE_SESSION: resource = "/account/sessions/"+param
        AccountTask.Task.UPDATE_NAME: resource = "/account/name"
        AccountTask.Task.UPDATE_PASSWORD: resource = "/account/password"
        AccountTask.Task.UPDATE_EMAIL: resource = "/account/email"
        AccountTask.Task.UPDATE_PREFS, AccountTask.Task.GET_PREFS: resource = "/account/prefs"
        AccountTask.Task.GET_SESSIONS, AccountTask.Task.DELETE_SESSIONS: resource = "/account/sessions"
        AccountTask.Task.CREATE_PWD_RECOVERY, AccountTask.Task.UPDATE_PWD_RECOVERY: resource = "/account/recovery"
        AccountTask.Task.CREATE_EMAIL_VERIFICATION, AccountTask.Task.UPDATE_EMAIL_VERIFICATION: resource = "/account/verification"
    return resource


# POST base function
func __post(type: int, payload: Dictionary = {}) -> AccountTask:
    var account_task : AccountTask = AccountTask.new(
        type,
        get_parent().endpoint + __match_resource(type), 
        get_parent()._get_headers(),
        payload
        )
    _process_task(account_task)
    return account_task

# GET base function
func __get(type : int, param: String = "") -> AccountTask:
    var account_task : AccountTask = AccountTask.new(
        type,
        get_parent().endpoint + __match_resource(type, param), 
        get_parent()._get_headers()
    )
    _process_task(account_task)
    return account_task 




# -------- CLIENT API

func get_logged() -> AccountTask :
    return __get(AccountTask.Task.GET)

func create(email: String, password: String, _name: String = "") -> AccountTask:
    var payload : Dictionary = { "email":email, "password":password }
    if _name != "" : payload["name"] = _name
    return __post(AccountTask.Task.CREATE, payload)

func delete() -> AccountTask:
    return null

func update_email() -> AccountTask:
    return null

func create_jwt() -> AccountTask:
    return null

func get_logs() -> AccountTask:
    return __get(AccountTask.Task.GET_LOGS)

func update_name() -> AccountTask:
    return null

func update_password() -> AccountTask:
    return null

func get_prefs() -> AccountTask:
    return __get(AccountTask.Task.GET_PREFS)

func update_prefs() -> AccountTask:
    return null

func create_recovery(email: String, url: String) -> AccountTask:
    var payload: Dictionary = { email = email, url = url }
    return _post(AccountTask.Task.CREATE_PWD_RECOVERY, payload)

func update_recover() -> AccountTask:
    return null

func get_sessions() -> AccountTask:
    return __get(AccountTask.Task.GET_SESSIONS)

func create_session(email: String, password: String) -> AccountTask:
    var payload : Dictionary = { "email":email, "password":password }
    return _post(AccountTask.Task.CREATE_SESSION, payload)

func delete_sessions() -> AccountTask:
    return null

func create_anonymous_session() -> AccountTask:
    return null

func create_magic_url_session() -> AccountTask:
    return null

func update_magic_url_session() -> AccountTask:
    return null

func create_oauth2_session() -> AccountTask:
    return null

func get_session(session_id: String) -> AccountTask:
    return __get(AccountTask.Task.GET_SESSION, session_id)

func delete_session() -> AccountTask:
    return null

func create_verification() -> AccountTask:
    return null

func update_verification() -> AccountTask:
    return null




# ------- SERVER API


# Process a specific task
func _process_task(task : AccountTask, _fake : bool = false) -> void:
    task.connect("completed", self, "_on_task_completed")
    if _fake:
        yield(get_tree().create_timer(0.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task : AccountTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        var _signal : String = ""
        match task._code:
            AccountTask.Task.GET:
                _signal = "got"
            AccountTask.Task.GET_PREFS:
                _signal = "got_prefs"
            AccountTask.Task.GET_LOGS:
                _signal = "got_logs"
            AccountTask.Task.GET_SESSIONS:
                _signal = "got_sessions"
            AccountTask.Task.GET_SESSION:
                _signal = "got_session"
            AccountTask.Task.CREATE:
                _signal = "created"
            AccountTask.Task.CREATE_SESSION:
                _fetch_cookies(task)
                _signal = "session_created"
            _:
                _signal = "task_response"
        emit_signal(_signal, task.response)
    else:
        emit_signal("error", task.error)


func _fetch_cookies(task : AccountTask) -> void:
    var cookies : Array
    for cookie in task.cookies:
        cookies.append("Cookie:%s=%s"%[cookie.keys()[0], cookie.values()[0]])
    _cookies = PoolStringArray(cookies)
    get_parent().cookies += _cookies
