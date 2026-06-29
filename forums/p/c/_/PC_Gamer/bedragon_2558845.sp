#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <bedragon>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION "1.0"

#define HHH		"models/player/pyro.mdl"
#define SPAWN	"#mvm/giant_heavy/giant_heavy_entrance.wav"
#define DEATH	"#mvm/giant_common/giant_common_explodes_01.wav"
#define LOOP	"mvm/giant_pyro/giant_pyro_loop.wav"

#define LEFTFOOT	")mvm/giant_pyro/giant_pyro_step_01.wav"
#define LEFTFOOT1	")mvm/giant_pyro/giant_pyro_step_03.wav"
#define RIGHTFOOT	")mvm/giant_pyro/giant_pyro_step_02.wav"
#define RIGHTFOOT1	")mvm/giant_pyro/giant_pyro_step_04.wav"

#define SOUND_GUNFIRE	")mvm/giant_pyro/giant_pyro_flamethrower_loop.wav"
#define SOUND_GUNSPIN	")"
#define SOUND_WINDUP	")mvm/giant_pyro/giant_pyro_flamethrower_start.wav"
#define SOUND_WINDDOWN	")"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Dragon Fury",
	author = "Pelipoika	(FlamingSarge) modified by Jaster and PC Gamer",
	description = "Play as the Giant Dragon Fury",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.com"
}

new Handle:g_hCvarThirdPerson;
new bool:g_bIsHHH[MAXPLAYERS + 1];

new bool:Locked1[MAXPLAYERS+1];
new bool:Locked2[MAXPLAYERS+1];
new bool:Locked3[MAXPLAYERS+1];
new bool:CanWindDown[MAXPLAYERS+1];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("bedragon_version", PLUGIN_VERSION, "[TF2] Be the Dragon Fury version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	g_hCvarThirdPerson = CreateConVar("bedragon_thirdperson", "0", "Whether or not dragon ought to be in third-person", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_bedragon", Command_dragon, ADMFLAG_ROOT, "It's a good time to run");

	AddNormalSoundHook(dragonSH);
	
	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("bedragon_Makedragon", Native_Setdragon);
	CreateNative("bedragon_Isdragon", Native_Isdragon);
	return APLRes_Success;
}

public OnClientPutInServer(client)
{
	OnClientDisconnect_Post(client);
}

public OnClientDisconnect_Post(client)
{
	if (g_bIsHHH[client])
	{
		StopSound(client, SNDCHAN_AUTO, LOOP);
		StopSound(client, SNDCHAN_AUTO, SOUND_GUNFIRE);
		StopSound(client, SNDCHAN_AUTO, SOUND_GUNSPIN);
		StopSound(client, SNDCHAN_AUTO, SOUND_WINDUP);
		StopSound(client, SNDCHAN_AUTO, SOUND_WINDDOWN);
		g_bIsHHH[client] = false;
	}
}

public OnMapStart()
{
	PrecacheModel(HHH);
	PrecacheSound(SPAWN);
	PrecacheSound(DEATH);
	PrecacheSound(LOOP);
	
	PrecacheSound("mvm/giant_pyro/giant_pyro_step_01.wav");
	PrecacheSound("mvm/giant_pyro/giant_pyro_step_03.wav");
	PrecacheSound("mvm/giant_pyro/giant_pyro_step_02.wav");
	PrecacheSound("mvm/giant_pyro/giant_pyro_step_04.wav");
	
	PrecacheSound(SOUND_GUNFIRE);
	PrecacheSound(SOUND_WINDUP);
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsHHH[client])
	{
		RemoveModel(client);
		
		new weapon = GetPlayerWeaponSlot(client, 0); 
		TF2Attrib_RemoveAll(weapon);
		
		StopSound(client, SNDCHAN_AUTO, LOOP);
		StopSound(client, SNDCHAN_AUTO, SOUND_GUNFIRE);
		StopSound(client, SNDCHAN_AUTO, SOUND_GUNSPIN);
		StopSound(client, SNDCHAN_AUTO, SOUND_WINDUP);
		StopSound(client, SNDCHAN_AUTO, SOUND_WINDDOWN);
		
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		TF2Attrib_RemoveAll(client);
			
		g_bIsHHH[client] = false;
	}
}

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsHHH[client])
		{
			StopSound(client, SNDCHAN_AUTO, LOOP);
			StopSound(client, SNDCHAN_AUTO, SOUND_GUNFIRE);
			StopSound(client, SNDCHAN_AUTO, SOUND_GUNSPIN);
			StopSound(client, SNDCHAN_AUTO, SOUND_WINDUP);
			StopSound(client, SNDCHAN_AUTO, SOUND_WINDDOWN);
			
			TF2Attrib_RemoveAll(client);
			EmitSoundToAll(DEATH);
		}
	}
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", true);
	}
}

