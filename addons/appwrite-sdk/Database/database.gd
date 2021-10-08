class_name AppwriteDatabase
extends Node

signal document_created(document)

func _init():
    pass

func _ready():
    pass

# -------- CLIENT API
func create_document(
    collection_id: String, data: Dictionary,
    read: PoolStringArray = ["*"], write: PoolStringArray = ["*"],
    parent_id: String = "", parent_property: String = "", parent_property_type: String = ""
) -> DatabaseTask:
    print(get_parent()._get_headers())
    var payload : Dictionary = {
        "data" : data,
        "read" : read, "write" : write,
        "parent_id" : parent_id, "parent_property" : parent_property, "parent_property_type" : parent_property_type
        }
    var database_task : DatabaseTask = DatabaseTask.new(
        DatabaseTask.Task.CREATE,
        get_parent().endpoint + "/database/collections/%s/documents"%collection_id, 
        get_parent()._get_headers(),
        payload
        )
    _process_task(database_task)
    return database_task

# ---------------------

# ------- SERVER API

# ---------------------


# Process a specific task
func _process_task(task : DatabaseTask, _fake : bool = false) -> void:
    task.connect("completed", self, "_on_task_completed")
    if _fake:
        yield(get_tree().create_timer(0.5), "timeout")
        task.complete(task.data, task.error)
    else:
        var httprequest : HTTPRequest = HTTPRequest.new()
        add_child(httprequest)
        task.push_request(httprequest)


func _on_task_completed(task : DatabaseTask) -> void:
    if task._handler!=null: task._handler.queue_free()
    if task.response != {}:
        match task._code:
            DatabaseTask.Task.CREATE:
                emit_signal("document_created", task.response)
            _:
                pass
    else:
        emit_signal("error", task.error)
