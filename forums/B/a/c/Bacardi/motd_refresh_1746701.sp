public Plugin:myinfo = 
{
	name = "MOTD window refresh. Valve fix this crap!!",
	description = "Refresh player MOTD window when spawn server",
	url = "https://forums.alliedmods.net/showthread.php?t=189158"
};

public OnPluginStart()
{
	HookEventEx("player_activate", activate);
}

public activate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	ShowMOTDPanel(GetClientOfUserId(userid), "Refresh MOTD", "http://www.google.com/images/errors/robot.png", MOTDPANEL_TYPE_URL);
	CreateTimer(1.0, delay, userid);
}

public Action:delay(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client != 0)
	{
		//ShowMOTDPanel(client, "Message Of The Day", "motd", MOTDPANEL_TYPE_INDEX); // Command button OK in action.
		new Handle:Kv = CreateKeyValues("data");
		KvSetString(Kv,	"title",		"Message Of The Day");
		KvSetNum(Kv,	"type",			MOTDPANEL_TYPE_INDEX);
		KvSetString(Kv,	"msg",			"motd");
		KvSetNum(Kv,	"cmd",			1); // Hope this work any game mod
		ShowVGUIPanel(client, "info",	Kv);
		CloseHandle(Kv);
	}
}