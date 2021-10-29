class_name AppwriteLocalization
extends Node

const _REST_BASE: String = "/locale"

var _cookies : PoolStringArray = []

signal task_response(task_response)
signal success(response)
signal got(locale)
signal got_countries(countries)
signal got_countries_eu(countries_eu)
signal got_countries_phones(countries_phones)
signal got_continents(continents)
signal got_currencies(currencies)
signal got_languages(languages)

func _init():
    pass

func _ready():
    pass


# function builder
func __match_resource(type: int, params: Dictionary = {}) -> String:
    var resource : String = ""
    match type:
        LocaleTask.Task.GET: resource = _REST_BASE
        LocaleTask.Task.GET_COUNTRIES: resource = _REST_BASE + "/countries"
        LocaleTask.Task.GET_COUNTRIES_EU: resource = _REST_BASE + "/countries/eu"
        LocaleTask.Task.GET_COUNTRIES_PHONES: resource = _REST_BASE + "/countries/phones"
        LocaleTask.Task.GET_CONTINENTS: resource = _REST_BASE + "/continents"
        LocaleTask.Task.GET_CURRENCIES: resource = _REST_BASE + "/currencies"
        LocaleTask.Task.GET_LANGUAGES: resource = _REST_BASE + "/languages"
    return resource

# GET, DELETE base function
func __get(type : int, params: Dictionary = {}) -> LocaleTask:
    var functions_task : LocaleTask = LocaleTask.new(
        type,
        get_parent().endpoint + __match_resource(type, params), 
        get_parent()._get_headers()
    )
    _process_task(functions_task)
    return functions_task 

# -------- CLIENT/SERVER API
func get_locale() -> LocaleTask:
    return __get(LocaleTask.Task.GET)

func get_countries() -> LocaleTask:
    return __get(LocaleTask.Task.GET_COUNTRIES)

func get_countries_eu() -> LocaleTask:
    return __get(LocaleTask.Task.GET_COUNTRIES_EU)

func get_countries_phones() -> LocaleTask:
    return __get(LocaleTask.Task.GET_COUNTRIES_PHONES)

func get_continents() -> LocaleTask:
    return __get(LocaleTask.Task.GET_CONTINENTS)

func get_currencies() -> LocaleTask:
    return __get(LocaleTask.Task.GET_CURRENCIES)

func get_languages() -> LocaleTask:
    return __get(LocaleTask.Task.GET_LANGUAGES)


# Process a specific task
func _process_task(task : LocaleTask, _fake : bool = false) -> void:
    task.connect("completed", self, "_on_task_completed", [task])
    if _fake:
        yield(get_tree().create_timer(0.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task_response: TaskResponse, task: LocaleTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        var _signal : String = ""
        match task._code:
            LocaleTask.Task.GET: _signal = "got"
            LocaleTask.Task.GET_COUNTRIES: _signal = "got_countries"
            LocaleTask.Task.GET_COUNTRIES_EU: _signal = "got_countries_eu"
            LocaleTask.Task.GET_COUNTRIES_PHONES: _signal = "got_countries_phones"
            LocaleTask.Task.GET_CONTINENTS: _signal = "got_continents"
            LocaleTask.Task.GET_CURRENCIES: _signal = "got_currencies"
            LocaleTask.Task.GET_LANGUAGES: _signal = "got_languages"
            _: _signal = "success"
        emit_signal(_signal, task.response)
    else:
        emit_signal("error", task.error)
    emit_signal("task_response", task_response)
