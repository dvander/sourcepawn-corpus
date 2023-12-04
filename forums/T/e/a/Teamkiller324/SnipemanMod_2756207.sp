#pragma		semicolon	1
#pragma		newdecls	required

public	Plugin	myinfo	=	{
	name		=	"SnipemanMod",
	author		=	"Snipeman (robert.oates@gmail.com), Tk /id/Teamkiller324",
	description	=	"Various TF2 gameplay tweaks.",
	version		=	"1.1.0.0",
	url			=	"http://www.sourcemod.net/"
}
 
ConVar	Hide_kills_knife, Hide_kills_sapper;

public void OnPluginStart()	{
	HookEvent("player_death",		SnipemanMod_PlayerDeath,		EventHookMode_Pre);
	HookEvent("object_destroyed",	SnipemanMod_ObjectDestroyed,	EventHookMode_Pre);

	Hide_kills_knife	= CreateConVar("sm_hide_kills_knife",	"1",	"SnipeManMod - If 1, backstab kills will not show on the HUD." );
	Hide_kills_sapper	= CreateConVar("sm_hide_kills_sapper",	"1",	"SnipeManMod - If 1, sapper kills (on buildings) will not show on the HUD." );

	AutoExecConfig(true, "plugin_snipeman");
}

void SnipemanMod_PlayerDeath(Event event, const char[] name, bool dontBroadcast)	{
	if(Hide_kills_knife.BoolValue && event.GetInt("customkill") == 2)
		event.BroadcastDisabled = true;
}

void SnipemanMod_ObjectDestroyed(Event event, const char[] name, bool dontBroadcast)	{
	if(!Hide_kills_sapper.BoolValue)
		return;
	
	char weaponName[32];
	event.GetString("weapon", weaponName, sizeof(weaponName));

	if(StrContains(weaponName, "obj_attachment_sapper") != -1)
		event.BroadcastDisabled = true;
}