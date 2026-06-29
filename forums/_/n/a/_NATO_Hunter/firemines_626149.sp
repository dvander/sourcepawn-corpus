/*
 *
 *  TF2 Firemines - SourceMod Plugin
 *  Copyright (C) 2008  Marc Hörsken
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PL_VERSION "1.1.9"
#define SOUND_A "weapons/smg_clip_out.wav"
#define SOUND_B "items/spawn_item.wav"
#define SOUND_C "ui/hint.wav"

public Plugin:myinfo = 
{
	name = "TF2 Firemines",
	author = "Hunter",
	description = "Allows pyros to drop firemines on death or with secondary Flamethrower fire.",
	version = PL_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=71404"
}

new bool:g_Pyros[MAXPLAYERS+1];
new bool:g_PyroButtonDown[MAXPLAYERS+1];
new Float:g_PyroPosition[MAXPLAYERS+1][3];
new Float:g_FireminesPos[2048][3];
new g_PyroAmmo[MAXPLAYERS+1];
new g_FireminesTime[2048];
new g_FireminesOwner[2048];
new g_FilteredEntity = -1;
new Handle:g_IsFireminesOn = INVALID_HANDLE;
new Handle:g_FireminesAmmo = INVALID_HANDLE;
new Handle:g_FireminesType = INVALID_HANDLE;
new Handle:g_FireminesDamage = INVALID_HANDLE;
new Handle:g_FireminesRadius = INVALID_HANDLE;
new Handle:g_FireminesKeep = INVALID_HANDLE;
new Handle:g_FireminesStay = INVALID_HANDLE;
new Handle:g_FriendlyFire = INVALID_HANDLE;

native TF2_IgnitePlayer(client, target);

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("firemines.phrases");
	
	CreateConVar("sm_tf_firemines", PL_VERSION, "Firemines", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_IsFireminesOn = CreateConVar("sm_firemines","2","Enable/Disable firemines (0 = disabled | 1 = on death | 2 = on command | 3 = on death and command)", _, true, 0.0, true, 3.0);
	g_FireminesAmmo = CreateConVar("sm_firemines_ammo","100","Ammo required for Firemines", _, true, 0.0, true, 200.0);
	g_FireminesType = CreateConVar("sm_firemines_type","1","Explosion type of Firemines (0 = normal explosion | 1 = fire explosion)", _, true, 0.0, true, 1.0);
	g_FireminesDamage = CreateConVar("sm_firemines_damage","80","Explosion damage of Firemines", _, true, 0.0, true, 1000.0);
	g_FireminesRadius = CreateConVar("sm_firemines_radius","150","Explosion radius of Firemines", _, true, 0.0, true, 1000.0);
	g_FireminesKeep = CreateConVar("sm_firemines_keep","180","Time to keep Firemines on map. (0 = off | >0 = seconds)", _, true, 0.0, true, 600.0);
	g_FireminesStay = CreateConVar("sm_firemines_stay","1","Firemines stay if the owner dies. (0 = no | 1 = yes)", _, true, 0.0, true, 1.0);
	g_FriendlyFire = FindConVar("mp_friendlyfire");

	HookConVarChange(g_IsFireminesOn, ConVarChange_IsFireminesOn);
	HookEvent("player_changeclass", Event_PlayerClass);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEntityOutput("prop_physics", "OnHealthChanged", EntityOutput:Entity_OnHealthChanged);
	RegConsoleCmd("sm_firemine", Command_Firemine)
	
	CreateTimer(1.0, Timer_Caching, _, TIMER_REPEAT);
	
	AutoExecConfig(true);
}

public OnMapStart()
{
	PrecacheModel("models/props_2fort/groundlight001.mdl", true);
	PrecacheSound(SOUND_A, true);
	PrecacheSound(SOUND_B, true);
	PrecacheSound(SOUND_C, true);
	
	AutoExecConfig(true);
}

public OnClientDisconnect(client)
{
	g_Pyros[client] = false;
	g_PyroButtonDown[client] = false;
	g_PyroAmmo[client] = 0;
	g_PyroPosition[client] = NULL_VECTOR;
}

public OnClientPutInServer(client)
{
	if(GetConVarBool(g_IsFireminesOn))
		CreateTimer(45.0, Timer_Advert, client);
}

public OnGameFrame()
{	
	if(!GetConVarBool(g_IsFireminesOn))
		return;

	new FireminesOn = GetConVarInt(g_IsFireminesOn)
	if (FireminesOn < 2)
		return;

	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if (g_Pyros[i] && !g_PyroButtonDown[i] && IsClientInGame(i))
		{
			if (GetClientButtons(i) & IN_RELOAD)
			{
				g_PyroButtonDown[i] = true;
				CreateTimer(0.5, Timer_ButtonUp, i);
				new String:classname[64];
				TF_GetCurrentWeaponClass(i, classname, 64);
				if(StrEqual(classname, "CTFFlameThrower"))
					TF_DropFiremine(i, true);
			}
		}
	}
}

public ConVarChange_IsFireminesOn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) > 0)
		PrintToChatAll("[SM] %t", "Enabled Firemines");
	else
		PrintToChatAll("[SM] %t", "Disabled Firemines");
}

public Action:Command_Firemine(client, args)
{
	if(!GetConVarBool(g_IsFireminesOn))
		return Plugin_Handled;
	
	new FireminesOn = GetConVarInt(g_IsFireminesOn)
	if (FireminesOn < 2)
		return Plugin_Handled;
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class != TFClass_Pyro)
		return Plugin_Handled;
	
	new String:classname[64];
	TF_GetCurrentWeaponClass(client, classname, 64);
	if(!StrEqual(classname, "CTFFlameThrower"))
		return Plugin_Handled;
	
	TF_DropFiremine(client, true);
	
	return Plugin_Handled;
}

public Action:Timer_Advert(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		new FireminesOn = GetConVarInt(g_IsFireminesOn);
		switch (FireminesOn)
		{
			case 1:
				PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeath Firemines");
			case 2:
				PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnCommand Firemines");
			case 3:
				PrintToChat(client, "\x01\x04[SM]\x01 %t", "OnDeathAndCommand Firemines");
		}
	}
}

public Action:Timer_Caching(Handle:timer)
{
	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if (g_Pyros[i] && IsClientInGame(i))
		{
			g_PyroAmmo[i] = TF_GetAmmoAmount(i);
			GetClientAbsOrigin(i, g_PyroPosition[i]);
		}
	}
	new FireminesKeep = GetConVarInt(g_FireminesKeep)
	if (FireminesKeep > 0)
	{
		new time = GetTime() - FireminesKeep;
		for (new c = 0; c < 2048; c++)
		{
			if (g_FireminesTime[c] != 0 && g_FireminesTime[c] < time)
			{
				g_FireminesTime[c] = 0;
				g_FireminesOwner[c] = 0;
				g_FireminesPos[c] = NULL_VECTOR;
				if (IsValidEntity(c))
				{
					new String:classname[64];
					GetEntityNetClass(c, classname, 64);
					if(StrEqual(classname, "CPhysicsProp"))
					{
						EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
						RemoveEdict(c);
					}
				}
			}
		}
	}
}

public Action:Timer_ButtonUp(Handle:timer, any:client)
{
	g_PyroButtonDown[client] = false;
}

public Action:Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new any:class = GetEventInt(event, "class");
	if (class != TFClass_Pyro)
	{
		g_Pyros[client] = false;
		return;
	}
	g_Pyros[client] = true;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_IsFireminesOn))
		return;
	
	new FireminesOn = GetConVarInt(g_IsFireminesOn)
	if (FireminesOn < 1)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!g_Pyros[client] || !IsClientInGame(client))
		return;
	
	new TFClassType:class = TF2_GetPlayerClass(client);	
	if (class != TFClass_Pyro)
		return;
	
	new FireminesStay = GetConVarInt(g_FireminesStay)
	if (FireminesStay < 1)
	{
		for (new c = 0; c < 2048; c++)
		{
			if (g_FireminesOwner[c] == client)
			{
				g_FireminesTime[c] = 0;
				g_FireminesOwner[c] = 0;
				g_FireminesPos[c] = NULL_VECTOR;
				if (IsValidEntity(c))
				{
					new String:classname[64];
					GetEntityNetClass(c, classname, 64);
					if(StrEqual(classname, "CPhysicsProp"))
					{
						EmitSoundToAll(SOUND_C, c, _, _, _, 0.75);
						RemoveEdict(c);
					}
				}
			}
		}
	}
	
	if (FireminesOn != 2)
		TF_DropFiremine(client, false);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client != 0)
	{
		new team = GetEventInt(event, "team");
		if (team < 2 && IsClientInGame(client))
		{
			g_Pyros[client] = false;
			g_PyroButtonDown[client] = false;
			g_PyroAmmo[client] = 0;
			g_PyroPosition[client] = NULL_VECTOR;
		}
	}
}

public Entity_OnHealthChanged(const String:output[], caller, activator, Float:delay)
{
	if (g_FireminesTime[caller] > 0 && IsClientInGame(g_FireminesOwner[caller]) && activator <= MAXPLAYERS && IsClientInGame(activator))
	{
		if (GetConVarInt(g_FireminesType))
		{
			new Float:PlayerPosition[3];
			new Float:maxdistance = GetConVarFloat(g_FireminesRadius);
			new maxclients = GetMaxClients();
			for (new i = 1; i <= maxclients; i++)
			{
				if (IsClientInGame(i))
				{
					GetClientAbsOrigin(i, PlayerPosition);
				//	if (GetVectorDistance(PlayerPosition, g_FireminesPos[caller]) <= maxdistance)
				//	{
				//		new team = 0;
				//		if (!GetConVarInt(g_FriendlyFire))
				//			team = GetClientTeam(g_FireminesOwner[caller]);
				//		if ((team != GetClientTeam(i)) || (i == g_FireminesOwner[caller]))
				//			TF2_IgnitePlayer(i, g_FireminesOwner[caller]);
				//	}
					
					if (g_Pyros[i])
					{
						g_PyroAmmo[i] = TF_GetAmmoAmount(i);
						g_PyroPosition[i] = PlayerPosition;
					}
				}
			}
		}

		new team = 0;
		if (!GetConVarInt(g_FriendlyFire))
			team = GetClientTeam(g_FireminesOwner[caller]);
		if ((team != GetClientTeam(activator)) || (activator == g_FireminesOwner[caller]))
		{
			AcceptEntityInput(caller, "Break", g_FireminesOwner[caller], g_FireminesOwner[caller]);

			g_FireminesTime[caller] = 0;
			g_FireminesOwner[caller] = 0;
			g_FireminesPos[caller] = NULL_VECTOR;
		}
	}
}

public bool:FiremineTraceFilter(ent, contentMask)
{
   return (ent == g_FilteredEntity) ? false : true;
}

stock TF_SpawnFiremine(client, String:name[], bool:cmd)
{
	new Float:PlayerPosition[3];
	if (cmd)
		GetClientAbsOrigin(client, PlayerPosition);
	else
		PlayerPosition = g_PyroPosition[client];
		
	if (PlayerPosition[0] != 0.0 && PlayerPosition[1] != 0.0 && PlayerPosition[2] != 0.0 && IsEntLimitReached() == false)
	{
		PlayerPosition[2] += 4;
		g_FilteredEntity = client;
		if (cmd)
		{
			new Float:PlayerPosEx[3], Float:PlayerAngle[3], Float:PlayerPosAway[3];
			GetClientEyeAngles(client, PlayerAngle);
			PlayerPosEx[0] = Cosine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[1] = Sine((PlayerAngle[1]/180)*FLOAT_PI);
			PlayerPosEx[2] = 0.0;
			ScaleVector(PlayerPosEx, 75.0);
			AddVectors(PlayerPosition, PlayerPosEx, PlayerPosAway);
			
			new Handle:TraceEx = TR_TraceRayFilterEx(PlayerPosition, PlayerPosAway, MASK_SOLID, RayType_EndPoint, FiremineTraceFilter);
			TR_GetEndPosition(PlayerPosition, TraceEx);
			CloseHandle(TraceEx);
		}

		new Float:Direction[3];
		Direction[0] = PlayerPosition[0];
		Direction[1] = PlayerPosition[1];
		Direction[2] = PlayerPosition[2]-1024;
		new Handle:Trace = TR_TraceRayFilterEx(PlayerPosition, Direction, MASK_SOLID, RayType_EndPoint, FiremineTraceFilter);
		
		new Float:MinePos[3];
		TR_GetEndPosition(MinePos, Trace);
		CloseHandle(Trace);
		MinePos[2] += 1;
		
		new Firemine = CreateEntityByName(name);
		SetEntityModel(Firemine, "models/props_2fort/groundlight001.mdl");
		DispatchKeyValue(Firemine, "StartDisabled", "false");
		if (DispatchSpawn(Firemine))
		{
			new String:targetname[32];
			new team = 0;
			
			if (!GetConVarInt(g_FriendlyFire))
				team = GetClientTeam(client);

			Format(targetname, 32, "firemine_%d", Firemine);
			TeleportEntity(Firemine, MinePos, NULL_VECTOR, NULL_VECTOR);
			SetEntProp(Firemine, Prop_Send, "m_iTeamNum", team, 4);
			SetEntProp(Firemine, Prop_Data, "m_usSolidFlags", 152);
			SetEntProp(Firemine, Prop_Data, "m_nSolidType", 6);
			SetEntProp(Firemine, Prop_Data, "m_takedamage", 3);
			SetEntPropEnt(Firemine, Prop_Data, "m_hLastAttacker", client);
			SetEntPropEnt(Firemine, Prop_Data, "m_hPhysicsAttacker", client);
			SetEntityMoveType(Firemine, MOVETYPE_NONE);
			DispatchKeyValue(Firemine, "targetname", targetname);
			DispatchKeyValue(Firemine, "spawnflags", "152")
			DispatchKeyValue(Firemine, "physdamagescale", "0");
		//	DispatchKeyValue(Firemine, "OnHealthChanged", "!self,Break,,0,-1"); // we handle this ourself now...
			DispatchKeyValue(Firemine, "OnBreak", "!self,Kill,,0,-1");
			DispatchKeyValueFloat(Firemine, "ExplodeDamage", GetConVarFloat(g_FireminesDamage))
			DispatchKeyValueFloat(Firemine, "ExplodeRadius", GetConVarFloat(g_FireminesRadius))
			EmitSoundToAll(SOUND_B, Firemine, _, _, _, 0.75);
			g_FireminesTime[Firemine] = GetTime();
			g_FireminesOwner[Firemine] = client;
			g_FireminesPos[Firemine] = MinePos;
		}
	}
}

stock bool:IsEntLimitReached()
{
	new maxclients = GetMaxClients();
	new maxents = GetMaxEntities();
	new i, c = 0;
	for(i = maxclients; i <= maxents; i++)
	{
	 	if(IsValidEntity(i))
			c += 1;
	}
	if (c >= (maxents-16))
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d", c, maxents);
		return true;
	}
	else
		return false;
}

stock TF_GetAmmoAmount(client)
{
	return GetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (1 * 4), 4);
}

stock TF_SetAmmoAmount(client, ammo)
{
	g_PyroAmmo[client] = ammo;
	SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (1 * 4), ammo, 4);
}

stock TF_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (index > 0 && IsValidEntity(index))
		GetEntityNetClass(index, name, maxlength);
}

stock bool:TF_DropFiremine(client, bool:cmd)
{
	new ammo;
	if (cmd)
		ammo = TF_GetAmmoAmount(client);
	else
		ammo = g_PyroAmmo[client];
	new FireminesAmmo = GetConVarInt(g_FireminesAmmo);
	if (ammo >= FireminesAmmo)
	{
		if (cmd) TF_SetAmmoAmount(client, (ammo-FireminesAmmo));
		TF_SpawnFiremine(client, "prop_physics_override", cmd);
		return true;
	}
	if (cmd)
	{
		EmitSoundToClient(client, SOUND_A, _, _, _, _, 0.75);
	}
	return false;
}
