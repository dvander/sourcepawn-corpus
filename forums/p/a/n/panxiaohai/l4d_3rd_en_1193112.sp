#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.12"
#define CVAR_FLAGS          FCVAR_PLUGIN|FCVAR_NOTIFY

#define DEBUG 0

new Handle:timer_handle=INVALID_HANDLE;


public Plugin:myinfo = 
{
	name = "thirdperson view",
	author = "Pan Xiaohai",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}


public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_Spawn);	 
 	RegConsoleCmd("sm_3",third, "into thirdperson");
	RegConsoleCmd("sm_1", first, "into firstperson");
 
}

public PlayerConnectFull(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClientCommand(client, "bind [ \"say /1\"");
	ClientCommand(client, "bind ] \"say /3\"");
}
public OnClientDisconnect(client)
{
	ClientCommand(client, "bind [ \"\"");
	ClientCommand(client, "bind ] \"\"");
}
public Event_Spawn(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
 	ClientCommand(client, "bind [ \"say /1\"");
	ClientCommand(client, "bind ] \"say /3\"");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	 
	if(timer_handle != INVALID_HANDLE )
				{
					KillTimer(timer_handle);
					timer_handle=INVALID_HANDLE;
				}
	if(timer_handle == INVALID_HANDLE)
				{
					timer_handle=CreateTimer(280.0, Msg, 0, TIMER_REPEAT);
				}
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	 
	if(timer_handle != INVALID_HANDLE )
				{
					KillTimer(timer_handle);
					timer_handle=INVALID_HANDLE;
				}
	return Plugin_Continue;
}
 
public Action:Msg(Handle:timer, any:data)
{
	PrintToChatAll("\x03Press \x04[ \x03and \x04]\x03 change view between firstperson and thirdperson");
  	return Plugin_Continue;
}
public Action:third(client, args)
{

	ClientCommand(client, "thirdpersonshoulder");
	ClientCommand(client, "c_thirdpersonshoulderoffset 0");
	ClientCommand(client, "c_thirdpersonshoulderaimdist 720");
	ClientCommand(client, "cam_ideallag 0");
	if(GetClientTeam(client)==3)	ClientCommand(client, "cam_idealdist 90");
	else ClientCommand(client, "cam_idealdist 40");

	ClientCommand(client, "bind leftarrow \"incrementvar cam_idealdist 30 130 10\"");
	ClientCommand(client, "bind rightarrow \"incrementvar cam_idealdist 30 130 -10\"");

	ClientCommand(client, "bind uparrow \"incrementvar c_thirdpersonshoulderheight 5 25 5\"");
	ClientCommand(client, "bind downarrow \"incrementvar c_thirdpersonshoulderheight 5 25 -5\"");
 
 	decl String:player_name[65];
	GetClientName(client, player_name, sizeof(player_name));

 	PrintToChat(client, "\x03Press\x04 arrow keys \x03to adjust view");
	return Plugin_Handled;
}
public Action:first(client, args)
{

	ClientCommand(client, "thirdpersonshoulder");
	ClientCommand(client, "c_thirdpersonshoulder 0");
	return Plugin_Handled;
}

