function Twitch() constructor {
	static data = new (function() constructor {
		client_id  ="";
		client_secret = "";
		scopes = "";
		scope_lut = {};
		redirect_uri = "http://localhost:3000";
		instance = undefined;
		ready = false;
		port = 3000;
		token = {
			access:"",
			refresh:"",
			expires_at:0,
		}
		user_data = {
			broadcaster_type:"",
			created_at: "",
			description: "",
			display_name:"",
			email: "",
			id:0,
			login:"",
			profile_image_url:"",
			type: "",
			view_count: 0,
		};
		polls = [];
		goals = [];
		save_token_fn = undefined;
		load_token_fn = undefined;
	})();
	
	static PubSub = new __TwitchPubSubClass(data);
	static Chat = undefined;
	static Init = function(_client_id,_client_secret,_scopes,_port=3000) {
		Twitch.data.instance = instance_create_depth(0,0,0,obj_twitch);
		Twitch.data.client_id =_client_id;
		Twitch.data.client_secret =_client_secret;
		Twitch.data.scopes = url_encode(array_join(_scopes," "));
		for (var i=0;i<array_length(_scopes);i++) {
			Twitch.data.scope_lut[$ _scopes[i]] = true;
		}
		Twitch.data.port = _port;
		Twitch.data.redirect_uri = "http://localhost:"+string(Twitch.data.port) + "/";
		
	}
	static Authorize = function(cb=function(){}) {
		var auth_url = "https://id.twitch.tv/oauth2/authorize?";
		var querystring = qs_encode({
			response_type: "code",
			client_id: Twitch.data.client_id,
			redirect_uri: Twitch.data.redirect_uri,
			scope: Twitch.data.scopes,
		});
		url_open(auth_url + querystring);
		Twitch.data.instance.setup_http_server(Twitch.data.port,cb);
	}
	static __ApiHeaders = function(){
		return struct_to_map({
			"Authorization": "Bearer " + Twitch.data.token.access,
			"Client-ID": Twitch.data.client_id,
		});
	}
	static exchange_code = function(code,cb) {
		var body = qs_encode({
			client_id: Twitch.data.client_id,
			client_secret: Twitch.data.client_secret,
			code: code,
			grant_type: "authorization_code",
			redirect_uri: Twitch.data.redirect_uri,
		});
		
		var map = ds_map_create();
		map[? "Content-Type"] = "application/x-www-form-urlencoded";
		var options = {
			headers: map,
			keep_header_map: false,
			callback: cb,
		}
		http("https://id.twitch.tv/oauth2/token","POST",body,options,function(status,result,options) {
			result = json_parse(result);
			Twitch.data.token.access = result.access_token;
			Twitch.data.token.refresh = result.refresh_token;
			// token is expired after this time
			Twitch.data.token.expires_at = date_inc_second(date_current_datetime(),real(result.expires_in));
			// yup, we're passing this along further
			get_user_data(options.callback);
		});
	}
	static get_user_data = function(cb=function(){}){
		var options = {
			headers: __ApiHeaders(),
			callback: cb,
		}
		http("https://api.twitch.tv/helix/users","GET","",options,function(status,result,options){
			result = json_parse(result);
			if (result[$ "data"] != undefined) {
				var _data = Twitch.data;
				result = result.data[0];
				_data.user_data.broadcaster_type = result.broadcaster_type;
				_data.user_data.created_at = result.created_at;
				_data.user_data.description = result.description;
				_data.user_data.display_name = result.display_name;
				_data.user_data.email = result[$ "email"] == undefined ? "" : result.email;
				// feather ignore once GM1008
				_data.user_data.id = result.id;
				_data.user_data.login = result.login;
				_data.user_data.profile_image_url = result.profile_image_url;
				_data.user_data.type = result.type;
				//Twitch.data.user_data.view_count = result.view_count;
				options.callback(_data.user_data);
			}
		});
	}
	static update_user = function(new_data={},cb=function(){}) {
		var query = qs_encode(new_data);
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		};
		http("https://api.twitch.tv/helix/users" + "?" + query,"PUT","",options,function(status,result,options){
			if (status == 200) {
				
				options.callback();	
			}
		});
	}
	static get_user_followers = function(user_id=Twitch.data.user_data.id,cb=function(){}) {
		// Gets all users that *follow* a channel
		// Has pagination. Needs handling. 
		
		var query = qs_encode({
			broadcaster_id: user_id,
			first: 100
		})
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/channels/followers" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) { 
				options.callback(result);
			} else {
				show_debug_message(json_stringify(result, true));	
			}
		});
	}
	
	static get_vips = function(user_id=Twitch.data.user_data.id,cb=function(){}) {
		// Gets all users that *follow* a channel
		// Has pagination. Needs handling. 
		
		var query = qs_encode({
			broadcaster_id: user_id,
			first: 100
		})
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/channels/vips" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) { 
				options.callback(result);
			} else {
				show_debug_message(json_stringify(result, true));	
			}
		});
	}
	
	static send_message = function(contents, user_id = Twitch.data.user_data.id,cb=function(){}) {
		var query = qs_encode({
			broadcaster_id: user_id,
			sender_id: user_id,
			message: contents,
		})
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/chat/messages" + "?" + query,"POST","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) { 
				options.callback(result);
			} else {
				show_debug_message(json_stringify(result, true));	
			}
		});
	}
	
	static send_announcement = function(contents, _col = "primary", broadcaster_id = Twitch.data.user_data.id, moderator_id = Twitch.data.user_data.id,cb=function(){}) {
		var query = qs_encode({
			broadcaster_id: broadcaster_id,
			moderator_id: moderator_id,
			message: contents,
			color: _col,
		});
		var options = {
			headers: struct_to_map({
				"Authorization": "Bearer " + Twitch.data.token.access,
				"Client-ID": Twitch.data.client_id,
				"Content-Type": "application/x-www-form-urlencoded",
			}),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/chat/announcements" + "?" + query,"POST","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 204) { 
				options.callback(result);
			} else {
				show_debug_message(json_stringify(result, true));	
			}
		});
	}
	
	static get_custom_reward = function(user_id=Twitch.data.user_data.id,cb=function(){}) {
		// Gets all users that *follow* a channel
		// Has pagination. Needs handling. 
		
		var query = qs_encode({
			broadcaster_id: user_id,
		})
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/channel_points/custom_rewards" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) { 
				options.callback(result);
			} else {
				show_debug_message(json_stringify(result, true));	
			}
		});
	}
	
	static get_users = function(user_id=Twitch.data.user_data.login,cb=function(){}) {
		// Gets all users that *follow* a channel
		// Has pagination. Needs handling. 
		
		var query = qs_encode({
			login: user_id,
		})
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/users" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) { 
				options.callback(result);
			} else {
				show_debug_message(json_stringify(result, true));	
			}
		});
	}
	
	static get_ad_schedule = function(user_id=Twitch.data.user_data.id,cb=function(){}) {
		// Gets all users that *follow* a channel
		// Has pagination. Needs handling. 
		
		var query = qs_encode({
			broadcaster_id: user_id
		})
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/channels/ads" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) { 
				options.callback(result);
			} else {
				show_debug_message(json_stringify(result, true));	
			}
		});
	}
	static get_user_follow = function(user_id=Twitch.data.user_data.id,cb=function(){}) {
		// Gets all channels that a single user follows
		// Has pagination. Needs handling. 
		
		var query = qs_encode({
			from_id: user_id
		})
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/users/follows" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) { 
				options.callback(result);
			}
		});
	}
	static get_user_blocklist = function(cb) {
		var query = qs_encode({
			broadcaster_id: user_data.id,
		});
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/users/blocks" + "?" + query,"GET","",function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				options.callback(result);
			}
		});
	}
	static block_user = function(user_id,reason="",source_context="",cb=function(){}) {
		
		var query = {
			target_user_id: user_id
		}
		if (array_pos(["spam","harassment","other"],reason) == -1) {
			query.reason = reason;
		}
		if (array_pos(["whisper","chat",],source_context) == -1) {
			query.source_context = source_context;
		}
		// feather ignore once GM1043
		query = qs_encode(query);
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		};
		// feather ignore once GM1009
		http("https://api.twitch.tv/helix/users/blocks" + "?" + query,"PUT","",options,function(status,result,options){
			// returns 204 on success - there is no result
			if (status == 204) {
				options.callback();	
			}
		});
	}
	static get_user_extensions = function(cb=function(){}) {
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		http("https://api.twitch.tv/helix/users/extensions/list","GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				options.callback(result.data);
			}
		});
	}
	static refresh_access_token = function(cb) {
		var body = qs_encode({
			client_id: Twitch.data.client_id,
			client_secret: Twitch.data.client_secret,
			refresh_token: Twitch.data.token.refresh,
			grant_type: "refresh-token",
		});
		var options = {
			headers: struct_to_map({
				"Content-Type": "application/x-www-form-urlencoded"
			}),
			keep_header_map: false,
			callback: cb,
		}
		http("https://id.twitch.tv/oauth2/token","POST",body,options,function(status,result,options) {
			show_message(json_parse(result));
		});	
	}
	
	static set_save_token_function = function(fn){
		Twitch.data.save_token_fn= fn;
	}
	static set_load_token_function = function(fn) {
		Twitch.data.load_token_fn = fn;
	}
	static save_token = function() {
		if (Twitch.data.save_token_fn != undefined) {
			Twitch.data.save_token_fn(token);	
			return;
		}
		// otherwise, default save
		var str = json_stringify({refresh_token: data.token.refresh});
		var buff = buffer_create(string_length(str),buffer_fixed,1);
		buffer_write(buff,buffer_text,str);
		buffer_save(buff,"twitch-token.json");
		buffer_delete(buff);
		
	}
	static load_token = function() {
		if (Twitch.data.load_token_fn != undefined) {
			var loaded_token = Twitch.data.load_token_fn();
			///
			return;
		}
		if (file_exists("twitch-token.json")) {
			var buff = buffer_load("twitch-token.json");
			var str = buffer_read(buff,buffer_text);
			var json = json_parse(str);
			Twitch.data.token.refresh = json.refresh_token;
		} else {
			// file doesn't exist, maybe throw or something
			throw {
				error: "file-not-found",
				description: "File 'twitch-token.json' not found"
			}
		}
	}
	static create_poll = function(title, choices, duration, options={bits_voting_enabled: false, bits_per_vote: 0, channel_points_voting_enabled: false, channel_points_per_vote: 0},cb=function(){}){
		var body = {
			title: title,
			choices: choices,
			duration: duration,
		}
		if (options.bits_voting_enabled == true) {
			body.bits_voting_enabled = true;
			body.bits_per_vote = options.bits_per_vote;
		}
		if (options.channel_points_voting_enabled == true) {
			body.channel_points_voting_enabled = true;
			body.channel_points_per_vote = options.channel_points_per_vote;
		}
		var http_options = {
			headers: __ApiHeaders(),
			keep_header_map: false,	
			callback:cb,
		}
		http("https://api.twitch.tv/helix/polls","POST",json_stringify(body),http_options,function(status,result,options){
			if (status == "200") {
				result = json_parse(result);
				result = result.data[0];
				// sends poll data back out - could replace with constructor?
				var poll = new TwitchPoll(result,self);
				options.callback(result);	
			}
			
		});
	}
	
	static get_polls = function(cb=function(){},after=0,num=0) {
		var query = qs_encode({
			broadcaster_id: Twitch.data.user_data.id,
			after: after,
			first: num,
		});
		var options = {
			headers: __ApiHeaders(),
			keep_header_map: false,
			callback: cb,
		}
		
		http("https://api.twitch.tv/helix/polls" + "?" + query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				var found_polls = [];
				for (var i=0;i<array_length(result.data);i++) {
					var ind = -1;
					for (var j=0;j<array_length(Twitch.data.polls);j++) {
						if (result.data[i].id == Twitch.data.polls[j].id) {
							ind = j;
							break;
						}
					}
					if (ind == -1) {
						array_push(Twitch.data.polls,new TwitchPoll(result.data[i],self));
					} else {
						Twitch.data.polls[i].update_choices(result.data[i].choices);
					}
				}
				options.callback(Twitch.data.polls);
			}
		});
		
	function get_goals(cb) {
		var query = qs_encode({
			broadcaster_id: user_data.id,
		});
		var options = {
			headers: __ApiHeaders(),
			keep_header_map:false,
			callback: cb,
		};
		http("https://api.twitch.tv/helix/goals"+"?"+query,"GET","",options,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				var found_goals = [];
				for (var i=0;i<array_length(result.data);i++) {
					var ind = -1;
					for (var j=0;j<array_length(goals);j++) {
						if (result.data[i].id == goals[j].id) {
							ind = j;
							break;
						}
					}
					if (ind == -1) {
						// feather ignore once GM1058
						array_push(goals,new TwitchGoal(result.data[i],self));
					} else {
						goals[ind].type = result.data[i].type;
						goals[ind].description = result.data[i].description;
						goals[ind].current_amount = result.data[i].current_amount;
						goals[ind].target_amount = result.data[i].target_amount;
					}
				}
			}
		});
	}

}
}
Twitch();
/// @param data Struct
/// @param parent Struct.Twitch
function TwitchPoll(data,parent) constructor {
	// feather ignore once GM1008
	id = data.id;	
	title = data.title;
	choices = [];
	for (var i=0;i<array_length(data.choices);i++) {
		array_push(choices,{
			id: data.choices[i].id,
			title: data.choices[i].title,
			votes: data.choices[i].votes,
			channel_points_votes: data.choices[i].channel_points_votes,
			bits_votes: data.choices[i].bits_votes,
		});	
	}
	bits_voting_enabled = data.bits_voting_enabled;
	bits_per_vote = data.bits_per_vote;
	channel_points_voting_enabled = data.channel_points_voting_enabled;
	channel_points_per_vote = data.channel_points_per_vote;
	status = data.status;
	duration = data.duration;
	started_at = data.started_at;
	client = parent;
	
	function update_choices(updated) {
		for (var i=0;i<array_length(updated);i++) {
			for (var j=0;j<array_length(choices);j++) {
					if (updated[i].id == choices[j].id) {
					choices[j].title = updated[i].title;
					choices[j].votes = updated[i].votes;
					choices[j].channel_points_votes = updated[i].channel_points_votes;
					choices[j].bits_votes = updated[i].bits_votes;
					break;
				}
			}
		}
	}
	
	function end_poll(cb) {
		var body = {
			broadcaster_id: client.user_data.id,
			id:id,
			status: "TERMINATED",
		};
		var options = {
			headers: client.__ApiHeaders(),
			keep_header_map: false,
		};
		http("https://api.twitch.tv/helix/polls","PATCH",body,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				result = result.data[0];
				status = result.status;
				update_choices(result.choices);
			}
		});
	}
	
	function archive_poll(cb) {
		var body = {
			broadcaster_id: client.user_data.id,
			id:id,
			status: "ARCHIVED",
		};
		var options = {
			headers: client.__ApiHeaders(),
			keep_header_map: false,
		};
		http("https://api.twitch.tv/helix/polls","PATCH",body,function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				result = result.data[0];
				status = result.status;
				update_choices(result.choices);
			}
		});
	}
	
	function update_poll(cb){
		var query = qs_encode({
			broadcaster_id: client.user_data.id,
			id:id,
		});
		var options = {
			headers: client.__ApiHeaders(),
			keep_header_map: false,
		};
		http("https://api.twitch.tv/helix/polls"+"?"+query,"GET",function(status,result,options){
			result = json_parse(result);
			if (status == 200) {
				result = result.data[0];
				status = result.status;
				update_choices(result.choices);
			}
		});
	}
}

/// @param data Struct
/// @param parent Struct.Twitch
function TwitchGoal(data,parent) constructor {
	// feather ignore once GM1008
	id = data.id;
	type = data.type;
	description = data.description;
	current_amount = data.current_amount;
	target_amount = data.target_amount;
	created_at = data.created_at;
	client = parent;
}


