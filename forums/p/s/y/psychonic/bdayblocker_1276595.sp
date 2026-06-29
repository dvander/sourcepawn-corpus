#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name = "Birthday Blocker",
	author = "psychonic",
	description = "Fully disables birthday mode when tf_birthday is 0",
	version = "1.0",
	url = "http://www.hlxce.com"
};

new Handle:g_version;
new Handle:g_birthday;

public OnPluginStart()
{
	g_version = CreateConVar("birthday_blocker_version", "1.0", "Birthday Blocker Version", FCVAR_NOTIFY);
	g_birthday = FindConVar("tf_birthday");
	if (g_birthday == INVALID_HANDLE)
	{
		SetFailState("tf_birthday not found! (this shouldn't happen...)");
	}
}

public OnConfigsExecuted()
{
	// hack for broken a2s_rules on linux servers
	decl String:version[16];
	GetConVarString(g_version, version, sizeof(version));
	SetConVarString(g_version, version);
}

public Action:TF2_OnGetHoliday(&TFHoliday:holiday)
{
	if (holiday == TFHoliday_Birthday && !GetConVarBool(g_birthday))
	{
		holiday = TFHoliday_None;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}