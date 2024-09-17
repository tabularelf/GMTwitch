function TwitchPubSubs() {
	
	static bits = "channel-bits-events-v2.<channel_id>";
	static bitsBadge = "channel-bits-badge-unlocks.<channel_id>";
	static points = "channel-points-channel-v1.<channel_id>";
	static subscriptions = "channel-subscribe-events-v1.<channel_id>";
	static chat = "automod-queue.<channel_id>";
	static modActions = "chat_moderator_actions.<channel_id>.<user_id>";
	static lowTrustedUsers = "low-trust-users.<channel_id>.<user_id>";
	static autoModNotification = "user-moderation-notifications.<user_id>.<channel_id>";
	static whispers = "whispers.<user_id>";
}
TwitchPubSubs();