#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

bool   q_stop;
Handle q_Timer = null;

public Plugin myinfo = 
{
	name = "[L4D] Third Person",
	author = "AlexMy",
	description = "It includes a camera view in the third person.",
	version ="1.5",
	url = "https://forums.alliedmods.net/showthread.php?p=2406576#post2406576",
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_third",     ThirdPerson);
	
	HookEvent("player_spawn",     event_PlayerSpawn);
	HookEvent("round_start",      event_ResetBool);
	HookEvent("round_end",        event_ResetBool);
}

public void event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(q_stop)return;
	{
		if (q_Timer != null)
		{
			delete(q_Timer);
			q_Timer = null;
		}
		q_Timer = CreateTimer(50.0, advertising, GetClientOfUserId(event.GetInt("userid")), TIMER_FLAG_NO_MAPCHANGE);
		q_stop = true;
	}
}
public void event_ResetBool(Event event, const char[] name, bool dontBroadcast)
{
	q_stop = false;
}

public Action advertising(Handle timer)
{
	for(int i=1; i<=MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) == 2)
	{
		PrintToChat(i, "\x03Change camera \x05!third \x03Activation via button \x05Z");
	}
	q_Timer = null;
	return;
}

public void OnClientPostAdminCheck(int client)
{
	ClientCommand(client, "bind z sm_third; bind v sm_laser; bind v laser");
	ClientCommand(client, "thirdpersonshoulder");
	ClientCommand(client, "thirdpersonshoulder");
}

public Action ThirdPerson(int client, int args)
{
	if(GetClientTeam(client) == 2)
	{
		ClientCommand(client, "thirdpersonshoulder");
		ClientCommand(client, "cl_crosshair_dynamic 0");   
		ClientCommand(client, "cl_crosshair_thickness 1"); 
		FakeClientCommand(client, "sm_laser", "laser");
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 90);  
		PrintToChat(client, "\x03Change camera \x05!third \x03Deactivating using the button \x05Z");
	}
	else
	{
		ClientCommand(client, "thirdpersonshoulder");
		ClientCommand(client, "cl_crosshair_dynamic 1");
		ClientCommand(client, "cl_crosshair_thickness 3");
		FakeClientCommand(client, "sm_laser", "laser");
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	return Plugin_Handled;
}