extends Reference
class_name TaskResponse


var response : Dictionary
var error : Dictionary
var cookies : Array

func _init(response: Dictionary, error: Dictionary, cookies: Array = []):
	self.response = response
	self.error = error
	self.cookies = cookies
