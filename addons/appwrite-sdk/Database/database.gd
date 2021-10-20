class_name AppwriteDatabase
extends Node

const _REST_BASE: String = "/database/collections"

signal created_document(document)
signal got_document(document)
signal updated_document(document)
signal listed_documents(list)
signal deleted_document()
signal created_collection(collection)
signal listed_collections(list)
signal got_collection(collection)
signal updated_collection(collection)
signal deleted_collection()

func _init():
    pass

func _ready():
    pass

# function builder
func __match_resource(type: int, params: Dictionary = {}) -> String:
    var resource : String = ""
    match type:
        DatabaseTask.Task.CREATE_COLLECTION, DatabaseTask.Task.LIST_COLLECTIONS: resource = _REST_BASE + ("?"+params.query if params.has("query") else "")
        DatabaseTask.Task.GET_COLLECTION, DatabaseTask.Task.UPDATE_COLLECTION, DatabaseTask.Task.DELETE_COLLECTION: resource = _REST_BASE+"/"+params.collection_id
        DatabaseTask.Task.CREATE_DOCUMENT, DatabaseTask.Task.LIST_DOCUMENTS : resource = _REST_BASE+"/"+params.collection_id+"/documents"
        DatabaseTask.Task.GET_DOCUMENT, DatabaseTask.Task.UPDATE_DOCUMENT, DatabaseTask.Task.DELETE_DOCUMENT: resource = _REST_BASE+"/"+params.collection_id+"/documents/"+params.document_id + ("?"+params.query if params.has("query") else "")
    return resource

# GET, DELETE base function
func __get(type : int, params: Dictionary = {}) -> DatabaseTask:
    var database_task : DatabaseTask = DatabaseTask.new(
        type,
        get_parent().endpoint + __match_resource(type, params), 
        get_parent()._get_headers()
    )
    _process_task(database_task)
    return database_task 

# POST, PUT, PATCH base function
func __post(type: int, payload: Dictionary = {}, params: Dictionary = {}) -> DatabaseTask:
    var database_task : DatabaseTask = DatabaseTask.new(
        type,
        get_parent().endpoint + __match_resource(type, params), 
        get_parent()._get_headers(),
        payload
        )
    _process_task(database_task)
    return database_task

# -------- CLIENT API
func create_document(
    collection_id: String, data: Dictionary,
    read: PoolStringArray = ["*"], write: PoolStringArray = ["*"],
    parent_id: String = "", parent_property: String = "", parent_property_type: String = ""
) -> DatabaseTask:
    var payload : Dictionary = {
        "data" : data,
        "read" : read, "write" : write,
        "parent_id" : parent_id, "parent_property" : parent_property, "parent_property_type" : parent_property_type
        }
    return __post(DatabaseTask.Task.CREATE_DOCUMENT, payload, { collection_id = collection_id })

func list_documents(collection_id: String, filters: String = "", order_field: String = "", order_type: String = "", order_cast: String = "", search: String = "") -> DatabaseTask:
    var query: String = ""
    if search!="": query+="search="+search
    if filters!="": query+="filters="+filters
    if order_field!="": query+="&orderField="+order_field
    if order_type!="": query+="&orderType="+order_type
    if order_cast!="": query+="&orderCast="+order_cast
    return __get(DatabaseTask.Task.LIST_DOCUMENTS, {collection_id = collection_id, query = query})

func get_document(collection_id: String, document_id: String) -> DatabaseTask:
    return __get(DatabaseTask.Task.GET_DOCUMENT, {collection_id = collection_id, document_id = document_id})

func update_document(
    document_id: String, collection_id: String, 
    data: Dictionary, read: PoolStringArray = ["*"], write: PoolStringArray = ["*"]
) -> DatabaseTask:
    var payload : Dictionary = {
        "data" : data,
        "read" : read, "write" : write,
        }
    return __post(DatabaseTask.Task.UPDATE_DOCUMENT, payload, { collection_id = collection_id, document_id = document_id })

func delete_document(collection_id: String, document_id: String) -> DatabaseTask:
    return __post(DatabaseTask.Task.DELETE_DOCUMENT, {}, { collection_id = collection_id, document_id = document_id })

# ------- SERVER API
func create_collection(
    collection_name: String,
    read: PoolStringArray, write: PoolStringArray, rules: Array
   ) -> DatabaseTask:
    var _rules : Array = []
    for rule in rules:
        _rules.append(rule._to_dict())
    var payload : Dictionary = {
        "name" : collection_name,
        "$permissions" : {"read" : read, "write" : write},
        "rules" : _rules
        }
    return __post(DatabaseTask.Task.CREATE_COLLECTION, payload)

func list_collections(search: String = "", limit: int = 0, offset: int = 0, order_type: String = "") -> DatabaseTask:
    var query: String = ""
    if search!="": query+="search="+search
    if limit!=0: query+="&limit="+str(limit)
    if offset!=0: query+="&offset="+str(offset)
    if order_type!="": query+="&orderType="+order_type
    return __get(DatabaseTask.Task.LIST_COLLECTIONS, {query = query})

func get_collection(collection_id: String) -> DatabaseTask:
    return __get(DatabaseTask.Task.GET_COLLECTION, {collection_id = collection_id})

func update_collection(
    collection_id: String, collection_name: String,
    read: PoolStringArray = [], write: PoolStringArray = [], rules: PoolStringArray = []
   ) -> DatabaseTask:
    var payload : Dictionary = { "name" : collection_name }
    if not read.empty() : payload["$permissions"]["read"] = read
    if not write.empty() : payload["$permissions"]["write"] = write
    if not rules.empty() : payload["rules"] = rules
    return __post(DatabaseTask.Task.UPDATE_COLLECTION, payload, {collection_id = collection_id})

func delete_collection(collection_id: String) -> DatabaseTask:
    return __post(DatabaseTask.Task.DELETE_COLLECTION, {}, {collection_id = collection_id})


# Process a specific task
func _process_task(task : DatabaseTask, _fake : bool = false) -> void:
    task.connect("completed", self, "_on_task_completed", [task])
    if _fake:
        yield(get_tree().create_timer(0.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task_response: TaskResponse, task : DatabaseTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        var _signal: String = ""
        match task._code:
            DatabaseTask.Task.CREATE_COLLECTION:
                _signal = "created_collection"
            DatabaseTask.Task.CREATE_DOCUMENT:
                _signal = "created_document"
            DatabaseTask.Task.LIST_COLLECTIONS:
                _signal = "listed_collections"
            DatabaseTask.Task.LIST_DOCUMENTS:
                _signal = "listed_documents"
            DatabaseTask.Task.GET_COLLECTION:
                _signal = "got_collection"
            DatabaseTask.Task.GET_DOCUMENT:
                _signal = "got_document"
            DatabaseTask.Task.DELETE_COLLECTION:
                _signal = "deleted_collection"
            DatabaseTask.Task.DELETE_DOCUMENT:
                _signal = "deleted_document"
            DatabaseTask.Task.UPDATE_COLLECTION:
                _signal = "updated_collection"
            DatabaseTask.Task.UPDATE_DOCUMENT:
                _signal = "updated_document"
            _:
                pass
        emit_signal(_signal, task.response)
    else:
        emit_signal("error", task.error)
