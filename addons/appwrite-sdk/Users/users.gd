class_name AppwriteUsers
extends Node

const _REST_BASE: String = "/users"

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
        UsersTask.Task.GET, UsersTask.Task.CREATE, UsersTask.Task.DELETE: resource = _REST_BASE
        UsersTask.Task.GET_SESSIONS, UsersTask.Task.CREATE_SESSION: resource = _REST_BASE+"/sessions"
        UsersTask.Task.CREATE_SESSION_OAUTH2: resource = _REST_BASE+"/sessions/oauth2/"+param
        UsersTask.Task.CREATE_MAGIC_LINK, UsersTask.Task.UPDATE_MAGIC_LINK: resource = _REST_BASE+"/sessions/magic-url"
        UsersTask.Task.CREATE_ANONYMOUS_SESSION: resource = _REST_BASE+"/sessions/anonymous"
        UsersTask.Task.CREATE_JWT: resource = _REST_BASE+"/jwt"
        UsersTask.Task.GET_LOGS: resource = _REST_BASE+"/logs"
        UsersTask.Task.GET_SESSION, UsersTask.Task.DELETE_SESSION: resource = _REST_BASE+"/sessions/"+param
        UsersTask.Task.UPDATE_NAME: resource = _REST_BASE+"/name"
        UsersTask.Task.UPDATE_PASSWORD: resource = _REST_BASE+"/password"
        UsersTask.Task.UPDATE_EMAIL: resource = _REST_BASE+"/email"
        UsersTask.Task.UPDATE_PREFS, UsersTask.Task.GET_PREFS: resource = _REST_BASE+"/prefs"
        UsersTask.Task.GET_SESSIONS, UsersTask.Task.DELETE_SESSIONS: resource = _REST_BASE+"/sessions"
        UsersTask.Task.CREATE_PWD_RECOVERY, UsersTask.Task.UPDATE_PWD_RECOVERY: resource = _REST_BASE+"/recovery"
        UsersTask.Task.CREATE_EMAIL_VERIFICATION, UsersTask.Task.UPDATE_EMAIL_VERIFICATION: resource = _REST_BASE+"/verification"
    return resource




# GET, DELETE base function
func __get(type : int, param: String = "") -> UsersTask:
    var account_task : UsersTask = UsersTask.new(
        type,
        get_parent().endpoint + __match_resource(type, param), 
        get_parent()._get_headers()
    )
    _process_task(account_task)
    return account_task 

# POST, PUT, PATCH base function
func __post(type: int, payload: Dictionary = {}, param: String = "") -> UsersTask:
    var account_task : UsersTask = UsersTask.new(
        type,
        get_parent().endpoint + __match_resource(type, param), 
        get_parent()._get_headers(),
        payload
        )
    _process_task(account_task)
    return account_task


# -------- CLIENT API

func get_logged() -> UsersTask :
    return __get(UsersTask.Task.GET)

func create(email: String, password: String, _name: String = "") -> UsersTask:
    var payload : Dictionary = { "email":email, "password":password }
    if _name != "" : payload["name"] = _name
    return __post(UsersTask.Task.CREATE, payload)

func delete() -> UsersTask:
    return __get(UsersTask.Task.DELETE)

func get_logs() -> UsersTask:
    return __get(UsersTask.Task.GET_LOGS)

func update_name(name: String) -> UsersTask:
    return __post(UsersTask.Task.UPDATE_NAME, { name = name })

func update_password(password: String, old_password: String) -> UsersTask:
    return __post(UsersTask.Task.UPDATE_PWD, { password = password, oldPassword = old_password })

func update_email(email: String, password: String) -> UsersTask:
    return __post(UsersTask.Task.UPDATE_EMAIL, { email = email, password = password })

func get_prefs() -> UsersTask:
    return __get(UsersTask.Task.GET_PREFS)

func update_prefs(prefs: Dictionary) -> UsersTask:
    return __post(UsersTask.Task.UPDATE_PREFS, { prefs = prefs })

func create_recovery(email: String, url: String) -> UsersTask:
    return __post(UsersTask.Task.CREATE_PWD_RECOVERY, { email = email, url = url })

func update_recovery(user_id: String, secret: String, password: String, password_again: String) -> UsersTask:
    return __post(UsersTask.Task.UPDATE_PWD_RECOVERY, { userId = user_id, secret = secret, password = password, passwordAgain = password_again })

func get_session(session_id: String) -> UsersTask:
    return __get(UsersTask.Task.GET_SESSION, session_id)

func get_sessions() -> UsersTask:
    return __get(UsersTask.Task.GET_SESSIONS)

