#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2items_giveweapon>

#define PLUGIN_VERSION "1.0"

#define HHH		"models/yeti/player/heavy.mdl"
#define SPAWN	"/player/taunt_yeti_roar_first.wav"
#define DEATH	"/player/taunt_yeti_roar_second.wav"

#define LEFTFOOT	")mvm/giant_heavy/giant_heavy_step01.wav"
#define LEFTFOOT1	")mvm/giant_heavy/giant_heavy_step03.wav"
#define RIGHTFOOT	")mvm/giant_heavy/giant_heavy_step02.wav"
#define RIGHTFOOT1	")mvm/giant_heavy/giant_heavy_step04.wav"

#define SOUND_GUNFIRE	")mvm/giant_heavy/giant_heavy_gunfire.wav"
#define SOUND_GUNSPIN	")mvm/giant_heavy/giant_heavy_gunspin.wav"
#define SOUND_WINDUP	")mvm/giant_heavy/giant_heavy_gunwindup.wav"
#define SOUND_WINDDOWN	")mvm/giant_heavy/giant_heavy_gunwinddown.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Yeti",
	author = "Pelipoika	(FlamingSarge) modified by PC Gamer",
	description = "Play as the Yeti",
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
	g_hCvarThirdPerson = CreateConVar("beyeti_thirdperson", "1", "Whether or not yeti ought to be in third-person", 0, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_beyeti", Command_yeti, ADMFLAG_SLAY, "It's a good time to run");

	AddNormalSoundHook(yetiSH);
	
	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("Beyeti_Makeyeti", Native_Setyeti);
	CreateNative("Beyeti_Isyeti", Native_Isyeti);
	RegPluginLibrary("beyeti");
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
//		StopSound(client, SNDCHAN_AUTO, LOOP);
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
//	PrecacheSound(LOOP);
	
	PrecacheSound("mvm/giant_heavy/giant_heavy_step01.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step03.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step02.wav");
	PrecacheSound("mvm/giant_heavy/giant_heavy_step04.wav");
	
	PrecacheSound(SOUND_GUNFIRE);
	PrecacheSound(SOUND_GUNSPIN);
	PrecacheSound(SOUND_WINDUP);
	PrecacheSound(SOUND_WINDDOWN);
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bIsHHH[client])
	{
		RemoveModel(client);
		
		new weapon = GetPlayerWeaponSlot(client, 0); 
		TF2Attrib_RemoveAll(weapon);
		
//		StopSound(client, SNDCHAN_AUTO, LOOP);
		StopSound(client, SNDCHAN_AUTO, SOUND_GUNFIRE);
		StopSound(client, SNDCHAN_AUTO, SOUND_GUNSPIN);
		StopSound(client, SNDCHAN_AUTO, SOUND_WINDUP);
		StopSound(client, SNDCHAN_AUTO, SOUND_WINDDOWN);
		
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		TF2Attrib_RemoveAll(client);
		SetWearableAlpha(client, 255);			
			
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
//			StopSound(client, SNDCHAN_AUTO, LOOP);
			StopSound(client, SNDCHAN_AUTO, SOUND_GUNFIRE);
			StopSound(client, SNDCHAN_AUTO, SOUND_GUNSPIN);
			StopSound(client, SNDCHAN_AUTO, SOUND_WINDUP);
			StopSound(client, SNDCHAN_AUTO, SOUND_WINDDOWN);
			
			TF2Attrib_RemoveAll(client);
			
			new weapon = GetPlayerWeaponSlot(client, 0); 
			TF2Attrib_RemoveAll(weapon);

			new weapon2 = GetPlayerWeaponSlot(client, 1); 
			TF2Attrib_RemoveAll(weapon2);
			
			new weapon3 = GetPlayerWeaponSlot(client, 2); 
			TF2Attrib_RemoveAll(weapon3);			
			
			RemoveModel(client);			
			SetWearableAlpha(client, 255);				
//			EmitSoundToAll(DEATH);
		}
	}
}

public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		RemoveModel(client);		
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");

		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		SetWearableAlpha(client, 0);		
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
		SetWearableAlpha(client, 255);		
	}
}

public Action:Command_yeti(client, args)
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
		Makeyeti(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" a Giant yeti Heavy!", client, target_list[i]);
	}
	EmitSoundToAll(SPAWN);
	return Plugin_Handled;
}

Makeyeti(client)
{
	TF2_SetPlayerClass(client, TFClass_Heavy);
	TF2_RegeneratePlayer(client);
//	EmitSoundToAll(LOOP, client);

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
	TF2_RemoveWeaponSlot(client, 2);
	TF2Items_GiveWeapon(client, 1071);

	TF2_SetHealth(client, 5010);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.6);
	UpdatePlayerHitbox(client, 1.6);
	
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
	g_bIsHHH[client] = true;
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
		Giveyeti(client);
}

