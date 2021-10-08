extends Node

# Modules
var account : AppwriteAccount
var database : AppwriteDatabase
var storage : AppwriteStorage


var endpoint : String = "https://appwrite.io/v1"
var headers : Dictionary = {
    "User-Agent":"Godot Engine",
    "x-sdk-version":"appwrite:gdscript:1.0.0",
    "X-Appwrite-Response-Format":"0.10.0",
    "Content-Type" : "application/json",
    "Accept-Type" : "application/json",
    "X-Appwrite-project" : "",
    "X-Appwrite-key" : ""
   }
var cookies : PoolStringArray = []

func _init() -> void:
    pass
    

func _ready() -> void:
    load_modules()


func load_modules() -> void:
    account = AppwriteAccount.new()
    database = AppwriteDatabase.new()
    
    add_child(account)
    add_child(database)
    
    

# ------ CLIENT API
func set_endpoint(endpoint : String) -> Node:
    self.endpoint = endpoint
    return self

func set_project(project : String) -> Node:
    self.headers["X-Appwrite-project"] = project
    return self

# ------ SERVER API
func set_key(key : String) -> Node:
    self.headers["X-Appwrite-key"] = key
    return self



func _get_headers() -> PoolStringArray:
    var headers_array : Array = []
    for header in headers:
        headers_array.append(header+":"+headers[header])
    return PoolStringArray(headers_array) + cookies