public Action:RemoveModel(client)
{
	if (IsValidClient(client))
	{
		new weapon = GetPlayerWeaponSlot(client, 0); 
		
		TF2Attrib_RemoveAll(weapon);
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
		UpdatePlayerHitbox(client, 1.0);

		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
}

public Action:Command_dragon(client, args)
{
	decl String:arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0),
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		Makedragon(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" a Giant Dragon Fury!", client, target_list[i]);
	}
	EmitSoundToAll(SPAWN);
	return Plugin_Handled;
}

Makedragon(client)
{
	TF2_SetPlayerClass(client, TFClass_Pyro);
	TF2_RegeneratePlayer(client);
	EmitSoundToAll(LOOP, client);

	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	CreateTimer(0.0, Timer_Switch, client);
	SetModel(client, HHH);
	
	if (GetConVarBool(g_hCvarThirdPerson))
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
	
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 3);
	
	TF2_SetHealth(client, 3000);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.5);
	UpdatePlayerHitbox(client, 1.6);
	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	g_bIsHHH[client] = true;
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

stock UpdatePlayerHitbox(const client, const Float:fScale)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;
	
	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);
	
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}

public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		Givedragon(client);
}

stock Givedragon(client)
{
	new weapon = GetPlayerWeaponSlot(client, 0); 
	TF2Attrib_SetByName(weapon, "max health additive bonus", 2825.0);
	TF2Attrib_SetByName(weapon, "ammo regen", 100.0);
	TF2Attrib_SetByName(weapon, "damage bonus", 1.20);
	TF2Attrib_SetByName(weapon, "mult_item_meter_charge_rate", 0.2);
	TF2Attrib_SetByName(weapon, "move speed bonus", 0.5);
	TF2Attrib_SetByName(weapon, "damage force reduction", 0.3);
	TF2Attrib_SetByName(weapon, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(weapon, "health from packs decreased", 0.001);
	TF2Attrib_SetByName(weapon, "airblast pushback scale", 5.0);
	
	new weapon2 = GetPlayerWeaponSlot(client, 1); 
	TF2Attrib_SetByName(weapon2, "mult_item_meter_charge_rate", 0.01);
	TF2Attrib_SetByName(weapon2, "thermal_thruster_air_launch", 1.0);	
	
	new weapon3 = GetPlayerWeaponSlot(client, 2); 
	TF2Attrib_SetByName(weapon3, "damage bonus", 1.20);
	TF2Attrib_SetByName(weapon3, "melee attack rate bonus", 0.5);	
	TF2Attrib_SetByName(weapon3, "speed buff ally", 1.0);		
}

public Action:dragonSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!g_bIsHHH[entity]) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_pyro/giant_pyro_step_01.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_pyro/giant_pyro_step_03.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_pyro/giant_pyro_step_02.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_pyro/giant_pyro_step_04.wav");
			EmitSoundToAll(sample, entity);
		}
		return Plugin_Changed;
	}
	
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
	if (!IsValidClient(entity)) return Plugin_Continue;
	new TFClassType:class = TF2_GetPlayerClass(entity);

	if (StrContains(sample, "vo/", false) == -1) return Plugin_Continue;
	if (StrContains(sample, "announcer", false) != -1) return Plugin_Continue;
	if (volume == 0.99997) return Plugin_Continue;
	ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/mght/", false);
	ReplaceString(sample, sizeof(sample), "_", "_m_", false);
	ReplaceString(sample, sizeof(sample), ".wav", ".mp3", false);
	new String:classname[10], String:classname_mvm[15];
	TF2_GetNameOfClass(class, classname, sizeof(classname));
	Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
	ReplaceString(sample, sizeof(sample), classname, classname_mvm, false);
	new String:soundchk[PLATFORM_MAX_PATH];
	Format(soundchk, sizeof(soundchk), "sound/%s", sample);
	PrecacheSound(sample);
	return Plugin_Changed;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVel[3], Float:fAng[3], &iWeapon) 
{
	if (IsValidClient(iClient) && g_bIsHHH[iClient]) 
	{	
		new weapon = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
		if(IsValidEntity(weapon))
		{
			new iWeaponState = GetEntProp(weapon, Prop_Send, "m_iWeaponState");
			if (iWeaponState == 1 && !Locked1[iClient])
			{
				EmitSoundToAll(SOUND_WINDUP, iClient);
			//	PrintToChatAll("WeaponState = Windup");
				
				Locked1[iClient] = true;
				Locked2[iClient] = false;
				Locked3[iClient] = false;
				CanWindDown[iClient] = true;
				
				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNSPIN);
				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
			}
			else if (iWeaponState == 2 && !Locked2[iClient])
			{
				EmitSoundToAll(SOUND_GUNFIRE, iClient);
			//	PrintToChatAll("WeaponState = Firing");
				
				Locked2[iClient] = true;
				Locked1[iClient] = true;
				Locked3[iClient] = false;
				CanWindDown[iClient] = true;
				
				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNSPIN);
				StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
			}
			else if (iWeaponState == 3 && !Locked3[iClient])
			{
				EmitSoundToAll(SOUND_GUNSPIN, iClient);
			//	PrintToChatAll("WeaponState = Spun Up");
				
				Locked3[iClient] = true;
				Locked1[iClient] = true;
				Locked2[iClient] = false;
				CanWindDown[iClient] = true;
				
				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
				StopSound(iClient, SNDCHAN_AUTO, SOUND_WINDUP);
			}
			else if (iWeaponState == 0)
			{
				if (CanWindDown[iClient])
				{
			//		PrintToChatAll("WeaponState = WindDown");
					EmitSoundToAll(SOUND_WINDDOWN, iClient);
					CanWindDown[iClient] = false;
				}
				
				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNSPIN);
				StopSound(iClient, SNDCHAN_AUTO, SOUND_GUNFIRE);
				
				Locked1[iClient] = false;
				Locked2[iClient] = false;
				Locked3[iClient] = false;
			}
		}
	}
}

stock TF2_GetNameOfClass(TFClassType:class, String:name[], maxlen)
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}

public Native_Setdragon(Handle:plugin, args)
	Makedragon(GetNativeCell(1));

public Native_Isdragon(Handle:plugin, args)
	return g_bIsHHH[GetNativeCell(1)];
	
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (g_bIsHHH[victim] && damagecustom == TF_CUSTOM_BACKSTAB)
	{
		new resEntity = GetPlayerResourceEntity();
		damage = float(GetEntProp(resEntity, Prop_Send, "m_iMaxHealth", _, victim)) / 8.0;
		PrintToChatAll("%.2f", damage);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

stock bool:IsValidWeapon(weapon)
{
	if (!IsValidEntity(weapon))
		return false;
	
	decl String:class[64];
	GetEdictClassname(weapon, class, sizeof(class));
	
	if (strncmp(class, "tf_weapon_", 10) == 0 || strncmp(class, "tf_wearable_demoshield", 22) == 0)
		return true;
		
	return false;
}