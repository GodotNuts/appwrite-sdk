class_name AppwriteRealtime
extends Node

signal subscribed()
signal unsubscribed(channels)
signal received_error(error)
signal received_updates(updates)

const _BASE_URL: String = "/realtime"

var _client = WebSocketClient.new()
var subscribed_channels: Array = []

func _ready():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")

func subscribe(channels: Array) -> bool:
	var endpoint: String = get_parent().endpoint_realtime
	var project_param: String = "project=%s&" % get_parent().get_project()
	var channels_param: String = ""
	subscribed_channels += channels
	for channel in subscribed_channels: channels_param+="channels[]=%s&" % channel
	var url: String = endpoint + _BASE_URL + "?" + project_param + channels_param
	var err: int = _client.connect_to_url(url)
	set_process(!bool(err))
	return !bool(err)

func unsubscribe(channels: Array = []) -> void:
	if channels.empty():
		_client.disconnect_from_host(1000, "Client ubsubscribed.")
	else:
		for channel in channels: subscribed_channels.erase(channel)
		subscribe([])
	emit_signal("unsubscribed", channels)

func _closed(was_clean = false):
	emit_signal("received_error", { was_clean = was_clean })
	emit_signal("unsubscribed")
	set_process(false)

func _connected(proto = ""):
	emit_signal("subscribed")
	
func _on_data():
	var data: String = _client.get_peer(1).get_packet().get_string_from_utf8()
	emit_signal("received_updates", parse_json(data))

func _process(delta):
	_client.poll()

