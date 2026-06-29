#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define SOUND_ZOOM  "/weapons/hunting_rifle/gunother/hunting_rifle_zoom.wav"
 

new bool:ZoomOn[MAXPLAYERS+1];
new KeyBuffer[MAXPLAYERS+1];
new fovmin=10;
new fovmax=90;
new String:weapon[32];
new middle=45;
new button;
new Handle:l4d_zoom_bind = INVALID_HANDLE;
public Plugin:myinfo = 
{
	name = "ZOOM",
	author = "xiaohai",
	description = "ZOOM",
	version = "1.0",
	url = "http://forums.alliedmods.net"
}
public OnPluginStart()
{
	l4d_zoom_bind = CreateConVar("l4d_zoom_bind", "0", "0:disable, 1:enable, bind mouse wheel for zoom", FCVAR_PLUGIN);

	AutoExecConfig(true, "l4d_zoom");	
 	HookEvent("player_spawn", Event_Spawn);
	HookEvent("weapon_zoom", weapon_zoom);
	HookEvent("weapon_reload", WeaponReload);
	RegConsoleCmd("sm_zoominc", zoom1);
 	RegConsoleCmd("sm_zoomdec", zoom2);
	
}
new Handle:msgTimer;
new msgp=0;
public OnMapStart()
{
 	msgTimer=CreateTimer(74.0, Msg, 0, TIMER_REPEAT);
	PrecacheSound(SOUND_ZOOM, true) ;
	 
}
public OnMapEnd()
{
 	CloseHandle(msgTimer);
}
public Action:Msg(Handle:timer, any:data)
{
 
	if(msgp>0)msgp=0;
	if(msgp==0)PrintToChatAll("\x03press mouse wheel for zoom");
	msgp++;
 	return Plugin_Continue;
}
public WeaponReload (Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new client   = 0;
	client = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	if(IsValidAliveClient(client))
	{
 		SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
		SetEntProp(client,    Prop_Send, "m_iFOV", 90);
	}
	ZoomOn[client]=false;
}
 
public Event_Spawn(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	if(IsValidAliveClient(client))
	{
		SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
		SetEntProp(client,    Prop_Send, "m_iFOV", 90);
		if(GetConVarInt(l4d_zoom_bind)>0)
		{
			ClientCommand(client, "bind mwheelup \"say /zoominc\"");
			ClientCommand(client, "bind mwheeldown \"say /zoomdec\"");
		}
	}
	ZoomOn[client] = false;

}
public Action:zoom1(client, args)
{
 	if (!IsValidAliveClient(client))return Plugin_Handled;
	Zoom(client, -15);
	return Plugin_Handled;
}
public Action:zoom2(client, args)
{
	if (!IsValidAliveClient(client))return Plugin_Handled;
	Zoom(client, 15);
	return Plugin_Handled;
}
Zoom(client, step)
{
	new fov;
	new String:weapon[32];

	GetClientWeapon(client, weapon, 32);
 	if(StrEqual(weapon, "weapon_hunting_rifle") ||  StrContains(weapon, "sniper")>=0)
	{
		fov=GetEntProp(client,  Prop_Send, "m_iFOV");
 		if(fov==0)fov=90;
		fov+=step;
		if(fov>fovmax)fov=fovmax;
		if(fov<fovmin)fov=fovmin;
 		SetEntProp(client,    Prop_Send, "m_iFOV", fov);
 		ZoomOn[client]=false;
	}
	else
	{
 		fov=GetEntProp(client,  Prop_Send, "m_iFOV");
 		if(fov==0)fov=90;
		fov+=step;
		if(fov>fovmax)fov=fovmax;
		if(fov<fovmin)fov=fovmin;
		if(fov==90)
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
		}
		else
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  0);
		}
		SetEntProp(client,    Prop_Send, "m_iFOV", fov);
 		ZoomOn[client]=true;
	}
	EmitSoundToAll(SOUND_ZOOM, client); 
 }


public weapon_zoom(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	//return;
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));

	
	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);
	new fov=GetEntProp(client,  Prop_Send, "m_iFOV");
	new view=GetEntProp(client,    Prop_Send, "m_bDrawViewmodel"); 
	if(StrEqual(weapon, "weapon_hunting_rifle"))
	{
		if(fov!=30)
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
		if(fov!=30)
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
			SetEntProp(client,    Prop_Send, "m_iFOV", 0);
			EmitSoundToAll(SOUND_ZOOM, client); 
		}
		//PrintToChatAll("weapon_sniper_military %d, %d", fov, view);	
		ZoomOn[client]=false;return;
	}
		else if(StrEqual(weapon, "weapon_sniper_awp"))
	{
		if(fov!=40)
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
			SetEntProp(client,    Prop_Send, "m_iFOV", 0);
			EmitSoundToAll(SOUND_ZOOM, client); 
		}
		//PrintToChatAll("weapon_sniper_awp %d, %d", fov, view);	
		ZoomOn[client]=false;return;
	}
	else if(StrEqual(weapon, "weapon_sniper_scout"))
	{
		if(fov!=40)
		{
			SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
			SetEntProp(client,    Prop_Send, "m_iFOV", 0);
			EmitSoundToAll(SOUND_ZOOM, client); 
		}
		//PrintToChatAll("weapon_sniper_scout %d, %d", fov, view);	
		ZoomOn[client]=false;return;
	}
	return;
	 
	
 }

public OnGameFrame()
{

  	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && !IsFakeClient(client))
		{
			button=GetClientButtons(client);
			if((button & IN_ZOOM) && !(KeyBuffer[client] & IN_ZOOM))
			{
				GetClientWeapon(client, weapon, 32);
 				if(! (StrEqual(weapon, "weapon_hunting_rifle") || StrContains(weapon, "sniper")>=0))
				{
					if(ZoomOn[client])
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client]=false;
					}
					else
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  0);
						SetEntProp(client,    Prop_Send, "m_iFOV", middle);
						ZoomOn[client]=true;
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
						ZoomOn[client]=false;
					}
					else if(button & IN_MOVELEFT)
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client]=false;
					}
					else if(button & IN_MOVERIGHT)
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client]=false;
					}
					else if(button & IN_BACK)
					{
						SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						ZoomOn[client]=false;
					}
					//else if(button & IN_JUMP)
					//{
						//SetEntProp(client,    Prop_Send, "m_bDrawViewmodel",  1);
						//SetEntProp(client,    Prop_Send, "m_iFOV", 90);
						//ZoomOn[client]=false;
 					//}
 				}

			}
			KeyBuffer[client]=button;
 		}
	}
}
SetMove(client, Float:v)
{
	 SetEntDataFloat(client, offsSpeed, v);
}
 stock bool:IsValidAliveClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if(!IsClientInGame(iClient))return false;
    if (GetClientTeam(iClient)!=2) return false;
    if (!IsPlayerAlive(iClient)) return false;
    if (IsFakeClient(iClient)) return false;
	return true;
}
