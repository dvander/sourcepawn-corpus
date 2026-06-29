#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>

#define PLUGIN_VERSION "1.4"

#define HHH "models/bots/headless_hatman.mdl"
#define AXE "models/weapons/c_models/c_bigaxe/c_bigaxe.mdl"
#define SPAWN "ui/halloween_boss_summoned_fx.wav"
#define SPAWNRUMBLE "ui/halloween_boss_summon_rumble.wav"
#define SPAWNVO "vo/halloween_boss/knight_spawn.wav"
#define BOO "vo/halloween_boss/knight_alert.wav"
#define DEATH "ui/halloween_boss_defeated_fx.wav"
#define DEATHVO "vo/halloween_boss/knight_death02.wav"
#define DEATHVO2 "vo/halloween_boss/knight_dying.wav"
#define LEFTFOOT "player/footsteps/giant1.wav"
#define RIGHTFOOT "player/footsteps/giant2.wav"

public Plugin:myinfo = 
{
	name = "[TF2] Be the Horsemann",
	author = "FlaminSarge",
	description = "Be the Horsemann",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=166819"
}

new Handle:hCvarThirdPerson;
new Handle:hCvarHealth;
new Handle:hCvarSounds;
new Handle:hCvarBoo;
new bool:g_IsModel[MAXPLAYERS+1] = { false, ... };
new bool:g_bIsTP[MAXPLAYERS+1] = { false, ... };
new bool:g_bIsHHH[MAXPLAYERS + 1] = { false, ... };
new g_iHHHParticle[MAXPLAYERS + 1][3];
//new bool:g_bLeftFootstep[MAXPLAYERS + 1] = { 0, ... };

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("bethehorsemann_version", PLUGIN_VERSION, "[TF2] Be the Horsemann version", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	hCvarHealth = CreateConVar("behhh_health", "750", "Amount of health to ADD to the HHH (stacks on current class health)", FCVAR_PLUGIN);
	hCvarSounds = CreateConVar("behhh_sounds", "1", "Use Horsemann sounds (spawn, death, footsteps; will not disable BOO)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvarBoo = CreateConVar("behhh_boo", "2", "2-Boo stuns nearby enemies; 1-Boo is sound only; 0-no Boo", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	hCvarThirdPerson = CreateConVar("behhh_thirdperson", "1", "Whether or not Horsemenn ought to be in third-person", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	RegAdminCmd("sm_behhh", Command_Horsemann, ADMFLAG_ROOT, "It's a good time to run - turns <target> into a Horsemann");
	AddNormalSoundHook(HorsemannSH);
	HookEvent("post_inventory_application", EventInventoryApplication,  EventHookMode_Post);
	HookEvent("player_death", Event_Death,  EventHookMode_Post);
}
public OnClientPutInServer(client)
{
	OnClientDisconnect_Post(client);
}
public OnClientDisconnect_Post(client)
{
	g_IsModel[client] = false;
	g_bIsTP[client] = false;
	g_bIsHHH[client] = false;
	ClearHorsemannParticles(client);
}
public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		ClearHorsemannParticles(client);
	}
}
public OnMapStart()
{
	PrecacheModel(HHH, true);
	PrecacheModel(AXE, true);
	PrecacheSound(BOO, true);
	PrecacheSound(SPAWN, true);
	PrecacheSound(SPAWNRUMBLE, true);
	PrecacheSound(SPAWNVO, true);
	PrecacheSound(DEATH, true);
	PrecacheSound(DEATHVO, true);
	PrecacheSound(LEFTFOOT, true);
	PrecacheSound(RIGHTFOOT, true);
//	TF2Items_CreateWeapon(8266, "tf_weapon_sword", 266, 2, 5, 100, "15 ; 0 ; 26 ; 750.0 ; 2 ; 999.0 ; 107 ; 4.0 ; 109 ; 0.0 ; 62 ; 0.09 ; 205 ; 0.05 ; 206 ; 0.05 ; 68 ; -2 ; 236 ; 1.0 ; 53 ; 1.0 ; 27 ; 1.0 ; 180 ; -25 ; 219 ; 1.0", _, "models/weapons/c_models/c_bigaxe/c_bigaxe.mdl", true);
}

public EventInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemoveModel(client);
	ClearHorsemannParticles(client);
	if (g_bIsHHH[client])
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
	g_bIsHHH[client] = false;
}
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new deathflags = GetEventInt(event, "death_flags");
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER))
	{
		if (IsValidClient(client) && g_bIsHHH[client])
		{
//			DoHorsemannDeath(client);
			ClearHorsemannParticles(client);
			if (GetConVarBool(hCvarSounds))
			{
				EmitSoundToAll(DEATH);
				EmitSoundToAll(DEATHVO);
			}
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

		g_IsModel[client] = true;
	}
}
public Action:RemoveModel(client)
{
	if (IsValidClient(client) && g_IsModel[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		g_IsModel[client] = false;
	}
//	return Plugin_Handled;
}
/*stock SwitchView (target, bool:observer, bool:viewmodel, bool:self)
{
	SetEntPropEnt(target, Prop_Send, "m_hObserverTarget", observer ? target:-1);
	SetEntProp(target, Prop_Send, "m_iObserverMode", observer ? 1:0);
	SetEntProp(target, Prop_Send, "m_iFOV", observer ? 100 : GetEntProp(target, Prop_Send, "m_iDefaultFOV"));
	SetEntProp(target, Prop_Send, "m_bDrawViewmodel", viewmodel ? 1:0);

	SetVariantBool(self);
	if (self) AcceptEntityInput(target, "SetCustomModelVisibletoSelf");
	g_bIsTP[target] = observer;
}*/
stock ClearHorsemannParticles(client)
{
	for (new i = 0; i < 3; i++)
	{
		new ent = EntRefToEntIndex(g_iHHHParticle[client][i]);
		if (ent > MaxClients && IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
		g_iHHHParticle[client][i] = INVALID_ENT_REFERENCE;
	}
}
stock DoHorsemannParticles(client)
{
/*
halloween_boss_summon
halloween_boss_eye_glow
halloween_boss_foot_impact
halloween_boss_death
*/
	ClearHorsemannParticles(client);
	new lefteye = MakeParticle(client, "halloween_boss_eye_glow", "lefteye");
	if (IsValidEntity(lefteye))
	{
		g_iHHHParticle[client][0] = EntIndexToEntRef(lefteye);
	}
	new righteye = MakeParticle(client, "halloween_boss_eye_glow", "righteye");
	if (IsValidEntity(righteye))
	{
		g_iHHHParticle[client][1] = EntIndexToEntRef(righteye);
	}
/*	new bodyglow = MakeParticle(client, "halloween_boss_shape_glow", "");
	if (IsValidEntity(bodyglow))
	{
		g_iHHHParticle[client][2] = EntIndexToEntRef(bodyglow);
	}*/
}
stock MakeParticle(client, String:effect[], String:attachment[])
{
		decl Float:pos[3];
		decl Float:ang[3];
		decl String:buffer[128];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		GetClientEyeAngles(client, ang);
		ang[0] *= -1;
		ang[1] += 180.0;
		if (ang[1] > 180.0) ang[1] -= 360.0;
		ang[2] = 0.0;
	//	GetAngleVectors(ang, pos2, NULL_VECTOR, NULL_VECTOR);
		new particle = CreateEntityByName("info_particle_system");
		if (!IsValidEntity(particle)) return -1;
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", effect);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", client, particle, 0);
		if (attachment[0] != '\0')
		{
			SetVariantString(attachment);
			AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
		}
		Format(buffer, sizeof(buffer), "%s_%s%d", effect, attachment, particle);
		DispatchKeyValue(particle, "targetname", buffer);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
		AcceptEntityInput(particle, "Start");
		return particle;
}
public Action:Command_Horsemann(client, args)
{
	decl String:arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	if (!StrEqual(arg1, "@me") && !CheckCommandAccess(client, "sm_behhh_others", ADMFLAG_ROOT, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0), /* Only allow alive players. If targetting self, allow self. */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
/*		if (strcmp(arg1, "@me", false) == 0 && target_count == COMMAND_TARGET_IMMUNE)
		{
			target_list[0] = client;
			target_count = 1;
		}
		else*/
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		MakeHorsemann(target_list[i]);
		LogAction(client, target_list[i], "\"%L\" made \"%L\" a Horseless Headless Horsemann", client, target_list[i]);
	}
	if (GetConVarBool(hCvarSounds))
	{
		EmitSoundToAll(SPAWN);
		EmitSoundToAll(SPAWNRUMBLE);
		EmitSoundToAll(SPAWNVO);
	}
	return Plugin_Handled;
}
MakeHorsemann(client)
{
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll > MaxClients && IsValidEntity(ragdoll)) AcceptEntityInput(ragdoll, "Kill");
	decl String:weaponname[32];
	GetClientWeapon(client, weaponname, sizeof(weaponname));
	if (strcmp(weaponname, "tf_weapon_minigun", false) == 0) 
	{
		SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iWeaponState", 0);
		TF2_RemoveCondition(client, TFCond_Slowed);
	}
	TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
	CreateTimer(0.0, Timer_Switch, client);
//	TF2Items_GiveWeapon(client, 8266);
	SetModel(client, HHH);
	if (GetConVarBool(hCvarThirdPerson))
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
	DoHorsemannParticles(client);
	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 5);
	TF2_RemoveWeaponSlot(client, 3);
	TF2_SetHealth(client, 350 + GetConVarInt(hCvarHealth));	//overheal, will seep down to normal max health... probably.
	g_bIsHHH[client] = true;
