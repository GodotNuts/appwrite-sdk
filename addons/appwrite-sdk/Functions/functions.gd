class_name AppwriteFunctions
extends Node

const _REST_BASE: String = "/functions"

var _cookies : PoolStringArray = []

signal task_response(task_response)
signal success(response)
signal created_execution(execution)
signal listed_executions(executions)
signal got_execution(execution)

signal created(function)
signal listed(functions)
signal got(function)
signal updated(function)
signal deleted(function)
signal updated_tag(tag)
signal created_tag(tag)
signal listed_tags(tags)
signal got_tag(tag)
signal deleted_tag(tag)


func _init():
    pass

func _ready():
    pass


# function builder
func __match_resource(type: int, params: Dictionary = {}) -> String:
    var resource : String = ""
    match type:    
        # Client
        FunctionsTask.Task.CREATE_EXECUTION, FunctionsTask.Task.LIST_EXECUTIONS: resource = _REST_BASE+"/"+params.function_id+"/executions" + (params.query if params.has("query") else "")
        FunctionsTask.Task.GET_EXECUTION: resource = _REST_BASE+"/"+params.function_id+"/executions/"+params.execution_id
        # Server
        FunctionsTask.Task.CREATE, FunctionsTask.Task.LIST, FunctionsTask.Task.DELETE: resource = _REST_BASE + (params.query if params.has("query") else "")
        FunctionsTask.Task.GET: resource = _REST_BASE + "/" + params.function_id
        FunctionsTask.Task.UPDATE_TAG: resource = _REST_BASE + "/" + params.function_id + "/tag"
        FunctionsTask.Task.CREATE_TAG, FunctionsTask.Task.LIST_TAGS: resource = _REST_BASE + "/" + params.function_id + "/tags" + (params.query if params.has("query") else "")
        FunctionsTask.Task.GET_TAG, FunctionsTask.Task.DELETE_TAG: resource = _REST_BASE + "/" + params.function_id + "/tags/" + params.tag_id
    return resource


# GET, DELETE base function
func __get(type : int, params: Dictionary = {}) -> FunctionsTask:
    var functions_task : FunctionsTask = FunctionsTask.new(
        type,
        get_parent().endpoint + __match_resource(type, params), 
        get_parent()._get_headers()
    )
    _process_task(functions_task)
    return functions_task 


# POST, PUT, PATCH base function
func __post(type: int, payload: Dictionary = {}, params: Dictionary = {}) -> FunctionsTask:
    var function_task : FunctionsTask = FunctionsTask.new(
        type,
        get_parent().endpoint + __match_resource(type, params), 
        get_parent()._get_headers(),
        payload
        )
    _process_task(function_task)
    return function_task

# CLIENT (/SERVER) API -----
func create_execution(function_id: String, data: Dictionary = {}) -> FunctionsTask:
    return __post(FunctionsTask.Task.CREATE_EXECUTION, { function_id = function_id, data = data })

func list_executions(function_id: String, search: String = "", limit: int = -1, offset: int = -1, order_by: String = "") -> FunctionsTask:
    var query: String = "?"
    if search!="": query+="search="+search
    if limit!=-1: query+="&limit="+str(limit)
    if offset!=-1: query+="&offset="+str(offset)
    if order_by!="": query+="&orderBy="+order_by
    return __get(FunctionsTask.Task.LIST_EXECUTIONS, {function_id = function_id, query = query})

func getExecution(function_id: String, execution_id: String) -> FunctionsTask:
    return __get(FunctionsTask.Task.GET_EXECUTION, { function_id = function_id , execution_id = execution_id })

# SERVER API -----
func create(name: String, execute: Array, runtime: String, vars: Dictionary = {}, events: Array = [], schedule: String = "", timeout: int = -1) -> FunctionsTask:
    return __post(FunctionsTask.Task.CREATE, { name = name, execute = execute, runtime = runtime, vars = vars, events = events, schedule = schedule, timeout = timeout })

func list(search: String = "", limit: int = -1, offset: int = -1, order_by: String = "") -> FunctionsTask:
    var query: String = "?"
    if search!="": query+="search="+search
    if limit!=-1: query+="&limit="+str(limit)
    if offset!=-1: query+="&offset="+str(offset)
    if order_by!="": query+="&orderBy="+order_by
    return __get(FunctionsTask.Task.LIST, { query = query })

func get_function(function_id: String) -> FunctionsTask:
    return __get(FunctionsTask.Task.GET, { function_id = function_id })

func update(function_id: String, name: String, execute: Array, vars: Dictionary = {}, events: Array = [], schedule: String = "", timeout: int = -1) -> FunctionsTask:
    return __post(FunctionsTask.Task.UPDATE, { name = name, execute = execute, vars = vars, events = events, schedule = schedule, timeout = timeout }, { function_id = function_id })

func update_tag(function_id: String, tag: String) -> FunctionsTask:
    return __post(FunctionsTask.Task.UPDATE_TAG, { tag = tag }, { function_id = function_id })

func delete(function_id: String) -> FunctionsTask:
    return __get(FunctionsTask.Task.DELETE, { function_id = function_id })

func create_tag(function_id: String, command: String, code_path: String) -> FunctionsTask:
    return __post(FunctionsTask.Task.CREATE_TAG, { command = command, code = code_path }, { function_id = function_id })

func list_tags(function_id: String, search: String = "", limit: int = -1, offset: int = -1, order_by: String = "") -> FunctionsTask:
    var query: String = "?"
    if search!="": query+="search="+search
    if limit!=-1: query+="&limit="+str(limit)
    if offset!=-1: query+="&offset="+str(offset)
    if order_by!="": query+="&orderBy="+order_by
    return __get(FunctionsTask.Task.LIST_TAGS, {function_id = function_id, query = query})

func get_tag(function_id: String, tag_id: String) -> FunctionsTask:
    return __get(FunctionsTask.Task.GET_TAG, { function_id = function_id, tag_id = tag_id })

func delete_tag(function_id: String, tag_id: String) -> FunctionsTask:
    return __get(FunctionsTask.Task.DELETE_TAG, { function_id = function_id, tag_id = tag_id })


# Process a specific task
func _process_task(task : FunctionsTask, _fake : bool = false) -> void:
    task.connect("completed", self, "_on_task_completed", [task])
    if _fake:
        yield(get_tree().create_timer(-1.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task_response: TaskResponse, task: FunctionsTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        var _signal : String = ""
        match task._code:
            # Client
            FunctionsTask.Task.CREATE_EXECUTION: _signal = "created_execution"
            FunctionsTask.Task.LIST_EXECUTIONS: _signal = "listed_executions"
            FunctionsTask.Task.GET_EXECUTION: _signal = "got_execution"
            # Server
            FunctionsTask.Task.CREATE: _signal = "created"
            FunctionsTask.Task.LIST: _signal = "listed"
            FunctionsTask.Task.GET: _signal = "got"
            FunctionsTask.Task.UPDATE: _signal = "updated"
            FunctionsTask.Task.UPDATE_TAG: _signal = "tag_updated"
            FunctionsTask.Task.DELETE: _signal = "deleted"
            FunctionsTask.Task.CREATE_TAG: _signal = "created_tag"
            FunctionsTask.Task.LIST_TAGS: _signal = "listed_tags"
            FunctionsTask.Task.GET_TAG: _signal = "got_tag"
            FunctionsTask.Task.DELETE_TAG: _signal = "deleted_tag"
            _: _signal = "success"
        emit_signal(_signal, task.response)
    else:
        emit_signal("error", task.error)
    emit_signal("task_response", task_response)
