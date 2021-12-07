#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define SPECTATOR 1
#define VERSION "1.2"

public Plugin:myinfo = 
{
	name = "Admin Stealth",
	author = "necavi",
	description = "Allows administrators to become nearly completely invisible.",
	version = VERSION,
	url = "http://necavi.org/"
}

new bool:g_bIsInvisible[MAXPLAYERS + 1] = {false, ...};
new g_iOldTeam[MAXPLAYERS + 1] = {0, ...};
new Handle:g_hHostname = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_adminstealth_version", VERSION, "", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_stealth",Command_Stealth,ADMFLAG_CUSTOM3,"Allows an administrator to toggle complete invisibility on themselves.");
	AddCommandListener(Command_Status,"status");
	g_hHostname = FindConVar("hostname");
	HookEvent("round_end", Event_RoundEnd);
	AddCommandListener(Command_JoinTeam, "jointeam"); 
}

public Action:Command_JoinTeam(client, const String:command[], argc)  
{ 
	if(g_bIsInvisible[client])
	{
		PrintToChat(client, "[SM] Can not join team when in invisible mode!");
		return Plugin_Handled; 
	}
	else 
	{ 
		return Plugin_Continue; 
	} 
}  
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i;i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			InvisOff(i);
		}
	}
}

public Action:Event_WeaponCanUse(client,weapon)
{
	return Plugin_Handled;
}
public Action:Command_Status(client, const String:command[], args)
{
	new String:buffer[64];
	GetConVarString(g_hHostname,buffer,sizeof(buffer));
	PrintToConsole(client,"hostname: %s",buffer);
	PrintToConsole(client,"version : 1.0.0.73/22 5028 secure");
	GetCurrentMap(buffer,sizeof(buffer));
	PrintToConsole(client,"map     : %s at: 0 x, 0 y, 0 z",buffer);
	if(CheckCommandAccess(client,"sm_stealth",0))
	{
		PrintToConsole(client,"players : %d (%d max)",GetClientCount(),MaxClients);
	} else {
		PrintToConsole(client,"players : %d (%d max)",GetClientCount() - GetInvisCount(),MaxClients);
	}
	PrintToConsole(client,"# userid name                uniqueid            connected ping loss state");
	new String:name[18];
	new String:steamID[19];
	new String:time[9];
	for(new i; i <= MaxClients; i++)
	{
		if(ValidPlayer(i))
		{
			if(CheckCommandAccess(client,"sm_stealth",0) || !g_bIsInvisible[i])
			{
				Format(name,sizeof(name),"\"%N\"",i);
				GetClientAuthString(i,steamID,sizeof(steamID));
				if(!IsFakeClient(i))
				{
					FormatShortTime(RoundToFloor(GetClientTime(i)),time,sizeof(time));
					PrintToConsole(client,"# %6d %-19s %19s %9s %4d %4d active",GetClientUserId(i),name,steamID,time,RoundToFloor(GetClientAvgLatency(i,NetFlow_Both) * 1000.0),RoundToFloor(GetClientAvgLoss(i,NetFlow_Both)*100.0));
				} else {
					PrintToConsole(client,"# %6d %-19s %19s                     active",GetClientUserId(i),name,steamID);
				}
			}
		}
	}
	return Plugin_Stop;
}
public Action:Command_Stealth(client, args)
{
	ToggleInvis(client);
	LogAction(client, -1, "%N has toggled stealth mode.", client);
	return Plugin_Handled;
}
public OnClientDisconnect(client)
{
	if(g_bIsInvisible[client])
	{
		InvisOff(client);
	}
}
public OnPluginEnd()
{
	UnhookEvent("round_end", Event_RoundEnd);
	for(new i;i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			InvisOff(i);
		}
	}
}
ToggleInvis(client)
{
	if(g_bIsInvisible[client]) 
	{
		InvisOff(client);
	} else {
		InvisOn(client);
	}
}
InvisOff(client)
{
	g_bIsInvisible[client] = false;
	if(g_iOldTeam[client] >= 0)
	{
		SetEntProp(client,Prop_Send,"m_iTeamNum",g_iOldTeam[client]);
	} else {
		SetEntProp(client,Prop_Send,"m_iTeamNum",0);
	}
	if(GetClientTeam(client) != SPECTATOR)
	{
		SetEntProp(client,Prop_Send,"m_lifeState",0);
		SetEntProp(client,Prop_Data,"m_takedamage",0);
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);	
		SDKUnhook(client,SDKHook_WeaponCanUse,Event_WeaponCanUse);
		if(IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_knife");
		}
	}
	PrintToChat(client, "You are no longer in stealth mode.");

}

InvisOn(client)
{
	g_bIsInvisible[client] = true;
	g_iOldTeam[client] = GetEntProp(client,Prop_Send,"m_iTeamNum");
	SetEntProp(client,Prop_Send,"m_iTeamNum",4);
	if(GetClientTeam(client) != SPECTATOR)
	{
		SetEntProp(client,Prop_Send,"m_lifeState",2);
		SetEntProp(client,Prop_Data,"m_takedamage",2);	
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
		RemoveAllWeapons(client);
		SDKHook(client,SDKHook_WeaponCanUse,Event_WeaponCanUse);
	}
	PrintToChat(client, "You are now in stealth mode.");

}
RemoveAllWeapons(client)
{
	
	new weaponIndex;
	for (new i = 0; i <= 5; i++)
	{
		while ((weaponIndex = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, weaponIndex);
			RemoveEdict(weaponIndex);
		}
	}
}
bool:ValidPlayer(i)
{
	if(i>0 && i<=MaxClients && IsClientConnected(i) && IsClientInGame(i))
	{
		return true;
	}
	return false;
}
FormatShortTime(time, String:outTime[],size)
{
	new temp;
	temp = time%60;
	Format(outTime,size,"%02d",temp);
	temp = (time%3600)/60;
	Format(outTime,size,"%02d:%s",temp,outTime);
	temp = (time%86400)/3600;
	if(temp>0)
	{
		Format(outTime,size,"%d%:s",temp,outTime);

	}
}
GetInvisCount()
{
	new count = 0;
	for(new i; i<=MaxClients;i++)
	{
		if(ValidPlayer(i) && g_bIsInvisible[i])
		{
			count ++;
		}
	}
	return count;
}