//	g_bIsTP[client] = true;
}
stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth, 1);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth, 1);
}
public Action:Timer_Switch(Handle:timer, any:client)
{
	if (IsValidClient(client))
		GiveAxe(client);
}
stock GiveAxe(client)
{
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Melee);
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_sword");
		TF2Items_SetItemIndex(hWeapon, 266);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
		new String:weaponAttribs[256];
		//This is so, so bad and I am so very, very sorry, but TF2Attributes will be better.
		Format(weaponAttribs, sizeof(weaponAttribs), "264 ; 1.75 ; 263 ; 1.3 ; 15 ; 0 ; 26 ; %d ; 2 ; 999.0 ; 107 ; 4.0 ; 109 ; 0.0 ; 62 ; 0.70 ; 205 ; 0.05 ; 206 ; 0.05 ; 68 ; -2 ; 69 ; 0.0 ; 53 ; 1.0 ; 27 ; 1.0", GetConVarInt(hCvarHealth));
		new String:weaponAttribsArray[32][32];
		new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);
		if (attribCount > 0) {
			TF2Items_SetNumAttributes(hWeapon, attribCount/2);
			new i2 = 0;
			for (new i = 0; i < attribCount; i+=2) {
				TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
				i2++;
			}
		} else {
			TF2Items_SetNumAttributes(hWeapon, 0);
		}
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
		EquipPlayerWeapon(client, weapon);

		CloseHandle(hWeapon);
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", PrecacheModel(AXE));
		SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", PrecacheModel(AXE), _, 0);
	}	
}
stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}
public Action:HorsemannSH(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
//	decl String:clientModel[64];
	if (!IsValidClient(entity)) return Plugin_Continue;
//	GetClientModel(entity, clientModel, sizeof(clientModel));
	if (!g_bIsHHH[entity]) return Plugin_Continue;
	new boo = GetConVarInt(hCvarBoo);
	if (boo && StrContains(sample, "_medic0", false) != -1)
	{
		sample = BOO;
		if (boo > 1)
		{
			DoHorsemannScare(entity);
		}
		return Plugin_Changed;
	}
	if (GetConVarBool(hCvarSounds) && strncmp(sample, "player/footsteps/", 17, false) == 0)
	{
		if (StrContains(sample, "1.wav", false) != -1 || StrContains(sample, "3.wav", false) != -1) sample = LEFTFOOT;
		else if (StrContains(sample, "2.wav", false) != -1 || StrContains(sample, "4.wav", false) != -1) sample = RIGHTFOOT;
		EmitSoundToAll(sample, entity, _, 150);
//		if (g_bLeftFootstep[client]) sample = LEFTFOOT;
//		else sample = RIGHTFOOT;
//		g_bLeftFootstep[client] = !g_bLeftFootstep[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
DoHorsemannScare(client)
{
	decl Float:HorsemannPosition[3];
	decl Float:pos[3];
	new HorsemannTeam;

	GetClientAbsOrigin(client, HorsemannPosition);
	HorsemannTeam = GetClientTeam(client);
	TF2_StunPlayer(client, 1.3, 1.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i) || HorsemannTeam == GetClientTeam(i))
			continue;

		GetClientAbsOrigin(i, pos);
		if (GetVectorDistance(HorsemannPosition, pos) <= 500 && !FindHHHSaxton(i) && !g_bIsHHH[i])
		{
			TF2_StunPlayer(i, 4.0, 0.3, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_SLOWDOWN);
		}
	}
}
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
//	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
stock bool:FindHHHSaxton(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 277 || idx == 278) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				return true;
			}
		}
	}
	return false;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}