stock Giveyeti(client)
{
	new weapon = GetPlayerWeaponSlot(client, 0); 
	
	TF2Attrib_SetByName(weapon, "max health additive bonus", 4700.0);
	TF2Attrib_SetByName(weapon, "cannot be backstabbed", 1.0);
	TF2Attrib_SetByName(weapon, "ammo regen", 2.0);
	TF2Attrib_SetByName(weapon, "damage bonus", 6.0);
	TF2Attrib_SetByName(weapon, "armor piercing", 10.0);	
	TF2Attrib_SetByName(weapon, "attack projectiles", 1.0);
	TF2Attrib_SetByName(weapon, "move speed bonus", 2.0);
	TF2Attrib_SetByName(weapon, "damage force reduction", 0.3);
	TF2Attrib_SetByName(weapon, "airblast vulnerability multiplier", 0.3);
	TF2Attrib_SetByName(weapon, "health from packs decreased", 0.001);
	TF2Attrib_SetByName(weapon, "aiming movespeed increased", 1.5);
	TF2Attrib_SetByName(weapon, "dmg taken from fire reduced", 0.5);	
	TF2Attrib_SetByName(weapon, "set bonus: no death from headshots", 1.0);	
	TF2Attrib_SetByName(weapon, "increased jump height", 3.0);	
	TF2Attrib_SetByName(weapon, "cancel falling damage", 1.0);	
	TF2Attrib_SetByName(weapon, "is australium item", 1.0);	
	TF2Attrib_SetByName(weapon, "loot rarity", 1.0);		
	TF2Attrib_SetByName(weapon, "item style override", 1.0);
	TF2Attrib_SetByName(weapon, "killstreak tier", 3.0);
	TF2Attrib_SetByName(weapon, "killstreak effect", 2005.0);
	TF2Attrib_SetByName(weapon, "killstreak idleeffect", 4.0);	
	
	new weapon2 = GetPlayerWeaponSlot(client, 1);
	TF2Attrib_SetByName(weapon2, "fire rate bonus", 0.2);	
	TF2Attrib_SetByName(weapon2, "faster reload rate", 0.1);
	TF2Attrib_SetByName(weapon2, "damage bonus", 6.0);
	TF2Attrib_SetByName(weapon2, "armor piercing", 10.0);	
	TF2Attrib_SetByName(weapon2, "projectile penetration", 1.0);
	TF2Attrib_SetByName(weapon2, "attack projectiles", 1.0);				
	TF2Attrib_SetByName(weapon2, "maxammo secondary increased", 3.0);
	TF2Attrib_SetByName(weapon2, "clip size bonus", 5.0);
	TF2Attrib_SetByName(weapon2, "ammo regen", 2.0);
	TF2Attrib_SetByName(weapon2, "killstreak tier", 3.0);
	TF2Attrib_SetByName(weapon2, "killstreak effect", 2005.0);
	TF2Attrib_SetByName(weapon2, "killstreak idleeffect", 7.0);	
	
	new weapon3 = GetPlayerWeaponSlot(client, 2); 
	TF2Attrib_SetByName(weapon3, "damage bonus", 6.00);
	TF2Attrib_SetByName(weapon3, "armor piercing", 10.0);	
	TF2Attrib_SetByName(weapon3, "melee attack rate bonus", 0.4);	
	TF2Attrib_SetByName(weapon3, "speed buff ally", 1.0);	
	TF2Attrib_SetByName(weapon3, "item style override", 0.0);
	TF2Attrib_SetByName(weapon3, "loot rarity", 1.0);		
	TF2Attrib_SetByName(weapon3, "turn to gold", 1.0);
	TF2Attrib_SetByName(weapon3, "killstreak tier", 3.0);
	TF2Attrib_SetByName(weapon3, "killstreak effect", 2005.0);
	TF2Attrib_SetByName(weapon3, "killstreak idleeffect", 4.0);		
	
	TF2_RemoveAllWearables(client);
}

public Action:yetiSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!IsValidClient(entity)) return Plugin_Continue;
	if (!g_bIsHHH[entity]) return Plugin_Continue;

	if (strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step01.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "3.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step03.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "2.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step02.wav");
			EmitSoundToAll(sample, entity);
		}
		else if (StrContains(sample, "4.wav", false) != -1)
		{
			Format(sample, sizeof(sample), "mvm/giant_heavy/giant_heavy_step04.wav");
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

public Native_Setyeti(Handle:plugin, args)
	Makeyeti(GetNativeCell(1));

public Native_Isyeti(Handle:plugin, args)
	return g_bIsHHH[GetNativeCell(1)];
	
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}

stock TF2_RemoveAllWearables(client)
{
	new wearable = -1;
	while ((wearable = FindEntityByClassname(wearable, "tf_wearable*")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_powerup_bottle")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}

	while ((wearable = FindEntityByClassname(wearable, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(wearable))
		{
			new player = GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity");
			if (client == player)
			{
				TF2_RemoveWearable(client, wearable);
			}
		}
	}
}

stock SetWearableAlpha(client, alpha, bool:override = false)
{
	new count;
	for (new z = MaxClients + 1; z <= 2048; z++)
	{
		if (!IsValidEntity(z)) continue;
		decl String:cls[35];
		GetEntityClassname(z, cls, sizeof(cls));
		if (!StrEqual(cls, "tf_wearable") && !StrEqual(cls, "tf_powerup_bottle")) continue;
		if (client != GetEntPropEnt(z, Prop_Send, "m_hOwnerEntity")) continue;
		{
			SetEntityRenderMode(z, RENDER_TRANSCOLOR);
			SetEntityRenderColor(z, 255, 255, 255, alpha);
		}
		if (alpha == 0) AcceptEntityInput(z, "Kill");
		count++;
	}
	return count;
}
