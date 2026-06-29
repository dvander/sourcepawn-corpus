#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.12"
#define CVAR_FLAGS          FCVAR_PLUGIN|FCVAR_NOTIFY

#define DEBUG 0

new Handle:timer_handle=INVALID_HANDLE;
new Dist[MAXPLAYERS+1];
new Height[MAXPLAYERS+1];
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
 	 
 	RegConsoleCmd("sm_3",third, "into thirdperson");
	RegConsoleCmd("sm_1", first, "into firstperson");
 	RegConsoleCmd("sm_viewup",sm_viewup, "");
 	RegConsoleCmd("sm_viewdown",sm_viewdown, ""); 
 	RegConsoleCmd("sm_viewfar",sm_viewfar, "");
 	RegConsoleCmd("sm_viewclose",sm_viewclose, "");
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
	PrintToChatAll("\x03say \x04!1 \x03and \x04!3\x03 change view between firstperson and thirdperson");
  	return Plugin_Continue;
}
public Action:third(client, args)
{

	ClientCommand(client, "thirdpersonshoulder");
	ClientCommand(client, "c_thirdpersonshoulderoffset 0");
	ClientCommand(client, "c_thirdpersonshoulderaimdist 720");
	ClientCommand(client, "cam_ideallag 0");
	if(GetClientTeam(client)==3)
	{
		ClientCommand(client, "cam_idealdist 90");
		Dist[client]=90;
	}
	else 
	{
		ClientCommand(client, "cam_idealdist 40");
		Dist[client]=40;	
	}


 	decl String:player_name[65];
	GetClientName(client, player_name, sizeof(player_name));

 	PrintToChat(client, "\x03say:\x04!viewup, !viewdown, !viewfar, !viewclose \x03to adjust view");
	return Plugin_Handled;
}
public Action:first(client, args)
{

	ClientCommand(client, "thirdpersonshoulder");
	ClientCommand(client, "c_thirdpersonshoulder 0");
	return Plugin_Handled;
}
public Action:sm_viewup(client, args)
{
	Height[client]+=5;
	if(Height[client]>25)Height[client]=25;
	if(Height[client]<5)Height[client]=5;
	ClientCommand(client, "c_thirdpersonshoulderheight %d", Height[client]);
	return Plugin_Handled;
}
public Action:sm_viewdown(client, args)
{
	Height[client]-=5;
	if(Height[client]>25)Height[client]=25;
	if(Height[client]<5)Height[client]=5;
	ClientCommand(client, "c_thirdpersonshoulderheight %d", Height[client]);
	return Plugin_Handled;
}
public Action:sm_viewfar(client, args)
{
	Dist[client]+=10;
	if(Dist[client]>130)Dist[client]=130;
	if(Dist[client]<30)Dist[client]=30;
	ClientCommand(client, "cam_idealdist %d", Dist[client]);
	return Plugin_Handled; 
 }
public Action:sm_viewclose(client, args)
{
	Dist[client]-=10;
	if(Dist[client]>130)Dist[client]=130;
	if(Dist[client]<30)Dist[client]=30;
	ClientCommand(client, "cam_idealdist %d", Dist[client]);
	return Plugin_Handled; 
}
