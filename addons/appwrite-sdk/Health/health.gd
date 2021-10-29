class_name AppwriteHealth
extends Node

const _REST_BASE: String = "/health"

var _cookies : PoolStringArray = []

signal task_response(task_response)
signal success(response)
signal got_http(http)
signal got_db(db)
signal got_cache(cache)
signal got_time(time)
signal got_webhooks_queue(webhooks_queue)
signal got_tasks_queue(tasks_queue)
signal got_logs_queue(logs_queue)
signal got_usage_queue(usage_queue)
signal got_certificates_queue(certificate_queue)
signal got_functions_queue(functions_queue)
signal got_local_storage(local_storage)
signal got_antivirus(got_antivirus)

func _init():
    pass

func _ready():
    pass


# function builder
func __match_resource(type: int, param: String = "") -> String:
    var resource : String = ""
    match type:    
        HealthTask.Task.HTTP: resource = _REST_BASE
        HealthTask.Task.DB: resource = _REST_BASE+"/db"
        HealthTask.Task.CACHE: resource = _REST_BASE+"/cache"
        HealthTask.Task.TIME: resource = _REST_BASE+"/time"
        HealthTask.Task.WEBHOOKS_QUEUE: resource = _REST_BASE+"/queue/webhooks"
        HealthTask.Task.TASKS_QUEUE: resource = _REST_BASE+"/queue/tasks"
        HealthTask.Task.LOGS_QUEUE: resource = _REST_BASE+"/queue/logs"
        HealthTask.Task.USAGE_QUEUE: resource = _REST_BASE+"/queue/usage"
        HealthTask.Task.CERTIFICATES_QUEUE: resource = _REST_BASE+"/queue/certificates"
        HealthTask.Task.FUNCTIONS_QUEUE: resource = _REST_BASE+"/queue/functions"
        HealthTask.Task.LOCAL_STORAGE: resource = _REST_BASE+"/storage/local"
        HealthTask.Task.ANTIVIRUS: resource = _REST_BASE+"/anti-virus"
    return resource


# GET, DELETE base function
func __get(type : int, param: String = "") -> HealthTask:
    var health_task : HealthTask = HealthTask.new(
        type,
        get_parent().endpoint + __match_resource(type, param), 
        get_parent()._get_headers()
    )
    _process_task(health_task)
    return health_task 


# SERVER API -----
func get_http() -> HealthTask:
    return __get(HealthTask.Task.HTTP)

func get_db() -> HealthTask:
    return __get(HealthTask.Task.DB)

func get_cache() -> HealthTask:
    return __get(HealthTask.Task.CACHE)

func get_time() -> HealthTask:
    return __get(HealthTask.Task.TIME)

func get_webhooks_queue() -> HealthTask:
    return __get(HealthTask.Task.WEBHOOKS_QUEUE)

func get_tasks_queue() -> HealthTask:
    return __get(HealthTask.Task.TASKS_QUEUE)

func get_logs_queue() -> HealthTask:
    return __get(HealthTask.Task.LOGS_QUEUE)

func get_usage_queue() -> HealthTask:
    return __get(HealthTask.Task.USAGE_QUEUE)

func get_certificates_queue() -> HealthTask:
    return __get(HealthTask.Task.CERTIFICATES_QUEUE)

func get_functions_queue() -> HealthTask:
    return __get(HealthTask.Task.FUNCTIONS_QUEUE)

func get_local_storage() -> HealthTask:
    return __get(HealthTask.Task.LOCAL_STORAGE)

func get_antivirus() -> HealthTask:
    return __get(HealthTask.Task.ANTIVIRUS)

# Process a specific task
func _process_task(task : HealthTask, _fake : bool = false) -> void:
    task.connect("completed", self, "_on_task_completed", [task])
    if _fake:
        yield(get_tree().create_timer(0.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task_response: TaskResponse, task: HealthTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        var _signal : String = ""
        match task._code:
            HealthTask.Task.HTTP: _signal = "got_http"
            HealthTask.Task.DB: _signal = "got_db"
            HealthTask.Task.CACHE: _signal = "got_cache"
            HealthTask.Task.TIME: _signal = "got_time"
            HealthTask.Task.WEBHOOKS_QUEUE: _signal = "got_webhooks_queue"
            HealthTask.Task.TASKS_QUEUE: _signal = "got_tasks_queue"
            HealthTask.Task.LOGS_QUEUE: _signal = "got_logs_queue"
            HealthTask.Task.USAGE_QUEUE: _signal = "got_usage_queue"
            HealthTask.Task.CERTIFICATES_QUEUE: _signal = "got_certificates_queue"
            HealthTask.Task.FUNCTIONS_QUEUE: _signal = "got_functions_queue"
            HealthTask.Task.LOCAL_STORAGE: _signal = "got_local_storage"
            HealthTask.Task.ANTIVIRUS: _signal = "got_antivirus"
            _: _signal = "success"
        emit_signal(_signal, task.response)
    else:
        emit_signal("error", task.error)
    emit_signal("task_response", task_response)


func _fetch_cookies(task : HealthTask) -> void:
    var cookies : Array
    for cookie in task.cookies:
        cookies.append("Cookie:%s=%s"%[cookie.keys()[0], cookie.values()[0]])
    _cookies = PoolStringArray(cookies)
    get_parent().cookies += _cookies
