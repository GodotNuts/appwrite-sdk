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

signal created(user)
signal session_created(session)

func _init():
    pass

func _ready():
    pass

# -------- CLIENT API
func create(email: String, password: String, _name: String = "") -> AccountTask:
    var payload : Dictionary = { "email":email, "password":password }
    if _name != "" : payload["name"] = _name
    var account_task : AccountTask = AccountTask.new(
        AccountTask.Task.CREATE,
        get_parent().endpoint + "/account", 
        get_parent()._get_headers(),
        payload
        )
    _process_task(account_task)
    return account_task

func create_session(email: String, password: String) -> AccountTask:
    var payload : Dictionary = { "email":email, "password":password }
    var account_task : AccountTask = AccountTask.new(
        AccountTask.Task.CREATE_SESSION,
        get_parent().endpoint + "/account/sessions", 
        get_parent()._get_headers(),
        payload
        )
    _process_task(account_task)
    return account_task

# ---------------------

# ------- SERVER API

# ---------------------


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

func _fetch_cookies(task : AccountTask) -> void:
    var cookies : Array
    for cookie in task.cookies:
        cookies.append("Cookie:%s=%s"%[cookie.keys()[0], cookie.values()[0]])
    _cookies = PoolStringArray(cookies)
    get_parent().cookies = _cookies


func _on_task_completed(task : AccountTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        match task._code:
            AccountTask.Task.CREATE:
                emit_signal("created", task.response)
            AccountTask.Task.CREATE_SESSION:
                _fetch_cookies(task)
                emit_signal("session_created", task.response)
            _:
                pass
    else:
        emit_signal("error", task.error)
