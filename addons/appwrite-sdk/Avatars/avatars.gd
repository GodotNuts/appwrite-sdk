class_name AppwriteAvatars
extends Node

const _REST_BASE: String = "/avatars"

var _cookies : PoolStringArray = []

signal task_response(task_response)
signal success(response)
signal got_credit_card(credit_card)
signal got_browser(browser_icon)
signal got_flag(country_flag)
signal got_image(image)
signal got_favicon(favicon)
signal got_qr(qr)
signal got_initials(initials)


func _init():
    pass

func _ready():
    pass


# function builder
func __match_resource(type: int, params: Dictionary = {}) -> String:
    var resource : String = ""
    match type:    
        # Client/Server
        AvatarsTask.Task.GET_CREDIT_CARD: resource = _REST_BASE+"/credit-cards/" + params.code + (params.query if params.get("query","?") != "?" else "")
        AvatarsTask.Task.GET_BROWSER_ICON: resource = _REST_BASE+"/browsers/" + params.code + (params.query if params.get("query","?") != "?" else "")
        AvatarsTask.Task.GET_COUNTRY_FLAG: resource = _REST_BASE+"/flags/" + params.code + (params.query if params.get("query","?") != "?" else "")
        AvatarsTask.Task.GET_AVATAR_IMAGE: resource = _REST_BASE+"/image" + (params.query if params.get("query","?") != "?" else "")
        AvatarsTask.Task.GET_FAVICON: resource = _REST_BASE+"/favicon" + (params.query if params.get("query","?") != "?" else "")
        AvatarsTask.Task.GET_QR: resource = _REST_BASE+"/qr" + (params.query if params.get("query","?") != "?" else "")
        AvatarsTask.Task.GET_INITIALS: resource = _REST_BASE+"/initials" + (params.query if params.get("query","?") != "?" else "")
    return resource


# GET, DELETE base function
func __get(type : int, params: Dictionary = {}) -> AvatarsTask:
    var functions_task : AvatarsTask = AvatarsTask.new(
        type,
        get_parent().endpoint + __match_resource(type, params), 
        get_parent()._get_headers()
    )
    _process_task(functions_task)
    return functions_task 


# POST, PUT, PATCH base function
func __post(type: int, payload: Dictionary = {}, params: Dictionary = {}) -> AvatarsTask:
    var avatars_task : AvatarsTask = AvatarsTask.new(
        type,
        get_parent().endpoint + __match_resource(type, params), 
        get_parent()._get_headers(),
        payload
        )
    _process_task(avatars_task)
    return avatars_task

# CLIENT (/SERVER) API -----
func get_credit_card(code: String, width: int = -1, height: int = -1, quality: int = -1) -> AvatarsTask:
    var query: String = "?"
    if width!=-1: query+="width="+str(width)
    if height!=-1: query+="&height="+str(height)
    if quality!=-1: query+="&quality="+str(quality)
    return __get(AvatarsTask.Task.GET_CREDIT_CARD, { code = code, query = query  })

func get_browser(code: String, width: int = -1, height: int = -1, quality: int = -1) -> AvatarsTask:
    var query: String = "?"
    if width!=-1: query+="&width="+str(width)
    if height!=-1: query+="&height="+str(height)
    if quality!=-1: query+="&quality="+str(quality)
    return __get(AvatarsTask.Task.GET_BROWSER_ICON, { code = code, query = query  })

func get_flag(code: String, width: int = -1, height: int = -1, quality: int = -1) -> AvatarsTask:
    var query: String = "?"
    if width!=-1: query+="width="+str(width)
    if height!=-1: query+="&height="+str(height)
    if quality!=-1: query+="&quality="+str(quality)
    return __get(AvatarsTask.Task.GET_COUNTRY_FLAG, { code = code, query = query  })
    
func get_image(url: String, width: int = -1, height: int = -1) -> AvatarsTask:
    var query: String = "?url="+url
    if width!=-1: query+="&width="+str(width)
    if height!=-1: query+="&height="+str(height)
    return __get(AvatarsTask.Task.GET_AVATAR_IMAGE, { query = query })

func get_favicon(url: String) -> AvatarsTask:
    var query: String = "?url="+url
    return __get(AvatarsTask.Task.GET_FAVICON, { query = query })
    
func get_qr(text: String, size: int = -1, margin: int = -1, download: bool = false) -> AvatarsTask:
    var query: String = "?text="+text.http_escape()
    query+="&download="+str(download).to_lower()
    if size!=-1: query+="&size="+str(size)
    if margin!=-1: query+="&margin="+str(margin)
    return __get(AvatarsTask.Task.GET_QR, { query = query })

func get_initials(name: String = "", width: int = -1, height: int = -1, color: Color = Color.white, background: Color = Color.magenta) -> AvatarsTask:
    var query: String = "?"
    query+="name="+name
    query+="&"+color.to_html()
    query+="&"+background.to_html()
    if width!=-1: query+="&width="+str(width)
    if height!=-1: query+="&height="+str(height)
    return __get(AvatarsTask.Task.GET_INITIALS, { query = query })
    

# Process a specific task
func _process_task(task : AvatarsTask, _fake : bool = false) -> void:
    task.connect("completed", self, "_on_task_completed", [task])
    if _fake:
        yield(get_tree().create_timer(0.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task_response: TaskResponse, task: AvatarsTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        var _signal : String = ""
        match task._code:
            # Client/Server
            AvatarsTask.Task.GET_CREDIT_CARD: _signal = "got_credit_card"
            AvatarsTask.Task.GET_BROWSER_ICON: _signal = "got_browser"
            AvatarsTask.Task.GET_COUNTRY_FLAG: _signal = "got_flag"
            AvatarsTask.Task.GET_AVATAR_IMAGE: _signal = "got_image"
            AvatarsTask.Task.GET_FAVICON: _signal = "got_favicon"
            AvatarsTask.Task.GET_QR: _signal = "got_qr"
            AvatarsTask.Task.GET_INITIALS: _signal = "got_initials"
            _: _signal = "success"
        emit_signal(_signal, task.response)
    else:
        emit_signal("error", task.error)
    emit_signal("task_response", task_response)
