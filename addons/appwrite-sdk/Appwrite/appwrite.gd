extends Node

# Modules
var account : AppwriteAccount
var users : AppwriteUsers
var teams : AppwriteTeams
var database : AppwriteDatabase
var storage : AppwriteStorage
var functions : AppwriteFunctions
var locale : AppwriteLocalization
var avatars : AppwriteAvatars
var health : AppwriteHealth
var realtime : AppwriteRealtime

var endpoint: String = "https://appwrite.io/v1"
var endpoint_realtime: String = ""
var cookies : PoolStringArray = []
var headers : Dictionary = {
	"Content-Type" : "application/json",
	"X-SDK-Version":"appwrite:gdscript:1.5.0",
	"X-Appwrite-Response-Format":"0.11.0",
	"X-Appwrite-Project" : "",
	"X-Appwrite-Key" : "",
	"X-Appwrite-JWT" : "",
	"X-Appwrite-Locale" : "",
	"X-Fallback-Cookies" : ""
	}

func _init() -> void:
	pass

func _ready() -> void:
	load_modules()


func load_modules() -> void:
	account = AppwriteAccount.new()
	users = AppwriteUsers.new()
	teams = AppwriteTeams.new()
	database = AppwriteDatabase.new()
	storage = AppwriteStorage.new()
	functions = AppwriteFunctions.new()
	locale = AppwriteLocalization.new()
	avatars = AppwriteAvatars.new()
	health = AppwriteHealth.new()
	realtime = AppwriteRealtime.new()
	
	add_child(account)
	add_child(users)
	add_child(teams)
	add_child(database)
	add_child(storage)
	add_child(functions)
	add_child(locale)
	add_child(avatars)
	add_child(health)
	add_child(realtime)


# ------ CLIENT API
func set_endpoint(endpoint : String) -> Node:
	self.endpoint = endpoint
	set_endpoint_realtime(endpoint.replace("http","ws"))
	return self

func set_endpoint_realtime(endpoint_realtime: String) -> Node:
	self.endpoint_realtime = endpoint_realtime
	return self

func set_project(project : String) -> Node:
	self.headers["X-Appwrite-project"] = project
	return self

func get_project() -> String:
	return self.headers["X-Appwrite-project"]

func set_locale(locale: String) -> Node:
	self.headers["X-Appwrite-Locale"] = locale
	return self

# ------ SERVER API
func set_key(key : String) -> Node:
	self.headers["X-Appwrite-key"] = key
	return self

func get_key() -> String:
	return self.headers["X-Appwrite-key"]

func set_jwt(jwt : String) -> Node:
	self.headers["X-Appwrite-JWT"] = jwt
	return self


func _get_headers() -> PoolStringArray:
	var headers_array : Array = []
	for header in headers:
		if headers[header] != "": headers_array.append(header+":"+headers[header])
	return PoolStringArray(headers_array) + cookies
