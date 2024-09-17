/// @description 

//show_message(url_parse("http://localhost:3000/?code=gulfwdmys5lsm6qyz4xiz9q32l10&scope=channel%3Amanage%3Apolls+channel%3Aread%3Apolls&state=c3ab8aa609ea11e793ae92361f002671"));

// user:read:email channel:read:subscriptions channel:manage:polls bits:read
var scopes = [
	TwitchScopes.user.read.email,
	TwitchScopes.channel.read.subscriptions,
	TwitchScopes.channel.manage.polls,
	TwitchScopes.channel.manage.predictions,
	TwitchScopes.bits.read,
	TwitchScopes.moderation.read.followers,
	TwitchScopes.channel.read.ads,
	TwitchScopes.channel.read.vips,
	TwitchScopes.channel.read.redemptions,
	TwitchScopes.user.write.chat,
	TwitchScopes.channel.bot,
	TwitchScopes.moderation.manage.announcements
];

authorCallback = function(user){
	state = "user";
	//Twitch.save_token();
	ts = call_later(5, time_source_units_seconds, function() {
		Twitch.get_ad_schedule(,function(result) {
			show_debug_message(result);	
			duration = result.data[0].duration;
			//show_debug_message(date_second_span(TwitchUnixTimeToDatetime(result.data[0].next_ad_at), date_current_datetime()));
			timestamp = TwitchUnixTimeToDatetime(result.data[0].next_ad_at);
		});
	}, true);
	//Twitch.send_announcement("Hello World!", TwitchColors.blue);
	//Twitch.PubSub.Connect(function() {
	//	Twitch.PubSub.Subscribe(TwitchPubSubs.points, function(_result) {
	//		show_debug_message(_result);
	//	});
	//});
}

var buff = buffer_load("./keys.json");
var keys = json_parse(buffer_read(buff,buffer_text));
var client_id = keys.client_id;
var client_secret = keys.client_secret;

Twitch.Init(client_id,client_secret,scopes,1234);

// Try refreshing existing tokens
try {
	Twitch.load_token();
	//Twitch.refresh_access_token(authorCallback);
} catch(_) {
	show_debug_message("Token wasn't saved yet!");	
}


state = "start";

socket = network_create_socket(network_socket_ws);