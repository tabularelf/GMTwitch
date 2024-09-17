/// @ignore
function __TwitchPubSubbedList() {
	static _list = ds_list_create();
	return _list;
}

function __TwitchPubSubbedClass(_topic, _callback) constructor {
	topic = _topic;
	callback = _callback;
}

function __TwitchPubSubClass(_owner) constructor {
	static _subbedList = __TwitchPubSubbedList();
	owner = _owner;
	subscriptions = [];
	maxReconnectAttempts = 60*60*2/10;
	
	id = undefined;
	ds_list_add(_subbedList, self);
	
	static Connect = function(_callbackSuccess, _callbackFailure = function() {}) {
		static _connections = __TwitchNetworkConnectionList();
		id = network_create_socket(network_socket_ws);	
		network_connect_raw_async(id, "wss://pubsub-edge.twitch.tv", 443);
		var _self = self;
		var _result = new __TwitchNetworkCallbackClass
		(
			id, 
			method({owner: _self, callback: _callbackSuccess}, function() {
				call_later(5, time_source_units_seconds, owner.__PING__);	
				callback(owner);
			}),
			_callbackFailure,
			,
			self
		);
		ds_list_add(_connections, _result);
	}
	
	static Unsubscribe = function(_topic, _callback, _channelId = owner.user_data.id, _userId = owner.user_data.id) {
		var _nonce = __TwitchUUIDv4();	
		var _self = self;
		
		var _topics = [];
		if (is_array(_topic)) {
			var _i = 0;
			repeat(array_length(_topic)) {
				_topics[_i] = __ResolveTopic(_topic[_i], _channelId, _userId);	
				++_i;
			}
		} else {
			_topics[0] = __ResolveTopic(_topic, _channelId, _userId);	
		}
		
		var _index = array_find_index(subscriptions, method({topic: _topics}, function(_elm) {
			return array_equals(_elm.topic, topic);
		}));
		
		if (_index == -1) return show_error($"Invalid topic {_topic}", true);
		
		var _result = new __TwitchNetworkCallbackClass(id, 
			method({pos: _index, owner: _self, topic: _topic}, 
			function() {
				array_delete(owner.subscriptions, pos, 1);
			}),
			_nonce
		);
		
		ds_list_add(_pubSubList, _result);
		
		__TwitchNetworkSendJSON
		(
			id, 
			{
				// Request from client to server
				 "type": "UNLISTEN",
				 "nonce": _nonce,
				 "data": {
				   "topics": _topic,
				   "auth_token": owner.token.access
				 },
			}
		);
	}
	
	static Disconnect = function(_callback) {
		static _pubSubList = __TwitchPubSubResponseList();
		
		var _i = 0;
		var _self = self;
		repeat(array_length(subscriptions)) {
			var _topic = subscriptions[_i].topic;
			Unsubscribe(_topic);
			++_i;
		}
		
		call_later(2, time_source_units_seconds, method({owner: _self, callback: _callback}, function() {
			network_destroy(owner.id);
			owner.id = undefined;
			callback();
		}));
	}
	
	static Subscribe = function(_topic, _callback, _channelId = owner.user_data.id, _userId = owner.user_data.id) {
		static _pubSubList = __TwitchPubSubResponseList();
		
		if (array_get_index(subscriptions, _topic) != -1) return undefined;
		var _nonce = __TwitchUUIDv4();	
		
		var _topics = [];
		if (is_array(_topic)) {
			var _i = 0;
			repeat(array_length(_topic)) {
				_topics[_i] = __ResolveTopic(_topic[_i], _channelId, _userId);	
				++_i;
			}
		} else {
			_topics[0] = __ResolveTopic(_topic, _channelId, _userId);	
		}
		
		var _self = self;
		var _result = new __TwitchNetworkCallbackClass
			(
			id, 
			method({owner: _self, callback: _callback, topic: is_array(_topics) ? _topics : [_topics]}, function() {
					array_push(owner.subscriptions, new __TwitchPubSubbedClass(
				topic,
				callback
				)
			);
			
		}),
		,
		_nonce
		);
		
		ds_list_add(_pubSubList, _result);
		
		
		__TwitchNetworkSendJSON
		(
			id, 
			{
				// Request from client to server
				 "type": "LISTEN",
				 "nonce": _nonce,
				 "data": {
				   "topics": _topics,
				   "auth_token": owner.token.access
				 },
			}
		);
		return self;
	}
	
		__PING__ = function() {
		if (id == undefined) return;
		var _buff = buffer_create(1, buffer_grow, 1);
		buffer_write(_buff, buffer_text, json_stringify({type: "PING"}));
		network_send_raw(id, _buff, buffer_tell(_buff), network_send_text);
		buffer_delete(_buff); 		
	};
	
	static __ResolveTopic = function(_topic, _channelId, _userId) {
		var _str = _topic;
		
		// channel id
		_str = string_replace(_str, "<channel_id>", _channelId);
		
		// user id (if any)
		_str = string_replace(_str, "<user_id>", _userId);
		
		return _str;
	}
}

function __TwitchRFC3339ToDateTime(_rfc) {
	// Not the full implementation
	// But this is what Twitch is supposedly formatted to be.
	var _rfcSplit = string_split_ext(_rfc, ["-", "T", "Z", ":"]);
	
	
	var _timezone = date_get_timezone();
	date_set_timezone(timezone_utc);
	var _date = date_create_datetime(_rfcSplit[0], _rfcSplit[1], _rfcSplit[2], _rfcSplit[3], _rfcSplit[4], _rfcSplit[5]);
	date_set_timezone(_timezone);
	return _date;
}