class_name AppwriteStorage
extends Node

const _REST_BASE: String = "/storage"


signal listed_objects(details)
signal uploaded_object(details)
signal updated_object(details)
signal moved_object(details)
signal removed_objects(details)
signal created_signed_url(details)
signal downloaded_object(details)
signal error(error)


# function builder
func __match_resource(type: int, param: String = "") -> String:
    var resource : String = ""
    match type:
        StorageTask.Task.CREATE_FILE, StorageTask.Task.LIST_FILES: resource = _REST_BASE+"/files"
    return resource




# GET, DELETE base function
func __get(type : int, param: String = "") -> AccountTask:
    var storage_task : StorageTask = StorageTask.new(
        type,
        get_parent().endpoint + __match_resource(type, param), 
        get_parent()._get_headers()
    )
    _process_task(storage_task)
    return storage_task 

	
# POST, PUT, PATCH base function
func __post(type: int, payload: Dictionary = {}, param: String = "") -> StorageTask:
    var storage_task : StorageTask = StorageTask.new(
        type,
        get_parent().endpoint + __match_resource(type, param), 
        get_parent()._get_headers(),
        payload
        )
    _process_task(storage_task)
    return storage_task

func _init() -> void:
  pass

func _ready() -> void:
  pass

func _read_file(file_path: String) -> PoolByteArray :
	var file : File = File.new()
	var error : int = file.open(file_path, File.READ)
	if error != OK: 
		printerr("could not open %s "%file_path)
		return []
	var bytes: PoolByteArray = file.get_buffer(file.get_len())
	file.close()
	return bytes

