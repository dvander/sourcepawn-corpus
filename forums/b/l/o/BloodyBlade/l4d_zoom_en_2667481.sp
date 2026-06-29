#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define SOUND_ZOOM  "/weapons/hunting_rifle/gunother/hunting_rifle_zoom.wav"

bool ZoomOn[MAXPLAYERS+1];
int KeyBuffer[MAXPLAYERS+1];
int fovmin = 10;
int fovmax = 90;
char weapon[32];
int middle = 45;
int button;

public Plugin myinfo = 
{
	name = "ZOOM",
	author = "xiaohai",
	description = "ZOOM",
	version = "1.0",
	url = "http://forums.alliedmods.net"
}

public void OnPluginStart()
{
 	HookEvent("player_spawn", Event_Spawn);
	HookEvent("weapon_zoom", weapon_zoom);
	HookEvent("weapon_reload", WeaponReload);
	RegConsoleCmd("sm_zoominc", zoom1);
 	RegConsoleCmd("sm_zoomdec", zoom2);	
}

Handle msgTimer;
int msgp = 0;
public void OnMapStart()
{
 	msgTimer = CreateTimer(74.0, Msg, 0, TIMER_REPEAT);
	PrecacheSound(SOUND_ZOOM, true) ;	 
}

public void OnMapEnd()
{
 	CloseHandle(msgTimer);
}

public Action Msg(Handle timer, any data)
{
	if(msgp > 0) msgp = 0;
	if(msgp == 0) PrintToChatAll("\x03press mouse wheel for zoom");
	msgp++;
 	return Plugin_Continue;
}

public void WeaponReload(Handle hEvent, const char[] name, bool dontBroadcast)
{
	int client   = 0;
	client = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	if(IsValidAliveClient(client))
	{
 		SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
		SetEntProp(client,    Prop_Send, "m_iFOV", 90);
	}
	ZoomOn[client] = false;
}
 
public void Event_Spawn(Handle Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	if(IsValidAliveClient(client))
	{
		SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
		SetEntProp(client,    Prop_Send, "m_iFOV", 90);
	}
	ZoomOn[client] = false;
}

public Action zoom1(int client, int args)
{
 	if (!IsValidAliveClient(client))return Plugin_Handled;
	Zoom(client, -15);
	return Plugin_Handled;
}

public Action zoom2(int client, int args)
{
	if (!IsValidAliveClient(client))return Plugin_Handled;
	Zoom(client, 15);
	return Plugin_Handled;
}

void Zoom(int client, int step)
{
	int fov;
	char Weapon[32];

	GetClientWeapon(client, Weapon, 32);
 	if(StrEqual(Weapon, "weapon_hunting_rifle") ||  StrContains(Weapon, "sniper")>=0)
	{
		fov = GetEntProp(client,  Prop_Send, "m_iFOV");
 		if(fov == 0) fov = 90;
		fov += step;
		if(fov > fovmax) fov = fovmax;
		if(fov < fovmin) fov = fovmin;
 		SetEntProp(client,    Prop_Send, "m_iFOV", fov);
 		ZoomOn[client]=false;
	}
	else
	{
 		fov = GetEntProp(client, Prop_Send, "m_iFOV");
 		if(fov == 0) fov = 90;
		fov += step;
		if(fov > fovmax) fov = fovmax;
		if(fov < fovmin) fov = fovmin;
		if(fov == 90)
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
		}
		else
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  0);
		}
		SetEntProp(client,    Prop_Send, "m_iFOV", fov);
 		ZoomOn[client] = true;
	}
	EmitSoundToAll(SOUND_ZOOM, client); 
}

public void weapon_zoom(Handle Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	//return;
	int client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	char Weapon[32];
	GetClientWeapon(client, Weapon, 32);
	int fov = GetEntProp(client,  Prop_Send, "m_iFOV");
	/*int view = GetEntProp(client, Prop_Send, "m_bDrawViewmodel");*/ 
	if(StrEqual(weapon, "weapon_hunting_rifle"))
	{
		if(fov != 30)
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
			SetEntProp(client,    Prop_Send, "m_iFOV", 0);
			EmitSoundToAll(SOUND_ZOOM, client); 
		}
		//PrintToChatAll("weapon_hunting_rifle %d, %d", fov, view);		
		return;
	}
	else if(StrEqual(weapon, "weapon_sniper_military"))
	{
		if(fov != 30)
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
			SetEntProp(client,    Prop_Send, "m_iFOV", 0);
			EmitSoundToAll(SOUND_ZOOM, client); 
		}
		//PrintToChatAll("weapon_sniper_military %d, %d", fov, view);	
		ZoomOn[client] = false; return;
	}
	else if(StrEqual(weapon, "weapon_sniper_awp"))
	{
		if(fov != 40)
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
			SetEntProp(client,    Prop_Send, "m_iFOV", 0);
			EmitSoundToAll(SOUND_ZOOM, client); 
		}
		//PrintToChatAll("weapon_sniper_awp %d, %d", fov, view);	
		ZoomOn[client] = false; return;
	}
	else if(StrEqual(weapon, "weapon_sniper_scout"))
	{
		if(fov != 40)
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
			SetEntProp(client,    Prop_Send, "m_iFOV", 0);
			EmitSoundToAll(SOUND_ZOOM, client); 
		}
		//PrintToChatAll("weapon_sniper_scout %d, %d", fov, view);	
		ZoomOn[client] = false; return;
	}
	return;
}

public void OnGameFrame()
{
  	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && !IsFakeClient(client))
		{
			button = GetClientButtons(client);
			if((button & IN_ZOOM) && !(KeyBuffer[client] & IN_ZOOM))
			{
				GetClientWeapon(client, weapon, 32);
 				if(! (StrEqual(weapon, "weapon_hunting_rifle") || StrContains(weapon, "sniper")>=0))
				{
					if(ZoomOn[client])
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client] = false;
					}
					else
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  0);
						SetEntProp(client,    Prop_Send, "m_iFOV", middle);
						ZoomOn[client] = true;
					}
 					EmitSoundToAll(SOUND_ZOOM, client); 
				}
			}
			if(ZoomOn[client])
			{
				if(button & IN_ATTACK2)
				{
					SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
					SetEntProp(client,    Prop_Send, "m_iFOV", 90);
					ZoomOn[client]=false;
				}
				else if(!(button & IN_DUCK) && !(button & IN_SPEED))
				{
					if(button & IN_FORWARD)
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client] = false;
					}
					else if(button & IN_MOVELEFT)
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client] = false;
					}
					else if(button & IN_MOVERIGHT)
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client] = false;
					}
					else if(button & IN_BACK)
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client] = false;
					}
					/*
					else if(button & IN_JUMP)
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client] = false;
 					}
					*/
 				}
			}
			KeyBuffer[client] = button;
 		}
	}
}

stock bool IsValidAliveClient(int iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if(!IsClientInGame(iClient))return false;
    if (GetClientTeam(iClient)!=2) return false;
    if (!IsPlayerAlive(iClient)) return false;
    if (IsFakeClient(iClient)) return false;
    return true;
}
