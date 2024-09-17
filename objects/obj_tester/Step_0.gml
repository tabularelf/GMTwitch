/// @description 

if (keyboard_check_pressed(vk_space)) {
	Twitch.Authorize(authorCallback);
}

if (keyboard_check_pressed(vk_control)) {
	twitch.pubSub.Disconnect(function() {
		show_debug_message("Disconnected successfully!");
	});
}