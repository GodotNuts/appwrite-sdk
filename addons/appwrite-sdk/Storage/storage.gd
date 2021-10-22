class_name AppwriteStorage
extends Node

const _REST_BASE: String = "/storage"

const BOUNDARY: String = "X-GODOT-ENGINE-BOUNDARY"

signal success()
signal task_response(task_response)
signal listed_files(details)
signal got_file(file)
signal got_file_preview(preview)
signal deleted_file()
signal updated_file(details)
signal moved_file(details)
signal removed_files(details)
signal created_signed_url(details)
signal downloaded_file(details)
signal got_view(view)
signal got_preview(preview)
signal error(error)

func _init() -> void:
  pass

func _ready() -> void:
  pass

# function builder
func __match_resource(type: int, params: Dictionary = {}) -> String:
    var resource : String = ""
    match type:
        StorageTask.Task.CREATE_FILE, StorageTask.Task.LIST_FILES: resource = _REST_BASE+"/files" + ("?"+params.query if params.has("query") else "")
        StorageTask.Task.GET_FILE, StorageTask.Task.UPDATE_FILE, StorageTask.Task.DELETE_FILE: resource = _REST_BASE+"/files/"+params.file_id
        StorageTask.Task.GET_FILE_PREVIEW: resource = _REST_BASE+"/files/"+params.file_id+"/preview" + ("?"+params.query if params.has("query") else "")
        StorageTask.Task.DOWNLOAD_FILE: resource = _REST_BASE+"/files/"+params.file_id+"/download"
        StorageTask.Task.GET_FILE_VIEW: resource = _REST_BASE+"/files/"+params.file_id+"/view"
    return resource


# GET, DELETE base function
func __get(type : int, params: Dictionary = {}) -> StorageTask:
    var storage_task : StorageTask = StorageTask.new(
        type,
        get_parent().endpoint + __match_resource(type, params), 
        get_parent()._get_headers()
    )
    _process_task(storage_task, false, {download_file = params.to_path} if params.has("to_path") else {})
    return storage_task 

    
# POST, PUT, PATCH base function
func __post(type: int, payload: Dictionary = {}, params: Dictionary = {}) -> StorageTask:
    var temp_headers: PoolStringArray = []
    temp_headers.append("Content-Type:multipart/form-data; boundary="+BOUNDARY)
    var headers: PoolStringArray = get_parent()._get_headers()
    headers.remove(3)
    var storage_task : StorageTask = StorageTask.new(
        type,
        get_parent().endpoint + __match_resource(type, params), 
        headers + temp_headers,
        {},
        payload.file
        )
    _process_task(storage_task)
    return storage_task

func _read_file(file_path: String) -> PoolByteArray :
    var file : File = File.new()
    var error : int = file.open(file_path, File.READ)
    if error != OK: 
        printerr("could not open %s "%file_path)
        return PoolByteArray([])
    var file_buff : PoolByteArray = file.get_buffer(file.get_len())
    file.close()
    return file_buff

func _build_multipart(file_path: String, read: PoolStringArray, write: PoolStringArray) -> PoolByteArray:
    var bytes: PoolByteArray = ("--"+BOUNDARY+"\r\n").to_ascii()
    bytes.append_array(('Content-Disposition: form-data; name="file"; filename="%s"\r\n'%[file_path.get_file()]).to_ascii())
    bytes.append_array("Content-Type: text/plain\r\n\r\n".to_ascii())
    bytes.append_array(_read_file(file_path))
    bytes.append_array("\r\n".to_ascii())
    if not read.empty():
        for permission_i in read.size():
            bytes.append_array(("--"+BOUNDARY+"\r\n").to_ascii())
            bytes.append_array(('Content-Disposition: form-data; name="read[%s]"\r\n\r\n'%[permission_i]).to_ascii())
            bytes.append_array((read[permission_i]+"\r\n").to_ascii())
    if not write.empty():
        for permission_i in write.size():
            bytes.append_array(("--"+BOUNDARY+"\r\n").to_ascii())
            bytes.append_array(('Content-Disposition: form-data; name="write[%s]"\r\n\r\n'%[permission_i]).to_ascii())
            bytes.append_array((write[permission_i]+"\r\n").to_ascii())
    return bytes