func create_session(email: String, password: String) -> UsersTask:
    return __post(UsersTask.Task.CREATE_SESSION, { email = email, password = password })

func delete_session(session_id: String) -> UsersTask:
    return __get(UsersTask.Task.DELETE_SESSION, session_id)

func delete_sessions() -> UsersTask:
    return __get(UsersTask.Task.DELETE_SESSIONS)

func create_anonymous_session() -> UsersTask:
    return __post(UsersTask.Task.CREATE_ANONYMOUS_SESSION)

func create_magic_url_session(email: String, url: String = "") -> UsersTask:
    var payload: Dictionary = { email = email, url = url }
    return __post(UsersTask.Task.CREATE_MAGIC_URL, payload)

func update_magic_url_session(user_id: String, secret: String) -> UsersTask:
    var payload: Dictionary = { userId = user_id, secret = secret }
    return __post(UsersTask.Task.UPDATE_MAGIC_URL, payload)

func create_oauth2_session(provider: String, success: String = "", failure: String = "", scopes: PoolStringArray = []) -> UsersTask:
    var endpoint: String = provider
    if success != "": endpoint+="&success="+success
    if failure != "": endpoint+="&failure="+failure
    if not scopes.empty(): endpoint+="&scopes="+scopes.join(",")
    return __get(UsersTask.Task.CREATE_SESSION_OAUTH2, endpoint)

func create_verification(url: String) -> UsersTask:
    return __post(UsersTask.Task.CREATE_EMAIL_VERIFICATION, { url = url })

func update_verification(user_id: String, secret: String) -> UsersTask:
    return __post(UsersTask.Task.UPDATE_EMAIL_VERIFICATION, { userId = user_id, secret = secret })




# ------- SERVER API


# Process a specific task
func _process_task(task : UsersTask, _fake : bool = false) -> void:
    task.connect("completed", self, "_on_task_completed", [task])
    if _fake:
        yield(get_tree().create_timer(0.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task_response: TaskResponse, task: UsersTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        var _signal : String = ""
        match task._code:
            UsersTask.Task.GET:
                _signal = "got"
            UsersTask.Task.GET_PREFS:
                _signal = "got_prefs"
            UsersTask.Task.GET_LOGS:
                _signal = "got_logs"
            UsersTask.Task.GET_SESSIONS:
                _signal = "got_sessions"
            UsersTask.Task.GET_SESSION:
                _signal = "got_session"
            UsersTask.Task.CREATE:
                _signal = "created"
            UsersTask.Task.CREATE_SESSION:
                _fetch_cookies(task)
                _signal = "session_created"
            UsersTask.Task.CREATE_ANONYMOUS_SESSION:
                _fetch_cookies(task)
                _signal = "anonymous_session_created"
            UsersTask.Task.CREATE_EMAIL_VERIFICATION:
                _signal = "email_confirmation_created"
            UsersTask.Task.CREATE_JWT:
                _signal = "jwt_created"
            UsersTask.Task.CREATE_MAGIC_LINK:
                _signal = "magic_link_created"
            UsersTask.Task.CREATE_PWD_RECOVERY:
                _signal = "pwd_recovery_created"
            UsersTask.Task.CREATE_SESSION_OAUTH2:
                _signal = "oauth2_session_created"
            UsersTask.Task.DELETE:
                _signal = "deleted"
            UsersTask.Task.DELETE_SESSION:
                _signal = "session_deleted"
            UsersTask.Task.DELETE_SESSIONS:
                _signal = "sessions_deleted"
            UsersTask.Task.UPDATE_EMAIL:
                _signal = "email_updated"
            UsersTask.Task.UPDATE_EMAIL_VERIFICATION:
                _signal = "email_confirmation_updated"
            UsersTask.Task.UPDATE_MAGIC_LINK:
                _signal = "magic_link_updated"
            UsersTask.Task.UPDATE_NAME:
                _signal = "name_updated"
            UsersTask.Task.UPDATE_PASSWORD:
                _signal = "password_updated"
            UsersTask.Task.UPDATE_PREFS:
                _signal = "prefs_updated"
            UsersTask.Task.UPDATE_PWD_RECOVERY:
                _signal = "pwd_recovery_updated"
            _:
                _signal = "success"
        emit_signal(_signal, task.response)
    else:
        emit_signal("error", task.error)
    emit_signal("task_response", task_response)


func _fetch_cookies(task : UsersTask) -> void:
    var cookies : Array
    for cookie in task.cookies:
        cookies.append("Cookie:%s=%s"%[cookie.keys()[0], cookie.values()[0]])
    _cookies = PoolStringArray(cookies)
    get_parent().cookies += _cookies
