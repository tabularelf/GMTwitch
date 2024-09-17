function TwitchScopes() {
	static analytics = {
		read: {
			extensions: "analytics:read:extensions",
			games: "analytics:read:games",
		},
	};
	static bits = {
		read: "bits:read",
	};
	static channel = {
		bot: "channel:bot",
		edit: {
			commercial: "channel:edit:commercial",	
		},
		manage: {
			broadcast: "channel:manage:broadcast",
			extensions: "channel:manage:extensions",
			polls: "channel:manage:polls",
			predictions: "channel:manage:predictions",
			raids: "channel:manage:raids",
			redemptions: "channel:manage:redemptions",
			schedule: "channel:manage:schedule",
			videos: "channel:manage:videos",
			vips: "channel:manage:vips",
			guest_star: "channel:manage:guest_star",
			moderators: "channel:manage:moderators",
		},
		read: {
			editors: "channel:read:editors",
			goals: "channel:read:goals",
			hype_train: "channel:read:hype_train",
			polls: "channel:read:polls",
			predictions: "channel:read:predictions",
			redemptions: "channel:read:redemptions",
			stream_key: "channel:read:stream_key",
			subscriptions: "channel:read:subscriptions",
			ads: "channel:read:ads",
			vips: "channel:read:vips",
		},
		moderate: "channel:moderate",
	};
	static chat = {
		edit: "chat:edit",
		read: "chat:read",	
	};
	static clips = {
		edit:"clips:edit"
	};
	static moderation = {
		read: {
			all: "moderation:read",
			blocked_terms: "moderation:read:blocked_terms",
			automod_settings: "moderation:read:automod_settings",
			chat_settings: "moderation:read:chat_settings",
			followers: "moderator:read:followers",
			chatters: "moderator:read:chatters",
			unban_requests: "moderator:read:unban_requests",
			guest_star: "moderator:read:guest_star",
		},
		manage: {
			banned_users:"moderation:manage:banned_users",
			blocked_terms: "moderation:manage:blocked_terms",
			automod: "moderation:manage:automod",
			chat_settings: "moderation:manage:chat_settings",
			unban_requests: "moderator:manage:unban_requests",
			shield_mode: "moderator:manage:shield_mode",
			shoutouts: "moderator:manage:shoutouts",
			blocked_terms: "moderator:manage:blocked_terms",
			announcements: "moderator:manage:announcements",
		}
	};
	static user = {
		bot: "user:bot",
		edit: "user:edit",
		manage: {
			blocked_users: "user:manage:blocked_users",	
			chat_color: "user:manage:chat_color",
			whispers: "user:manage:whispers",
		},
		read: {
			blocked_users: "user:read:blocked_users",
			broadcast: "user_read_broadcast",
			email: "user:read:email",
			subscriptions: "user:read:subscriptions",
			emotes: "user:read:emotes",
		},
		write: {
			chat: "user:write:chat",	
		}
	};
	static whispers = {
		read: "whispers:read",
		edit: "whispers:edit",
	};
}
TwitchScopes();