class_name AppwriteTeams
extends Node

const _REST_BASE: String = "/teams"

var _cookies : PoolStringArray = []

signal task_response(task_response)
signal success(response)
signal got(team)
signal created(team)
signal listed(teams)
signal deleted(team)
signal updated(team)
signal created_membership(membership)
signal got_membership(membership)
signal updated_membership_roles(membership)
signal deleted_membership(membership)
signal updated_membership_status(membership)

func _init():
	pass

func _ready():
	pass


# function builder
func __match_resource(type: int, params: Dictionary = {}) -> String:
	var resource : String = ""
	match type:
		TeamsTask.Task.LIST, TeamsTask.Task.CREATE, TeamsTask.Task.DELETE: resource = _REST_BASE
		TeamsTask.Task.GET, TeamsTask.Task.UPDATE, TeamsTask.Task.DELETE: resource = _REST_BASE + "/" + params.team_id
		TeamsTask.Task.CREATE_MEMBERSHIP, TeamsTask.Task.GET_MEMBERSHIPS: resource = _REST_BASE + "/" + params.team_id + "/memberships" + (params.query if params.has("query") else "")
		TeamsTask.Task.UPDATE_MEMBERSHIP_ROLES, TeamsTask.Task.UPDATE_MEMBERSHIP_STATUS, TeamsTask.Task.DELETE_MEMBERSHIP: resource = _REST_BASE + "/" + params.team_id + "/memberships/" + params.membership_id
	return resource

# GET, DELETE base function
func __get(type : int, params: Dictionary = {}) -> TeamsTask:
	var functions_task : TeamsTask = TeamsTask.new(
		type,
		get_parent().endpoint + __match_resource(type, params), 
		get_parent()._get_headers()
	)
	_process_task(functions_task)
	return functions_task 


# POST, PUT, PATCH base function
func __post(type: int, payload: Dictionary = {}, params: Dictionary = {}) -> TeamsTask:
	var function_task : TeamsTask = TeamsTask.new(
		type,
		get_parent().endpoint + __match_resource(type, params), 
		get_parent()._get_headers(),
		payload
		)
	_process_task(function_task)
	return function_task


# -------- CLIENT/SERVER API
func create(name: String, roles: Array = []) -> TeamsTask:
	return __post(TeamsTask.Task.CREATE, { name = name, roles = roles })

func delete(team_id: String) -> TeamsTask:
	return __get(TeamsTask.Task.DELETE, { team_id = team_id })

func list() -> TeamsTask:
	return __get(TeamsTask.Task.LIST)

func get_team(team_id: String) -> TeamsTask:
	return __get(TeamsTask.Task.GET, { team_id = team_id })
	
func get_logs() -> TeamsTask:
	return __get(TeamsTask.Task.GET_LOGS)

func update(team_id: String, name: String) -> TeamsTask:
	return __post(TeamsTask.Task.UPDATE, { name = name }, { team_id = team_id })

func create_membership(team_id: String, email: String, roles: Array, url: String, name: String = "") -> TeamsTask:
	return __post(TeamsTask.Task.CREATE_MEMBERSHIP, { email = email, name = name, roles = roles, url = url }, { team_id = team_id })
	
func update_membership_roles(team_id: String, membership_id: String, roles: Array) -> TeamsTask:
	return __post(TeamsTask.Task.UPDATE_MEMBERSHIP_ROLES, { roles = roles }, { team_id = team_id, membership_id = membership_id })

func get_memberships(team_id: String, search: String = "", limit: int = 0, offset: int = 0, order_by: String = "") -> TeamsTask:
	var query: String = "?"
	if search!="": query+="search="+search
	if limit!=0: query+="&limit="+str(limit)
	if offset!=0: query+="&offset="+str(offset)
	if order_by!="": query+="&orderBy="+order_by
	return __get(TeamsTask.Task.GET_MEMBERSHIPS, {team_id = team_id, query = query})

func update_membership_status(team_id: String, membership_id: String, user_id: String, secret: String) -> TeamsTask:
	return __post(TeamsTask.Task.UPDATE_MEMBERSHIP_STATUS, { userId = user_id, secret = secret }, { team_id = team_id, membership_id = membership_id })

func delete_membership(team_id: String, membership_id: String, roles: Array) -> TeamsTask:
	return __get(TeamsTask.Task.DELETE_MEMBERSHIP, { team_id = team_id, membership_id = membership_id })	


# Process a specific task
func _process_task(task : TeamsTask, _fake : bool = false) -> void:
	task.connect("completed", self, "_on_task_completed", [task])
	if _fake:
		yield(get_tree().create_timer(0.5), "timeout")
		task.complete(task.data, task.error)
	else:
		var httprequest : HTTPRequest = HTTPRequest.new()
		add_child(httprequest)
		task.push_request(httprequest)


func _on_task_completed(task_response: TaskResponse, task: TeamsTask) -> void:
	if task._handler!=null: task._handler.queue_free()
	if task.response != {}:
		var _signal : String = ""
		match task._code:
			TeamsTask.Task.GET: _signal = "got"
			TeamsTask.Task.CREATE: _signal = "created"
			TeamsTask.Task.LIST: _signal = "listed"
			TeamsTask.Task.UPDATE: _signal = "updated"
			TeamsTask.Task.DELETE: _signal = "deleted"
			TeamsTask.Task.CREATE_MEMBERSHIP : _signal = "created_membership"
			TeamsTask.Task.UPDATE_MEMBERSHIP_ROLES : _signal = "updated_membership_roles"
			TeamsTask.Task.GET_MEMBERSHIPS : _signal = "got_membership"
			TeamsTask.Task.UPDATE_MEMBERSHIP_STATUS : _signal = "updated_membership_status"
			TeamsTask.Task.DELETE_MEMBERSHIP : _signal = "deleted_membership"
			_: _signal = "success"
		emit_signal(_signal, task.response)
	else:
		emit_signal("error", task.error)
	emit_signal("task_response", task_response)

