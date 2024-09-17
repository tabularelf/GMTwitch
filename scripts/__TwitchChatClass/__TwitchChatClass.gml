function __TwitchChatClass(_owner) constructor {
	owner = _owner;
	responses = 5;
	socketId = undefined;
	
	static Connect = function(_callbackSuccess, _callbackFailure, _type = network_socket_ws) {
		socketId = network_create_socket(_type);
		network_connect_raw_async(socketId, "wss://irc-ws.chat.twitch.tv", 443);
	}
}