func create(file_path: String, read: Array = ["*"], write: Array = ["*"]) -> StorageTask:
	var bytes: PoolStringArray = _read_file(file_path)
	if bytes.empty(): return StorageTask.new()
    return __post(StorageTask.Task.CREATE_FILE, { file = bytes, read = read, write = write }


func list(prefix : String = "", limit : int = 100, offset : int = 0, sort_by : Dictionary = {column = "name", order = "asc"} ) -> StorageTask:
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + "list/" + id
    var task : StorageTask = StorageTask.new()
    var header : PoolStringArray = [_header[0] % "application/json"]
    task._setup(
        task.METHODS.LIST_OBJECTS, 
        endpoint, 
        header + _bearer,
        to_json({prefix = prefix, limit = limit, offset = offset, sort_by = sort_by}))
    _process_task(task)
    return task
	
	
func update(bucket_path : String, file_path : String) -> StorageTask:
    requesting_raw = true
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + id + "/" + bucket_path
    var file : File = File.new()
    file.open(file_path, File.READ)
    var header : PoolStringArray = [_header[0] % MIME_TYPES[file_path.get_extension()]]
    header.append("Content-Length: %s" % file.get_len())
    var task : StorageTask = StorageTask.new()
    task.connect("completed", self, "_on_task_completed")
    task._setup(
        task.METHODS.UPDATE_OBJECT, 
        endpoint, 
        header + _bearer,
        "",
        file.get_buffer(file.get_len())
    )
    _current_task = task
    set_process_internal(requesting_raw)
    file.close()
    return task


func move(source_path : String, destination_path : String) -> StorageTask:
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + "move"
    var task : StorageTask = StorageTask.new()
    var header : PoolStringArray = [_header[0] % "application/json"]
    task._setup(
        task.METHODS.MOVE_OBJECT, 
        endpoint, 
        header + _bearer,
        to_json({bucketId = id, sourceKey = source_path, destinationKey = destination_path}))
    _process_task(task)
    return task


func create_signed_url(object : String, expires_in : int = 60000) -> StorageTask:
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + "sign/" + id + "/" + object
    var task : StorageTask = StorageTask.new()
    var header : PoolStringArray = [_header[0] % "application/json"]
    task._setup(
        task.METHODS.CREATE_SIGNED_URL, 
        endpoint, 
        header + _bearer,
        to_json({expiresIn = expires_in})
    )
    _process_task(task)
    return task


func download(object : String, to_path : String = "", private : bool = false) -> StorageTask:
    if not private:
        var endpoint : String = _config.supabaseUrl + _rest_endpoint + "public/" + id + "/" + object
        var task : StorageTask = StorageTask.new()
        var header : PoolStringArray = [_header[0] % "application/json"]
        task._setup(
            task.METHODS.DOWNLOAD, 
            endpoint, 
            header + _bearer
            )
        _process_task(task, {download_file = to_path})
        return task
    else:
        var endpoint : String = _config.supabaseUrl + _rest_endpoint + "authenticated/" + id + "/" + object
        var task : StorageTask = StorageTask.new()
        var header : PoolStringArray = [_header[0] % "application/json"]
        task._setup(
            task.METHODS.DOWNLOAD, 
            endpoint, 
            header + _bearer
            )
        _process_task(task, {download_file = to_path})
        return task        


func get_public_url(object : String) -> String:
    return _config.supabaseUrl + _rest_endpoint + "public/" + id + "/" + object


func remove(objects : PoolStringArray) -> StorageTask:
    var endpoint : String = _config.supabaseUrl + _rest_endpoint + id + ("/" + objects[0] if objects.size() == 1 else "")
    var task : StorageTask = StorageTask.new()
    var header : PoolStringArray = [_header[0] % "application/json"]
    task._setup(
        task.METHODS.REMOVE, 
        endpoint, 
        header + _bearer,
        to_json({prefixes = objects}) if objects.size() > 1 else "" )
    _process_task(task)
    return task


func _notification(what : int) -> void:
    if what == NOTIFICATION_INTERNAL_PROCESS:
        _internal_process(get_process_delta_time())

func _internal_process(_delta : float) -> void:
    if not requesting_raw:
        set_process_internal(false)
        return
    
    var task : StorageTask = _current_task
    
    match _http_client.get_status():
        HTTPClient.STATUS_DISCONNECTED:
            _http_client.connect_to_host(_config.supabaseUrl, 443, true)
        
        HTTPClient.STATUS_RESOLVING, HTTPClient.STATUS_REQUESTING, HTTPClient.STATUS_CONNECTING:
            _http_client.poll()

        HTTPClient.STATUS_CONNECTED:
            var err : int = _http_client.request_raw(task._method, task._endpoint.replace(_config.supabaseUrl, ""), task._headers, task._bytepayload)
            if err :
                task.error = SupabaseStorageError.new({statusCode = HTTPRequest.RESULT_CONNECTION_ERROR})
                _on_task_completed(task)
        
        HTTPClient.STATUS_BODY:
            if _http_client.has_response() or _reading_body:
                _reading_body = true
                
                # If there is a response...
                if _response_headers.empty():
                    _response_headers = _http_client.get_response_headers() # Get response headers.
                    _response_code = _http_client.get_response_code()
                    
                    for header in _response_headers:
                        if "Content-Length" in header:
                            _content_length = header.trim_prefix("Content-Length: ").to_int()
                
                _http_client.poll()
                var chunk : PoolByteArray = _http_client.read_response_body_chunk() # Get a chunk.
                if chunk.size() == 0:
                    # Got nothing, wait for buffers to fill a bit.
                    pass
                else:
                    _response_data += chunk # Append to read buffer.
                    if _content_length != 0:
                        pass
                if _http_client.get_status() != HTTPClient.STATUS_BODY:
                    task._on_task_completed(0, _response_code, _response_headers, [])
            else:
                task._on_task_completed(0, _response_code, _response_headers, [])
                
        HTTPClient.STATUS_CANT_CONNECT:
            task.error = SupabaseStorageError.new({statusCode = HTTPRequest.RESULT_CANT_CONNECT})
        HTTPClient.STATUS_CANT_RESOLVE:
            task.error = SupabaseStorageError.new({statusCode = HTTPRequest.RESULT_CANT_RESOLVE})
        HTTPClient.STATUS_CONNECTION_ERROR:
            task.error = SupabaseStorageError.new({statusCode = HTTPRequest.RESULT_CONNECTION_ERROR})
        HTTPClient.STATUS_SSL_HANDSHAKE_ERROR:
            task.error = SupabaseStorageError.new({statusCode = HTTPRequest.RESULT_SSL_HANDSHAKE_ERROR})


# ---

func _process_task(task : StorageTask, _params : Dictionary = {}) -> void:
    var httprequest : HTTPRequest = HTTPRequest.new()
    add_child(httprequest)
    if not _params.empty():
        httprequest.download_file = _params.get("download_file", "")
    task.connect("completed", self, "_on_task_completed")
    task.push_request(httprequest)
    _pooled_tasks.append(task)

# .............. HTTPRequest completed
func _on_task_completed(task : StorageTask) -> void:
    if task._handler : task._handler.queue_free()
    if requesting_raw:
        _clear_raw_request()
    if task.data!=null and not task.data.empty():    
        match task._code:
            task.METHODS.LIST_OBJECTS: emit_signal("listed_objects", task.data)
            task.METHODS.UPLOAD_OBJECT: emit_signal("uploaded_object", task.data)
            task.METHODS.UPDATE_OBJECT: emit_signal("updated_object", task.data)
            task.METHODS.MOVE_OBJECT: emit_signal("moved_object", task.data)
            task.METHODS.REMOVE: emit_signal("removed_objects", task.data)
            task.METHODS.CREATE_SIGNED_URL: emit_signal("created_signed_url", task.data)
            task.METHODS.DOWNLOAD: emit_signal("downloaded_object", task.data)
    elif task.error != null:
        emit_signal("error", task.error)
    _pooled_tasks.erase(task)

func _clear_raw_request() -> void:
    requesting_raw = false
    _current_task = null
    _reading_body = false
    _response_headers = []
    _response_data = []
    _content_length = -1
    _response_code = -1
    set_process_internal(requesting_raw)
    _http_client.close()
