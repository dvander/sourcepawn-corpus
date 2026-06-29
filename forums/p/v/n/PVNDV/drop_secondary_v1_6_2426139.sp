#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define MODEL_V_FIREAXE "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_V_FRYING_PAN "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_V_MACHETE "models/weapons/melee/v_machete.mdl"
#define MODEL_V_BASEBALL_BAT "models/weapons/melee/v_bat.mdl"
#define MODEL_V_CROWBAR "models/weapons/melee/v_crowbar.mdl"
#define MODEL_V_CRICKET_BAT "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_V_TONFA "models/weapons/melee/v_tonfa.mdl"
#define MODEL_V_KATANA "models/weapons/melee/v_katana.mdl"
#define MODEL_V_ELECTRIC_GUITAR "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_V_GOLFCLUB "models/weapons/melee/v_golfclub.mdl"
#define MODEL_V_SHIELD "models/weapons/melee/v_riotshield.mdl"
#define MODEL_V_KNIFE "models/v_models/v_knife_t.mdl"

static g_PlayerSecondaryWeapons[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name		= "L4D2 Drop Secondary",
	author		= "Jahze, Visor, NoBody",
	version		= "1.6",
	description	= "Survivor players will drop their secondary weapon when they die",
	url		= "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_use", OnPlayerUse, EventHookMode_Post);
	HookEvent("player_bot_replace", player_bot_replace);
	HookEvent("bot_player_replace", bot_player_replace);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public OnRoundStart() 
{
	for (new i = 0; i <= MAXPLAYERS; i++) 
	{
		g_PlayerSecondaryWeapons[i] = -1;
	}
}

public Action:OnPlayerUse(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == 0 || !IsClientInGame(client))
	{
		return;
	}
	
	new weapon = GetPlayerWeaponSlot(client, 1);
	
	g_PlayerSecondaryWeapons[client] = (weapon == -1 ? weapon : EntIndexToEntRef(weapon));
}

public Action:bot_player_replace(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	new client = GetClientOfUserId(GetEventInt(event, "player"));

	g_PlayerSecondaryWeapons[client] = g_PlayerSecondaryWeapons[bot];
	g_PlayerSecondaryWeapons[bot] = -1;
}

public Action:player_bot_replace(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));

	g_PlayerSecondaryWeapons[bot] = g_PlayerSecondaryWeapons[client];
	g_PlayerSecondaryWeapons[client] = -1;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == 0 || !IsClientInGame(client))
	{
		return;
	}
	
	new weapon = EntRefToEntIndex(g_PlayerSecondaryWeapons[client]);
	
	if(weapon == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	new String:sWeapon[32];
	new clip;
	GetEdictClassname(weapon, sWeapon, 32);
	
	new index = CreateEntityByName(sWeapon); 
	new Float:origin[3];
	new Float:ang[3];
	if (StrEqual(sWeapon, "weapon_melee"))
	{
		new String:melee[150];
		GetEntPropString(weapon , Prop_Data, "m_ModelName", melee, sizeof(melee));
		if (StrEqual(melee, MODEL_V_FIREAXE))
		{
			DispatchKeyValue(index, "melee_script_name", "fireaxe");
		}
		else if (StrEqual(melee, MODEL_V_FRYING_PAN))
		{
			DispatchKeyValue(index, "melee_script_name", "frying_pan");
		}
		else if (StrEqual(melee, MODEL_V_MACHETE))
		{
			DispatchKeyValue(index, "melee_script_name", "machete");
		}
		else if (StrEqual(melee, MODEL_V_BASEBALL_BAT))
		{
			DispatchKeyValue(index, "melee_script_name", "baseball_bat");
		}
		else if (StrEqual(melee, MODEL_V_CROWBAR))
		{
			DispatchKeyValue(index, "melee_script_name", "crowbar");
		}
		else if (StrEqual(melee, MODEL_V_CRICKET_BAT))
		{
			DispatchKeyValue(index, "melee_script_name", "cricket_bat");
		}
		else if (StrEqual(melee, MODEL_V_TONFA))
		{
			DispatchKeyValue(index, "melee_script_name", "tonfa");
		}
		else if (StrEqual(melee, MODEL_V_KATANA))
		{
			DispatchKeyValue(index, "melee_script_name", "katana");
		}
		else if (StrEqual(melee, MODEL_V_ELECTRIC_GUITAR))
		{
			DispatchKeyValue(index, "melee_script_name", "electric_guitar");
		}
		else if (StrEqual(melee, MODEL_V_GOLFCLUB))
		{
			DispatchKeyValue(index, "melee_script_name", "golfclub");
		}
		else if (StrEqual(melee, MODEL_V_SHIELD))
		{
				DispatchKeyValue(index, "melee_script_name", "riotshield");
		}
		else if (StrEqual(melee, MODEL_V_KNIFE))
		{
			DispatchKeyValue(index, "melee_script_name", "knife");
		}
		else return;
	}
	else if (StrEqual(sWeapon, "weapon_chainsaw"))
	{
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	}
	else if (StrEqual(sWeapon, "weapon_pistol") && (GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0))
	{
		new indexC = CreateEntityByName(sWeapon);
		GetClientEyePosition(client,origin);
		GetClientEyeAngles(client, ang);
		GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
		NormalizeVector(ang,ang);
		ScaleVector(ang, 90.0);
		
		DispatchSpawn(indexC);
		TeleportEntity(indexC, origin, NULL_VECTOR, ang);
	}
	else if (StrEqual(sWeapon, "weapon_pistol_magnum"))
	{
		clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	}

	RemovePlayerItem(client, weapon);
	AcceptEntityInput(weapon, "Kill");
	
	GetClientEyePosition(client,origin);
	GetClientEyeAngles(client, ang);
	GetAngleVectors(ang, ang, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(ang,ang);
	ScaleVector(ang, 90.0);
	
	DispatchSpawn(index);
	TeleportEntity(index, origin, NULL_VECTOR, ang);

	if (StrEqual(sWeapon, "weapon_chainsaw") || StrEqual(sWeapon, "weapon_pistol") || StrEqual(sWeapon, "weapon_pistol_magnum"))
	{
		SetEntProp(index, Prop_Send, "m_iClip1", clip);
	}
}
