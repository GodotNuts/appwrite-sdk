class_name AppwriteAccount
extends Node

const _REST_BASE: String = "/account"

class Providers:
    const APPLE := "apple"
    const AMAZON := "amazon"
    const BITBUCKET := "bitbucket"
    const DISCORD := "discord"
    const FACEBOOK := "facebook"
    const GITHUB := "github"
    const GITLAB := "gitlab"
    const GOOGLE := "google"
    const TWITTER := "twitter"

var _cookies : PoolStringArray = []

signal task_response(task_response)
signal success(response)
signal got(user)
signal created(user)
signal got_prefs(prefs)
signal got_logs(logs)
signal got_session(session)
signal got_sessions(sessions)
signal session_created(session)
signal anonymous_session_created(session)
signal email_confirmation_created()
signal jwt_created()
signal magic_link_created()
signal pwd_recovery_created()
signal oauth2_session_created(session)
signal deleted()
signal session_deleted()
signal sessions_deleted()
signal email_updated()
signal email_confirmation_updated()
signal magic_link_updated()
signal name_updated()
signal password_updated()
signal prefs_updated()
signal pwd_recovery_updated()

func _init():
    pass

func _ready():
    pass


# function builder
func __match_resource(type: int, param: String = "") -> String:
    var resource : String = ""
    match type:
        AccountTask.Task.GET, AccountTask.Task.CREATE, AccountTask.Task.DELETE: resource = _REST_BASE
        AccountTask.Task.GET_SESSIONS, AccountTask.Task.CREATE_SESSION: resource = _REST_BASE+"/sessions"
        AccountTask.Task.CREATE_SESSION_OAUTH2: resource = _REST_BASE+"/sessions/oauth2/"+param
        AccountTask.Task.CREATE_MAGIC_LINK, AccountTask.Task.UPDATE_MAGIC_LINK: resource = _REST_BASE+"/sessions/magic-url"
        AccountTask.Task.CREATE_ANONYMOUS_SESSION: resource = _REST_BASE+"/sessions/anonymous"
        AccountTask.Task.CREATE_JWT: resource = _REST_BASE+"/jwt"
        AccountTask.Task.GET_LOGS: resource = _REST_BASE+"/logs"
        AccountTask.Task.GET_SESSION, AccountTask.Task.DELETE_SESSION: resource = _REST_BASE+"/sessions/"+param
        AccountTask.Task.UPDATE_NAME: resource = _REST_BASE+"/name"
        AccountTask.Task.UPDATE_PASSWORD: resource = _REST_BASE+"/password"
        AccountTask.Task.UPDATE_EMAIL: resource = _REST_BASE+"/email"
        AccountTask.Task.UPDATE_PREFS, AccountTask.Task.GET_PREFS: resource = _REST_BASE+"/prefs"
        AccountTask.Task.GET_SESSIONS, AccountTask.Task.DELETE_SESSIONS: resource = _REST_BASE+"/sessions"
        AccountTask.Task.CREATE_PWD_RECOVERY, AccountTask.Task.UPDATE_PWD_RECOVERY: resource = _REST_BASE+"/recovery"
        AccountTask.Task.CREATE_EMAIL_VERIFICATION, AccountTask.Task.UPDATE_EMAIL_VERIFICATION: resource = _REST_BASE+"/verification"
    return resource




# GET, DELETE base function
func __get(type : int, param: String = "") -> AccountTask:
    var account_task : AccountTask = AccountTask.new(
        type,
        get_parent().endpoint + __match_resource(type, param), 
        get_parent()._get_headers()
    )
    _process_task(account_task)
    return account_task 

