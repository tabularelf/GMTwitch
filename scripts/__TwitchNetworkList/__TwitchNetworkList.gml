function __TwitchNetworkList() {
	static _list = ds_list_create();
	return _list;
}

function __TwitchNetworkConnectionList() {
	static _list = ds_list_create();
	return _list;
}

function __TwitchPubSubResponseList() {
	static _list = ds_list_create();
	return _list;
}

function __TwitchNetworkCallbackClass(_id, _callbackSuccess, _callbackFailure = function() {}, _nonce = "", _owner = undefined) constructor {
	static _list = __TwitchNetworkList();
	id = _id;
	callbackSuccess = _callbackSuccess;
	callbackFailure = _callbackFailure;
	nonce = _nonce;
	owner = _owner;
}

function TwitchNetworkAsync() {	
	switch(async_load[? "type"]) {
		case network_type_non_blocking_connect:	
			__TwitchNetworkHandleConnect();
		break;
		
		case network_type_data:
			__TwitchNetworkHandleData();
		break;
	}
}

function __TwitchNetworkHandleConnect() {
	static _connections = __TwitchNetworkConnectionList();
	var _id = async_load[? "id"];
	var _i = 0;
	repeat(ds_list_size(_connections)) {
		if (_connections[| _i].id == _id) {
			_connections[| _i].callbackSuccess(_connections[| _i].owner);
			ds_list_delete(_connections, _i);
			break;
		}
		++_i;
	}
}

function __TwitchNetworkHandleData() {
	static _generalList = __TwitchNetworkList();
	static _pubSubList = __TwitchPubSubResponseList();
	static _pubSubbedList = __TwitchPubSubbedList();
	
	var _id = async_load[? "id"];
	var _i = 0;
	repeat(ds_list_size(_generalList)) {
		if (_generalList[| _i].id == _id) {
			var _json = buffer_read(async_load[? "buffer"], buffer_text);
			var _struct = json_parse(_json);
			_generalList[| _i].callback(_struct);
			ds_list_delete(_generalList, _i);
			return;
		}
		++_i;
	}	
	
	_i = 0;
	repeat(ds_list_size(_pubSubbedList)) {
		if (_pubSubbedList[| _i].id == _id) {
			var _json = buffer_read(async_load[? "buffer"], buffer_text);
			var _struct = json_parse(_json);
			switch(_struct.type) {
				case "PONG":
					call_later(3, time_source_units_seconds, _pubSubbedList[| _i].__PING__);
				break;
				
				case "RESPONSE":
					__TwitchPubSubHandleResponseData(_struct);
				break;
				
				case "AUTH_REVOKED":
					__TwitchPubSubHandleResponseData(_struct);
				break;
				
				
				case "MESSAGE":
					_struct.data.message = json_parse(_struct.data.message);
					__TwitchPubSubbedHandleData(_pubSubbedList[| _i], _struct);
				break;
				
				case "RECONNECT":
					call_later(1, time_source_units_frames, method(_pubSubbedList[| _i], function() {
							
					}));
				break;
			}
			return;
		}
		++_i;
	}
}

function __TwitchPubSubbedHandleData(_owner, _struct) {
	var _topic = _struct.data.topic;
	var _subscriptions = _owner.subscriptions;
	var _index = array_find_index(_subscriptions, method({_topic}, function(_elm) {
		return array_get_index(_elm.topic, _topic) != -1;
	}));
	if (_index != -1) {
		_subscriptions[_index].callback(_struct.data);
	}
}

function __TwitchPubSubHandleResponseData(_struct) {
	static _pubSubList = __TwitchPubSubResponseList();
	var _i = 0;
	repeat(ds_list_size(_pubSubList)) {
		if (_pubSubList[| _i].nonce == _struct.nonce) {
			if (_struct.error == "") {
				_pubSubList[| _i].callbackSuccess(_struct);	
			} else {
				_pubSubList[| _i].callbackFailure(_struct);	
			}
	
			ds_list_delete(_pubSubList, _i);
			break;
		}
		++_i;
	}
}

function __TwitchPubSubHandleFailure(_struct) {
	static _pubSubList = __TwitchPubSubResponseList();
	var _i = 0;
	repeat(ds_list_size(_pubSubList)) {
		if (_pubSubList[| _i].nonce == _struct.nonce) {
			_pubSubList[| _i].callbackFailure(_struct);
			ds_list_delete(_pubSubList, _i);
			break;
		}
		++_i;
	}
}

function __TwitchNetworkSendJSON(_id, _struct) {
	var _buff = buffer_create(1, buffer_grow, 1);
	var _json = json_stringify(_struct);
	show_debug_message(_json);
	buffer_write(_buff, buffer_text, _json);
	
	network_send_raw(_id, _buff, buffer_tell(_buff), network_send_text);
	buffer_delete(_buff); 		
}