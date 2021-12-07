#include <cstrike> 
#include <sourcemod> 
#include <sdktools> 
new g_Music[MAXPLAYERS + 1] = 1;
new Handle:g_MusicUpdate[MAXPLAYERS+1];
public OnPluginStart()
{
	RegConsoleCmd("sm_music", sm_music);
	HookEvent("player_connect_full", Event_OnFullConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_Disc);
}
public Action:Event_OnFullConnect(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;
	if(GetEntProp(client,Prop_Send,"m_unMusicID") == 1)
	{
	SetEntProp(client, Prop_Send, "m_unMusicID",g_Music[client]);
	}
	return Plugin_Continue;
}
public Action:Event_Disc(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_Music[client] != 1)
	{
	g_Music[client] = 1;
	}
	if(g_MusicUpdate[client] != INVALID_HANDLE)
	{
	KillTimer(g_MusicUpdate[client]);
	g_MusicUpdate[client] = INVALID_HANDLE;
	}
}
public Action:sm_music(client, args)
{

	if (client < 1)
		return Plugin_Handled;
	new musicclass = 1;
	decl info[25];
	GetCmdArg(1, info, 10); 
	musicclass = StringToInt(info);
	if( musicclass > 0 && musicclass < 18)
	{
	SetEntProp(client, Prop_Send, "m_unMusicID",musicclass);
	g_Music[client] = musicclass;
	g_MusicUpdate[client] = CreateTimer(0.1, Timer_MusicFx, client, TIMER_REPEAT);
	//EZ
	}
	return Plugin_Handled;
}
public Action:Timer_MusicFx(Handle:timer, any:client)
{

	if(g_Music[client] > 0)
	{
	if(IsClientInGame(client) && IsValidEntity(client))
	{
	SetEntProp(client, Prop_Send, "m_unMusicID",g_Music[client]);
	}
	}
}

