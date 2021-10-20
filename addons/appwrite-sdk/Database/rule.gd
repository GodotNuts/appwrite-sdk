extends Reference
class_name Rule

var label: String
var key: String
var type: String
var default
var required: bool
var array: bool
var list: Array

class ValidationTypes:
    const text:= "text"
    const numeric:= "numeric"
    const boolean:= "boolean"
    const wildcard:= "wildcard"
    const url:= "url"
    const email:= "email"
    const ip:= "ip"
    const document:= "document"

func _ready():
    pass # Replace with function body.

func _init(label: String, key: String, type: String, default, required:bool, array: bool, list: Array = []):
    self.label = label
    self.key = key
    self.type = type
    self.required = required
    self.array = array
    self.list = list

func _to_dict() -> Dictionary:
    return \
    {
        label = label,
        key = key,
        type = type,
        default = default,
        required = required,
        array = array,
        list = list    
    }
