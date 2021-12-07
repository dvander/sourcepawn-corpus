#define PLUGIN_VERSION "2.0"

public Plugin:myinfo = {
	name = "Password reset",
	author = "mad_hamster",
	description = "Resets the password when the server gets empty",
	version = PLUGIN_VERSION,
	url = "http://pro-css.co.il"
};


static Handle:password_reset_threshold;
static Handle:password_publish_change;
static Handle:password_change_admin_flag;



public OnPluginStart() {
	CreateConVar("password_reset", PLUGIN_VERSION, "password_reset version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	password_reset_threshold   = CreateConVar("password_reset_threshold",   "3", "Number of human players on the server above which the password is not reset. E.g. -1 disables resets, 3 will reset password whenever 3 players or less are present.");
	password_publish_change    = CreateConVar("password_publish_change",    "3", "Whether to publish server password when it changes. 0 = Off, 1+ = number of prints to chat");
	password_change_admin_flag = CreateConVar("password_change_admin_flag", "l", "Admin flag required to use the /pw command to change the server password. Useful if you don't want to give your admins access to sm_cvar.");
	AutoExecConfig();
	
	HookConVarChange(FindConVar("sv_password"), OnPasswordChanged);
	CreateTimer(1.0, OnCheckPassword, _, TIMER_REPEAT);
}



public OnConfigsExecuted() {
	decl String:admin_flags_str[10];
	GetConVarString(password_change_admin_flag, admin_flags_str, sizeof(admin_flags_str));
	new admin_flags = ReadFlagString(admin_flags_str);
	if (admin_flags > 0)
		RegAdminCmd("pw", OnPasswordCmd, admin_flags, "pw password");
}



CountHumanPlayers() {
	new human_players = 0;
	for (new client=1; client<=MaxClients; ++client)
		if (IsClientInGame(client) && !IsFakeClient(client))
			++human_players;
	return human_players;
}



public Action:OnCheckPassword(Handle:timer) {
	decl String:pword[64];
	GetConVarString(FindConVar("sv_password"), pword, sizeof(pword));
	if (strlen(pword) > 0 && CountHumanPlayers() <= GetConVarInt(password_reset_threshold)) {
		PrintToChatAll("\x03Server password removed since there are %d players or less",
			GetConVarInt(password_reset_threshold));
		SetConVarString(FindConVar("sv_password"), "");
	}
}



public OnPasswordChanged(Handle:cvar, const String:oldval[], const String:newval[]) {
	for (new i=GetConVarInt(password_publish_change); i>0; --i)
		PrintToChatAll("\x03Server password is now '\x01%s\x03'", newval);
}



public Action:OnPasswordCmd(client, num_args) {
	if (num_args != 1) {
		ReplyToCommand(client, "Usage: pw password");
		return Plugin_Handled;
	}
	
	else if (CountHumanPlayers() <= GetConVarInt(password_reset_threshold)) {
		ReplyToCommand(client, "You can't put a password with %d or less players",
			GetConVarInt(password_reset_threshold));
		return Plugin_Handled;
	}
	
	else {
		decl String:quoted_arg[32], String:arg[32];
		GetCmdArgString(quoted_arg, sizeof(quoted_arg));
		BreakString(quoted_arg, arg, sizeof(arg));
		SetConVarString(FindConVar("sv_password"), arg);
		return Plugin_Handled;
	}
}