#       CLIENT & SERVER
func create_file(file_path: String, read: PoolStringArray = [], write: PoolStringArray = []) -> StorageTask:
    var file: PoolByteArray = _build_multipart(file_path, read, write)
    if file.empty(): 
        var fake_task: StorageTask = StorageTask.new(-1, "", [])
        fake_task.error = { message = "Could not open file." }
        _process_task(fake_task, true)
        return fake_task
    return __post(StorageTask.Task.CREATE_FILE, { file = file })

func list_files(search: String = "", limit: int = 0, offset: int = 0, order_by: String = "") -> StorageTask:
    var query: String = ""
    if search!="": query+="search="+search
    if limit!=0: query+="&limit="+str(limit)
    if offset!=0: query+="&offset="+str(offset)
    if order_by!="": query+="&orderBy="+order_by
    return __get(StorageTask.Task.LIST_FILES, {query = query})

func get_file(file_id: String) -> StorageTask:
    return __get(StorageTask.Task.GET_FILE, {file_id = file_id})

func get_file_preview(file_id: String, save_path: String = "", width: int = 0, height: int = 0, gravity: String ="", quality: int = 0, border_width: int = 0, border_color: String = "", border_radius: int = 0, opacity: float = 0, rotation: int = 0, background: String = "", output: String = "") -> StorageTask:
    var query: String = ""
    if width!=0: query+="width="+str(width)
    if height!=0: query+="&height="+str(height)
    if gravity!="": query+="&gravity="+gravity
    if quality!=0: query+="&quality="+str(quality)
    if border_width!=0: query+="&borderWidth="+str(border_width)
    if border_color!="": query+="&borderColor="+border_color
    if border_radius!=0: query+="&borderRadius="+str(border_radius)
    if opacity!=0: query+="&opacity="+str(opacity)
    if rotation!=0: query+="&rotation="+str(rotation)
    if background!="": query+="&background="+background
    if output!="": query+="&output="+output
    return __get(StorageTask.Task.GET_FILE_PREVIEW, 
    {
        file_id = file_id,
        query = query,
        to_path = save_path
    })

func get_file_download(file_id: String, save_path: String = "") -> StorageTask:
    return __get(StorageTask.Task.DOWNLOAD_FILE, {file_id = file_id, to_path = save_path })

func get_file_view(file_id: String, save_path: String = "") -> StorageTask:
    return __get(StorageTask.Task.GET_FILE_VIEW, {file_id = file_id, to_path = save_path })

func update_file(file_path: String, read: PoolStringArray, write: PoolStringArray) -> StorageTask:
    var file: PoolByteArray = _build_multipart(file_path, read, write)
    if file.empty(): 
        var fake_task: StorageTask = StorageTask.new(-1, "", [])
        fake_task.error = { message = "Could not open file." }
        _process_task(fake_task, true)
        return fake_task
    return __post(StorageTask.Task.UPDATE_FILE, { file = file })

func delete_file(file_id: String) -> StorageTask:
    return __get(StorageTask.Task.DELETE_FILE, {file_id = file_id})



# Process a specific task
func _process_task(task : StorageTask, _fake : bool = false, _params: Dictionary = {}) -> void:
    task.connect("completed", self, "_on_task_completed", [task])
    if _fake:
        yield(get_tree().create_timer(0.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        if not _params.empty():
             httprequest.download_file = _params.get("download_file", "")
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task_response: TaskResponse, task: StorageTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        var _signal : String = ""
        match task._code:
            StorageTask.Task.LIST_FILES:
                _signal = "listed_files"
            StorageTask.Task.GET_FILE_PREVIEW:
                _signal = "got_file_preview"
            StorageTask.Task.GET_FILE:
                _signal = "got_file"
            StorageTask.Task.DELETE_FILE:
                _signal = "deleted_file"
            StorageTask.Task.UPDATE_FILE:
                _signal = "updated_file"
            StorageTask.Task.DOWNLOAD_FILE:
                _signal = "downloaded_file"
            StorageTask.Task.GET_FILE_VIEW:
                _signal = "got_view"
            StorageTask.Task.GET_FILE_PREVIEW:
                _signal = "got_preview"
            _:
                _signal = "success"
        emit_signal(_signal, task.response)
    else:
        emit_signal("error", task.error)
    emit_signal("task_response", task_response)