# POST, PUT, PATCH base function
func __post(type: int, payload: Dictionary = {}, param: String = "") -> AccountTask:
    var account_task : AccountTask = AccountTask.new(
        type,
        get_parent().endpoint + __match_resource(type, param), 
        get_parent()._get_headers(),
        payload
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
    return __get(AccountTask.Task.DELETE)

func get_logs() -> AccountTask:
    return __get(AccountTask.Task.GET_LOGS)

func update_name(name: String) -> AccountTask:
    return __post(AccountTask.Task.UPDATE_NAME, { name = name })

func update_password(password: String, old_password: String) -> AccountTask:
    return __post(AccountTask.Task.UPDATE_PWD, { password = password, oldPassword = old_password })

func update_email(email: String, password: String) -> AccountTask:
    return __post(AccountTask.Task.UPDATE_EMAIL, { email = email, password = password })

func get_prefs() -> AccountTask:
    return __get(AccountTask.Task.GET_PREFS)

func update_prefs(prefs: Dictionary) -> AccountTask:
    return __post(AccountTask.Task.UPDATE_PREFS, { prefs = prefs })

func create_recovery(email: String, url: String) -> AccountTask:
    return __post(AccountTask.Task.CREATE_PWD_RECOVERY, { email = email, url = url })

func update_recovery(user_id: String, secret: String, password: String, password_again: String) -> AccountTask:
    return __post(AccountTask.Task.UPDATE_PWD_RECOVERY, { userId = user_id, secret = secret, password = password, passwordAgain = password_again })

func get_session(session_id: String) -> AccountTask:
    return __get(AccountTask.Task.GET_SESSION, session_id)

func get_sessions() -> AccountTask:
    return __get(AccountTask.Task.GET_SESSIONS)

func create_session(email: String, password: String) -> AccountTask:
    return __post(AccountTask.Task.CREATE_SESSION, { email = email, password = password })

func delete_session(session_id: String) -> AccountTask:
    return __get(AccountTask.Task.DELETE_SESSION, session_id)

func delete_sessions() -> AccountTask:
    return __get(AccountTask.Task.DELETE_SESSIONS)

func create_anonymous_session() -> AccountTask:
    return __post(AccountTask.Task.CREATE_ANONYMOUS_SESSION)

func create_jwt() -> AccountTask:
    return __post(AccountTask.Task.CREATE_JWT)

func create_magic_url_session(email: String, url: String = "") -> AccountTask:
    var payload: Dictionary = { email = email, url = url }
    return __post(AccountTask.Task.CREATE_MAGIC_URL, payload)

func update_magic_url_session(user_id: String, secret: String) -> AccountTask:
    var payload: Dictionary = { userId = user_id, secret = secret }
    return __post(AccountTask.Task.UPDATE_MAGIC_URL, payload)

func create_oauth2_session(provider: String, success: String = "", failure: String = "", scopes: PoolStringArray = []) -> AccountTask:
    var endpoint: String = provider
    if success != "": endpoint+="&success="+success
    if failure != "": endpoint+="&failure="+failure
    if not scopes.empty(): endpoint+="&scopes="+scopes.join(",")
    return __get(AccountTask.Task.CREATE_SESSION_OAUTH2, endpoint)

func create_verification(url: String) -> AccountTask:
    return __post(AccountTask.Task.CREATE_EMAIL_VERIFICATION, { url = url })

func update_verification(user_id: String, secret: String) -> AccountTask:
    return __post(AccountTask.Task.UPDATE_EMAIL_VERIFICATION, { userId = user_id, secret = secret })




# ------- SERVER API


# Process a specific task
func _process_task(task : AccountTask, _fake : bool = false) -> void:
    task.connect("completed", self, "_on_task_completed", [task])
    if _fake:
        yield(get_tree().create_timer(0.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task_response: TaskResponse, task: AccountTask) -> void:
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
            AccountTask.Task.CREATE_ANONYMOUS_SESSION:
                _fetch_cookies(task)
                _signal = "anonymous_session_created"
            AccountTask.Task.CREATE_EMAIL_VERIFICATION:
                _signal = "email_confirmation_created"
            AccountTask.Task.CREATE_JWT:
                _signal = "jwt_created"
            AccountTask.Task.CREATE_MAGIC_LINK:
                _signal = "magic_link_created"
            AccountTask.Task.CREATE_PWD_RECOVERY:
                _signal = "pwd_recovery_created"
            AccountTask.Task.CREATE_SESSION_OAUTH2:
                _signal = "oauth2_session_created"
            AccountTask.Task.DELETE:
                _signal = "deleted"
            AccountTask.Task.DELETE_SESSION:
                _signal = "session_deleted"
            AccountTask.Task.DELETE_SESSIONS:
                _signal = "sessions_deleted"
            AccountTask.Task.UPDATE_EMAIL:
                _signal = "email_updated"
            AccountTask.Task.UPDATE_EMAIL_VERIFICATION:
                _signal = "email_confirmation_updated"
            AccountTask.Task.UPDATE_MAGIC_LINK:
                _signal = "magic_link_updated"
            AccountTask.Task.UPDATE_NAME:
                _signal = "name_updated"
            AccountTask.Task.UPDATE_PASSWORD:
                _signal = "password_updated"
            AccountTask.Task.UPDATE_PREFS:
                _signal = "prefs_updated"
            AccountTask.Task.UPDATE_PWD_RECOVERY:
                _signal = "pwd_recovery_updated"
            _:
                _signal = "success"
        emit_signal(_signal, task.response)
    else:
        emit_signal("error", task.error)
    emit_signal("task_response", task_response)


func _fetch_cookies(task : AccountTask) -> void:
    var cookies : Array
    for cookie in task.cookies:
        cookies.append("Cookie:%s=%s"%[cookie.keys()[0], cookie.values()[0]])
    _cookies = PoolStringArray(cookies)
    get_parent().cookies += _cookies
