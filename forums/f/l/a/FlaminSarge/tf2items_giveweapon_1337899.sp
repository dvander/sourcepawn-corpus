#pragma semicolon 1 // Force strict semicolon mode.
//#tf2items_giveweapon#

#include <sourcemod>
#define REQUIRE_EXTENSIONS
#include <tf2items>
#include <tf2_stocks>
#include <sdktools>
#undef REQUIRE_PLUGIN
#tryinclude <visweps>
#tryinclude <tf2itemsinfo>
#define REQUIRE_PLUGIN

//#define TF2ITEMSOLD

#define PLUGIN_NAME		"[TF2Items] Give Weapon"
#define PLUGIN_AUTHOR		"FlaminSarge (orig by asherkin)"
#define PLUGIN_VERSION		"3.14159" //as of Nov29, 2013, Pi Round 4?
#define PLUGIN_CONTACT		"https://forums.alliedmods.net/showthread.php?t=141962"
#define PLUGIN_DESCRIPTION	"Give any weapon to any player on command"

#define EF_BONEMERGE			(1 << 0)
#define EF_BONEMERGE_FASTCULL	(1 << 7)

new iPermItems[MAXPLAYERS+1][6];
new Handle:hItemInfoTrie = INVALID_HANDLE;
#if defined _visweps_included
new bool:bVisWeps = false;
#endif
#if defined _tf2itemsinfo_included
new bool:bTF2ItemsInfo = false;
new Handle:hCvarTF2II = INVALID_HANDLE;
#endif
//new rnd_isenabled;
new iCvarNotify;
new iCvarValveWeapons;
new bool:bCvarLowAdmins;
new bool:bCvarGimme;
new bJarated[MAXPLAYERS + 1];
new iLastButtons[MAXPLAYERS + 1];

new bool:bSDKStarted = false;
new Handle:hSDKEquipWearable;
//new Handle:hMaxHealth;
new Handle:hChargeTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new iEyeParticle[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };
//new Handle:g_hFireProjectile;

public Plugin:myinfo = {
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	new Handle:cv_version = CreateConVar("tf2items_giveweapon_version", PLUGIN_VERSION, "[TF2Items] Give Weapon Version", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	new Handle:cv_notify = CreateConVar("tf2items_giveweapon_notify", "2", "If 1, makes Give Weapon show the plugin activity for givew only. If 2, makes it show activity for both givew and givew_ex.", FCVAR_PLUGIN);
	new Handle:cv_valveweps = CreateConVar("tf2items_valveweapons", "1337", "1337 to allow giving Valve weapons, anything else to disallow. Just because I got annoyed.", FCVAR_PLUGIN);
	new Handle:cv_lowadmins = CreateConVar("tf2items_customweapons_lowadmins", "1", "0 to disallow lower admins giving themselves custom weapons, 1 to allow. Just because I got annoyed.", FCVAR_PLUGIN);
	new Handle:cv_gimme = CreateConVar("tf2items_allow_gimme", "1", "0 to disallow the use of sm_gimme, 1 to allow", FCVAR_PLUGIN);

	RegAdminCmd("sm_giveweapon", Command_Weapon, ADMFLAG_CHEATS, "sm_giveweapon <player> <itemindex>");
	RegAdminCmd("sm_giveweapon_ex", Command_WeaponEx, ADMFLAG_CHEATS, "Give Permanent Weapon sm_giveweapon_ex <player> <itemindex>");
	RegAdminCmd("sm_ludmila", Command_GiveLudmila, ADMFLAG_GENERIC, "Give Ludmila to yourself using sm_ludmila");
	RegAdminCmd("sm_glovesofrunning", Command_GiveGlovesofRunning, ADMFLAG_GENERIC, "Give the Gloves of Running Urgently to yourself using sm_gloves or sm_glovesofrunning");
	RegAdminCmd("sm_spycrabpda", Command_GiveSpycrabPDA, ADMFLAG_CHEATS, "Give the Spycrab PDA to yourself with sm_spycrabpda or sm_spycrab");
	RegAdminCmd("sm_gloves", Command_GiveGlovesofRunning, ADMFLAG_GENERIC, "Give the Gloves of Running Urgently to yourself using sm_gloves or sm_glovesofrunning");
	RegAdminCmd("sm_spycrab", Command_GiveSpycrabPDA, ADMFLAG_CHEATS, "Give the Spycrab PDA to yourself with sm_spycrabpda or sm_spycrab");
	RegAdminCmd("sm_givew", Command_Weapon, ADMFLAG_CHEATS, "sm_givew <player> <itemindex>");
	RegAdminCmd("sm_givew_ex", Command_WeaponEx, ADMFLAG_CHEATS, "Give Permanent Weapon sm_givew_ex <player> <itemindex>");
	RegAdminCmd("sm_addwearable", Command_AddWearable, ADMFLAG_CHEATS, "Add a wearable weapon to a player sm_addwearable <player> <itemindex>");
	RegAdminCmd("sm_addwr", Command_AddWearable, ADMFLAG_CHEATS, "Add a wearable weapon to a player sm_addwearable <player> <itemindex>");
	RegAdminCmd("tf2items_giveweapon_reload", Command_ReloadCustoms, ADMFLAG_CHEATS, "Reloads custom items list");
	RegAdminCmd("sm_resetex", Command_ResetEx, ADMFLAG_GENERIC, "Reset the Permanent Weapons of a Player sm_resetex <target>");
	RegAdminCmd("sm_gimme", Command_Gimme, ADMFLAG_KICK, "Give self a weapon sm_gimme <itemindex>");

	AddCommandListener(Cmd_taunt, "+taunt");
	AddCommandListener(Cmd_taunt, "taunt");
	AddCommandListener(Cmd_taunt, "+use_action_slot_item_server");
	AddCommandListener(Cmd_taunt, "use_action_slot_item_server");

//	MarkNativeAsOptional("VisWep_GiveWeapon");
	SetConVarString(cv_version, PLUGIN_VERSION);
	HookConVarChange(cv_version, cvhook_version);
	iCvarNotify = GetConVarInt(cv_notify);
	iCvarValveWeapons = GetConVarInt(cv_valveweps);
	bCvarLowAdmins = GetConVarBool(cv_lowadmins);
	bCvarGimme = GetConVarBool(cv_gimme);

	HookConVarChange(cv_valveweps, cvhook_valveweps);
	HookConVarChange(cv_notify, cvhook_notify);
	HookConVarChange(cv_lowadmins, cvhook_lowadmins);
	HookConVarChange(cv_gimme, cvhook_gimme);
	HookUserMessage(GetUserMessageId("PlayerJarated"), Event_PlayerJarated);
	HookUserMessage(GetUserMessageId("PlayerJaratedFade"), Event_PlayerJaratedFade);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("post_inventory_application", lockerwepreset,  EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);

#if defined _visweps_included
	bVisWeps = LibraryExists("visweps");
#endif
#if defined _tf2itemsinfo_included
	hCvarTF2II = CreateConVar("tf2items_use_tf2ii", "1", "Enable/disable tf2ii plugin usage", FCVAR_PLUGIN);
	bTF2ItemsInfo = LibraryExists("tf2itemsinfo");
#endif
	CreateItemInfoTrie();
	TF2_SdkStartup();
	for (new i = 0; i <= MaxClients; i++)
	{
		OnClientPutInServer(i);
	}
}
public OnPluginEnd()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		ClearEyeParticle(client);
	}
}
public cvhook_version(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (strcmp(newVal, PLUGIN_VERSION, false) != 0)
		SetConVarString(cvar, PLUGIN_VERSION);
}
public cvhook_notify(Handle:cvar, const String:oldVal[], const String:newVal[]) { iCvarNotify = GetConVarInt(cvar); }
public cvhook_valveweps(Handle:cvar, const String:oldVal[], const String:newVal[]) { iCvarValveWeapons = GetConVarInt(cvar); }
public cvhook_lowadmins(Handle:cvar, const String:oldVal[], const String:newVal[]) { bCvarLowAdmins = GetConVarBool(cvar); }
public cvhook_gimme(Handle:cvar, const String:oldVal[], const String:newVal[]) { bCvarGimme = GetConVarBool(cvar); }

public OnLibraryAdded(const String:strName[])
{
#if defined _visweps_included
	if(strcmp(strName, "visweps", false) == 0)
		bVisWeps = true;
#endif
#if defined _tf2itemsinfo_included
	if(strcmp(strName, "tf2itemsinfo", false) == 0)
	{
		bTF2ItemsInfo = true;
		CreateItemInfoTrie();
	}
#endif
}
public OnLibraryRemoved(const String:strName[])
{
#if defined _visweps_included
	if (strcmp(strName, "visweps", false) == 0)
		bVisWeps = false;
#endif
#if defined _tf2itemsinfo_included
	if(strcmp(strName, "tf2itemsinfo", false) == 0)
	{
		bTF2ItemsInfo = false;
//		CreateItemInfoTrie();
	}
#endif
}

public OnMapStart()
{
	for (new client = 1; client < MaxClients; client++)
	{
		OnClientPutInServer(client);
	}
	PrepareAllModels();
	PrecacheSound("player/recharged.wav", true);
	PrecacheSound("vo/pyro_laughhappy01.wav", true);
	PrecacheSound("vo/pyro_paincrticialdeath01.wav", true);
	PrecacheSound("vo/pyro_paincrticialdeath03.wav", true);
	PrecacheSound("weapons/drg_wrench_teleport.wav", true);
	if (FileExists("models/buildables/toolbox_placement_sentry1.mdl", true)) PrecacheModel("models/buildables/toolbox_placement_sentry1.mdl", true);
	if (FileExists("models/buildables/toolbox_placement.mdl", true)) PrecacheModel("models/buildables/toolbox_placement.mdl", true);
	if (FileExists("models/buildables/toolbox_placed.mdl", true)) PrecacheModel("models/buildables/toolbox_placed.mdl", true);
}

public OnClientPutInServer(client)
{
	for (new i = 0; i < 6; i++)
	{
		if (iPermItems[client][i] != -1)
		{
			iPermItems[client][i] = -1;
		}
	}
	bJarated[client] = false;
	ClearTimer(hChargeTimer[client]);
	ClearEyeParticle(client);
}

public OnClientDisconnect_Post(client)
{
	OnClientPutInServer(client);
}
public Action:Cmd_taunt(client, String:cmd[], args)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	decl String:arg1[32];
	if (args > 0)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		if (StrEqual(arg1, "AmputatorFix")) return Plugin_Continue;
	}
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class != TFClass_Spy && (TF2_IsPlayerInCondition(client, TFCond_Disguised) || TF2_IsPlayerInCondition(client, TFCond_Disguising))) return Plugin_Handled;
	if (StrContains(cmd, "taunt", false) != -1
		&& (GetEntityFlags(client) & FL_ONGROUND)
		&& !TF2_IsPlayerInCondition(client, TFCond_Taunting)
		&& !TF2_IsPlayerInCondition(client, TFCond_Cloaked)
		&& !TF2_IsPlayerInCondition(client, TFCond_Disguised)
		&& !TF2_IsPlayerInCondition(client, TFCond_Disguising)
		&& class != TFClass_Medic
		&& GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 304
		&& GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
	{
//		new Handle:pack;
//		CreateDataTimer(0.0, Timer_SetAmpTauntBack, pack, TIMER_FLAG_NO_MAPCHANGE);
//		WritePackCell(pack, GetClientUserId(client));
//		WritePackCell(pack, _:TF2_GetPlayerClass(client));
		TF2_SetPlayerClass(client, TFClass_Medic, _, false);
		FakeClientCommand(client, "taunt AmputatorFix");
		TF2_SetPlayerClass(client, class, _, false);
		if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
		{
			//new bool:healing = TF2_IsPlayerInCondition(client, TFCond_Healing);
			TF2_AddCondition(client, TFCond:55, 4.2);
			CreateTimer(0.05, Timer_RemoveHealing, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
/*public Action:Timer_SetAmpTauntBack(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = GetClientOfUserId(ReadPackCell(pack));
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;
	new TFClassType:class = TFClassType:ReadPackCell(pack);
	TF2_SetPlayerClass(client, class, _, false);
	if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
	{
		//new bool:healing = TF2_IsPlayerInCondition(client, TFCond_Healing);
		TF2_AddCondition(client, TFCond:55, 4.2);
		CreateTimer(0.05, Timer_RemoveHealing, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Stop;
}*/
public Action:Timer_RemoveHealing(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;
	if (!TF2_IsPlayerInCondition(client, TFCond:55) || !TF2_IsPlayerInCondition(client, TFCond_Taunting)) return Plugin_Stop;
	if (GetEntProp(client, Prop_Send, "m_nNumHealers") <= 1) TF2_RemoveCondition(client, TFCond_Healing);
	return Plugin_Continue;
}
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Error-checking
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client) return;
	if (!IsPlayerAlive(client)) return;
	ClearEyeParticle(client);
	bJarated[client] = false;
/*	if (TF2_GetPlayerClass(client) != TFClass_Soldier && TF2_GetPlayerClass(client) != TFClass_Pyro)
	{
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 0.0);
		SetEntProp(client, Prop_Send, "m_bRageDraining", 0);
	}*/
}

public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
//	if (rnd_isenabled) return Plugin_Continue;
	new deathflags = GetEventInt(event, "death_flags");
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	new custom = GetEventInt(event, "customkill");
	new weaponid = GetEventInt(event, "weaponid");
	new inflictor = GetEventInt(event, "inflictor_entindex");
	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	ClearEyeParticle(client);
	if (!IsValidEdict(inflictor))
	{
		inflictor = 0;
	}
/* 	if (weaponid == TF_WEAPON_WRENCH)
	{
		if (inflictor > 0 && inflictor <= MaxClients && IsClientInGame(inflictor))
		{
			new weaponent = GetEntPropEnt(inflictor, Prop_Send, "m_hActiveWeapon");
			if (weaponent > -1 && GetEntProp(weaponent, Prop_Send, "m_iItemDefinitionIndex") == 197 && GetEntProp(weaponent, Prop_Send, "m_iEntityLevel") == (-128+13)) //Checking if it's a Rebel's Curse
			{
				CreateTimer(0.1, Timer_DissolveRagdoll, userid);
			}
		}
	} */
	if (custom == TF_CUSTOM_DECAPITATION && weaponid == TF_WEAPON_SWORD && IsValidClient(attacker) && IsPlayerAlive(attacker) && TF2_GetPlayerClass(attacker) != TFClass_DemoMan && !StrEqual(weapon, "demokatana"))
	{
		if (StrEqual(weapon, "sword", false) || StrEqual(weapon, "nessieclub", false) || StrEqual(weapon, "headtaker", false)) AddDecapitation(attacker, client);
	}
	if (!(deathflags & TF_DEATHFLAG_DEADRINGER) && weaponid == TF_WEAPON_KNIFE && custom == TF_CUSTOM_BACKSTAB && IsValidClient(attacker) && IsPlayerAlive(attacker) && TF2_GetPlayerClass(attacker) != TFClass_Spy)
	{
		if (StrEqual(weapon, "eternal_reward", false) || StrEqual(weapon, "voodoo_pin", false)) InstantDisguise(attacker, client);
	}
	if (IsValidClient(assister) && IsPlayerAlive(assister) && GetIndexOfWeaponSlot(assister, TFWeaponSlot_Primary) == 752 && TF2_GetPlayerClass(assister) != TFClass_Sniper)
	{
		new Float:rage = GetEntPropFloat(assister, Prop_Send, "m_flRageMeter");
		rage += 15.0;
		if (rage > 100.0) rage = 100.0;
		SetEntPropFloat(assister, Prop_Send, "m_flRageMeter", rage);
	}
	if (IsValidClient(attacker) && IsPlayerAlive(attacker) && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 752 && TF2_GetPlayerClass(attacker) != TFClass_Sniper)
	{
		new Float:rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
		rage += 35.0;
		if (rage > 100.0) rage = 100.0;
		SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", rage);
	}
	return Plugin_Continue;
}

public Action:Timer_DissolveRagdoll(Handle:timer, any:userid)
{
	new victim = GetClientOfUserId(userid);
	new ragdoll = (IsValidClient(victim) ? GetEntPropEnt(victim, Prop_Send, "m_hRagdoll") : -1);
	if (IsValidEntity(ragdoll))
	{
		DissolveRagdoll(ragdoll);
	}
}
stock DissolveRagdoll(ragdoll, team = 0)
{
	new dissolver = CreateEntityByName("env_entity_dissolver");

	if (!IsValidEntity(dissolver))
	{
		return;
	}
//	if (team) SetEntProp(dissolver, Prop_Send, "m_iTeamNum", team);
	DispatchKeyValue(dissolver, "dissolvetype", "0");
	DispatchKeyValue(dissolver, "magnitude", "200");
	DispatchKeyValue(dissolver, "target", "!activator");

	AcceptEntityInput(dissolver, "Dissolve", ragdoll);
	AcceptEntityInput(dissolver, "Kill");
//	PrintToChatAll("dissolving2");

	return;
}
stock AddDecapitation(client, victim)
{
	new heads = GetEntProp(client, Prop_Send, "m_iDecapitations") + 1;
	if (IsValidClient(victim)) heads += GetEntProp(victim, Prop_Send, "m_iDecapitations");
	SetEntProp(client, Prop_Send, "m_iDecapitations", heads);
	if (!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
	{
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);
	}
	ChangeEyeParticle(client);
}

stock InstantDisguise(client, victim)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	TF2_SetPlayerClass(client, TFClass_Spy, _, false);
	new TFTeam:team = TFTeam:GetClientTeam(victim);
	if (team != TFTeam_Red && team != TFTeam_Blue) team = ((GetClientTeam(client) == _:TFTeam_Red) ? (TFTeam_Blue) : (TFTeam_Red));
	TF2_DisguisePlayer(client, team, TF2_GetPlayerClass(victim), victim);
	TF2_SetPlayerClass(client, class, _, false);
/*	TF2_AddCondition(client, TFCond_Disguised, -1.0);
	SetEntProp(client, Prop_Send, "m_nDisguiseTeam", GetClientTeam(victim));
	SetEntProp(client, Prop_Send, "m_nDisguiseClass", _:TF2_GetPlayerClass(victim));
	SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", victim);
	SetEntProp(client, Prop_Send, "m_iDisguiseHealth", TF2_GetMaxHealth(victim));*/
//	SetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon", CreateDisguiseWeapon(victim));
//	SetEntProp(client, Prop_Send, "m_iDisguiseBody", GetEntProp(victim, Prop_Send, "m_nBody"));
}

stock CreateDisguiseWeapon(client, victim)
{
	decl String:formatBuffer[32], String:weaponClassname[64];
	new victimwep = GetPlayerWeaponSlot(victim, TFWeaponSlot_Primary);
	new idx = (victimwep > MaxClients && IsValidEntity(victimwep) ? GetEntProp(victimwep, Prop_Send, "m_iItemDefinitionIndex") : -1);
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", idx, "classname");
	if (!GetTrieString(hItemInfoTrie, formatBuffer, weaponClassname, sizeof(weaponClassname)) || strncmp(weaponClassname, "tf_wearable", 11, false) == 0)
	{
		idx = GetDefaultWeaponIndex(TF2_GetPlayerClass(victim), TFWeaponSlot_Primary);
		Format(formatBuffer, sizeof(formatBuffer), "%d_%s", idx, "classname");
		GetTrieString(hItemInfoTrie, formatBuffer, weaponClassname, sizeof(weaponClassname));
	}
	// Start TF2Items generation method
	new Handle:hWeapon = PrepareItemHandle(idx);
	if (hWeapon != INVALID_HANDLE)
	{
		new weapon = TF2Items_GiveWeapon(client, hWeapon);
		SetEntProp(weapon, Prop_Send, "m_bDisguiseWeapon", 1);
		SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
		SetEntPropEnt(weapon, Prop_Send, "m_hOwner", client);
		SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
		CloseHandle(hWeapon);
		return weapon;
	}
/*	new actualindex;
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", idx, "index");
	GetTrieValue(hItemInfoTrie, formatBuffer, actualindex);
//	new weapon = GivePlayerItem(victim, weaponClassname);
	new weapon = CreateEntityByName(weaponClassname);
	if (!IsValidEntity(weapon))
	{
		PrintToChatAll("Invalid weapon");
		return -1;
	}
	SetEntProp(weapon, Prop_Send, "m_bDisguiseWeapon", 1);
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", idx);
	SetEntProp(weapon, Prop_Send, "m_iEntityQuality", (idx < 29) ? 0 : 6);
	SetEntProp(weapon, Prop_Send, "m_iEntityLevel", 10);
	SetEntPropEnt(weapon, Prop_Send, "m_hOwner", client);
	SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
	SetEntPropEnt(weapon, Prop_Send, "moveparent", client);
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 1);
	DispatchSpawn(weapon);
	return weapon;*/
}

stock GetDefaultWeaponIndex(TFClassType:class, slot)
{
	static defweps[TFClassType][3] = {
		{ -1, -1, -1 },		//Unknown
		{ 13, 23, 0 },		//Scout
		{ 14, 16, 3 },		//Sniper
		{ 18, 10, 6 },		//Soldier
		{ 19, 20, 1 },		//Demoman
		{ 17, 29, 8 },		//Medic
		{ 15, 11, 5 },		//Heavy
		{ 21, 12, 2 },		//Pyro
		{ 24, 735, 4 },		//Spy
		{ 9, 22, 7 }		//Engineer
	};
	return defweps[class][slot];
}

stock ClearEyeParticle(client)
{
	new eye = EntRefToEntIndex(iEyeParticle[client]);
	if (eye > MaxClients && IsValidEntity(eye)) AcceptEntityInput(eye, "Kill");
	iEyeParticle[client] = INVALID_ENT_REFERENCE;
}
stock ChangeEyeParticle(client)
{
	ClearEyeParticle(client);
	new decap = GetEntProp(client, Prop_Send, "m_iDecapitations");
	if (decap <= 0) return;
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle)) return;
	decl Float:pos[3];
	decl Float:ang[3];
	decl String:effect[64];
	Format(effect, sizeof(effect), "eye_powerup_%s_lvl_%d", (TFTeam:GetClientTeam(client) == TFTeam_Red) ? "red" : "blue", decap > 4 ? 4 : decap);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	GetClientEyeAngles(client, ang);
	ang[0] *= -1;
	ang[1] += 180.0;
	if (ang[1] > 180.0) ang[1] -= 360.0;
	ang[2] = 0.0;
	TeleportEntity(particle, pos, ang, NULL_VECTOR);
	DispatchKeyValue(particle, "effect_name", effect);
	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", client, particle, 0);
	SetVariantString("lefteye");
	AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
	DispatchKeyValue(particle, "targetname", "demoeyeglow");
	DispatchSpawn(particle);
	ActivateEntity(particle);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", client);
	AcceptEntityInput(particle, "Start");
	iEyeParticle[client] = EntIndexToEntRef(particle);
}
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return;
	new weapon = GetEventInt(event, "weaponid");
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "damageamount");
	new custom = GetEventInt(event, "custom");
	if (weapon == TF_WEAPON_SNIPERRIFLE && TF2_IsPlayerInCondition(client, TFCond_Jarated))
	{
		bJarated[client] = true;
	}
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (attacker == client)
	{
		if (!IsPlayerAlive(client)) return;
		if (class == TFClass_Soldier || class == TFClass_DemoMan) return;
		new jumpstate = 1;
		new bool:playsound = false;
		if (weapon == TF_WEAPON_ROCKETLAUNCHER && GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 237)
		{
			playsound = true;
		}
		if (weapon == TF_WEAPON_PIPEBOMBLAUNCHER)
		{
			jumpstate = 2;
		}
		if (custom == TF_CUSTOM_PRACTICE_STICKY)
		{
			jumpstate = 2;
			playsound = true;
		}
		SetBlastJumpState(client, jumpstate, playsound);
		return;
	}
	new buffclient = GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary);
/*	if (IsValidClient(attacker) && IsPlayerAlive(client) && class != TFClass_Soldier && (buffclient == 226 || buffclient == 354) && !GetEntProp(client, Prop_Send, "m_bRageDraining"))
	{
		new Float:rage = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
		if (buffclient == 354) rage += (damage / 3.33);
		else rage += (damage / 3.50);
		if (rage > 100.0) rage = 100.0;
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", rage);
	}*/
	if (IsValidClient(attacker) && IsPlayerAlive(client) && class != TFClass_Soldier && buffclient == 226 && !GetEntProp(client, Prop_Send, "m_bRageDraining"))
	{
		new Float:rage = GetEntPropFloat(client, Prop_Send, "m_flRageMeter");
		rage += (damage / 3.50);
		if (rage > 100.0) rage = 100.0;
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", rage);
	}
	if (!IsValidClient(attacker)) return;
	if (!IsPlayerAlive(attacker)) return;
	if (weapon == TF_WEAPON_MINIGUN && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 15 && GetEntProp(GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary), Prop_Send, "m_iEntityLevel") == (-128+5) && (GetClientButtons(attacker) & (IN_ATTACK|IN_ATTACK2)) == IN_ATTACK2)
	{
		new health = GetClientHealth(attacker);
		if (health < TF2_GetMaxHealth(attacker))
		{
			health += 3;
			TF2_SetHealth(attacker, health);
		}
		new Handle:healevent = CreateEvent("player_healonhit", true);
		SetEventInt(healevent, "entindex", attacker);
		SetEventInt(healevent, "amount", 3);
		FireEvent(healevent);
	}
	new TFClassType:attackerclass = TF2_GetPlayerClass(attacker);
	if (weapon == TF_WEAPON_BONESAW && attackerclass != TFClass_Medic && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee) == 37)
	{
		decl String:secondary[64];
		new sec = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Secondary);
		if (sec > MaxClients && IsValidEntity(sec) && GetEntityClassname(sec, secondary, sizeof(secondary)) && StrEqual(secondary, "tf_weapon_medigun", false))
		{
			new Float:charge = GetEntPropFloat(sec, Prop_Send, "m_flChargeLevel");
			charge += 0.25;
			if (charge > 1.0) charge = 1.0;
			SetEntPropFloat(sec, Prop_Send, "m_flChargeLevel", charge);
		}
	}
	if (GetEntProp(attacker, Prop_Send, "m_bRageDraining")) return;
	if ((custom == TF_CUSTOM_BURNING || custom == TF_CUSTOM_BURNING_FLARE) && attackerclass != TFClass_Pyro && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 594 && GetEntPropFloat(attacker, Prop_Send, "m_flNextRageEarnTime") <= GetGameTime())
	{
		new Float:rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
		rage += (damage / 2.25);
		if (rage > 100.0) rage = 100.0;
		SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", rage);
	}
	buffclient = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Secondary);
	if (attackerclass != TFClass_Soldier && (buffclient == 129 || buffclient == 354))
	{
		if (custom == TF_CUSTOM_BURNING && GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 594) return;
		new Float:rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
		if (buffclient == 354) rage += (damage / 4.80);
		else rage += (damage / 6.0);
		if (rage > 100.0) rage = 100.0;
		SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", rage);
	}
}

stock SetBlastJumpState(client, jumpstate, bool:playsound)
{
	new offs = FindSendPropInfo("CTFPlayer", "m_iSpawnCounter") + 12;
	if (offs == 11 || offs == 12) return;
	SetEntData(client, offs, GetEntData(client, offs) | jumpstate);
	if (jumpstate == 1 || jumpstate == 2)
	{
		new Handle:event = CreateEvent(jumpstate == 2 ? "sticky_jump" : "rocket_jump", true);
		SetEventInt(event, "userid", GetClientUserId(client));
		SetEventBool(event, "playsound", playsound);
		FireEvent(event);
	}
}

stock GetIndexOfWeaponSlot(client, slot)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon > MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}
public Action:Event_PlayerJaratedFade(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	BfReadByte(bf); //client
	new victim = BfReadByte(bf);
	bJarated[victim] = false;
}
public Action:Event_PlayerJarated(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = BfReadByte(bf);
	new victim = BfReadByte(bf);
	new jar = GetPlayerWeaponSlot(client, 1);
	if (jar != -1 && GetEntProp(jar, Prop_Send, "m_iItemDefinitionIndex") == 58 && GetEntProp(jar, Prop_Send, "m_iEntityLevel") == (-128+6))
	{
		if (!bJarated[victim]) CreateTimer(0.0, Timer_NoPiss, GetClientUserId(victim));	//TF2_RemoveCondition(victim, TFCond_Jarated);
		TF2_MakeBleed(victim, client, 10.0);
	}
	else bJarated[victim] = true;
	return Plugin_Continue;
}
public Action:Timer_NoPiss(Handle:timer, any:userid)
{
	new victim = GetClientOfUserId(userid);
	if (IsValidClient(victim)) TF2_RemoveCondition(victim, TFCond_Jarated);
}
/*public OnAllPluginsLoaded()
{
	new Handle:randomizerhandle = FindConVar("tf2items_rnd_enabled");
	if (randomizerhandle != INVALID_HANDLE)
	{
		rnd_isenabled = GetConVarBool(randomizerhandle);
		HookConVarChange(randomizerhandle, cvhook_rndisenabled);
	}
}*/
//public cvhook_rndisenabled(Handle:cvar, const String:oldVal[], const String:newVal[]) { rnd_isenabled = GetConVarBool(cvar); }

public lockerwepreset(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, Timer_LockerWeaponReset, GetClientUserId(client));
	ClearTimer(hChargeTimer[client]);
}

public Action:Timer_LockerWeaponReset(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	new bool:checkhealth = false;
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		for (new i = 0; i < 6; i++)
		{
			if (iPermItems[client][i] != -1)
			{
				GiveWeaponOfIndex(client, iPermItems[client][i], i);
				checkhealth = true;
			}
		}
		if (checkhealth) CreateTimer(0.1, Timer_CheckHealth, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action:Timer_CheckHealth(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		if (GetClientHealth(client) > RoundToFloor(1.5 * TF2_GetMaxHealth(client))) TF2_SetHealth(client, RoundToFloor(1.5 * TF2_GetMaxHealth(client)));
		else if (GetClientHealth(client) < TF2_GetMaxHealth(client)) TF2_SetHealth(client, TF2_GetMaxHealth(client));
	}
}
/*public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)		//STRANGE STUFF HAPPENS HERE
{
	new flags = OVERRIDE_ITEM_DEF|PRESERVE_ATTRIBUTES;
	hItem = TF2Items_CreateItem(flags);

	new weaponSlot;
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", iItemDefinitionIndex, "slot");
	GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);


	if (iPermItems[client][weaponSlot] != -1)
	{
		PrintToServer("SetItemIndex %N > slot: %i index: %i", client, weaponSlot, iPermItems[client][weaponSlot]);
		TF2Items_SetItemIndex(hItem, iPermItems[client][weaponSlot]);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}*/
/*public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)		//STRANGE STUFF HAPPENS HERE
{
	new weaponSlot;
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", iItemDefinitionIndex, "slot");
	GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);

	if (iPermItems[client][weaponSlot] == -1) // || weaponSlot < 2 || iPermItems[client][weaponSlot] == 44)
	{
		//PrintToChat(client, "No weapon for slot %d.", weaponSlot);
		return Plugin_Continue;
	}

	//PrintToChat(client, "Weapon in-queue for slot %d.", weaponSlot);
	hItem = PrepareItemHandle(iPermItems[client][weaponSlot]);	//, TF2_GetPlayerClass(client));

	return Plugin_Changed;
}
public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	new weaponSlot;
	decl String:strSteamID[32];
	new idx = GetEntProp(entityIndex, Prop_Send, "m_iItemDefinitionIndex");
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", idx, "slot");
	GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);
	new weaponLookupIndex = iPermItems[client][weaponSlot];
	if (weaponLookupIndex != -1)
	{
		switch (weaponLookupIndex)
		{
			case 2171:
			{
				SetEntProp(entity, Prop_Send, "m_iEntityLevel", (-128+11));
				GetClientAuthString(client, strSteamID, sizeof(strSteamID));
				if (StrEqual(strSteamID, "STEAM_0:0:17402999") || StrEqual(strSteamID, "STEAM_0:1:35496121")) SetEntProp(entity, Prop_Send, "m_iEntityQuality", 9); //Mecha the Slag's Self-Made Khopesh Climber
			}
			case 2197:
			{
				SetEntProp(entity, Prop_Send, "m_iEntityLevel", (-128+13));
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 120, 10, 255, 205);
				if (TF2_GetMetal(client) > 150)
					TF2_SetMetal(client, 150);
			}
			case 215:
			{
				if (TF2_GetPlayerClass(client) == TFClass_Medic) //Medic with Degreaser: fix for screen-blocking
				{
					SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
					SetEntityRenderColor(entity, 255, 255, 255, 75);
				}
			}
			case 35, 411:
			{
				new class = TF2_GetPlayerClass(client)
				if (class == TFClass_Sniper || class == TFClass_Engineer) //Sniper or Engineer with Kritzkrieg: fix for screen-blocking
				{
					SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
					SetEntityRenderColor(entity, 255, 255, 255, 75);
				}
			}
		}
		new weaponAmmo;
		Format(formatBuffer, 32, "%d_ammo", weaponLookupIndex);
		GetTrieValue(hItemInfoTrie, formatBuffer, weaponAmmo);
		if (weaponAmmo != -1)
		{
			SetSpeshulAmmo(client, weaponSlot, weaponAmmo);
		}
#if defined _visweps_included
		if (bVisWeps)
		{
			decl String:indexmodel[128];
			new index = weaponLookupIndex;
			Format(formatBuffer, 32, "%d_%s", index, "model");
			if (GetTrieString(hItemInfoTrie, formatBuffer, indexmodel, 128) && IsModelPrecached(indexmodel))
			{
				VisWep_GiveWeapon(client, weaponSlot, indexmodel);
//				LogMessage("Setting Wep Model to %s", indexmodel);
			}
			else
			{
				new index2;
				Format(formatBuffer, 32, "%d_%s", index, "index");
				GetTrieValue(hItemInfoTrie, formatBuffer, index2);
				if (index2 == 193) index2 = 3;
				if (index2 == 205) index2 = 18;
				if (index == 2041 && index2 == 41) index2 = 2041;
				if (index == 2009 && index2 == 141) index2 = 9;
				IntToString(index2, indexmodel, 32);
				VisWep_GiveWeapon(client, weaponSlot, indexmodel);
//				LogMessage("Setting Wep Model to %s", indexmodel);
			}
		}
#endif
	}
}*/
/*public Action:CheckAmmoNao(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new slot = ReadPackCell(pack);
	new weaponAmmo;
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", iPermItems[client][slot], "ammo");
	GetTrieValue(hItemInfoTrie, formatBuffer, weaponAmmo);
	if (weaponAmmo != -1) SetSpeshulAmmo(client, slot, weaponAmmo);
}*/

public Action:Command_WeaponEx(client, args)
{
	if (!CheckCommandAccess(client, "sm_giveweapon_ex", ADMFLAG_CHEATS))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	decl String:arg1[32];
	decl String:arg2[32];
	decl String:arg3[32];
	new weaponLookupIndex = -1;
	new mode = 0;

	if (args != 2 && args != 3)
	{
		ReplyToCommand(client, "[TF2Items] Usage: sm_giveweapon_ex <player> <itemindex> [givenow]");
		return Plugin_Handled;
	}

	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if (args == 3)
	{
		GetCmdArg(3, arg3, sizeof(arg3));
		mode = StringToInt(arg3);
	}
	weaponLookupIndex = StringToInt(arg2);
//	mode = StringToInt(arg3);
	new weaponSlot;
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "slot");
	new bool:isValidItem = GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);
	if (!isValidItem)
	{
		ReplyToCommand(client, "[TF2Items] Invalid Weapon Index");
		return Plugin_Handled;
	}
	new valveindex = (weaponLookupIndex < 0 ? -1*weaponLookupIndex : weaponLookupIndex);
	if (iCvarValveWeapons != 1337 && (valveindex == 7018 || (valveindex >= 8000 && valveindex <= 9999)))
	{
		ReplyToCommand(client, "[TF2Items] Valve Weapons are Disabled");
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
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		if (mode != 1 || !IsPlayerAlive(target_list[i])) PrintToChat(target_list[i], "[TF2Items] Respawn or touch a locker to receive your permanent weapon.");
		iPermItems[target_list[i]][weaponSlot] = weaponLookupIndex;
		if (mode == 1 && IsPlayerAlive(target_list[i])) GiveWeaponOfIndex(target_list[i], weaponLookupIndex, weaponSlot);
		LogAction(client, target_list[i], "\"%L\" gave a permanent weapon %d to \"%L\"", client, weaponLookupIndex, target_list[i]);
	}
	if (iCvarNotify == 2)
	{
		if (tn_is_ml) {
			ShowActivity2(client, "[TF2Items] ", "%t received permanent weapon %d!", target_name, weaponLookupIndex);
		} else {
			ShowActivity2(client, "[TF2Items] ", "%s received permanent weapon %d!", target_name, weaponLookupIndex);
		}
	}
	else ReplyToCommand(client, "[TF2Items] %s received permanent weapon %d!", target_name, weaponLookupIndex);
	return Plugin_Handled;
}

public Action:Command_ResetEx(client, args)
{
	new String:arg1[32];

	if (args < 1)
	{
		ReplyToCommand(client, "[TF2Items] Usage: sm_resetex <target> [\"slot\"/\"index\"] [slots 0-5/index numbers]");
		return Plugin_Handled;
	}

	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	new String:arg2[32];
	new String:argBuffer[32];
	new indexArray[32] = { -1, ... };
	new type = 0;
	if (args >= 3)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		if (strcmp(arg2, "slot", false) == 0) type = 1;
		else if (strcmp(arg2, "index", false) == 0) type = 2;
		for (new i = 0; i <= args-3 && i < 32; i++)
		{
			argBuffer = "";
			GetCmdArg(i+3, argBuffer, sizeof(argBuffer));
			indexArray[i] = StringToInt(argBuffer);
		}
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
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	new String:activity[64];
	new String:formatBuffer[32];
	if (type == 1)
	{
		StrCat(activity, sizeof(activity), " for slot(s)");
		for (new arrayindex = 0; arrayindex <= args-3 && arrayindex < 32; arrayindex++)
		{
			Format(formatBuffer, sizeof(formatBuffer), "%s%d", arrayindex == 0 ? " " : ", ", indexArray[arrayindex]);
			StrCat(activity, sizeof(activity), formatBuffer);
		}
	}
	else if (type == 2)
	{
		StrCat(activity, sizeof(activity), " for index(es)");
		for (new arrayindex = 0; arrayindex <= args-3 && arrayindex < 32; arrayindex++)
		{
			Format(formatBuffer, sizeof(formatBuffer), "%s%d", arrayindex == 0 ? " " : ", ", indexArray[arrayindex]);
			StrCat(activity, sizeof(activity), formatBuffer);
		}
	}
	for (new i = 0; i < target_count; i++)
	{
		if (type == 1)
		{
			for (new arrayindex = 0; arrayindex <= args-3 && arrayindex < 32; arrayindex++)
			{
				if (indexArray[arrayindex] > -1 && indexArray[arrayindex] < 6 && iPermItems[target_list[i]][indexArray[arrayindex]] != -1)
				{
					iPermItems[target_list[i]][indexArray[arrayindex]] = -1;
				}
			}
		}
		else
		{
			for (new slot = 0; slot < 6; slot++)
			{
				if (type == 2)
				{
					for (new arrayindex = 0; arrayindex <= args-3 && arrayindex < 32; arrayindex++)
					{
						if (indexArray[arrayindex] != -1 && iPermItems[target_list[i]][slot] == indexArray[arrayindex])
						{
							iPermItems[target_list[i]][slot] = -1;
						}
					}
				}
				else
				{
					if (iPermItems[target_list[i]][slot] != -1) iPermItems[target_list[i]][slot] = -1;
				}
			}
		}
		LogAction(client, target_list[i], "\"%L\" reset permanent weapons for \"%L\", %s", client, target_list[i], activity);
	}
	if (tn_is_ml) {
		ShowActivity2(client, "[TF2Items] ", "%t had permanent weapons reset%s!", target_name, activity);
	} else {
		ShowActivity2(client, "[TF2Items] ", "%s had permanent weapons reset%s!", target_name, activity);
	}
	return Plugin_Handled;
}
public Action:Command_Gimme(client, args)
{
	new String:arg1[32];
	new weaponLookupIndex = -1;
	if (!bCvarGimme)
	{
		ReplyToCommand(client, "[TF2Items] Use of sm_gimme is disabled");
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "[TF2Items] Usage: sm_gimme <itemindex>");
		return Plugin_Handled;
	}
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[TF2Items] Command is in-game only");
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[TF2Items] Cannot give weapon to self while dead");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	weaponLookupIndex = StringToInt(arg1);
	new weaponSlot;
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "slot");
	new bool:isValidItem = GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);
	if (!isValidItem)
	{
		ReplyToCommand(client, "[TF2Items] Invalid Weapon Index");
		return Plugin_Handled;
	}
	new valveindex = (weaponLookupIndex < 0 ? -1*weaponLookupIndex : weaponLookupIndex);
	if (iCvarValveWeapons != 1337 && (valveindex == 7018 || (valveindex >= 8000 && valveindex <= 9999)))
	{
		ReplyToCommand(client, "[TF2Items] Valve Weapons are Disabled");
		return Plugin_Handled;
	}

	GiveWeaponOfIndex(client, weaponLookupIndex, weaponSlot);
	LogAction(client, client, "\"%L\" gave weapon %d to self", client, weaponLookupIndex);
	if (GetClientHealth(client) > RoundToFloor(1.5 * TF2_GetMaxHealth(client))) TF2_SetHealth(client, RoundToFloor(1.5 * TF2_GetMaxHealth(client)));

 	if (iCvarNotify == 1 || iCvarNotify == 2)
	{
		ShowActivity2(client, "[TF2Items] ", "%N was given weapon %d!", client, weaponLookupIndex);
	}
	else ReplyToCommand(client, "[TF2Items] %N was given weapon %d!", client, weaponLookupIndex);
	return Plugin_Handled;
}
public Action:Command_Weapon(client, args)
{
	if (!CheckCommandAccess(client, "sm_giveweapon", ADMFLAG_CHEATS))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	new String:arg1[32];
	new String:arg2[32];
	new weaponLookupIndex = -1;

	if (args != 2)
	{
		ReplyToCommand(client, "[TF2Items] Usage: sm_giveweapon <player> <itemindex>");
		return Plugin_Handled;
	}

	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	weaponLookupIndex = StringToInt(arg2);
	new weaponSlot;
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "slot");
	new bool:isValidItem = GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);
	if (!isValidItem)
	{
		ReplyToCommand(client, "[TF2Items] Invalid Weapon Index");
		return Plugin_Handled;
	}
	new valveindex = (weaponLookupIndex < 0 ? -1*weaponLookupIndex : weaponLookupIndex);
	if (iCvarValveWeapons != 1337 && (valveindex == 7018 || (valveindex >= 8000 && valveindex <= 9999)))
	{
		ReplyToCommand(client, "[TF2Items] Valve Weapons are Disabled");
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
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		GiveWeaponOfIndex(target_list[i], weaponLookupIndex, weaponSlot);
		LogAction(client, target_list[i], "\"%L\" gave weapon %d to \"%L\"", client, weaponLookupIndex, target_list[i]);
	}
 	if (iCvarNotify == 1 || iCvarNotify == 2)
	{
		if (tn_is_ml) {
			ShowActivity2(client, "[TF2Items] ", "%t received weapon %d!", target_name, weaponLookupIndex);
		} else {
			ShowActivity2(client, "[TF2Items] ", "%s received weapon %d!", target_name, weaponLookupIndex);
		}
	}
	else ReplyToCommand(client, "[TF2Items] %s received weapon %d!", target_name, weaponLookupIndex);
	return Plugin_Handled;
}

stock GiveWeaponOfIndex(client, weaponLookupIndex, weaponSlot)
{
	decl String:strSteamID[32];

	new loopBreak = 0;
	new slotEntity = -1;
	while ((slotEntity = GetPlayerWeaponSlot(client, weaponSlot)) != -1 && loopBreak < 20)
	{
		RemovePlayerItem(client, slotEntity);
		RemoveEdict(slotEntity);
		loopBreak++;
	}
	loopBreak = 0;
	while ((slotEntity = GetPlayerWeaponSlot_Wearable(client, weaponSlot)) != -1 && loopBreak < 20)
	{
		RemoveEdict(slotEntity);
		loopBreak++;
	}
	if (weaponSlot == 1)
	{
		RemovePlayerBack(client);
		RemovePlayerTarge(client);
	}
	if (weaponSlot == 0) RemovePlayerBooties(client);

	decl String:formatBuffer[32];

	new Handle:hWeapon = PrepareItemHandle(weaponLookupIndex, TF2_GetPlayerClass(client));
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);

	if (!IsValidEntity(entity))
	{
		PrintToChat(client, "[TF2Items] Something went wrong, invalid entity created.");
		return -1;
	}
	switch (weaponLookupIndex)
	{
		case 2228:
		{
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", (-128+5));
		}
		case 2041:
		{
			SetEntProp(entity, Prop_Send, "m_nSkin", 0);
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", (-128+5));
		}
		case 2171:
		{
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", (-128+11));
			GetClientAuthString(client, strSteamID, sizeof(strSteamID));
			if (StrEqual(strSteamID, "STEAM_0:0:17402999") || StrEqual(strSteamID, "STEAM_0:1:35496121")) SetEntProp(entity, Prop_Send, "m_iEntityQuality", 9); //Mecha the Slag's Self-Made Khopesh Climber
		}
		case 2197:
		{
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", (-128+13));
/*				SetEntityRenderFx(entity, RENDERFX_PULSE_SLOW);
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 120, 10, 255, 205);*/
			if (TF2_GetMetal(client) > 150)	//metal
				TF2_SetMetal(client, 150);
		}
/*			case 215:
		{
			if (TF2_GetPlayerClass(client) == TFClass_Medic) //Medic with Degreaser: fix for screen-blocking
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 75);
			}
		}*/
		case 35, 411, 998:
		{
			new TFClassType:class = TF2_GetPlayerClass(client);
			//Sniper or Engineer or gunsling with Kritzkrieg: fix for screen-blocking
			if (class == TFClass_Sniper || class == TFClass_Engineer || GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 142)
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 75);
			}
		}
		case 2058:
		{
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", (-128+6));
			GetClientAuthString(client, strSteamID, sizeof(strSteamID));
//				if (StrEqual(strSteamID, "STEAM_0:1:19100391", false)) SetEntProp(entity, Prop_Send, "m_iEntityQuality", 9); //FlaminSarge's Self-Made Jar of Ants
			if (StrEqual(strSteamID, "STEAM_0:0:6404564", false) || StrEqual(strSteamID, "STEAM_0:0:1048930", false)) SetEntProp(entity, Prop_Send, "m_iEntityQuality", 9); //Reag and BAT MAN- Self-Made Ant'eh'gen
		}
		case 142:
		{
			new secondary = GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary);
			if (secondary == 35 || secondary == 411 || secondary == 998)
			{
				secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
				SetEntityRenderMode(secondary, RENDER_TRANSCOLOR);
				SetEntityRenderColor(secondary, 255, 255, 255, 75);
			}
			if (TF2_GetPlayerClass(client) == TFClass_Engineer)
			{
				new flags = GetEntProp(client, Prop_Send, "m_nBody");
				if (!(flags & (1 << 1)))
				{
					flags |= (1 << 1);
					SetEntProp(client, Prop_Send, "m_nBody", flags);
				}
			}
		}
		case 45, 8045:
		{
			if (TF2_GetPlayerClass(client) == TFClass_Sniper)
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 75);
			}
		}
		case 9266:
		{
			new model = PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl");
			SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", model);
			SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", model, _, 0);
			if (TF2_GetPlayerClass(client) == TFClass_Heavy)
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 75);
			}
		}
		case 266:
		{
			if (TF2_GetPlayerClass(client) == TFClass_Heavy)
			{
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 255, 255, 255, 75);
			}
		}
		case 5142:
		{
/*			new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
			decl String:cls[64];
			if (primary > MaxClients && IsValidEntity(primary) && GetEntityClassname(primary, cls, sizeof(cls)))
			{
				new TFClassType:primclassfix = FixReload(client, GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex"), cls);
				if (primclassfix != TFClass_Unknown)
				{
					RemovePlayerItem(client, primary);
					EquipPlayerWeapon(client, primary);
					TF2_SetPlayerClass(client, primclassfix, _, false);
				}
			}*/
			new secondary = GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary);
			if (secondary == 35 || secondary == 411 || secondary == 998)
			{
				secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
				SetEntityRenderMode(secondary, RENDER_TRANSCOLOR);
				SetEntityRenderColor(secondary, 255, 255, 255, 75);
			}
			SetEntProp(entity, Prop_Send, "m_iEntityLevel", (-128+25));
			if (TF2_GetPlayerClass(client) == TFClass_Engineer)
			{
				new flags = GetEntProp(client, Prop_Send, "m_nBody");
				if (!(flags & (1 << 1)))
				{
					flags |= (1 << 1);
					SetEntProp(client, Prop_Send, "m_nBody", flags);
				}
			}
		}
		case 735, 736, 810, 831, 933:
		{
			decl String:classname[64];
			for (new i = 0; i < 48; i++)
			{
				new ent = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
				if (ent > MaxClients && IsValidEntity(ent) && GetEntityClassname(ent, classname, sizeof(classname)) && (StrEqual(classname, "tf_weapon_builder", false) || StrEqual(classname, "tf_weapon_sapper", false)))
				{
					new idx = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
					if (idx == 735 || idx == 736 || idx == 810 || idx == 831 || idx == 933)
					{
						RemovePlayerItem(client, ent);
						AcceptEntityInput(ent, "Kill");
					}
				}
			}
			SetEntProp(entity, Prop_Send, "m_iObjectType", 3);
			SetEntProp(entity, Prop_Data, "m_iSubType", 3);
		}
	}

	decl String:classname[64];
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "classname");
	GetTrieString(hItemInfoTrie, formatBuffer, classname, sizeof(classname));

	if (StrEqual(classname, "tf_weapon_builder", false) || StrEqual(classname, "tf_weapon_sapper", false))
	{
		if (weaponSlot == TFWeaponSlot_Secondary)
		{
			SetEntProp(entity, Prop_Send, "m_iObjectType", 3);
			SetEntProp(entity, Prop_Data, "m_iSubType", 3);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}
		else
		{
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
			SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
		}
	}

	new bool:wearable = (StrContains(classname, "wearable", false) != -1 || StrContains(classname, "powerup", false) != -1);
	decl String:viewmodel[128];
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "viewmodel");
	if (GetTrieString(hItemInfoTrie, formatBuffer, viewmodel, sizeof(viewmodel)) && FileExists(viewmodel))
	{
		new vm = CreateVM(client, viewmodel);
		if (weaponLookupIndex != 5142) SetEntPropEnt(vm, Prop_Send, "m_hWeaponAssociatedWith", entity);
		SetEntPropEnt(entity, Prop_Send, "m_hExtraWearableViewModel", vm);
		if (weaponLookupIndex == 2197) SetEntPropFloat(vm, Prop_Send, "m_flModelScale", 1.008);
	}
	decl String:worldmodel[128];
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "model");
	if (GetTrieString(hItemInfoTrie, formatBuffer, worldmodel, sizeof(worldmodel)) && FileExists(worldmodel, true) && weaponLookupIndex != 169)
	{
		new model = PrecacheModel(worldmodel);
		if (weaponLookupIndex == 5142)
		{
			/*if (TF2_GetPlayerClass(client) == TFClass_Engineer)
			{
				new flags = GetEntProp(client, Prop_Send, "m_nBody");
				if (IsModelPrecached(worldmodel))
				{
					SetVariantString(worldmodel);
					AcceptEntityInput(client, "SetCustomModel");
					SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
				}
				flags |= (1 << 1);
				SetEntProp(client, Prop_Send, "m_nBody", flags);
			}*/
		}
		else if (!wearable)
		{
			SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", model);
			SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", model, _, 0);
		}
		else SetEntProp(entity, Prop_Send, "m_nModelIndex", model);
	}
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "model_pv");
	if (GetTrieString(hItemInfoTrie, formatBuffer, worldmodel, sizeof(worldmodel)) && FileExists(worldmodel, true) && weaponLookupIndex != 169)
	{
		new model = PrecacheModel(worldmodel);
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", model, _, 1);
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (!wearable ? GetEntProp(entity, Prop_Send, "m_iWorldModelIndex") : GetEntProp(entity, Prop_Send, "m_nModelIndex")), _, 0);
	}
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "model_hv");
	if (GetTrieString(hItemInfoTrie, formatBuffer, worldmodel, sizeof(worldmodel)) && FileExists(worldmodel, true) && weaponLookupIndex != 169)
	{
		new model = PrecacheModel(worldmodel);
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", model, _, 2);
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (!wearable ? GetEntProp(entity, Prop_Send, "m_iWorldModelIndex") : GetEntProp(entity, Prop_Send, "m_nModelIndex")), _, 0);
	}
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "model_rv");
	if (GetTrieString(hItemInfoTrie, formatBuffer, worldmodel, sizeof(worldmodel)) && FileExists(worldmodel, true) && weaponLookupIndex != 169)
	{
		new model = PrecacheModel(worldmodel);
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", model, _, 3);
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (!wearable ? GetEntProp(entity, Prop_Send, "m_iWorldModelIndex") : GetEntProp(entity, Prop_Send, "m_nModelIndex")), _, 0);
	}
	if (wearable)
	{
		TF2_EquipWearable(client, entity);
/*		if (weaponLookupIndex == 131)
		{
			decl String:attachment[32];
			new TFClassType:class = TF2_GetPlayerClass(client);
			switch (class)
			{
				case TFClass_Scout: strcopy(attachment, sizeof(attachment), "hand_L");
				case TFClass_Pyro, TFClass_Soldier: strcopy(attachment, sizeof(attachment), "weapon_bone_L");
				case TFClass_Engineer: strcopy(attachment, sizeof(attachment), "exhaust");
				default: strcopy(attachment, sizeof(attachment), "");
			}
			if (attachment[0] != '\0')
			{
				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", client);
				SetVariantString(attachment);
				AcceptEntityInput(entity, "SetParentAttachment");
			}
		}*/
	}
	else
	{
		new gunslingerfix = -1;
		new TFClassType:class = FixReload(client, entity, weaponLookupIndex, classname, gunslingerfix);
		EquipPlayerWeapon(client, entity);
//		if (gunslingerfix != -1)
//		{
//			SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", gunslingerfix);
//		}
		if (class != TFClass_Unknown)
		{
			TF2_SetPlayerClass(client, class, _, false);
		}
		if (TF2_GetPlayerClass(client) == TFClass_Heavy && StrEqual(classname, "tf_weapon_medigun", false))
		{
			SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects") & ~(EF_BONEMERGE|EF_BONEMERGE_FASTCULL));
			SetEntPropVector(entity, Prop_Send, "m_vecOrigin", Float:{ 0.0, 0.0, 38.0 });
		}
/*		new TFClassType:class = FixReload(client, weaponLookupIndex, classname);
		new melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		if (melee > 0 && GetEntityClassname(melee, classname, sizeof(classname)) && StrEqual(classname, "tf_weapon_robot_arm", false))
		{
			RemovePlayerItem(client, melee);
		}
		else melee = -1;
		EquipPlayerWeapon(client, entity);
		if (class != TFClass_Unknown)
		{
			TF2_SetPlayerClass(client, class, _, false);
		}
		if (melee != -1)
		{
			EquipPlayerWeapon(client, melee);
		}*/
/*		new TFClassType:class = FixReload(client, weaponLookupIndex, classname);
		new melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		new i = 0;
		if (melee > 0 && GetEntityClassname(melee, classname, sizeof(classname)) && StrEqual(classname, "tf_weapon_robot_arm", false))
		{
			for (; i < 48; i++)
			{
				new ent = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
				if (ent == melee)
				{
					SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", -1, i);
					break;
				}
			}
		}
		else melee = -1;
		EquipPlayerWeapon(client, entity);
		if (class != TFClass_Unknown)
		{
			TF2_SetPlayerClass(client, class, _, false);
		}
		if (melee != -1)
		{
			SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", melee, i);
		}*/
	}

	new weaponAmmo = -1;
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "ammo");
	GetTrieValue(hItemInfoTrie, formatBuffer, weaponAmmo);

	if (weaponAmmo != -1)
	{
//		if (!IsFakeClient(client) || GetSpeshulAmmo(client, weaponSlot) < weaponAmmo)
		SetSpeshulAmmo(client, weaponSlot, weaponAmmo);
	}
#if defined _visweps_included
	if (bVisWeps)
	{
		decl String:indexmodel[128];
		new index = weaponLookupIndex;
		Format(formatBuffer, sizeof(formatBuffer), "%d_%s", index, "model");
		if (GetTrieString(hItemInfoTrie, formatBuffer, indexmodel, sizeof(indexmodel)) && (IsModelPrecached(indexmodel) || strcmp(indexmodel, "-1", false) == 0))
		{
			if (wearable) weaponSlot = 6;
			VisWep_GiveWeapon(client, weaponSlot, indexmodel, _, (weaponSlot == 1));
//				LogMessage("Setting Wep Model to %s", indexmodel);
		}
		else
		{
			if (wearable) weaponSlot = 6;
			new index2;
			Format(formatBuffer, sizeof(formatBuffer), "%d_%s", index, "index");
			GetTrieValue(hItemInfoTrie, formatBuffer, index2);
//				if (index2 == 193) index2 = 3;
//				if (index2 == 205) index2 = 18;
			if (index == 2041 && index2 == 41) index2 = 2041;
			if (index == 2009 && index2 == 141) index2 = 9;
			if (index == 9266 && index2 == 266) index2 = 9266;
			IntToString(index2, indexmodel, sizeof(indexmodel));
			VisWep_GiveWeapon(client, weaponSlot, indexmodel, _, (weaponSlot == 1));
//				LogMessage("Setting Wep Model to %s", indexmodel);
		}
	}
#endif
	return entity;
}
stock CreateVM(client, String:model[])
{
	new ent = CreateEntityByName("tf_wearable_vm");
	if (!IsValidEntity(ent)) return -1;
	SetEntProp(ent, Prop_Send, "m_nModelIndex", PrecacheModel(model));
	SetEntProp(ent, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntProp(ent, Prop_Send, "m_usSolidFlags", 4);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 11);
	DispatchSpawn(ent);
	SetVariantString("!activator");
	ActivateEntity(ent);
	TF2_EquipWearable(client, ent);
	return ent;
}

stock TFClassType:FixReload(client, weapon, idx, String:classname[], &realindex)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	new String:formatBuffer[32];
	Format(formatBuffer, 32, "%d_%s", idx, "index");
	if (!GetTrieValue(hItemInfoTrie, formatBuffer, realindex))
	{
		realindex = -1;
	}
	new bool:found = false;
	new bool:gunslinger = false;//(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 142);
	if (StrEqual(classname, "tf_weapon_revolver", false) && realindex != 24 && realindex != 210 && (class != TFClass_Spy || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Spy, _, false);
		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 24);
	}
	if (StrEqual(classname, "tf_weapon_syringegun_medic", false) && realindex != 17 && realindex != 204 && (class != TFClass_Medic || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Medic, _, false);
		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 17);
	}
	if (StrEqual(classname, "tf_weapon_smg", false) && (class != TFClass_Sniper))// || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
//		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 16);
	}
	if (strncmp(classname, "tf_weapon_handgun_scout_primary", 23, false) == 0 && (class != TFClass_Scout || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Scout, _, false);
		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 13);
	}
	if (strncmp(classname, "tf_weapon_handgun_scout_secondary", 23, false) == 0 && (class != TFClass_Scout))// || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Scout, _, false);
//		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 22);
	}
	if (strncmp(classname, "tf_weapon_pistol", 16, false) == 0 && class != TFClass_Scout && class != TFClass_Engineer)
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Scout, _, false);
	}
	if (StrEqual(classname, "tf_weapon_soda_popper", false) && (class != TFClass_Scout || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Scout, _, false);
		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 13);
	}
	if (StrEqual(classname, "tf_weapon_scattergun", false) && realindex == 45 && (class != TFClass_Scout || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Scout, _, false);
		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 13);
	}
	if (StrEqual(classname, "tf_weapon_rocketlauncher", false) && realindex == 730 && (class != TFClass_Soldier || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Soldier, _, false);
		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 18);
	}
	if (StrEqual(classname, "tf_weapon_crossbow", false) && ((class != TFClass_Medic && class != TFClass_Soldier) || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Medic, _, false);
		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 17);
	}
	if (StrEqual(classname, "tf_weapon_compound_bow", false) && (class != TFClass_Sniper || gunslinger))
	{
		found = true;
		TF2_SetPlayerClass(client, TFClass_Sniper, _, false);
		if (gunslinger) SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 14);
	}
	if (!found) return TFClass_Unknown;
	return class;
}
public Action:Command_AddWearable(client, args)
{
	if (!CheckCommandAccess(client, "sm_addwearable", ADMFLAG_CHEATS))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	new String:arg1[32];
	new String:arg2[32];
	new weaponLookupIndex = 0;

	if (args != 2) {
		ReplyToCommand(client, "[TF2Items] Usage: sm_addwearable <player> <itemindex>");
		return Plugin_Handled;
	}

	/* Get the arguments */
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	weaponLookupIndex = StringToInt(arg2);
	new String:classname[64];
	new weaponSlot;
	new String:formatBuffer[32];
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "classname");
	GetTrieString(hItemInfoTrie, formatBuffer, classname, sizeof(classname));
	Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "slot");
	new bool:isValidItem = GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);
	if (!isValidItem || StrContains(classname, "wearable", false) == -1)
	{
		ReplyToCommand(client, "[TF2Items] Invalid Wearable Index");
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
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		new Handle:hWeapon = PrepareItemHandle(weaponLookupIndex);
		new entity = TF2Items_GiveNamedItem(target_list[i], hWeapon);
		CloseHandle(hWeapon);
		if (IsValidEntity(entity))
		{
			decl String:worldmodel[128];
			Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "model");
			if (GetTrieString(hItemInfoTrie, formatBuffer, worldmodel, sizeof(worldmodel)) && FileExists(worldmodel, true) && weaponLookupIndex != 169)
			{
				new model = PrecacheModel(worldmodel);
				SetEntProp(entity, Prop_Send, "m_nModelIndex", model);
			}
			Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "model_pv");
			if (GetTrieString(hItemInfoTrie, formatBuffer, worldmodel, sizeof(worldmodel)) && FileExists(worldmodel, true) && weaponLookupIndex != 169)
			{
				new model = PrecacheModel(worldmodel);
				SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", model, _, 1);
				SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", GetEntProp(entity, Prop_Send, "m_nModelIndex"), _, 0);
			}
			Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "model_hv");
			if (GetTrieString(hItemInfoTrie, formatBuffer, worldmodel, sizeof(worldmodel)) && FileExists(worldmodel, true) && weaponLookupIndex != 169)
			{
				new model = PrecacheModel(worldmodel);
				SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", model, _, 2);
				SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", GetEntProp(entity, Prop_Send, "m_nModelIndex"), _, 0);
			}
			Format(formatBuffer, sizeof(formatBuffer), "%d_%s", weaponLookupIndex, "model_rv");
			if (GetTrieString(hItemInfoTrie, formatBuffer, worldmodel, sizeof(worldmodel)) && FileExists(worldmodel, true) && weaponLookupIndex != 169)
			{
				new model = PrecacheModel(worldmodel);
				SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", model, _, 3);
				SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", GetEntProp(entity, Prop_Send, "m_nModelIndex"), _, 0);
			}

			TF2_EquipWearable(target_list[i], entity);

#if defined _visweps_included
			if (bVisWeps)
			{
				decl String:indexmodel[128];
				new index = weaponLookupIndex;
				Format(formatBuffer, 32, "%d_%s", index, "model");
				if (GetTrieString(hItemInfoTrie, formatBuffer, indexmodel, 128) && IsModelPrecached(indexmodel))
				{
					VisWep_GiveWeapon(target_list[i], 6, indexmodel);
	//				LogMessage("Setting Wep Model to %s", indexmodel);
				}
				else
				{
					new index2;
					Format(formatBuffer, 32, "%d_%s", index, "index");
					GetTrieValue(hItemInfoTrie, formatBuffer, index2);
					IntToString(index2, indexmodel, 32);
					VisWep_GiveWeapon(target_list[i], 6, indexmodel);
	//				LogMessage("Setting Wep Model to %s", indexmodel);
				}
			}
#endif
			LogAction(client, target_list[i], "\"%L\" added wearable %d to \"%L\"", client, weaponLookupIndex, target_list[i]);
		}
	}
 	if (iCvarNotify == 1 || iCvarNotify == 2)
	{
		if (tn_is_ml) {
			ShowActivity2(client, "[TF2Items] ", "%t received extra wearable %d!", target_name, weaponLookupIndex);
		} else {
			ShowActivity2(client, "[TF2Items] ", "%s received extra wearable %d!", target_name, weaponLookupIndex);
		}
	}
	else ReplyToCommand(client, "[TF2Items] %s received extra wearable %d!", target_name, weaponLookupIndex);
	return Plugin_Handled;
}
public Action:Command_GiveLudmila(client, args)
{
	if (args == 0)
	{
		if (client == 0)
		{
			ReplyToCommand(client, "[TF2Items] Cannot give Ludmila to console");
			return Plugin_Handled;
		}
		if(IsClientInGame(client) && IsPlayerAlive(client) && bCvarLowAdmins)
		{
//			ServerCommand("sm_giveweapon #%d 2041", GetClientUserId(client));		//BADBADBADBAD
			new weaponSlot;
			new String:formatBuffer[32];
			Format(formatBuffer, 32, "%d_%s", 2041, "slot");
			new bool:isValidItem = GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);
			if (isValidItem)
			{
				GiveWeaponOfIndex(client, 2041, weaponSlot);
			}
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[TF2Items] Cannot give Ludmila right now.");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action:Command_GiveGlovesofRunning(client, args)
{
	if (args == 0)
	{
		if (client == 0)
		{
			ReplyToCommand(client, "[TF2Items] Cannot give Gloves of Running Urgently to console");
			return Plugin_Handled;
		}
		if(IsClientInGame(client) && IsPlayerAlive(client) && bCvarLowAdmins)
		{
			new weaponSlot;
			new String:formatBuffer[32];
			Format(formatBuffer, 32, "%d_%s", 239, "slot");
			new bool:isValidItem = GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);
			if (isValidItem)
			{
				GiveWeaponOfIndex(client, 239, weaponSlot);
			}
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[TF2Items] Cannot give Gloves of Running Urgently right now.");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action:Command_GiveSpycrabPDA(client, args)
{
	if (args == 0)
	{
		if (client == 0)
		{
			ReplyToCommand(client, "[TF2Items] Cannot give Spycrab PDA to console");
			return Plugin_Handled;
		}
		if(IsClientInGame(client) && IsPlayerAlive(client) && bCvarLowAdmins && iCvarValveWeapons)
		{
			new weaponSlot;
			new String:formatBuffer[32];
			Format(formatBuffer, 32, "%d_%s", 9027, "slot");
			new bool:isValidItem = GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);
			if (isValidItem)
			{
				GiveWeaponOfIndex(client, 9027, weaponSlot);
			}
			return Plugin_Handled;
		}
		else
		{
			ReplyToCommand(client, "[TF2Items] Cannot give Spycrab PDA right now.");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

stock Handle:PrepareItemHandle(weaponLookupIndex, TFClassType:classbased = TFClass_Unknown)
{
	new String:formatBuffer[32];
	new String:weaponClassname[64];
	new weaponIndex;
	new weaponSlot;
	new weaponQuality;
	new weaponLevel;
	new String:weaponAttribs[256];

	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "classname");
	GetTrieString(hItemInfoTrie, formatBuffer, weaponClassname, 64);

	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "index");
	GetTrieValue(hItemInfoTrie, formatBuffer, weaponIndex);

	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "slot");
	GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);

	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "quality");
	GetTrieValue(hItemInfoTrie, formatBuffer, weaponQuality);

	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "level");
	if (!GetTrieValue(hItemInfoTrie, formatBuffer, weaponLevel))
	{
		weaponLevel = 1;
	}

	Format(formatBuffer, 32, "%d_%s", weaponLookupIndex, "attribs");
	GetTrieString(hItemInfoTrie, formatBuffer, weaponAttribs, 256);

	new String:weaponAttribsArray[32][32];
	new attribCount = ExplodeString(weaponAttribs, " ; ", weaponAttribsArray, 32, 32);

	new flags = OVERRIDE_CLASSNAME | OVERRIDE_ITEM_DEF | OVERRIDE_ITEM_LEVEL | OVERRIDE_ITEM_QUALITY | OVERRIDE_ATTRIBUTES;
	if (strcmp(weaponClassname, "saxxy", false) != 0) flags |= FORCE_GENERATION;
//	if (strcmp(weaponClassname, "tf_weapon_shotgun_hwg", false) == 0 || strcmp(weaponClassname, "tf_weapon_shotgun_pyro", false) == 0 || strcmp(weaponClassname, "tf_weapon_shotgun_soldier", false) == 0)
//	{
//		switch (classbased)
//		{
//			case TFClass_Heavy, TFClass_Soldier, TFClass_Pyro: flags &= ~FORCE_GENERATION;
//			default: flags |= FORCE_GENERATION;
//		}
//	}
	new Handle:hWeapon = TF2Items_CreateItem(flags);
//will switch this to use the FORCE_GENERATION bit later
	if (StrEqual(weaponClassname, "tf_weapon_shotgun", false)) strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shotgun_soldier");
	if (strcmp(weaponClassname, "tf_weapon_shotgun_hwg", false) == 0 || strcmp(weaponClassname, "tf_weapon_shotgun_pyro", false) == 0 || strcmp(weaponClassname, "tf_weapon_shotgun_soldier", false) == 0)
	{
		switch (classbased)
		{
			case TFClass_Heavy: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shotgun_hwg");
			case TFClass_Soldier: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shotgun_soldier");
			case TFClass_Pyro: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shotgun_pyro");
		}
	}
	if (strcmp(weaponClassname, "tf_weapon_shovel", false) == 0 && (weaponIndex == 154 || weaponIndex == 264) && classbased == TFClass_DemoMan)
	{
		strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_bottle");
	}
// #if defined TF2ITEMSOLD
	// if (strcmp(weaponClassname, "saxxy", false) == 0)	//this line
	// {													//this line
//		if (weaponIndex == 423)
//		{
		// switch (classbased)								//these lines
		// {
			// case TFClass_Scout: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_bat");
			// case TFClass_Sniper: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_club");
			// case TFClass_Soldier: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shovel");
			// case TFClass_DemoMan: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_bottle");
			// case TFClass_Engineer: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_wrench");
			// case TFClass_Pyro: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_fireaxe");
			// case TFClass_Heavy: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_fireaxe");
			// case TFClass_Spy: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_knife");
			// case TFClass_Medic: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_bonesaw");
		// }
//		}
// /*		if (weaponLookupIndex == 199)
		// {
			// switch classbased:
			// {
				// case TFClass_Engineer: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shotgun_primary");
				// case TFClass_Soldier: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shotgun_soldier");
				// case TFClass_Heavy: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shotgun_hwg");
				// case TFClass_Pyro: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shotgun_pyro");
				// default: strcopy(weaponClassname, sizeof(weaponClassname), "tf_weapon_shotgun_primary");
			// }
		// }*/
	// }													//this line
// #endif

	TF2Items_SetClassname(hWeapon, weaponClassname);
	TF2Items_SetItemIndex(hWeapon, weaponIndex);
	TF2Items_SetLevel(hWeapon, weaponLevel);
	TF2Items_SetQuality(hWeapon, weaponQuality);

	if (attribCount > 1) {
		new attrIdx;
		new Float:attrVal;
		TF2Items_SetNumAttributes(hWeapon, attribCount/2);
		new i2 = 0;
		for (new i = 0; i < attribCount; i+=2) {
			attrIdx = StringToInt(weaponAttribsArray[i]);
			if (attrIdx <= 0)
			{
				LogError("Tried to set attribute index to %d on weapon of index %d, attrib string was '%s', count was %d", attrIdx, weaponLookupIndex, weaponAttribs, attribCount);
				continue;
			}
			switch (attrIdx)
			{
				case 133, 143, 147, 152, 184, 185, 186, 192, 193, 194, 198, 211, 214, 227, 228, 229, 262, 294, 302, 372, 373, 374, 379, 381, 383, 403, 420:
				{
					attrVal = Float:StringToInt(weaponAttribsArray[i+1]);
				}
				default:
				{
					attrVal = StringToFloat(weaponAttribsArray[i+1]);
				}
			}
			TF2Items_SetAttribute(hWeapon, i2, attrIdx, attrVal);
			i2++;
		}
	} else {
		TF2Items_SetNumAttributes(hWeapon, 0);
	}
//	FixForWeaponAmmo(hWeapon, classbased, weaponClassname, (attribCount/2 > 0) ? attribCount/2 : 0);
	return hWeapon;
}
stock FixForWeaponAmmo(Handle:hWeapon, TFClassType:class, String:classname[], attribs)
{
	if (class < TFClass_Unknown || class > TFClass_Engineer) return;
	if (attribs >= 16) return;
	new ammotype = GetAmmoType(classname);
	if (ammotype != 1 && ammotype != 2 && ammotype != -2) return;
	if (ammotype == -2)
	{
//		if (class == TFClass_Engineer) return;
//		TF2Items_SetAttribute(hWeapon, attribs, 80, 2.0);	//MUST ACCOUNT FOR GRU HERE EVENTUALLY, OK? I think I should just equip an invisible wearable that does it, actually. I think I shall.
//		TF2Items_SetNumAttributes(hWeapon, attribs + 1);
		return;
	}
	static classmaxs[TFClassType][3];
	if (classmaxs[TFClass_Scout][1] != 32)
	{
		classmaxs[TFClass_Scout][1] = 32;
		classmaxs[TFClass_Scout][2] = 36;
		classmaxs[TFClass_Sniper][1] = 25;
		classmaxs[TFClass_Sniper][2] = 75;
		classmaxs[TFClass_Soldier][1] = 20;
		classmaxs[TFClass_Soldier][2] = 32;
		classmaxs[TFClass_DemoMan][1] = 16;
		classmaxs[TFClass_DemoMan][2] = 24;
		classmaxs[TFClass_Medic][1] = 150;
		classmaxs[TFClass_Medic][2] = 150;
		classmaxs[TFClass_Heavy][1] = 200;
		classmaxs[TFClass_Heavy][2] = 32;
		classmaxs[TFClass_Pyro][1] = 200;
		classmaxs[TFClass_Pyro][2] = 32;
		classmaxs[TFClass_Spy][1] = 20;
		classmaxs[TFClass_Spy][2] = 24;
		classmaxs[TFClass_Engineer][1] = 32;
		classmaxs[TFClass_Engineer][2] = 200;
	}
	new Handle:hAmmoTrie = MakeAmmoTrie();
	new ammo;
	new attribute = 37;
	if (ammotype == 2) attribute = 25;
	if (!GetTrieValue(hAmmoTrie, classname, ammo)) return;
	TF2Items_SetAttribute(hWeapon, attribs, attribute, float(ammo)/float(classmaxs[class][ammotype]));
	TF2Items_SetNumAttributes(hWeapon, attribs + 1);
}
stock GetAmmoType(String:classname[])
{
	new Handle:ammotypetrie = MakeAmmotypeTrie();
	new ammotype = 0;
	if (!GetTrieValue(ammotypetrie, classname, ammotype)) return 0;
	return ammotype;
}
stock Handle:MakeAmmoTrie(bool:remake = false)
{
	static Handle:hTrie = INVALID_HANDLE;
	if (remake)
	{
		CloseHandle(hTrie);
		hTrie = INVALID_HANDLE;
	}
	if (hTrie != INVALID_HANDLE) return hTrie;
	hTrie = CreateTrie();
	//scout
	SetTrieValue(hTrie, "tf_weapon_scattergun", 32);
	SetTrieValue(hTrie, "tf_weapon_handgun_scout_primary", 36);
	SetTrieValue(hTrie, "tf_weapon_handgun_scout_secondary", 36);
	SetTrieValue(hTrie, "tf_weapon_soda_popper", 32);
	SetTrieValue(hTrie, "tf_weapon_pep_brawler_blaster", 32);
	SetTrieValue(hTrie, "tf_weapon_pistol_scout", 36);
	SetTrieValue(hTrie, "tf_weapon_lunchbox_drink", 1);
	SetTrieValue(hTrie, "tf_weapon_jar_milk", 1);
	SetTrieValue(hTrie, "tf_weapon_cleaver", 1);
	SetTrieValue(hTrie, "tf_weapon_bat_wood", 1);
	SetTrieValue(hTrie, "tf_weapon_bat_giftwrap", 1);

	// Soldier
	SetTrieValue(hTrie, "tf_weapon_rocketlauncher", 20);
	SetTrieValue(hTrie, "tf_weapon_rocketlauncher_directhit", 20);
	SetTrieValue(hTrie, "tf_weapon_shotgun_soldier", 32);

	// Pyro
	SetTrieValue(hTrie, "tf_weapon_flamethrower", 200);
	SetTrieValue(hTrie, "tf_weapon_shotgun_pyro", 32);
	SetTrieValue(hTrie, "tf_weapon_flaregun", 32);

	// Demo
	SetTrieValue(hTrie, "tf_weapon_grenadelauncher", 16);
	SetTrieValue(hTrie, "tf_weapon_cannon", 16);
	SetTrieValue(hTrie, "tf_weapon_pipebomblauncher", 24);

	// Heavy
	SetTrieValue(hTrie, "tf_weapon_minigun", 200);
	SetTrieValue(hTrie, "tf_weapon_shotgun_hwg", 32);
	SetTrieValue(hTrie, "tf_weapon_lunchbox", 1);

	// Engineer
	SetTrieValue(hTrie, "tf_weapon_shotgun_primary", 32);
	SetTrieValue(hTrie, "tf_weapon_sentry_revenge", 32);
	SetTrieValue(hTrie, "tf_weapon_shotgun_building_rescue", 32);
	SetTrieValue(hTrie, "tf_weapon_pistol", 200);
	SetTrieValue(hTrie, "tf_weapon_mechanical_arm", 200);

	// Medic
	SetTrieValue(hTrie, "tf_weapon_syringegun_medic", 150);
	SetTrieValue(hTrie, "tf_weapon_crossbow", 150);

	// Sniper
	SetTrieValue(hTrie, "tf_weapon_sniperrifle", 25);
	SetTrieValue(hTrie, "tf_weapon_sniperrifle_decap", 25);
	SetTrieValue(hTrie, "tf_weapon_compound_bow", 25);
	SetTrieValue(hTrie, "tf_weapon_smg", 75);
	SetTrieValue(hTrie, "tf_weapon_jar", 1);

	// Spy
	SetTrieValue(hTrie, "tf_weapon_revolver", 24);

	return hTrie;
}
stock Handle:MakeAmmotypeTrie(bool:remake = false)
{
	static Handle:hTrie = INVALID_HANDLE;
	if (remake)
	{
		CloseHandle(hTrie);
		hTrie = INVALID_HANDLE;
	}
	if (hTrie != INVALID_HANDLE) return hTrie;
	hTrie = CreateTrie();
	//scout
	SetTrieValue(hTrie, "tf_weapon_scattergun", 1);
	SetTrieValue(hTrie, "tf_weapon_handgun_scout_primary", 2);
	SetTrieValue(hTrie, "tf_weapon_handgun_scout_secondary", 2);
	SetTrieValue(hTrie, "tf_weapon_soda_popper", 1);
	SetTrieValue(hTrie, "tf_weapon_pep_brawler_blaster", 1);
	SetTrieValue(hTrie, "tf_weapon_pistol_scout", 2);
	SetTrieValue(hTrie, "tf_weapon_lunchbox_drink", 5);
	SetTrieValue(hTrie, "tf_weapon_jar_milk", 5);
	SetTrieValue(hTrie, "tf_weapon_cleaver", 5);
	SetTrieValue(hTrie, "tf_weapon_bat_wood", 4);
	SetTrieValue(hTrie, "tf_weapon_bat_giftwrap", 4);

	// Soldier
	SetTrieValue(hTrie, "tf_weapon_rocketlauncher", 1);
	SetTrieValue(hTrie, "tf_weapon_rocketlauncher_directhit", 1);
	SetTrieValue(hTrie, "tf_weapon_shotgun_soldier", 2);

	// Pyro
	SetTrieValue(hTrie, "tf_weapon_flamethrower", 1);
	SetTrieValue(hTrie, "tf_weapon_shotgun_pyro", 2);
	SetTrieValue(hTrie, "tf_weapon_flaregun", 2);

	// Demo
	SetTrieValue(hTrie, "tf_weapon_grenadelauncher", 1);
	SetTrieValue(hTrie, "tf_weapon_cannon", 1);
	SetTrieValue(hTrie, "tf_weapon_pipebomblauncher", 2);

	// Heavy
	SetTrieValue(hTrie, "tf_weapon_minigun", 1);
	SetTrieValue(hTrie, "tf_weapon_shotgun_hwg", 2);
	SetTrieValue(hTrie, "tf_weapon_lunchbox", 4);

	// Engineer
	SetTrieValue(hTrie, "tf_weapon_shotgun_primary", 1);
	SetTrieValue(hTrie, "tf_weapon_sentry_revenge", 1);
	SetTrieValue(hTrie, "tf_weapon_shotgun_building_rescue", 1);
	SetTrieValue(hTrie, "tf_weapon_pistol", 2);
	SetTrieValue(hTrie, "tf_weapon_mechanical_arm", 3);

	// Medic
	SetTrieValue(hTrie, "tf_weapon_syringegun_medic", 1);
	SetTrieValue(hTrie, "tf_weapon_crossbow", 1);

	// Sniper
	SetTrieValue(hTrie, "tf_weapon_sniperrifle", 1);
	SetTrieValue(hTrie, "tf_weapon_sniperrifle_decap", 1);
	SetTrieValue(hTrie, "tf_weapon_compound_bow", 1);
	SetTrieValue(hTrie, "tf_weapon_smg", 2);
	SetTrieValue(hTrie, "tf_weapon_jar", 4);

	// Spy
	SetTrieValue(hTrie, "tf_weapon_revolver", 2);

	//Melee (for metal)
	SetTrieValue(hTrie, "tf_weapon_wrench", -2);
	SetTrieValue(hTrie, "tf_weapon_shovel", -2);
	SetTrieValue(hTrie, "tf_weapon_bottle", -2);
	SetTrieValue(hTrie, "tf_weapon_fists", -2);
	SetTrieValue(hTrie, "tf_weapon_bat", -2);
	SetTrieValue(hTrie, "tf_weapon_bonesaw", -2);
	SetTrieValue(hTrie, "tf_weapon_sword", -2);
	SetTrieValue(hTrie, "tf_weapon_fireaxe", -2);
	SetTrieValue(hTrie, "tf_weapon_robot_arm", -2);
	SetTrieValue(hTrie, "tf_weapon_bat_wood", -2);
	SetTrieValue(hTrie, "tf_weapon_club", -2);
	SetTrieValue(hTrie, "tf_weapon_bat_fish", -2);
	SetTrieValue(hTrie, "tf_weapon_stickbomb", -2);
	SetTrieValue(hTrie, "tf_weapon_knife", -2);
	SetTrieValue(hTrie, "saxxy", -2);
	return hTrie;
}
public Action:Command_ReloadCustoms(client, args)
{
	ReloadItemTrie();
	ReplyToCommand(client, "[TF2Items] Custom Weapons list for Give Weapons reloaded");
	return Plugin_Handled;
}
stock ReloadItemTrie()
{
	static bool:reloading = false;
	if (reloading) return;
	reloading = true;
	CreateItemInfoTrie();
	for (new i = 1; i < MaxClients; i++)
	{
		for (new slot = 0; slot < 6; slot++)
		{
			if (iPermItems[i][slot] != -1)
			{
				iPermItems[i][slot] = -1;
			}
		}
	}
	PrepareAllModels();
	reloading = false;
}
stock CustomItemsTrieSetup(Handle:trie)
{
	decl String:strBuffer[256];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/tf2items.givecustom.txt");
	decl String:strBuffer2[256];
	decl String:strBuffer3[PLATFORM_MAX_PATH];
	new Handle:hKeyValues = CreateKeyValues("TF2ItemsGiveWeapon");
	if(FileToKeyValues(hKeyValues, strBuffer) == true)
	{
		KvGetSectionName(hKeyValues, strBuffer, sizeof(strBuffer));
		if (StrEqual("custom_give_weapons_vlolz", strBuffer) == true)
		{
			if (KvGotoFirstSubKey(hKeyValues))
			{
				do
				{
					KvGetSectionName(hKeyValues, strBuffer, sizeof(strBuffer));
					if (strBuffer[0] != '*')
					{
						Format(strBuffer2, 32, "%s_%s", strBuffer, "classname");
						KvGetString(hKeyValues, "classname", strBuffer3, sizeof(strBuffer3));
						SetTrieString(trie, strBuffer2, strBuffer3);
						Format(strBuffer2, 32, "%s_%s", strBuffer, "index");
						SetTrieValue(trie, strBuffer2, KvGetNum(hKeyValues, "index"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "slot");
						SetTrieValue(trie, strBuffer2, KvGetNum(hKeyValues, "slot"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "quality");
						SetTrieValue(trie, strBuffer2, KvGetNum(hKeyValues, "quality"));
						Format(strBuffer2, 32, "%s_%s", strBuffer, "level");
						SetTrieValue(trie, strBuffer2, KvGetNum(hKeyValues, "level"));
						Format(strBuffer2, 256, "%s_%s", strBuffer, "attribs");
						KvGetString(hKeyValues, "attribs", strBuffer3, sizeof(strBuffer3));
						SetTrieString(trie, strBuffer2, strBuffer3);
						Format(strBuffer2, 32, "%s_%s", strBuffer, "ammo");
						SetTrieValue(trie, strBuffer2, KvGetNum(hKeyValues, "ammo", -1));
						Format(strBuffer2, 256, "%s_%s", strBuffer, "model");
						KvGetString(hKeyValues, "model", strBuffer3, sizeof(strBuffer3));
						if (strBuffer3[0] != '\0') SetTrieString(trie, strBuffer2, strBuffer3);
						Format(strBuffer2, 256, "%s_%s", strBuffer, "model_pv");
						KvGetString(hKeyValues, "model_pv", strBuffer3, sizeof(strBuffer3));
						if (strBuffer3[0] != '\0') SetTrieString(trie, strBuffer2, strBuffer3);
						Format(strBuffer2, 256, "%s_%s", strBuffer, "model_hv");
						KvGetString(hKeyValues, "model_hv", strBuffer3, sizeof(strBuffer3));
						if (strBuffer3[0] != '\0') SetTrieString(trie, strBuffer2, strBuffer3);
						Format(strBuffer2, 256, "%s_%s", strBuffer, "model_rv");
						KvGetString(hKeyValues, "model_rv", strBuffer3, sizeof(strBuffer3));
						if (strBuffer3[0] != '\0') SetTrieString(trie, strBuffer2, strBuffer3);
						Format(strBuffer2, 256, "%s_%s", strBuffer, "viewmodel");
						KvGetString(hKeyValues, "viewmodel", strBuffer3, sizeof(strBuffer3));
						if (strBuffer3[0] != '\0') SetTrieString(trie, strBuffer2, strBuffer3);
					}
				}
				while (KvGotoNextKey(hKeyValues));
				KvGoBack(hKeyValues);
			}
		}
	}
	CloseHandle(hKeyValues);
}

#if defined _tf2itemsinfo_included
public TF2II_OnItemSchemaUpdated()
{
	if (bTF2ItemsInfo && hItemInfoTrie != INVALID_HANDLE && GetConVarBool(hCvarTF2II))
	{
		MakeTF2IITrie(hItemInfoTrie);
	}
}
MakeTF2IITrie(Handle:trie)
{
	new Handle:hItemsArray = CreateArray();

	new String:strSlots[6][] = { "primary", "secondary", "melee", "pda", "pda2", "building" };
	new i, iSlot, iClass, Handle:hResults;
	for (iSlot = 0; iSlot < sizeof(strSlots); iSlot++)
	{
		for (iClass = 1; iClass < _:TFClassType; iClass++)
		{
			hResults = TF2II_FindItems(_, strSlots[iSlot], (1 << (iClass-1)));
			if (GetArraySize(hResults) > 0)
			{
				for (i = 0; i < GetArraySize(hResults); i++)
				{
					if (FindValueInArray(hItemsArray, GetArrayCell(hResults, i)) == -1)
					{
						PushArrayCell(hItemsArray, GetArrayCell(hResults, i));
					}
				}
			}
			CloseHandle(hResults);
		}
	}
	if (GetArraySize(hItemsArray) <= 0)
	{
		LogMessage("[TF2Items GiveWeapon] TF2ItemsInfo found no items. Loading hardcoded items...");
		if (TF2II_IsItemSchemaPrecached()) SetConVarBool(hCvarTF2II, false);
		CloseHandle(hItemsArray);
//		CreateItemInfoTrie();
		return;
	}
	else
		LogMessage("[TF2Items GiveWeapon] TF2ItemsInfo loaded %d items.", GetArraySize(hItemsArray));

	SortADTArray(hItemsArray, Sort_Ascending, Sort_Integer);

	new iItemDefID, iItemSlot, iItemQuality, iItemLevel;
	decl String:strItemClass[64], String:strTrieName[16];

	new a, iAttributeNum, ammo;
	decl String:strAttributes[(4 + 3 + 8) * 16 + 1];
	decl String:appendBuffer[64];
	decl String:strFloat[10];
	new Handle:ammotrie = MakeAmmoTrie();
	for (i = 0; i < GetArraySize(hItemsArray); i++)
	{
		iItemDefID = GetArrayCell(hItemsArray, i);
		TF2II_GetItemClass(iItemDefID, strItemClass, sizeof(strItemClass));
//		if (StrEqual(strItemClass, "bundle", false)) continue; //we don't want bundles in here...yet
		iItemSlot = _:TF2II_GetItemSlot(iItemDefID);
		if (iItemDefID == 735 || iItemDefID == 736 || iItemDefID == 810 || iItemDefID == 831 || iItemDefID == 933) iItemSlot = 1;
//		if (StrEqual(strItemClass, "tf_weapon_sapper", false)) iItemSlot = 1;
		iItemQuality = _:TF2II_GetItemQuality(iItemDefID);
		iItemLevel = TF2II_GetItemMaxLevel(iItemDefID);
		if (iItemLevel < 0) iItemLevel = 1;
		if (!GetTrieValue(ammotrie, strItemClass, ammo)) ammo = -1;
		strAttributes = "";
		iAttributeNum = TF2II_GetItemNumAttributes(iItemDefID);
		if (iAttributeNum)
		{
			for (a = 0; a < iAttributeNum; a++)
			{
				new attrid = TF2II_GetItemAttributeID(iItemDefID, a);
				new Float:attrvalue = TF2II_GetItemAttributeValue(iItemDefID, a);
				FloatToString(attrvalue, strFloat, sizeof(strFloat));
				switch (attrid)
				{
					case 78, 79, 25: if (iItemSlot == TFWeaponSlot_Secondary && ammo != -1) ammo = RoundFloat(float(ammo) * attrvalue);
					case 76, 77, 37: if (iItemSlot == TFWeaponSlot_Primary && ammo != -1) ammo = RoundFloat(float(ammo) * attrvalue);
				}
				if (iItemDefID == 527) ammo = 200;
				Format(appendBuffer, sizeof(appendBuffer), "%s%d ; %s", a > 0 ? " ; " : "", TF2II_GetItemAttributeID(iItemDefID, a), strFloat);
				for (new c = strlen(appendBuffer) - 2; c > 0; c--)
				{
					if (appendBuffer[c] != '0')
					{
						if (appendBuffer[c] == '.')
						{
							appendBuffer[c+1] = '0';
							appendBuffer[c+2] = '\0';
						}
						else appendBuffer[c+1] = '\0';
						break;
					}
				}
				StrCat(strAttributes, sizeof(strAttributes), appendBuffer);
			}
		}
		Format(strTrieName, sizeof(strTrieName), "%d_classname", iItemDefID);
		SetTrieString(trie, strTrieName, strItemClass);
		Format(strTrieName, sizeof(strTrieName), "%d_index", iItemDefID);
		SetTrieValue(trie, strTrieName, iItemDefID);
		Format(strTrieName, sizeof(strTrieName), "%d_slot", iItemDefID);
		SetTrieValue(trie, strTrieName, iItemSlot);
		Format(strTrieName, sizeof(strTrieName), "%d_quality", iItemDefID);
		SetTrieValue(trie, strTrieName, iItemQuality);
		Format(strTrieName, sizeof(strTrieName), "%d_level", iItemDefID);
		SetTrieValue(trie, strTrieName, iItemLevel);
		Format(strTrieName, sizeof(strTrieName), "%d_attribs", iItemDefID);
		SetTrieString(trie, strTrieName, strAttributes);
		Format(strTrieName, sizeof(strTrieName), "%d_ammo", iItemDefID);
		SetTrieValue(trie, strTrieName, ammo);
	}
	SetTrieString(trie, "9_classname", "tf_weapon_shotgun_primary");//, false);
	SetTrieString(trie, "199_classname", "tf_weapon_shotgun_primary");//, false);
	SetTrieString(trie, "10_classname", "tf_weapon_shotgun_soldier");//, false);
	SetTrieString(trie, "11_classname", "tf_weapon_shotgun_hwg");//, false);
	SetTrieString(trie, "12_classname", "tf_weapon_shotgun_pyro");//, false);
	SetTrieString(trie, "415_classname", "tf_weapon_shotgun_soldier");//, false);
	SetTrieString(trie, "425_classname", "tf_weapon_shotgun_hwg");//, false);
	CloseHandle(hItemsArray);
}

#endif
CreateItemInfoTrie()
{
	if (hItemInfoTrie != INVALID_HANDLE)
	{
		CloseHandle(hItemInfoTrie);
	}
	hItemInfoTrie = CreateTrie();
	decl String:strBuffer[256];
	BuildPath(Path_SM, strBuffer, sizeof(strBuffer), "configs/tf2items.givecustom.txt");
	if (FileExists(strBuffer))	CustomItemsTrieSetup(hItemInfoTrie);
	AddCustomHardcodedToTrie(hItemInfoTrie);
#if defined _tf2itemsinfo_included
	if (bTF2ItemsInfo && GetConVarBool(hCvarTF2II))
	{
		MakeTF2IITrie(hItemInfoTrie);
//		return;
	}
#endif
//bat
	SetTrieString(hItemInfoTrie, "0_classname", "tf_weapon_bat", false);
	SetTrieValue(hItemInfoTrie, "0_index", 0, false);
	SetTrieValue(hItemInfoTrie, "0_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "0_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "0_level", 1, false);
	SetTrieString(hItemInfoTrie, "0_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "0_ammo", -1, false);

//bottle
	SetTrieString(hItemInfoTrie, "1_classname", "tf_weapon_bottle", false);
	SetTrieValue(hItemInfoTrie, "1_index", 1, false);
	SetTrieValue(hItemInfoTrie, "1_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "1_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "1_level", 1, false);
	SetTrieString(hItemInfoTrie, "1_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "1_ammo", -1, false);

//fire axe
	SetTrieString(hItemInfoTrie, "2_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "2_index", 2, false);
	SetTrieValue(hItemInfoTrie, "2_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "2_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "2_level", 1, false);
	SetTrieString(hItemInfoTrie, "2_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "2_ammo", -1, false);

//kukri
	SetTrieString(hItemInfoTrie, "3_classname", "tf_weapon_club", false);
	SetTrieValue(hItemInfoTrie, "3_index", 3, false);
	SetTrieValue(hItemInfoTrie, "3_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "3_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "3_level", 1, false);
	SetTrieString(hItemInfoTrie, "3_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "3_ammo", -1, false);

//knife
	SetTrieString(hItemInfoTrie, "4_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "4_index", 4, false);
	SetTrieValue(hItemInfoTrie, "4_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "4_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "4_level", 1, false);
	SetTrieString(hItemInfoTrie, "4_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "4_ammo", -1, false);

//fists
	SetTrieString(hItemInfoTrie, "5_classname", "tf_weapon_fists", false);
	SetTrieValue(hItemInfoTrie, "5_index", 5, false);
	SetTrieValue(hItemInfoTrie, "5_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "5_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "5_level", 1, false);
	SetTrieString(hItemInfoTrie, "5_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "5_ammo", -1, false);

//shovel
	SetTrieString(hItemInfoTrie, "6_classname", "tf_weapon_shovel", false);
	SetTrieValue(hItemInfoTrie, "6_index", 6, false);
	SetTrieValue(hItemInfoTrie, "6_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "6_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "6_level", 1, false);
	SetTrieString(hItemInfoTrie, "6_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "6_ammo", -1, false);

//wrench
	SetTrieString(hItemInfoTrie, "7_classname", "tf_weapon_wrench", false);
	SetTrieValue(hItemInfoTrie, "7_index", 7, false);
	SetTrieValue(hItemInfoTrie, "7_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "7_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "7_level", 1, false);
	SetTrieString(hItemInfoTrie, "7_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "7_ammo", -1, false);

//bonesaw
	SetTrieString(hItemInfoTrie, "8_classname", "tf_weapon_bonesaw", false);
	SetTrieValue(hItemInfoTrie, "8_index", 8, false);
	SetTrieValue(hItemInfoTrie, "8_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "8_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "8_level", 1, false);
	SetTrieString(hItemInfoTrie, "8_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "8_ammo", -1, false);

//shotgun engineer
	SetTrieString(hItemInfoTrie, "9_classname", "tf_weapon_shotgun_primary");//, false);
	SetTrieValue(hItemInfoTrie, "9_index", 9, false);
	SetTrieValue(hItemInfoTrie, "9_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "9_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "9_level", 1, false);
	SetTrieString(hItemInfoTrie, "9_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "9_ammo", 32, false);

//shotgun soldier
	SetTrieString(hItemInfoTrie, "10_classname", "tf_weapon_shotgun_soldier");//, false);
	SetTrieValue(hItemInfoTrie, "10_index", 10, false);
	SetTrieValue(hItemInfoTrie, "10_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "10_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "10_level", 1, false);
	SetTrieString(hItemInfoTrie, "10_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "10_ammo", 32, false);

//shotgun heavy
	SetTrieString(hItemInfoTrie, "11_classname", "tf_weapon_shotgun_hwg");//, false);
	SetTrieValue(hItemInfoTrie, "11_index", 11, false);
	SetTrieValue(hItemInfoTrie, "11_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "11_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "11_level", 1, false);
	SetTrieString(hItemInfoTrie, "11_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "11_ammo", 32, false);

//shotgun pyro
	SetTrieString(hItemInfoTrie, "12_classname", "tf_weapon_shotgun_pyro");//, false);
	SetTrieValue(hItemInfoTrie, "12_index", 12, false);
	SetTrieValue(hItemInfoTrie, "12_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "12_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "12_level", 1, false);
	SetTrieString(hItemInfoTrie, "12_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "12_ammo", 32, false);

//scattergun
	SetTrieString(hItemInfoTrie, "13_classname", "tf_weapon_scattergun", false);
	SetTrieValue(hItemInfoTrie, "13_index", 13, false);
	SetTrieValue(hItemInfoTrie, "13_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "13_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "13_level", 1, false);
	SetTrieString(hItemInfoTrie, "13_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "13_ammo", 32, false);

//sniper rifle
	SetTrieString(hItemInfoTrie, "14_classname", "tf_weapon_sniperrifle", false);
	SetTrieValue(hItemInfoTrie, "14_index", 14, false);
	SetTrieValue(hItemInfoTrie, "14_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "14_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "14_level", 1, false);
	SetTrieString(hItemInfoTrie, "14_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "14_ammo", 25, false);

//minigun
	SetTrieString(hItemInfoTrie, "15_classname", "tf_weapon_minigun", false);
	SetTrieValue(hItemInfoTrie, "15_index", 15, false);
	SetTrieValue(hItemInfoTrie, "15_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "15_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "15_level", 1, false);
	SetTrieString(hItemInfoTrie, "15_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "15_ammo", 200, false);

//smg
	SetTrieString(hItemInfoTrie, "16_classname", "tf_weapon_smg", false);
	SetTrieValue(hItemInfoTrie, "16_index", 16, false);
	SetTrieValue(hItemInfoTrie, "16_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "16_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "16_level", 1, false);
	SetTrieString(hItemInfoTrie, "16_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "16_ammo", 75, false);

//syringe gun
	SetTrieString(hItemInfoTrie, "17_classname", "tf_weapon_syringegun_medic", false);
	SetTrieValue(hItemInfoTrie, "17_index", 17, false);
	SetTrieValue(hItemInfoTrie, "17_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "17_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "17_level", 1, false);
	SetTrieString(hItemInfoTrie, "17_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "17_ammo", 150, false);

//rocket launcher
	SetTrieString(hItemInfoTrie, "18_classname", "tf_weapon_rocketlauncher", false);
	SetTrieValue(hItemInfoTrie, "18_index", 18, false);
	SetTrieValue(hItemInfoTrie, "18_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "18_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "18_level", 1, false);
	SetTrieString(hItemInfoTrie, "18_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "18_ammo", 20, false);

//grenade launcher
	SetTrieString(hItemInfoTrie, "19_classname", "tf_weapon_grenadelauncher", false);
	SetTrieValue(hItemInfoTrie, "19_index", 19, false);
	SetTrieValue(hItemInfoTrie, "19_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "19_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "19_level", 1, false);
	SetTrieString(hItemInfoTrie, "19_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "19_ammo", 16, false);

//sticky launcher
	SetTrieString(hItemInfoTrie, "20_classname", "tf_weapon_pipebomblauncher", false);
	SetTrieValue(hItemInfoTrie, "20_index", 20, false);
	SetTrieValue(hItemInfoTrie, "20_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "20_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "20_level", 1, false);
	SetTrieString(hItemInfoTrie, "20_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "20_ammo", 24, false);

//flamethrower
	SetTrieString(hItemInfoTrie, "21_classname", "tf_weapon_flamethrower", false);
	SetTrieValue(hItemInfoTrie, "21_index", 21, false);
	SetTrieValue(hItemInfoTrie, "21_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "21_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "21_level", 1, false);
	SetTrieString(hItemInfoTrie, "21_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "21_ammo", 200, false);

//pistol engineer
	SetTrieString(hItemInfoTrie, "22_classname", "tf_weapon_pistol", false);
	SetTrieValue(hItemInfoTrie, "22_index", 22, false);
	SetTrieValue(hItemInfoTrie, "22_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "22_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "22_level", 1, false);
	SetTrieString(hItemInfoTrie, "22_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "22_ammo", 200, false);

//pistol scout
	SetTrieString(hItemInfoTrie, "23_classname", "tf_weapon_pistol_scout", false);
	SetTrieValue(hItemInfoTrie, "23_index", 23, false);
	SetTrieValue(hItemInfoTrie, "23_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "23_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "23_level", 1, false);
	SetTrieString(hItemInfoTrie, "23_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "23_ammo", 36, false);

//revolver
	SetTrieString(hItemInfoTrie, "24_classname", "tf_weapon_revolver", false);
	SetTrieValue(hItemInfoTrie, "24_index", 24, false);
	SetTrieValue(hItemInfoTrie, "24_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "24_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "24_level", 1, false);
	SetTrieString(hItemInfoTrie, "24_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "24_ammo", 24, false);

//build pda engineer
	SetTrieString(hItemInfoTrie, "25_classname", "tf_weapon_pda_engineer_build", false);
	SetTrieValue(hItemInfoTrie, "25_index", 25, false);
	SetTrieValue(hItemInfoTrie, "25_slot", 3, false);
	SetTrieValue(hItemInfoTrie, "25_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "25_level", 1, false);
	SetTrieString(hItemInfoTrie, "25_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "25_ammo", -1, false);

//destroy pda engineer
	SetTrieString(hItemInfoTrie, "26_classname", "tf_weapon_pda_engineer_destroy", false);
	SetTrieValue(hItemInfoTrie, "26_index", 26, false);
	SetTrieValue(hItemInfoTrie, "26_slot", 4, false);
	SetTrieValue(hItemInfoTrie, "26_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "26_level", 1, false);
	SetTrieString(hItemInfoTrie, "26_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "26_ammo", -1, false);

//disguise kit spy
	SetTrieString(hItemInfoTrie, "27_classname", "tf_weapon_pda_spy", false);
	SetTrieValue(hItemInfoTrie, "27_index", 27, false);
	SetTrieValue(hItemInfoTrie, "27_slot", 3, false);
	SetTrieValue(hItemInfoTrie, "27_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "27_level", 1, false);
	SetTrieString(hItemInfoTrie, "27_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "27_ammo", -1, false);

//builder
	SetTrieString(hItemInfoTrie, "28_classname", "tf_weapon_builder", false);
	SetTrieValue(hItemInfoTrie, "28_index", 28, false);
	SetTrieValue(hItemInfoTrie, "28_slot", 5, false);
	SetTrieValue(hItemInfoTrie, "28_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "28_level", 1, false);
	SetTrieString(hItemInfoTrie, "28_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "28_ammo", -1, false);

//medigun
	SetTrieString(hItemInfoTrie, "29_classname", "tf_weapon_medigun", false);
	SetTrieValue(hItemInfoTrie, "29_index", 29, false);
	SetTrieValue(hItemInfoTrie, "29_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "29_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "29_level", 1, false);
	SetTrieString(hItemInfoTrie, "29_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "29_ammo", -1, false);

//invis watch
	SetTrieString(hItemInfoTrie, "30_classname", "tf_weapon_invis", false);
	SetTrieValue(hItemInfoTrie, "30_index", 30, false);
	SetTrieValue(hItemInfoTrie, "30_slot", 4, false);
	SetTrieValue(hItemInfoTrie, "30_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "30_level", 1, false);
	SetTrieString(hItemInfoTrie, "30_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "30_ammo", -1, false);

/*flaregun engineerpistol
	SetTrieString(hItemInfoTrie, "31_classname", "tf_weapon_flaregun", false);
	SetTrieValue(hItemInfoTrie, "31_index", 31, false);
	SetTrieValue(hItemInfoTrie, "31_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "31_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "31_level", 1, false);
	SetTrieString(hItemInfoTrie, "31_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "31_ammo", 16);*/

//Sapper
	SetTrieString(hItemInfoTrie, "735_classname", "tf_weapon_builder", false);
	SetTrieValue(hItemInfoTrie, "735_index", 735, false);
	SetTrieValue(hItemInfoTrie, "735_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "735_quality", 0, false);
	SetTrieValue(hItemInfoTrie, "735_level", 1, false);
	SetTrieString(hItemInfoTrie, "735_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "735_ammo", -1, false);

//Upgradeable Sapper
	SetTrieString(hItemInfoTrie, "736_classname", "tf_weapon_builder", false);
	SetTrieValue(hItemInfoTrie, "736_index", 736, false);
	SetTrieValue(hItemInfoTrie, "736_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "736_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "736_level", 1, false);
	SetTrieString(hItemInfoTrie, "736_attribs", "292 ; 24", false);
	SetTrieValue(hItemInfoTrie, "736_ammo", -1, false);

//Upgradeable build pda engineer
	SetTrieString(hItemInfoTrie, "737_classname", "tf_weapon_pda_engineer_build", false);
	SetTrieValue(hItemInfoTrie, "737_index", 737, false);
	SetTrieValue(hItemInfoTrie, "737_slot", 3, false);
	SetTrieValue(hItemInfoTrie, "737_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "737_level", 1, false);
	SetTrieString(hItemInfoTrie, "737_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "737_ammo", -1, false);

//kritzkrieg
	SetTrieString(hItemInfoTrie, "35_classname", "tf_weapon_medigun", false);
	SetTrieValue(hItemInfoTrie, "35_index", 35, false);
	SetTrieValue(hItemInfoTrie, "35_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "35_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "35_level", 8, false);
	SetTrieString(hItemInfoTrie, "35_attribs", "18 ; 1.0 ; 10 ; 1.25 ; 292 ; 2.0 ; 293 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "35_ammo", -1, false);

//blutsauger
	SetTrieString(hItemInfoTrie, "36_classname", "tf_weapon_syringegun_medic", false);
	SetTrieValue(hItemInfoTrie, "36_index", 36, false);
	SetTrieValue(hItemInfoTrie, "36_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "36_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "36_level", 5, false);
	SetTrieString(hItemInfoTrie, "36_attribs", "16 ; 3.0 ; 129 ; -2.0", false);
	SetTrieValue(hItemInfoTrie, "36_ammo", 150, false);

//ubersaw
	SetTrieString(hItemInfoTrie, "37_classname", "tf_weapon_bonesaw", false);
	SetTrieValue(hItemInfoTrie, "37_index", 37, false);
	SetTrieValue(hItemInfoTrie, "37_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "37_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "37_level", 10, false);
	SetTrieString(hItemInfoTrie, "37_attribs", "17 ; 0.25 ; 5 ; 1.2 ; 144 ; 1", false);
	SetTrieValue(hItemInfoTrie, "37_ammo", -1, false);

//axetinguisher
	SetTrieString(hItemInfoTrie, "38_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "38_index", 38, false);
	SetTrieValue(hItemInfoTrie, "38_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "38_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "38_level", 10, false);
	SetTrieString(hItemInfoTrie, "38_attribs", "20 ; 1.0 ; 21 ; 0.5 ; 22 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "38_ammo", -1, false);

//flaregun pyro
	SetTrieString(hItemInfoTrie, "39_classname", "tf_weapon_flaregun", false);
	SetTrieValue(hItemInfoTrie, "39_index", 39, false);
	SetTrieValue(hItemInfoTrie, "39_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "39_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "39_level", 10, false);
	SetTrieString(hItemInfoTrie, "39_attribs", "25 ; 0.5", false);
	SetTrieValue(hItemInfoTrie, "39_ammo", 16, false);

//backburner
	SetTrieString(hItemInfoTrie, "40_classname", "tf_weapon_flamethrower", false);
	SetTrieValue(hItemInfoTrie, "40_index", 40, false);
	SetTrieValue(hItemInfoTrie, "40_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "40_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "40_level", 10, false);
//	SetTrieString(hItemInfoTrie, "40_attribs", "23 ; 1.0 ; 24 ; 1.0 ; 28 ; 0.0 ; 2 ; 1.15");	//these are the old backburner attribs (before april 14th, 2011)
//	SetTrieString(hItemInfoTrie, "40_attribs", "170 ; 2.5 ; 24 ; 1.0 ; 28 ; 0.0 ; 2 ; 1.10");	//old pyromania jun 27 2012
	SetTrieString(hItemInfoTrie, "40_attribs", "170 ; 2.5 ; 24 ; 1.0 ; 28 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "40_ammo", 200, false);

//natascha
	SetTrieString(hItemInfoTrie, "41_classname", "tf_weapon_minigun", false);
	SetTrieValue(hItemInfoTrie, "41_index", 41, false);
	SetTrieValue(hItemInfoTrie, "41_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "41_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "41_level", 5, false);
	SetTrieString(hItemInfoTrie, "41_attribs", "32 ; 1.0 ; 1 ; 0.75 ; 86 ; 1.3 ; 144 ; 1", false);
	SetTrieValue(hItemInfoTrie, "41_ammo", 200, false);

//sandvich
	SetTrieString(hItemInfoTrie, "42_classname", "tf_weapon_lunchbox", false);
	SetTrieValue(hItemInfoTrie, "42_index", 42, false);
	SetTrieValue(hItemInfoTrie, "42_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "42_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "42_level", 1, false);
	SetTrieString(hItemInfoTrie, "42_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "42_ammo", 1, false);

//killing gloves of boxing
	SetTrieString(hItemInfoTrie, "43_classname", "tf_weapon_fists", false);
	SetTrieValue(hItemInfoTrie, "43_index", 43, false);
	SetTrieValue(hItemInfoTrie, "43_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "43_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "43_level", 7, false);
	SetTrieString(hItemInfoTrie, "43_attribs", "31 ; 5.0 ; 5 ; 1.2", false);
	SetTrieValue(hItemInfoTrie, "43_ammo", -1, false);

//sandman
	SetTrieString(hItemInfoTrie, "44_classname", "tf_weapon_bat_wood", false);
	SetTrieValue(hItemInfoTrie, "44_index", 44, false);
	SetTrieValue(hItemInfoTrie, "44_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "44_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "44_level", 15, false);
	SetTrieString(hItemInfoTrie, "44_attribs", "38 ; 1.0 ; 125 ; -15.0", false);
	SetTrieValue(hItemInfoTrie, "44_ammo", 1, false);

//force a nature
	SetTrieString(hItemInfoTrie, "45_classname", "tf_weapon_scattergun", false);
	SetTrieValue(hItemInfoTrie, "45_index", 45, false);
	SetTrieValue(hItemInfoTrie, "45_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "45_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "45_level", 10, false);
	SetTrieString(hItemInfoTrie, "45_attribs", "44 ; 1.0 ; 6 ; 0.5 ; 45 ; 1.2 ; 1 ; 0.9 ; 3 ; 0.34 ; 43 ; 1.0 ; 328 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "45_ammo", 32, false);

//bonk atomic punch
	SetTrieString(hItemInfoTrie, "46_classname", "tf_weapon_lunchbox_drink", false);
	SetTrieValue(hItemInfoTrie, "46_index", 46, false);
	SetTrieValue(hItemInfoTrie, "46_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "46_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "46_level", 5, false);
	SetTrieString(hItemInfoTrie, "46_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "46_ammo", 1, false);

//huntsman
	SetTrieString(hItemInfoTrie, "56_classname", "tf_weapon_compound_bow", false);
	SetTrieValue(hItemInfoTrie, "56_index", 56, false);
	SetTrieValue(hItemInfoTrie, "56_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "56_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "56_level", 10, false);
	SetTrieString(hItemInfoTrie, "56_attribs", "37 ; 0.5 ; 328 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "56_ammo", 12, false);

//razorback (broken NO LONGER)
	SetTrieString(hItemInfoTrie, "57_classname", "tf_wearable", false);
	SetTrieValue(hItemInfoTrie, "57_index", 57, false);
	SetTrieValue(hItemInfoTrie, "57_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "57_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "57_level", 10, false);
	SetTrieString(hItemInfoTrie, "57_attribs", "52 ; 1 ; 292 ; 5.0", false);

//jarate
	SetTrieString(hItemInfoTrie, "58_classname", "tf_weapon_jar", false);
	SetTrieValue(hItemInfoTrie, "58_index", 58, false);
	SetTrieValue(hItemInfoTrie, "58_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "58_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "58_level", 5, false);
	SetTrieString(hItemInfoTrie, "58_attribs", "56 ; 1.0 ; 292 ; 4.0", false);
	SetTrieValue(hItemInfoTrie, "58_ammo", 1, false);

//dead ringer
	SetTrieString(hItemInfoTrie, "59_classname", "tf_weapon_invis", false);
	SetTrieValue(hItemInfoTrie, "59_index", 59, false);
	SetTrieValue(hItemInfoTrie, "59_slot", 4, false);
	SetTrieValue(hItemInfoTrie, "59_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "59_level", 5, false);
	SetTrieString(hItemInfoTrie, "59_attribs", "33 ; 1.0 ; 34 ; 1.6 ; 35 ; 1.8", false);
	SetTrieValue(hItemInfoTrie, "59_ammo", -1, false);

//cloak and dagger
	SetTrieString(hItemInfoTrie, "60_classname", "tf_weapon_invis", false);
	SetTrieValue(hItemInfoTrie, "60_index", 60, false);
	SetTrieValue(hItemInfoTrie, "60_slot", 4, false);
	SetTrieValue(hItemInfoTrie, "60_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "60_level", 5, false);
	SetTrieString(hItemInfoTrie, "60_attribs", "48 ; 2.0 ; 35 ; 2.0", false);
	SetTrieValue(hItemInfoTrie, "60_ammo", -1, false);

//ambassador
	SetTrieString(hItemInfoTrie, "61_classname", "tf_weapon_revolver", false);
	SetTrieValue(hItemInfoTrie, "61_index", 61, false);
	SetTrieValue(hItemInfoTrie, "61_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "61_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "61_level", 5, false);
	SetTrieString(hItemInfoTrie, "61_attribs", "51 ; 1.0 ; 1 ; 0.85 ; 5 ; 1.2", false);
	SetTrieValue(hItemInfoTrie, "61_ammo", 24, false);

//direct hit
	SetTrieString(hItemInfoTrie, "127_classname", "tf_weapon_rocketlauncher_directhit", false);
	SetTrieValue(hItemInfoTrie, "127_index", 127, false);
	SetTrieValue(hItemInfoTrie, "127_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "127_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "127_level", 1, false);
	SetTrieString(hItemInfoTrie, "127_attribs", "100 ; 0.3 ; 103 ; 1.8 ; 2 ; 1.25 ; 114 ; 1.0 ; 328 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "127_ammo", 20, false);

//equalizer
	SetTrieString(hItemInfoTrie, "128_classname", "tf_weapon_shovel", false);
	SetTrieValue(hItemInfoTrie, "128_index", 128, false);
	SetTrieValue(hItemInfoTrie, "128_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "128_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "128_level", 10, false);
	SetTrieString(hItemInfoTrie, "128_attribs", "115 ; 1.0 ; 236 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "128_ammo", -1, false);

//buff banner
	SetTrieString(hItemInfoTrie, "129_classname", "tf_weapon_buff_item", false);
	SetTrieValue(hItemInfoTrie, "129_index", 129, false);
	SetTrieValue(hItemInfoTrie, "129_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "129_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "129_level", 5, false);
	SetTrieString(hItemInfoTrie, "129_attribs", "116 ; 1", false);
	SetTrieValue(hItemInfoTrie, "129_ammo", -1, false);

//scottish resistance
	SetTrieString(hItemInfoTrie, "130_classname", "tf_weapon_pipebomblauncher", false);
	SetTrieValue(hItemInfoTrie, "130_index", 130, false);
	SetTrieValue(hItemInfoTrie, "130_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "130_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "130_level", 5, false);
	SetTrieString(hItemInfoTrie, "130_attribs", "6 ; 0.75 ; 119 ; 1.0 ; 121 ; 1.0 ; 78 ; 1.5 ; 88 ; 6.0 ; 120 ; 0.8", false);
	SetTrieValue(hItemInfoTrie, "130_ammo", 36, false);

//chargin targe (broken NO LONGER)
	SetTrieString(hItemInfoTrie, "131_classname", "tf_wearable_demoshield", false);
	SetTrieValue(hItemInfoTrie, "131_index", 131, false);
	SetTrieValue(hItemInfoTrie, "131_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "131_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "131_level", 10, false);
	SetTrieString(hItemInfoTrie, "131_attribs", "60 ; 0.5 ; 64 ; 0.6", false);

//eyelander
	SetTrieString(hItemInfoTrie, "132_classname", "tf_weapon_sword", false);
	SetTrieValue(hItemInfoTrie, "132_index", 132, false);
	SetTrieValue(hItemInfoTrie, "132_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "132_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "132_level", 5, false);
	SetTrieString(hItemInfoTrie, "132_attribs", "15 ; 0 ; 125 ; -25 ; 219 ; 1.0 ; 292 ; 6.0", false);
	SetTrieValue(hItemInfoTrie, "132_ammo", -1, false);

//gunboats (broken NO LONGER)
	SetTrieString(hItemInfoTrie, "133_classname", "tf_wearable", false);
	SetTrieValue(hItemInfoTrie, "133_index", 133, false);
	SetTrieValue(hItemInfoTrie, "133_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "133_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "133_level", 10, false);
	SetTrieString(hItemInfoTrie, "133_attribs", "135 ; 0.4", false);

//wrangler
	SetTrieString(hItemInfoTrie, "140_classname", "tf_weapon_laser_pointer", false);
	SetTrieValue(hItemInfoTrie, "140_index", 140, false);
	SetTrieValue(hItemInfoTrie, "140_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "140_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "140_level", 5, false);
	SetTrieString(hItemInfoTrie, "140_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "140_ammo", -1, false);

//frontier justice
	SetTrieString(hItemInfoTrie, "141_classname", "tf_weapon_sentry_revenge", false);
	SetTrieValue(hItemInfoTrie, "141_index", 141, false);
	SetTrieValue(hItemInfoTrie, "141_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "141_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "141_level", 5, false);
	SetTrieString(hItemInfoTrie, "141_attribs", "136 ; 1 ; 15 ; 0 ; 3 ; 0.5", false);
	SetTrieValue(hItemInfoTrie, "141_ammo", 32, false);

//gunslinger
	SetTrieString(hItemInfoTrie, "142_classname", "tf_weapon_robot_arm", false);
	SetTrieValue(hItemInfoTrie, "142_index", 142, false);
	SetTrieValue(hItemInfoTrie, "142_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "142_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "142_level", 15, false);
	SetTrieString(hItemInfoTrie, "142_attribs", "124 ; 1.0 ; 26 ; 25.0 ; 15 ; 0.0 ; 292 ; 3.0 ; 293 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "142_ammo", -1, false);

//homewrecker
	SetTrieString(hItemInfoTrie, "153_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "153_index", 153, false);
	SetTrieValue(hItemInfoTrie, "153_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "153_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "153_level", 5, false);
	SetTrieString(hItemInfoTrie, "153_attribs", "137 ; 2.0 ; 138 ; 0.75 ; 146 ; 1", false);
	SetTrieValue(hItemInfoTrie, "153_ammo", -1, false);

//pain train
	SetTrieString(hItemInfoTrie, "154_classname", "tf_weapon_shovel", false);
	SetTrieValue(hItemInfoTrie, "154_index", 154, false);
	SetTrieValue(hItemInfoTrie, "154_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "154_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "154_level", 5, false);
	SetTrieString(hItemInfoTrie, "154_attribs", "68 ; 1 ; 67 ; 1.1", false);
	SetTrieValue(hItemInfoTrie, "154_ammo", -1, false);

//southern hospitality
	SetTrieString(hItemInfoTrie, "155_classname", "tf_weapon_wrench", false);
	SetTrieValue(hItemInfoTrie, "155_index", 155, false);
	SetTrieValue(hItemInfoTrie, "155_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "155_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "155_level", 20, false);
	SetTrieString(hItemInfoTrie, "155_attribs", "15 ; 0 ; 149 ; 5 ; 61 ; 1.20", false);
	SetTrieValue(hItemInfoTrie, "155_ammo", -1, false);

//dalokohs bar
	SetTrieString(hItemInfoTrie, "159_classname", "tf_weapon_lunchbox", false);
	SetTrieValue(hItemInfoTrie, "159_index", 159, false);
	SetTrieValue(hItemInfoTrie, "159_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "159_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "159_level", 1, false);
	SetTrieString(hItemInfoTrie, "159_attribs", "139 ; 1", false);
	SetTrieValue(hItemInfoTrie, "159_ammo", 1, false);

//lugermorph
	SetTrieString(hItemInfoTrie, "160_classname", "tf_weapon_pistol", false);
	SetTrieValue(hItemInfoTrie, "160_index", 160, false);
	SetTrieValue(hItemInfoTrie, "160_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "160_quality", 3, false);
	SetTrieValue(hItemInfoTrie, "160_level", 5, false);
	SetTrieString(hItemInfoTrie, "160_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "160_ammo", 36, false);

//big kill
	SetTrieString(hItemInfoTrie, "161_classname", "tf_weapon_revolver", false);
	SetTrieValue(hItemInfoTrie, "161_index", 161, false);
	SetTrieValue(hItemInfoTrie, "161_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "161_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "161_level", 5, false);
	SetTrieString(hItemInfoTrie, "161_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "161_ammo", 24, false);

//crit a cola
	SetTrieString(hItemInfoTrie, "163_classname", "tf_weapon_lunchbox_drink", false);
	SetTrieValue(hItemInfoTrie, "163_index", 163, false);
	SetTrieValue(hItemInfoTrie, "163_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "163_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "163_level", 5, false);
	SetTrieString(hItemInfoTrie, "163_attribs", "144 ; 2", false);
	SetTrieValue(hItemInfoTrie, "163_ammo", 1, false);

//golden wrench
	SetTrieString(hItemInfoTrie, "169_classname", "tf_weapon_wrench", false);
	SetTrieValue(hItemInfoTrie, "169_index", 169, false);
	SetTrieValue(hItemInfoTrie, "169_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "169_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "169_level", 25, false);
	SetTrieString(hItemInfoTrie, "169_attribs", "150 ; 1", false);
	SetTrieValue(hItemInfoTrie, "169_ammo", -1, false);

//tribalmans shiv
	SetTrieString(hItemInfoTrie, "171_classname", "tf_weapon_club", false);
	SetTrieValue(hItemInfoTrie, "171_index", 171, false);
	SetTrieValue(hItemInfoTrie, "171_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "171_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "171_level", 5, false);
	SetTrieString(hItemInfoTrie, "171_attribs", "149 ; 6 ; 1 ; 0.5", false);
	SetTrieValue(hItemInfoTrie, "171_ammo", -1, false);

//scotsmans skullcutter
	SetTrieString(hItemInfoTrie, "172_classname", "tf_weapon_sword", false);
	SetTrieValue(hItemInfoTrie, "172_index", 172, false);
	SetTrieValue(hItemInfoTrie, "172_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "172_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "172_level", 5, false);
	SetTrieString(hItemInfoTrie, "172_attribs", "2 ; 1.2 ; 54 ; 0.85", false);
	SetTrieValue(hItemInfoTrie, "172_ammo", -1, false);

//The Vita-Saw
	SetTrieString(hItemInfoTrie, "173_classname", "tf_weapon_bonesaw", false);
	SetTrieValue(hItemInfoTrie, "173_index", 173, false);
	SetTrieValue(hItemInfoTrie, "173_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "173_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "173_level", 5, false);
	SetTrieString(hItemInfoTrie, "173_attribs", "188 ; 20 ; 125 ; -10 ; 144 ; 2.0", false);
	SetTrieValue(hItemInfoTrie, "173_ammo", -1, false);

//Upgradeable bat
	SetTrieString(hItemInfoTrie, "190_classname", "tf_weapon_bat", false);
	SetTrieValue(hItemInfoTrie, "190_index", 190, false);
	SetTrieValue(hItemInfoTrie, "190_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "190_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "190_level", 1, false);
	SetTrieString(hItemInfoTrie, "190_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "190_ammo", -1, false);

//Upgradeable bottle
	SetTrieString(hItemInfoTrie, "191_classname", "tf_weapon_bottle", false);
	SetTrieValue(hItemInfoTrie, "191_index", 191, false);
	SetTrieValue(hItemInfoTrie, "191_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "191_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "191_level", 1, false);
	SetTrieString(hItemInfoTrie, "191_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "191_ammo", -1, false);

//Upgradeable fire axe
	SetTrieString(hItemInfoTrie, "192_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "192_index", 192, false);
	SetTrieValue(hItemInfoTrie, "192_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "192_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "192_level", 1, false);
	SetTrieString(hItemInfoTrie, "192_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "192_ammo", -1, false);

//Upgradeable kukri
	SetTrieString(hItemInfoTrie, "193_classname", "tf_weapon_club", false);
	SetTrieValue(hItemInfoTrie, "193_index", 193, false);
	SetTrieValue(hItemInfoTrie, "193_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "193_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "193_level", 1, false);
	SetTrieString(hItemInfoTrie, "193_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "193_ammo", -1, false);

//Upgradeable knife
	SetTrieString(hItemInfoTrie, "194_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "194_index", 194, false);
	SetTrieValue(hItemInfoTrie, "194_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "194_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "194_level", 1, false);
	SetTrieString(hItemInfoTrie, "194_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "194_ammo", -1, false);

//Upgradeable fists
	SetTrieString(hItemInfoTrie, "195_classname", "tf_weapon_fists", false);
	SetTrieValue(hItemInfoTrie, "195_index", 195, false);
	SetTrieValue(hItemInfoTrie, "195_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "195_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "195_level", 1, false);
	SetTrieString(hItemInfoTrie, "195_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "195_ammo", -1, false);

//Upgradeable shovel
	SetTrieString(hItemInfoTrie, "196_classname", "tf_weapon_shovel", false);
	SetTrieValue(hItemInfoTrie, "196_index", 196, false);
	SetTrieValue(hItemInfoTrie, "196_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "196_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "196_level", 1, false);
	SetTrieString(hItemInfoTrie, "196_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "196_ammo", -1, false);

//Upgradeable wrench
	SetTrieString(hItemInfoTrie, "197_classname", "tf_weapon_wrench", false);
	SetTrieValue(hItemInfoTrie, "197_index", 197, false);
	SetTrieValue(hItemInfoTrie, "197_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "197_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "197_level", 1, false);
	SetTrieString(hItemInfoTrie, "197_attribs", "292 ; 3.0 ; 293 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "197_ammo", -1, false);

//Upgradeable bonesaw
	SetTrieString(hItemInfoTrie, "198_classname", "tf_weapon_bonesaw", false);
	SetTrieValue(hItemInfoTrie, "198_index", 198, false);
	SetTrieValue(hItemInfoTrie, "198_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "198_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "198_level", 1, false);
	SetTrieString(hItemInfoTrie, "198_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "198_ammo", -1, false);

//Upgradeable shotgun engineer
	SetTrieString(hItemInfoTrie, "199_classname", "tf_weapon_shotgun_primary", false);
	SetTrieValue(hItemInfoTrie, "199_index", 199, false);
	SetTrieValue(hItemInfoTrie, "199_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "199_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "199_level", 1, false);
	SetTrieString(hItemInfoTrie, "199_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "199_ammo", 32, false);

/*Upgradeable shotgun other classes - appears in custom trie stuff below
	SetTrieString(hItemInfoTrie, "4199_classname", "tf_weapon_shotgun_soldier", false);
	SetTrieValue(hItemInfoTrie, "4199_index", 199, false);
	SetTrieValue(hItemInfoTrie, "4199_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "4199_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "4199_level", 1, false);
	SetTrieString(hItemInfoTrie, "4199_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "4199_ammo", 32, false);*/

//Upgradeable scattergun
	SetTrieString(hItemInfoTrie, "200_classname", "tf_weapon_scattergun", false);
	SetTrieValue(hItemInfoTrie, "200_index", 200, false);
	SetTrieValue(hItemInfoTrie, "200_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "200_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "200_level", 1, false);
	SetTrieString(hItemInfoTrie, "200_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "200_ammo", 32, false);

//Upgradeable sniper rifle
	SetTrieString(hItemInfoTrie, "201_classname", "tf_weapon_sniperrifle", false);
	SetTrieValue(hItemInfoTrie, "201_index", 201, false);
	SetTrieValue(hItemInfoTrie, "201_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "201_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "201_level", 1, false);
	SetTrieString(hItemInfoTrie, "201_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "201_ammo", 25, false);

//Upgradeable minigun
	SetTrieString(hItemInfoTrie, "202_classname", "tf_weapon_minigun", false);
	SetTrieValue(hItemInfoTrie, "202_index", 202, false);
	SetTrieValue(hItemInfoTrie, "202_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "202_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "202_level", 1, false);
	SetTrieString(hItemInfoTrie, "202_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "202_ammo", 200, false);

//Upgradeable smg
	SetTrieString(hItemInfoTrie, "203_classname", "tf_weapon_smg", false);
	SetTrieValue(hItemInfoTrie, "203_index", 203, false);
	SetTrieValue(hItemInfoTrie, "203_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "203_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "203_level", 1, false);
	SetTrieString(hItemInfoTrie, "203_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "203_ammo", 75, false);

//Upgradeable syringe gun
	SetTrieString(hItemInfoTrie, "204_classname", "tf_weapon_syringegun_medic", false);
	SetTrieValue(hItemInfoTrie, "204_index", 204, false);
	SetTrieValue(hItemInfoTrie, "204_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "204_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "204_level", 1, false);
	SetTrieString(hItemInfoTrie, "204_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "204_ammo", 150, false);

//Upgradeable rocket launcher
	SetTrieString(hItemInfoTrie, "205_classname", "tf_weapon_rocketlauncher", false);
	SetTrieValue(hItemInfoTrie, "205_index", 205, false);
	SetTrieValue(hItemInfoTrie, "205_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "205_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "205_level", 1, false);
	SetTrieString(hItemInfoTrie, "205_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "205_ammo", 20, false);

//Upgradeable grenade launcher
	SetTrieString(hItemInfoTrie, "206_classname", "tf_weapon_grenadelauncher", false);
	SetTrieValue(hItemInfoTrie, "206_index", 206, false);
	SetTrieValue(hItemInfoTrie, "206_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "206_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "206_level", 1, false);
	SetTrieString(hItemInfoTrie, "206_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "206_ammo", 16, false);

//Upgradeable sticky launcher
	SetTrieString(hItemInfoTrie, "207_classname", "tf_weapon_pipebomblauncher", false);
	SetTrieValue(hItemInfoTrie, "207_index", 207, false);
	SetTrieValue(hItemInfoTrie, "207_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "207_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "207_level", 1, false);
	SetTrieString(hItemInfoTrie, "207_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "207_ammo", 24, false);

//Upgradeable flamethrower
	SetTrieString(hItemInfoTrie, "208_classname", "tf_weapon_flamethrower", false);
	SetTrieValue(hItemInfoTrie, "208_index", 208, false);
	SetTrieValue(hItemInfoTrie, "208_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "208_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "208_level", 1, false);
	SetTrieString(hItemInfoTrie, "208_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "208_ammo", 200, false);

//Upgradeable pistol
	SetTrieString(hItemInfoTrie, "209_classname", "tf_weapon_pistol", false);
	SetTrieValue(hItemInfoTrie, "209_index", 209, false);
	SetTrieValue(hItemInfoTrie, "209_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "209_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "209_level", 1, false);
	SetTrieString(hItemInfoTrie, "209_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "209_ammo", 100, false);
	//36 for scout, 200 for engy, but idk what to use.

//Upgradeable revolver
	SetTrieString(hItemInfoTrie, "210_classname", "tf_weapon_revolver", false);
	SetTrieValue(hItemInfoTrie, "210_index", 210, false);
	SetTrieValue(hItemInfoTrie, "210_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "210_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "210_level", 1, false);
	SetTrieString(hItemInfoTrie, "210_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "210_ammo", 24, false);

//Upgradeable medigun
	SetTrieString(hItemInfoTrie, "211_classname", "tf_weapon_medigun", false);
	SetTrieValue(hItemInfoTrie, "211_index", 211, false);
	SetTrieValue(hItemInfoTrie, "211_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "211_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "211_level", 1, false);
	SetTrieString(hItemInfoTrie, "211_attribs", "292 ; 1.0 ; 293 ; 2.0", false);
	SetTrieValue(hItemInfoTrie, "211_ammo", -1, false);

//Upgradeable invis watch
	SetTrieString(hItemInfoTrie, "212_classname", "tf_weapon_invis", false);
	SetTrieValue(hItemInfoTrie, "212_index", 212, false);
	SetTrieValue(hItemInfoTrie, "212_slot", 4, false);
	SetTrieValue(hItemInfoTrie, "212_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "212_level", 1, false);
	SetTrieString(hItemInfoTrie, "212_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "212_ammo", -1, false);

//The Powerjack
	SetTrieString(hItemInfoTrie, "214_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "214_index", 214, false);
	SetTrieValue(hItemInfoTrie, "214_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "214_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "214_level", 5, false);
//	SetTrieString(hItemInfoTrie, "214_attribs", "180 ; 75 ; 2 ; 1.25 ; 15 ; 0");	//old attribs (before april 14, 2011)
	SetTrieString(hItemInfoTrie, "214_attribs", "180 ; 75 ; 206 ; 1.2", false);
	SetTrieValue(hItemInfoTrie, "214_ammo", -1, false);

//The Degreaser
	SetTrieString(hItemInfoTrie, "215_classname", "tf_weapon_flamethrower", false);
	SetTrieValue(hItemInfoTrie, "215_index", 215, false);
	SetTrieValue(hItemInfoTrie, "215_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "215_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "215_level", 10, false);
	SetTrieString(hItemInfoTrie, "215_attribs", "178 ; 0.35 ; 1 ; 0.9 ; 72 ; 0.75", false);
	SetTrieValue(hItemInfoTrie, "215_ammo", 200, false);

//The Shortstop
	SetTrieString(hItemInfoTrie, "220_classname", "tf_weapon_handgun_scout_primary", false);
	SetTrieValue(hItemInfoTrie, "220_index", 220, false);
	SetTrieValue(hItemInfoTrie, "220_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "220_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "220_level", 1, false);
	SetTrieString(hItemInfoTrie, "220_attribs", "241 ; 1.5 ; 328 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "220_ammo", 36, false);

//The Holy Mackerel
	SetTrieString(hItemInfoTrie, "221_classname", "tf_weapon_bat_fish", false);
	SetTrieValue(hItemInfoTrie, "221_index", 221, false);
	SetTrieValue(hItemInfoTrie, "221_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "221_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "221_level", 42, false);
	SetTrieString(hItemInfoTrie, "221_attribs", "292 ; 7.0 ; 388 ; 7.0", false);
	SetTrieValue(hItemInfoTrie, "221_ammo", -1, false);

//Mad Milk
	SetTrieString(hItemInfoTrie, "222_classname", "tf_weapon_jar_milk", false);
	SetTrieValue(hItemInfoTrie, "222_index", 222, false);
	SetTrieValue(hItemInfoTrie, "222_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "222_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "222_level", 5, false);
	SetTrieString(hItemInfoTrie, "222_attribs", "292 ; 4.0", false);
	SetTrieValue(hItemInfoTrie, "222_ammo", 1, false);

//L'Etranger
	SetTrieString(hItemInfoTrie, "224_classname", "tf_weapon_revolver", false);
	SetTrieValue(hItemInfoTrie, "224_index", 224, false);
	SetTrieValue(hItemInfoTrie, "224_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "224_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "224_level", 5, false);
	SetTrieString(hItemInfoTrie, "224_attribs", "166 ; 15.0 ; 1 ; 0.8", false);
	SetTrieValue(hItemInfoTrie, "224_ammo", 24, false);

//Your Eternal Reward
	SetTrieString(hItemInfoTrie, "225_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "225_index", 225, false);
	SetTrieValue(hItemInfoTrie, "225_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "225_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "225_level", 1, false);
	SetTrieString(hItemInfoTrie, "225_attribs", "154 ; 1.0 ; 156 ; 1.0 ; 155 ; 1.0 ; 144 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "225_ammo", -1, false);

//The Battalion's Backup
	SetTrieString(hItemInfoTrie, "226_classname", "tf_weapon_buff_item", false);
	SetTrieValue(hItemInfoTrie, "226_index", 226, false);
	SetTrieValue(hItemInfoTrie, "226_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "226_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "226_level", 10, false);
	SetTrieString(hItemInfoTrie, "226_attribs", "116 ; 2.0", false);
	SetTrieValue(hItemInfoTrie, "226_ammo", -1, false);

//The Black Box
	SetTrieString(hItemInfoTrie, "228_classname", "tf_weapon_rocketlauncher", false);
	SetTrieValue(hItemInfoTrie, "228_index", 228, false);
	SetTrieValue(hItemInfoTrie, "228_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "228_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "228_level", 5, false);
	SetTrieString(hItemInfoTrie, "228_attribs", "16 ; 15.0 ; 3 ; 0.75", false);
	SetTrieValue(hItemInfoTrie, "228_ammo", 20, false);

//The Sydney Sleeper
	SetTrieString(hItemInfoTrie, "230_classname", "tf_weapon_sniperrifle", false);
	SetTrieValue(hItemInfoTrie, "230_index", 230, false);
	SetTrieValue(hItemInfoTrie, "230_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "230_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "230_level", 1, false);
	SetTrieString(hItemInfoTrie, "230_attribs", "42 ; 1.0 ; 175 ; 8.0 ; 15 ; 0 ; 41 ; 1.25", false);
	SetTrieValue(hItemInfoTrie, "230_ammo", 25, false);

//darwin's danger shield (broken NO LONGER)
	SetTrieString(hItemInfoTrie, "231_classname", "tf_wearable", false);
	SetTrieValue(hItemInfoTrie, "231_index", 231, false);
	SetTrieValue(hItemInfoTrie, "231_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "231_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "231_level", 10, false);
	SetTrieString(hItemInfoTrie, "231_attribs", "26 ; 25", false);

//The Bushwacka
	SetTrieString(hItemInfoTrie, "232_classname", "tf_weapon_club", false);
	SetTrieValue(hItemInfoTrie, "232_index", 232, false);
	SetTrieValue(hItemInfoTrie, "232_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "232_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "232_level", 5, false);
	SetTrieString(hItemInfoTrie, "232_attribs", "179 ; 1 ; 61 ; 1.2", false);
	SetTrieValue(hItemInfoTrie, "232_ammo", -1, false);

//Rocket Jumper
	SetTrieString(hItemInfoTrie, "237_classname", "tf_weapon_rocketlauncher", false);
	SetTrieValue(hItemInfoTrie, "237_index", 237, false);
	SetTrieValue(hItemInfoTrie, "237_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "237_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "237_level", 1, false);
//	SetTrieString(hItemInfoTrie, "237_attribs", "1 ; 0.0 ; 181 ; 2.0 ; 76 ; 3.0 ; 65 ; 2.0 ; 67 ; 2.0 ; 61 ; 2.0");		//pre-may31 2012; before sep15, 2011, used to be 181 ; 1.0
	SetTrieString(hItemInfoTrie, "237_attribs", "76 ; 3.0 ; 181 ; 2.0 ; 1 ; 0.0 ; 15 ; 0.0 ; 400 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "237_ammo", 60, false);

//gloves of running urgently
	SetTrieString(hItemInfoTrie, "239_classname", "tf_weapon_fists", false);
	SetTrieValue(hItemInfoTrie, "239_index", 239, false);
	SetTrieValue(hItemInfoTrie, "239_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "239_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "239_level", 10, false);
//	SetTrieString(hItemInfoTrie, "239_attribs", "128 ; 1.0 ; 107 ; 1.3 ; 1 ; 0.5 ; 191 ; -6.0 ; 144 ; 2.0", false);
	SetTrieString(hItemInfoTrie, "239_attribs", "128 ; 1.0 ; 107 ; 1.3 ; 414 ; 1.0 ; 1 ; 0.75 ; 144 ; 2.0", false);
	SetTrieValue(hItemInfoTrie, "239_ammo", -1, false);

//Frying Pan (Now if only it had augment slots)
//	SetTrieString(hItemInfoTrie, "264_classname", "tf_weapon_shovel", false);
	SetTrieString(hItemInfoTrie, "264_classname", "saxxy", false);
	SetTrieValue(hItemInfoTrie, "264_index", 264, false);
	SetTrieValue(hItemInfoTrie, "264_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "264_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "264_level", 5, false);
	SetTrieString(hItemInfoTrie, "264_attribs", "195 ; 1", false);
	SetTrieValue(hItemInfoTrie, "264_ammo", -1, false);

//sticky jumper
	SetTrieString(hItemInfoTrie, "265_classname", "tf_weapon_pipebomblauncher", false);
	SetTrieValue(hItemInfoTrie, "265_index", 265, false);
	SetTrieValue(hItemInfoTrie, "265_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "265_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "265_level", 1, false);
	SetTrieString(hItemInfoTrie, "265_attribs", "78 ; 3.0 ; 181 ; 1.0 ; 1 ; 0.0 ; 15 ; 0.0 ; 400 ; 1.0 ; 280 ; 14.0", false);
//	SetTrieString(hItemInfoTrie, "265_attribs", "181 ; 1.0 ; 78 ; 3.0 ; 280 ; 14.0 ; 1 ; 0.0 ; 15 ; 0.0");	//pre-may31 2012
//	SetTrieString(hItemInfoTrie, "265_attribs", "1 ; 0.0 ; 181 ; 1.0 ; 78 ; 3.0 ; 65 ; 2.0 ; 67 ; 2.0 ; 61 ; 2.0");	//old pre-sep15,2011 update
	SetTrieValue(hItemInfoTrie, "265_ammo", 72, false);

//horseless headless horsemann's headtaker
	SetTrieString(hItemInfoTrie, "266_classname", "tf_weapon_sword", false);
	SetTrieValue(hItemInfoTrie, "266_index", 266, false);
	SetTrieValue(hItemInfoTrie, "266_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "266_quality", 5, false);
	SetTrieValue(hItemInfoTrie, "266_level", 5, false);
	SetTrieString(hItemInfoTrie, "266_attribs", "15 ; 0 ; 125 ; -25 ; 219 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "266_ammo", -1, false);

//lugermorph from Poker Night
	SetTrieString(hItemInfoTrie, "294_classname", "tf_weapon_pistol", false);
	SetTrieValue(hItemInfoTrie, "294_index", 294, false);
	SetTrieValue(hItemInfoTrie, "294_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "294_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "294_level", 5, false);
	SetTrieString(hItemInfoTrie, "294_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "294_ammo", 36, false);

//Enthusiast's Timepiece
	SetTrieString(hItemInfoTrie, "297_classname", "tf_weapon_invis", false);
	SetTrieValue(hItemInfoTrie, "297_index", 297, false);
	SetTrieValue(hItemInfoTrie, "297_slot", 4, false);
	SetTrieValue(hItemInfoTrie, "297_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "297_level", 5, false);
	SetTrieString(hItemInfoTrie, "297_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "297_ammo", -1, false);

//The Iron Curtain
	SetTrieString(hItemInfoTrie, "298_classname", "tf_weapon_minigun", false);
	SetTrieValue(hItemInfoTrie, "298_index", 298, false);
	SetTrieValue(hItemInfoTrie, "298_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "298_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "298_level", 5, false);
	SetTrieString(hItemInfoTrie, "298_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "298_ammo", 200, false);

//Amputator
	SetTrieString(hItemInfoTrie, "304_classname", "tf_weapon_bonesaw", false);
	SetTrieValue(hItemInfoTrie, "304_index", 304, false);
	SetTrieValue(hItemInfoTrie, "304_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "304_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "304_level", 15, false);
	SetTrieString(hItemInfoTrie, "304_attribs", "200 ; 1 ; 144 ; 3.0", false);
	SetTrieValue(hItemInfoTrie, "304_ammo", -1, false);

//Crusader's Crossbow
	SetTrieString(hItemInfoTrie, "305_classname", "tf_weapon_crossbow", false);
	SetTrieValue(hItemInfoTrie, "305_index", 305, false);
	SetTrieValue(hItemInfoTrie, "305_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "305_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "305_level", 15, false);
	SetTrieString(hItemInfoTrie, "305_attribs", "97 ; 0.6 ; 199 ; 1.0 ; 42 ; 1.0 ; 77 ; 0.25", false);
	SetTrieValue(hItemInfoTrie, "305_ammo", 38, false);

//Ullapool Caber
	SetTrieString(hItemInfoTrie, "307_classname", "tf_weapon_stickbomb", false);
	SetTrieValue(hItemInfoTrie, "307_index", 307, false);
	SetTrieValue(hItemInfoTrie, "307_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "307_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "307_level", 10, false);
	SetTrieString(hItemInfoTrie, "307_attribs", "15 ; 0", false);
	SetTrieValue(hItemInfoTrie, "307_ammo", -1, false);

//Loch-n-Load
	SetTrieString(hItemInfoTrie, "308_classname", "tf_weapon_grenadelauncher", false);
	SetTrieValue(hItemInfoTrie, "308_index", 308, false);
	SetTrieValue(hItemInfoTrie, "308_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "308_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "308_level", 10, false);
	SetTrieString(hItemInfoTrie, "308_attribs", "3 ; 0.5 ; 2 ; 1.2 ; 103 ; 1.25 ; 207 ; 1.25 ; 127 ; 2.0", false);
	SetTrieValue(hItemInfoTrie, "308_ammo", 16, false);

//Warrior's Spirit
	SetTrieString(hItemInfoTrie, "310_classname", "tf_weapon_fists", false);
	SetTrieValue(hItemInfoTrie, "310_index", 310, false);
	SetTrieValue(hItemInfoTrie, "310_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "310_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "310_level", 10, false);
	SetTrieString(hItemInfoTrie, "310_attribs", "2 ; 1.3 ; 125 ; -20", false);
	SetTrieValue(hItemInfoTrie, "310_ammo", -1, false);

//Buffalo Steak Sandvich
	SetTrieString(hItemInfoTrie, "311_classname", "tf_weapon_lunchbox", false);
	SetTrieValue(hItemInfoTrie, "311_index", 311, false);
	SetTrieValue(hItemInfoTrie, "311_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "311_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "311_level", 1, false);
	SetTrieString(hItemInfoTrie, "311_attribs", "144 ; 2", false);
	SetTrieValue(hItemInfoTrie, "311_ammo", 1, false);

//Brass Beast
	SetTrieString(hItemInfoTrie, "312_classname", "tf_weapon_minigun", false);
	SetTrieValue(hItemInfoTrie, "312_index", 312, false);
	SetTrieValue(hItemInfoTrie, "312_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "312_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "312_level", 5, false);
	SetTrieString(hItemInfoTrie, "312_attribs", "2 ; 1.2 ; 86 ; 1.5 ; 183 ; 0.4", false);
	SetTrieValue(hItemInfoTrie, "312_ammo", 200, false);

//Candy Cane
	SetTrieString(hItemInfoTrie, "317_classname", "tf_weapon_bat", false);
	SetTrieValue(hItemInfoTrie, "317_index", 317, false);
	SetTrieValue(hItemInfoTrie, "317_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "317_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "317_level", 25, false);
	SetTrieString(hItemInfoTrie, "317_attribs", "203 ; 1.0 ; 65 ; 1.25", false);
	SetTrieValue(hItemInfoTrie, "317_ammo", -1, false);

//Boston Basher
	SetTrieString(hItemInfoTrie, "325_classname", "tf_weapon_bat", false);
	SetTrieValue(hItemInfoTrie, "325_index", 325, false);
	SetTrieValue(hItemInfoTrie, "325_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "325_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "325_level", 25, false);
	SetTrieString(hItemInfoTrie, "325_attribs", "149 ; 5.0 ; 204 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "325_ammo", -1, false);

//Backscratcher
	SetTrieString(hItemInfoTrie, "326_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "326_index", 326, false);
	SetTrieValue(hItemInfoTrie, "326_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "326_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "326_level", 10, false);
	SetTrieString(hItemInfoTrie, "326_attribs", "2 ; 1.25 ; 69 ; 0.25 ; 108 ; 1.5", false);
	SetTrieValue(hItemInfoTrie, "326_ammo", -1, false);

//Claidheamh Mòr
	SetTrieString(hItemInfoTrie, "327_classname", "tf_weapon_sword", false);
	SetTrieValue(hItemInfoTrie, "327_index", 327, false);
	SetTrieValue(hItemInfoTrie, "327_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "327_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "327_level", 5, false);
	SetTrieString(hItemInfoTrie, "327_attribs", "15 ; 0.0 ; 202 ; 0.5 ; 125 ; -15", false);
	SetTrieValue(hItemInfoTrie, "327_ammo", -1, false);

//Jag
	SetTrieString(hItemInfoTrie, "329_classname", "tf_weapon_wrench", false);
	SetTrieValue(hItemInfoTrie, "329_index", 329, false);
	SetTrieValue(hItemInfoTrie, "329_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "329_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "329_level", 15, false);
	SetTrieString(hItemInfoTrie, "329_attribs", "92 ; 1.3 ; 1 ; 0.75 ; 292 ; 3.0 ; 293 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "329_ammo", -1, false);

//Fists of Steel
	SetTrieString(hItemInfoTrie, "331_classname", "tf_weapon_fists", false);
	SetTrieValue(hItemInfoTrie, "331_index", 331, false);
	SetTrieValue(hItemInfoTrie, "331_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "331_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "331_level", 10, false);
	SetTrieString(hItemInfoTrie, "331_attribs", "205 ; 0.6 ; 206 ; 2.0 ; 177 ; 1.2", false);
	SetTrieValue(hItemInfoTrie, "331_ammo", -1, false);

//Sharpened Volcano Fragment
	SetTrieString(hItemInfoTrie, "348_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "348_index", 348, false);
	SetTrieValue(hItemInfoTrie, "348_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "348_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "348_level", 10, false);
	SetTrieString(hItemInfoTrie, "348_attribs", "208 ; 1.0 ; 1 ; 0.8", false);
	SetTrieValue(hItemInfoTrie, "348_ammo", -1, false);

//Sun on a Stick
	SetTrieString(hItemInfoTrie, "349_classname", "tf_weapon_bat", false);
	SetTrieValue(hItemInfoTrie, "349_index", 349, false);
	SetTrieValue(hItemInfoTrie, "349_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "349_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "349_level", 10, false);
//	SetTrieString(hItemInfoTrie, "349_attribs", "209 ; 1.0 ; 1 ; 0.85 ; 153 ; 1.0");	//old pre april 14, 2011 attribs
	SetTrieString(hItemInfoTrie, "349_attribs", "20 ; 1.0 ; 1 ; 0.75", false);
	SetTrieValue(hItemInfoTrie, "349_ammo", -1, false);

//Detonator
	SetTrieString(hItemInfoTrie, "351_classname", "tf_weapon_flaregun", false);
	SetTrieValue(hItemInfoTrie, "351_index", 351, false);
	SetTrieValue(hItemInfoTrie, "351_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "351_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "351_level", 10, false);
	SetTrieString(hItemInfoTrie, "351_attribs", "25 ; 0.5 ; 207 ; 1.25 ; 144 ; 1.0");	//207 used to be 65
	SetTrieValue(hItemInfoTrie, "351_ammo", 16, false);

//Soldier's Sashimono - The Concheror
	SetTrieString(hItemInfoTrie, "354_classname", "tf_weapon_buff_item", false);
	SetTrieValue(hItemInfoTrie, "354_index", 354, false);
	SetTrieValue(hItemInfoTrie, "354_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "354_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "354_level", 5, false);
	SetTrieString(hItemInfoTrie, "354_attribs", "116 ; 3.0", false);
	SetTrieValue(hItemInfoTrie, "354_ammo", -1, false);

//Gunbai - Fan o'War
	SetTrieString(hItemInfoTrie, "355_classname", "tf_weapon_bat", false);
	SetTrieValue(hItemInfoTrie, "355_index", 355, false);
	SetTrieValue(hItemInfoTrie, "355_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "355_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "355_level", 5, false);
	SetTrieString(hItemInfoTrie, "355_attribs", "218 ; 1.0 ; 1 ; 0.1", false);
	SetTrieValue(hItemInfoTrie, "355_ammo", -1, false);

//Kunai - Conniver's Kunai
	SetTrieString(hItemInfoTrie, "356_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "356_index", 356, false);
	SetTrieValue(hItemInfoTrie, "356_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "356_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "356_level", 1, false);
	SetTrieString(hItemInfoTrie, "356_attribs", "217 ; 1.0 ; 125 ; -65 ; 144 ; 1", false);
	SetTrieValue(hItemInfoTrie, "356_ammo", -1, false);

//Soldier Katana - The Half-Zatoichi
	SetTrieString(hItemInfoTrie, "357_classname", "tf_weapon_katana", false);
	SetTrieValue(hItemInfoTrie, "357_index", 357, false);
	SetTrieValue(hItemInfoTrie, "357_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "357_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "357_level", 5, false);
	SetTrieString(hItemInfoTrie, "357_attribs", "219 ; 1.0 ; 220 ; 100.0 ; 226 ; 1", false);
	SetTrieValue(hItemInfoTrie, "357_ammo", -1, false);

//Shahanshah
	SetTrieString(hItemInfoTrie, "401_classname", "tf_weapon_club", false);
	SetTrieValue(hItemInfoTrie, "401_index", 401, false);
	SetTrieValue(hItemInfoTrie, "401_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "401_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "401_level", 5, false);
	SetTrieString(hItemInfoTrie, "401_attribs", "224 ; 1.25 ; 225 ; 0.75", false);
	SetTrieValue(hItemInfoTrie, "401_ammo", -1, false);

//Bazaar Bargain
	SetTrieString(hItemInfoTrie, "402_classname", "tf_weapon_sniperrifle_decap", false);
	SetTrieValue(hItemInfoTrie, "402_index", 402, false);
	SetTrieValue(hItemInfoTrie, "402_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "402_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "402_level", 10, false);
	SetTrieString(hItemInfoTrie, "402_attribs", "268 ; 1.2", false);
	SetTrieValue(hItemInfoTrie, "402_ammo", 25, false);

//Persian Persuader
	SetTrieString(hItemInfoTrie, "404_classname", "tf_weapon_sword", false);
	SetTrieValue(hItemInfoTrie, "404_index", 404, false);
	SetTrieValue(hItemInfoTrie, "404_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "404_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "404_level", 10, false);
	SetTrieString(hItemInfoTrie, "404_attribs", "249 ; 2.0 ; 258 ; 1.0 ; 15 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "404_ammo", -1, false);

//Ali Baba's Wee Booties
	SetTrieString(hItemInfoTrie, "405_classname", "tf_wearable", false);
	SetTrieValue(hItemInfoTrie, "405_index", 405, false);
	SetTrieValue(hItemInfoTrie, "405_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "405_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "405_level", 10, false);
	SetTrieString(hItemInfoTrie, "405_attribs", "246 ; 2.0 ; 26 ; 25.0", false);
	SetTrieValue(hItemInfoTrie, "405_ammo", -1, false);

//Splendid Screen
	SetTrieString(hItemInfoTrie, "406_classname", "tf_wearable_demoshield", false);
	SetTrieValue(hItemInfoTrie, "406_index", 406, false);
	SetTrieValue(hItemInfoTrie, "406_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "406_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "406_level", 10, false);
	SetTrieString(hItemInfoTrie, "406_attribs", "247 ; 1.0 ; 248 ; 1.7 ; 60 ; 0.8 ; 64 ; 0.85", false);
	SetTrieValue(hItemInfoTrie, "406_ammo", -1, false);

//Quick Fix
	SetTrieString(hItemInfoTrie, "411_classname", "tf_weapon_medigun", false);
	SetTrieValue(hItemInfoTrie, "411_index", 411, false);
	SetTrieValue(hItemInfoTrie, "411_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "411_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "411_level", 8, false);
	SetTrieString(hItemInfoTrie, "411_attribs", "231 ; 2.0 ; 8 ; 1.4 ; 10 ; 1.25 ; 144 ; 2.0", false);
	SetTrieValue(hItemInfoTrie, "411_ammo", -1, false);

//Overdose
	SetTrieString(hItemInfoTrie, "412_classname", "tf_weapon_syringegun_medic", false);
	SetTrieValue(hItemInfoTrie, "412_index", 412, false);
	SetTrieValue(hItemInfoTrie, "412_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "412_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "412_level", 5, false);
	SetTrieString(hItemInfoTrie, "412_attribs", "144 ; 1.0 ; 1 ; 0.9", false);
	SetTrieValue(hItemInfoTrie, "412_ammo", 150, false);

//Solemn Vow (Also known as Hippocrates)
	SetTrieString(hItemInfoTrie, "413_classname", "tf_weapon_bonesaw", false);
	SetTrieValue(hItemInfoTrie, "413_index", 413, false);
	SetTrieValue(hItemInfoTrie, "413_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "413_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "413_level", 10, false);
	SetTrieString(hItemInfoTrie, "413_attribs", "269 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "413_ammo", -1, false);

//Liberty Launcher
	SetTrieString(hItemInfoTrie, "414_classname", "tf_weapon_rocketlauncher", false);
	SetTrieValue(hItemInfoTrie, "414_index", 414, false);
	SetTrieValue(hItemInfoTrie, "414_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "414_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "414_level", 25, false);
	SetTrieString(hItemInfoTrie, "414_attribs", "103 ; 1.4 ; 3 ; 0.75", false);
	SetTrieValue(hItemInfoTrie, "414_ammo", 20, false);

//Reserve Shooter
	SetTrieString(hItemInfoTrie, "415_classname", "tf_weapon_shotgun_soldier");//, false);
	SetTrieValue(hItemInfoTrie, "415_index", 415, false);
	SetTrieValue(hItemInfoTrie, "415_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "415_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "415_level", 10, false);
	SetTrieString(hItemInfoTrie, "415_attribs", "178 ; 0.85 ; 265 ; 3.0 ; 3 ; 0.5", false);
	SetTrieValue(hItemInfoTrie, "415_ammo", 32, false);

//Market Gardener
	SetTrieString(hItemInfoTrie, "416_classname", "tf_weapon_shovel", false);
	SetTrieValue(hItemInfoTrie, "416_index", 416, false);
	SetTrieValue(hItemInfoTrie, "416_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "416_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "416_level", 10, false);
	SetTrieString(hItemInfoTrie, "416_attribs", "267 ; 1.0 ; 15 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "416_ammo", -1, false);

//Saxxy
	SetTrieString(hItemInfoTrie, "423_classname", "saxxy", false);
	SetTrieValue(hItemInfoTrie, "423_index", 423, false);
	SetTrieValue(hItemInfoTrie, "423_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "423_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "423_level", 25, false);
	SetTrieString(hItemInfoTrie, "423_attribs", "150 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "423_ammo", -1, false);

//Tomislav
	SetTrieString(hItemInfoTrie, "424_classname", "tf_weapon_minigun", false);
	SetTrieValue(hItemInfoTrie, "424_index", 424, false);
	SetTrieValue(hItemInfoTrie, "424_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "424_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "424_level", 5, false);
	SetTrieString(hItemInfoTrie, "424_attribs", "87 ; 0.9 ; 238 ; 1.0 ; 5 ; 1.2", false);
	SetTrieValue(hItemInfoTrie, "424_ammo", 200, false);

//Family Business
	SetTrieString(hItemInfoTrie, "425_classname", "tf_weapon_shotgun_hwg", false);
	SetTrieValue(hItemInfoTrie, "425_index", 425, false);
	SetTrieValue(hItemInfoTrie, "425_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "425_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "425_level", 10, false);
	SetTrieString(hItemInfoTrie, "425_attribs", "4 ; 1.33 ; 1 ; 0.85", false);
	SetTrieValue(hItemInfoTrie, "425_ammo", 32, false);

//Eviction Notice
	SetTrieString(hItemInfoTrie, "426_classname", "tf_weapon_fists", false);
	SetTrieValue(hItemInfoTrie, "426_index", 426, false);
	SetTrieValue(hItemInfoTrie, "426_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "426_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "426_level", 10, false);
	SetTrieString(hItemInfoTrie, "426_attribs", "6 ; 0.5 ; 1 ; 0.4", false);
	SetTrieValue(hItemInfoTrie, "426_ammo", -1, false);

//Fishcake
	SetTrieString(hItemInfoTrie, "433_classname", "tf_weapon_lunchbox", false);
	SetTrieValue(hItemInfoTrie, "433_index", 433, false);
	SetTrieValue(hItemInfoTrie, "433_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "433_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "433_level", 1, false);
	SetTrieString(hItemInfoTrie, "433_attribs", "139 ; 1", false);
	SetTrieValue(hItemInfoTrie, "433_ammo", 1, false);

//Cow Mangler 5000
	SetTrieString(hItemInfoTrie, "441_classname", "tf_weapon_particle_cannon", false);
	SetTrieValue(hItemInfoTrie, "441_index", 441, false);
	SetTrieValue(hItemInfoTrie, "441_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "441_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "441_level", 30, false);
	SetTrieString(hItemInfoTrie, "441_attribs", "281 ; 1.0 ; 282 ; 1.0 ; 15 ; 0.0 ; 284 ; 1.0 ; 1 ; 0.9 ; 288 ; 1.0 ; 96 ; 1.05", false);
	SetTrieValue(hItemInfoTrie, "441_ammo", -1, false);

//Righteous Bison
	SetTrieString(hItemInfoTrie, "442_classname", "tf_weapon_raygun", false);
	SetTrieValue(hItemInfoTrie, "442_index", 442, false);
	SetTrieValue(hItemInfoTrie, "442_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "442_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "442_level", 30, false);
	SetTrieString(hItemInfoTrie, "442_attribs", "281 ; 1.0 ; 283 ; 1.0 ; 285 ; 0.0 ; 284 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "442_ammo", -1, false);

//Mantreads
	SetTrieString(hItemInfoTrie, "444_classname", "tf_wearable", false);
	SetTrieValue(hItemInfoTrie, "444_index", 444, false);
	SetTrieValue(hItemInfoTrie, "444_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "444_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "444_level", 10, false);
	SetTrieString(hItemInfoTrie, "444_attribs", "252 ; 0.25 ; 259 ; 1.0 ; 292 ; 26.0 ; 388 ; 26.0", false);
	SetTrieValue(hItemInfoTrie, "444_ammo", -1, false);

//Disciplinary Action
	SetTrieString(hItemInfoTrie, "447_classname", "tf_weapon_shovel", false);
	SetTrieValue(hItemInfoTrie, "447_index", 447, false);
	SetTrieValue(hItemInfoTrie, "447_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "447_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "447_level", 10, false);
	SetTrieString(hItemInfoTrie, "447_attribs", "251 ; 1.0 ; 1 ; 0.75 ; 264 ; 1.7 ; 263 ; 1.55", false);
	SetTrieValue(hItemInfoTrie, "447_ammo", -1, false);

//Soda Popper
	SetTrieString(hItemInfoTrie, "448_classname", "tf_weapon_soda_popper", false);
	SetTrieValue(hItemInfoTrie, "448_index", 448, false);
	SetTrieValue(hItemInfoTrie, "448_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "448_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "448_level", 10, false);
	SetTrieString(hItemInfoTrie, "448_attribs", "6 ; 0.5 ; 97 ; 0.75 ; 3 ; 0.34 ; 15 ; 0.0 ; 43 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "448_ammo", 32, false);

//Winger
	SetTrieString(hItemInfoTrie, "449_classname", "tf_weapon_handgun_scout_secondary", false);
	SetTrieValue(hItemInfoTrie, "449_index", 449, false);
	SetTrieValue(hItemInfoTrie, "449_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "449_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "449_level", 15, false);
	SetTrieString(hItemInfoTrie, "449_attribs", "2 ; 1.15 ; 3 ; 0.4", false);
	SetTrieValue(hItemInfoTrie, "449_ammo", 36, false);

//Atomizer
	SetTrieString(hItemInfoTrie, "450_classname", "tf_weapon_bat", false);
	SetTrieValue(hItemInfoTrie, "450_index", 450, false);
	SetTrieValue(hItemInfoTrie, "450_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "450_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "450_level", 10, false);
	SetTrieString(hItemInfoTrie, "450_attribs", "250 ; 1.0 ; 5 ; 1.3 ; 138 ; 0.8", false);
	SetTrieValue(hItemInfoTrie, "450_ammo", -1, false);

//Three-Rune Blade
	SetTrieString(hItemInfoTrie, "452_classname", "tf_weapon_bat", false);
	SetTrieValue(hItemInfoTrie, "452_index", 452, false);
	SetTrieValue(hItemInfoTrie, "452_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "452_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "452_level", 10, false);
	SetTrieString(hItemInfoTrie, "452_attribs", "149 ; 5.0 ; 204 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "452_ammo", -1, false);

//Postal Pummeler
	SetTrieString(hItemInfoTrie, "457_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "457_index", 457, false);
	SetTrieValue(hItemInfoTrie, "457_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "457_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "457_level", 10, false);
	SetTrieString(hItemInfoTrie, "457_attribs", "20 ; 1.0 ; 21 ; 0.5 ; 22 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "457_ammo", -1, false);

//Enforcer
	SetTrieString(hItemInfoTrie, "460_classname", "tf_weapon_revolver", false);
	SetTrieValue(hItemInfoTrie, "460_index", 460, false);
	SetTrieValue(hItemInfoTrie, "460_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "460_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "460_level", 5, false);
	SetTrieString(hItemInfoTrie, "460_attribs", "410 ; 1.2 ; 5 ; 1.2 ; 15 ; 0.0", false);
//	SetTrieString(hItemInfoTrie, "460_attribs", "2 ; 1.2 ; 253 ; 0.5");	//pre-may31 2012
	SetTrieValue(hItemInfoTrie, "460_ammo", 24, false);

//Big Earner
	SetTrieString(hItemInfoTrie, "461_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "461_index", 461, false);
	SetTrieValue(hItemInfoTrie, "461_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "461_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "461_level", 1, false);
	SetTrieString(hItemInfoTrie, "461_attribs", "158 ; 30 ; 125 ; -25", false);
	SetTrieValue(hItemInfoTrie, "461_ammo", -1, false);

//Maul
	SetTrieString(hItemInfoTrie, "466_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "466_index", 466, false);
	SetTrieValue(hItemInfoTrie, "466_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "466_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "466_level", 5, false);
	SetTrieString(hItemInfoTrie, "466_attribs", "137 ; 2.0 ; 138 ; 0.75 ; 146 ; 1", false);
	SetTrieValue(hItemInfoTrie, "466_ammo", -1, false);

//Conscientious Objector
	SetTrieString(hItemInfoTrie, "474_classname", "saxxy", false);
	SetTrieValue(hItemInfoTrie, "474_index", 474, false);
	SetTrieValue(hItemInfoTrie, "474_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "474_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "474_level", 25, false);
	SetTrieString(hItemInfoTrie, "474_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "474_ammo", -1, false);

//Nessie's Nine Iron
	SetTrieString(hItemInfoTrie, "482_classname", "tf_weapon_sword", false);
	SetTrieValue(hItemInfoTrie, "482_index", 482, false);
	SetTrieValue(hItemInfoTrie, "482_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "482_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "482_level", 5, false);
	SetTrieString(hItemInfoTrie, "482_attribs", "15 ; 0 ; 125 ; -25 ; 219 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "482_ammo", -1, false);

//The Original
	SetTrieString(hItemInfoTrie, "513_classname", "tf_weapon_rocketlauncher", false);
	SetTrieValue(hItemInfoTrie, "513_index", 513, false);
	SetTrieValue(hItemInfoTrie, "513_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "513_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "513_level", 5, false);
	SetTrieString(hItemInfoTrie, "513_attribs", "289 ; 1", false);
	SetTrieValue(hItemInfoTrie, "513_ammo", 20, false);

//The Diamondback
	SetTrieString(hItemInfoTrie, "525_classname", "tf_weapon_revolver", false);
	SetTrieValue(hItemInfoTrie, "525_index", 525, false);
	SetTrieValue(hItemInfoTrie, "525_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "525_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "525_level", 5, false);
	SetTrieString(hItemInfoTrie, "525_attribs", "296 ; 1.0 ; 1 ; 0.85 ; 15 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "525_ammo", 24, false);

//The Machina
	SetTrieString(hItemInfoTrie, "526_classname", "tf_weapon_sniperrifle", false);
	SetTrieValue(hItemInfoTrie, "526_index", 526, false);
	SetTrieValue(hItemInfoTrie, "526_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "526_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "526_level", 5, false);
	SetTrieString(hItemInfoTrie, "526_attribs", "304 ; 1.15 ; 308 ; 1.0 ; 297 ; 1.0 ; 305 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "526_ammo", 25, false);

//The Widowmaker
	SetTrieString(hItemInfoTrie, "527_classname", "tf_weapon_shotgun_primary", false);
	SetTrieValue(hItemInfoTrie, "527_index", 527, false);
	SetTrieValue(hItemInfoTrie, "527_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "527_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "527_level", 5, false);
	SetTrieString(hItemInfoTrie, "527_attribs", "299 ; 100.0 ; 307 ; 1.0 ; 303 ; -1.0 ; 298 ; 30.0 ; 301 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "527_ammo", 200, false);

//The Short Circuit
	SetTrieString(hItemInfoTrie, "528_classname", "tf_weapon_mechanical_arm", false);
	SetTrieValue(hItemInfoTrie, "528_index", 528, false);
	SetTrieValue(hItemInfoTrie, "528_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "528_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "528_level", 5, false);
	SetTrieString(hItemInfoTrie, "528_attribs", "300 ; 1.0 ; 307 ; 1.0 ; 303 ; -1.0 ; 15 ; 0.0 ; 298 ; 35.0 ; 301 ; 1.0 ; 312 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "528_ammo", 200, false);

//Unarmed Combat
	SetTrieString(hItemInfoTrie, "572_classname", "tf_weapon_bat_fish", false);
	SetTrieValue(hItemInfoTrie, "572_index", 572, false);
	SetTrieValue(hItemInfoTrie, "572_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "572_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "572_level", 13, false);
	SetTrieString(hItemInfoTrie, "572_attribs", "332 ; 1.0 ; 292 ; 7.0 ; 388 ; 7.0", false);
	SetTrieValue(hItemInfoTrie, "572_ammo", -1, false);

//Wanga Prick
	SetTrieString(hItemInfoTrie, "574_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "574_index", 574, false);
	SetTrieValue(hItemInfoTrie, "574_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "574_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "574_level", 54, false);
	SetTrieString(hItemInfoTrie, "574_attribs", "154 ; 1.0 ; 156 ; 1.0 ; 155 ; 1.0 ; 144 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "574_ammo", -1, false);

//Apoco-Fists
	SetTrieString(hItemInfoTrie, "587_classname", "tf_weapon_fists", false);
	SetTrieValue(hItemInfoTrie, "587_index", 587, false);
	SetTrieValue(hItemInfoTrie, "587_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "587_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "587_level", 10, false);
	SetTrieString(hItemInfoTrie, "587_attribs", "309 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "587_ammo", -1, false);

//Pomson 6000
	SetTrieString(hItemInfoTrie, "588_classname", "tf_weapon_drg_pomson", false);
	SetTrieValue(hItemInfoTrie, "588_index", 588, false);
	SetTrieValue(hItemInfoTrie, "588_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "588_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "588_level", 10, false);
	SetTrieString(hItemInfoTrie, "588_attribs", "281 ; 1.0 ; 285 ; 1.0 ; 337 ; 10.0 ; 338 ; 20.0", false);
	SetTrieValue(hItemInfoTrie, "588_ammo", -1, false);

//Eureka Effect
	SetTrieString(hItemInfoTrie, "589_classname", "tf_weapon_wrench", false);
	SetTrieValue(hItemInfoTrie, "589_index", 589, false);
	SetTrieValue(hItemInfoTrie, "589_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "589_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "589_level", 20, false);
	SetTrieString(hItemInfoTrie, "589_attribs", "352 ; 1.0 ; 353 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "589_ammo", -1, false);

//Third Degree
	SetTrieString(hItemInfoTrie, "593_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "593_index", 593, false);
	SetTrieValue(hItemInfoTrie, "593_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "593_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "593_level", 10, false);
	SetTrieString(hItemInfoTrie, "593_attribs", "360 ; 1.0 ; 350 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "593_ammo", -1, false);

//Phlogistinator
	SetTrieString(hItemInfoTrie, "594_classname", "tf_weapon_flamethrower", false);
	SetTrieValue(hItemInfoTrie, "594_index", 594, false);
	SetTrieValue(hItemInfoTrie, "594_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "594_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "594_level", 10, false);
//	SetTrieString(hItemInfoTrie, "594_attribs", "368 ; 1.0 ; 116 ; 5.0 ; 356 ; 1.0 ; 357 ; 1.2 ; 350 ; 1.0 ; 144 ; 1.0 ; 15 ; 0.0", false);
	SetTrieString(hItemInfoTrie, "594_attribs", "1 ; 0.9 ; 368 ; 1.0 ; 116 ; 5.0 ; 356 ; 1.0 ; 350 ; 1.0 ; 144 ; 1.0 ; 15 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "594_ammo", 200, false);

//Manmelter
	SetTrieString(hItemInfoTrie, "595_classname", "tf_weapon_flaregun_revenge", false);
	SetTrieValue(hItemInfoTrie, "595_index", 595, false);
	SetTrieValue(hItemInfoTrie, "595_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "595_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "595_level", 30, false);
	SetTrieString(hItemInfoTrie, "595_attribs", "281 ; 1.0 ; 283 ; 1.0 ; 348 ; 1.2 ; 103 ; 1.5 ; 367 ; 1.0 ; 15 ; 0.0 ; 350 ; 1.0 ; 144 ; 2.0", false);
	SetTrieValue(hItemInfoTrie, "595_ammo", -1, false);

//Bootlegger
	SetTrieString(hItemInfoTrie, "608_classname", "tf_wearable", false);
	SetTrieValue(hItemInfoTrie, "608_index", 608, false);
	SetTrieValue(hItemInfoTrie, "608_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "608_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "608_level", 10, false);
	SetTrieString(hItemInfoTrie, "608_attribs", "246 ; 2.0 ; 26 ; 25.0", false);
	SetTrieValue(hItemInfoTrie, "608_ammo", -1, false);

//Scottish Handshake
	SetTrieString(hItemInfoTrie, "609_classname", "tf_weapon_bottle", false);
	SetTrieValue(hItemInfoTrie, "609_index", 609, false);
	SetTrieValue(hItemInfoTrie, "609_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "609_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "609_level", 10, false);
	SetTrieString(hItemInfoTrie, "609_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "609_ammo", -1, false);

//Sharp Dresser
	SetTrieString(hItemInfoTrie, "638_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "638_index", 638, false);
	SetTrieValue(hItemInfoTrie, "638_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "638_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "638_level", 1, false);
	SetTrieString(hItemInfoTrie, "638_attribs", "328 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "638_ammo", -1, false);

//Cozy Camper
	SetTrieString(hItemInfoTrie, "642_classname", "tf_wearable", false);
	SetTrieValue(hItemInfoTrie, "642_index", 642, false);
	SetTrieValue(hItemInfoTrie, "642_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "642_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "642_level", 10, false);
	SetTrieString(hItemInfoTrie, "642_attribs", "57 ; 1.0 ; 376 ; 1.0 ; 377 ; 0.80 ; 378 ; 0.2", false);

//Wrap Assassin
	SetTrieString(hItemInfoTrie, "648_classname", "tf_weapon_bat_giftwrap", false);
	SetTrieValue(hItemInfoTrie, "648_index", 648, false);
	SetTrieValue(hItemInfoTrie, "648_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "648_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "648_level", 15, false);
	SetTrieString(hItemInfoTrie, "648_attribs", "346 ; 1.0 ; 1 ; 0.3", false);
	SetTrieValue(hItemInfoTrie, "648_ammo", 1, false);

//Spy-cicle
	SetTrieString(hItemInfoTrie, "649_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "649_index", 649, false);
	SetTrieValue(hItemInfoTrie, "649_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "649_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "649_level", 1, false);
	SetTrieString(hItemInfoTrie, "649_attribs", "347 ; 1.0 ; 156 ; 1.0 ; 359 ; 15.0 ; 361 ; 2.0 ; 365 ; 3.0", false);
	SetTrieValue(hItemInfoTrie, "649_ammo", 1, false);

//Festive Minigun 2011
	SetTrieString(hItemInfoTrie, "654_classname", "tf_weapon_minigun", false);
	SetTrieValue(hItemInfoTrie, "654_index", 654, false);
	SetTrieValue(hItemInfoTrie, "654_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "654_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "654_level", 1, false);
	SetTrieString(hItemInfoTrie, "654_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "654_ammo", 200, false);

//Holiday Punch
	SetTrieString(hItemInfoTrie, "656_classname", "tf_weapon_fists", false);
	SetTrieValue(hItemInfoTrie, "656_index", 656, false);
	SetTrieValue(hItemInfoTrie, "656_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "656_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "656_level", 10, false);
	SetTrieString(hItemInfoTrie, "656_attribs", "358 ; 1.0 ; 362 ; 1.0 ; 363 ; 1.0 ; 369 ; 1.0 ; 292 ; 25.0 ; 293 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "656_ammo", -1, false);

//Festive Rocket Launcher 2011
	SetTrieString(hItemInfoTrie, "658_classname", "tf_weapon_rocketlauncher", false);
	SetTrieValue(hItemInfoTrie, "658_index", 658, false);
	SetTrieValue(hItemInfoTrie, "658_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "658_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "658_level", 1, false);
	SetTrieString(hItemInfoTrie, "658_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "658_ammo", 20, false);

//Festive Flamethrower 2011
	SetTrieString(hItemInfoTrie, "659_classname", "tf_weapon_flamethrower", false);
	SetTrieValue(hItemInfoTrie, "659_index", 659, false);
	SetTrieValue(hItemInfoTrie, "659_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "659_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "659_level", 1, false);
	SetTrieString(hItemInfoTrie, "659_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "659_ammo", 200, false);

//Festive Bat 2011
	SetTrieString(hItemInfoTrie, "660_classname", "tf_weapon_bat", false);
	SetTrieValue(hItemInfoTrie, "660_index", 660, false);
	SetTrieValue(hItemInfoTrie, "660_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "660_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "660_level", 1, false);
	SetTrieString(hItemInfoTrie, "660_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "660_ammo", -1, false);

//Festive Sticky Launcher 2011
	SetTrieString(hItemInfoTrie, "661_classname", "tf_weapon_pipebomblauncher", false);
	SetTrieValue(hItemInfoTrie, "661_index", 661, false);
	SetTrieValue(hItemInfoTrie, "661_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "661_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "661_level", 1, false);
	SetTrieString(hItemInfoTrie, "661_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "661_ammo", 24, false);

//Festive Wrench 2011
	SetTrieString(hItemInfoTrie, "662_classname", "tf_weapon_wrench", false);
	SetTrieValue(hItemInfoTrie, "662_index", 662, false);
	SetTrieValue(hItemInfoTrie, "662_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "662_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "662_level", 1, false);
	SetTrieString(hItemInfoTrie, "662_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "662_ammo", -1, false);

//Festive Medigun 2011
	SetTrieString(hItemInfoTrie, "663_classname", "tf_weapon_medigun", false);
	SetTrieValue(hItemInfoTrie, "663_index", 663, false);
	SetTrieValue(hItemInfoTrie, "663_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "663_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "663_level", 1, false);
	SetTrieString(hItemInfoTrie, "663_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "663_ammo", -1, false);

//Festive Sniper Rifle 2011
	SetTrieString(hItemInfoTrie, "664_classname", "tf_weapon_sniperrifle", false);
	SetTrieValue(hItemInfoTrie, "664_index", 664, false);
	SetTrieValue(hItemInfoTrie, "664_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "664_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "664_level", 1, false);
	SetTrieString(hItemInfoTrie, "664_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "664_ammo", 25, false);

//Festive Knife 2011
	SetTrieString(hItemInfoTrie, "665_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "665_index", 665, false);
	SetTrieValue(hItemInfoTrie, "665_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "665_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "665_level", 1, false);
	SetTrieString(hItemInfoTrie, "665_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "665_ammo", -1, false);

//Festive Scattergun 2011
	SetTrieString(hItemInfoTrie, "669_classname", "tf_weapon_scattergun", false);
	SetTrieValue(hItemInfoTrie, "669_index", 669, false);
	SetTrieValue(hItemInfoTrie, "669_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "669_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "669_level", 1, false);
	SetTrieString(hItemInfoTrie, "669_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "669_ammo", 32, false);

//Black Rose
	SetTrieString(hItemInfoTrie, "727_classname", "tf_weapon_knife", false);
	SetTrieValue(hItemInfoTrie, "727_index", 727, false);
	SetTrieValue(hItemInfoTrie, "727_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "727_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "727_level", 1, false);
	SetTrieString(hItemInfoTrie, "727_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "727_ammo", -1, false);

//Beggar's Bazooka
	SetTrieString(hItemInfoTrie, "730_classname", "tf_weapon_rocketlauncher", false);
	SetTrieValue(hItemInfoTrie, "730_index", 730, false);
	SetTrieValue(hItemInfoTrie, "730_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "730_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "730_level", 1, false);
	SetTrieString(hItemInfoTrie, "730_attribs", "394 ; 0.3 ; 413 ; 1.0 ; 411 ; 3.0 ; 417 ; 1.0 ; 421 ; 1.0 ; 241 ; 1.3 ; 424 ; 0.75", false);
	SetTrieValue(hItemInfoTrie, "730_ammo", 20, false);

//Lollichop
	SetTrieString(hItemInfoTrie, "739_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "739_index", 739, false);
	SetTrieValue(hItemInfoTrie, "739_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "739_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "739_level", 1, false);
	SetTrieString(hItemInfoTrie, "739_attribs", "406 ; 1.0 ; 422 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "739_ammo", -1, false);

//Scorch Shot
	SetTrieString(hItemInfoTrie, "740_classname", "tf_weapon_flaregun", false);
	SetTrieValue(hItemInfoTrie, "740_index", 740, false);
	SetTrieValue(hItemInfoTrie, "740_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "740_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "740_level", 10, false);
	SetTrieString(hItemInfoTrie, "740_attribs", "25 ; 0.5 ; 416 ; 3.0 ; 1 ; 0.5", false);
	SetTrieValue(hItemInfoTrie, "740_ammo", 16, false);

//Rainblower
	SetTrieString(hItemInfoTrie, "741_classname", "tf_weapon_flamethrower", false);
	SetTrieValue(hItemInfoTrie, "741_index", 741, false);
	SetTrieValue(hItemInfoTrie, "741_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "741_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "741_level", 10, false);
	SetTrieString(hItemInfoTrie, "741_attribs", "406 ; 1.0 ; 144 ; 3.0 ; 422 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "741_ammo", 200, false);

//Cleaner's Carbine
	SetTrieString(hItemInfoTrie, "751_classname", "tf_weapon_smg", false);
	SetTrieValue(hItemInfoTrie, "751_index", 751, false);
	SetTrieValue(hItemInfoTrie, "751_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "751_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "751_level", 1, false);
	SetTrieString(hItemInfoTrie, "751_attribs", "31 ; 3.0 ; 3 ; 0.8 ; 5 ; 1.35 ; 15 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "751_ammo", 75, false);

//Hitman's Heatmaker
	SetTrieString(hItemInfoTrie, "752_classname", "tf_weapon_sniperrifle", false);
	SetTrieValue(hItemInfoTrie, "752_index", 752, false);
	SetTrieValue(hItemInfoTrie, "752_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "752_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "752_level", 1, false);
	SetTrieString(hItemInfoTrie, "752_attribs", "387 ; 35.0 ; 398 ; 15.0 ; 393 ; 0.0 ; 219 ; 1.0 ; 392 ; 0.8 ; 116 ; 6.0", false);
	SetTrieValue(hItemInfoTrie, "752_ammo", 25, false);

//Baby Face's Blaster
	SetTrieString(hItemInfoTrie, "772_classname", "tf_weapon_pep_brawler_blaster", false);
	SetTrieValue(hItemInfoTrie, "772_index", 772, false);
	SetTrieValue(hItemInfoTrie, "772_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "772_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "772_level", 10, false);
	SetTrieString(hItemInfoTrie, "772_attribs", "106 ; 0.6 ; 418 ; 1.0 ; 1 ; 0.7 ; 54 ; 0.65 ; 419 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "772_ammo", 32, false);

//Pretty Boy's Pocket Pistol
	SetTrieString(hItemInfoTrie, "773_classname", "tf_weapon_handgun_scout_secondary", false);
	SetTrieValue(hItemInfoTrie, "773_index", 773, false);
	SetTrieValue(hItemInfoTrie, "773_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "773_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "773_level", 10, false);
	SetTrieString(hItemInfoTrie, "773_attribs", "26 ; 15.0 ; 275 ; 1.0 ; 5 ; 1.25 ; 61 ; 1.5", false);
	SetTrieValue(hItemInfoTrie, "773_ammo", 36, false);

//Escape Plan
	SetTrieString(hItemInfoTrie, "775_classname", "tf_weapon_shovel", false);
	SetTrieValue(hItemInfoTrie, "775_index", 775, false);
	SetTrieValue(hItemInfoTrie, "775_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "775_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "775_level", 10, false);
	SetTrieString(hItemInfoTrie, "775_attribs", "235 ; 2.0 ; 236 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "775_ammo", -1, false);

//Red-Tape Recorder
	SetTrieString(hItemInfoTrie, "810_classname", "tf_weapon_sapper", false);
	SetTrieValue(hItemInfoTrie, "810_index", 810, false);
	SetTrieValue(hItemInfoTrie, "810_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "810_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "810_level", 1, false);
	SetTrieString(hItemInfoTrie, "810_attribs", "433 ; 0.5 ; 426 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "810_ammo", -1, false);

//Huo Long Heater
	SetTrieString(hItemInfoTrie, "811_classname", "tf_weapon_minigun", false);
	SetTrieValue(hItemInfoTrie, "811_index", 811, false);
	SetTrieValue(hItemInfoTrie, "811_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "811_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "811_level", 1, false);
	SetTrieString(hItemInfoTrie, "811_attribs", "430 ; 15.0 ; 431 ; 6.0", false);
	SetTrieValue(hItemInfoTrie, "811_ammo", 200, false);

//Flying Guillotine
	SetTrieString(hItemInfoTrie, "812_classname", "tf_weapon_cleaver", false);
	SetTrieValue(hItemInfoTrie, "812_index", 812, false);
	SetTrieValue(hItemInfoTrie, "812_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "812_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "812_level", 1, false);
	SetTrieString(hItemInfoTrie, "812_attribs", "435 ; 1.0 ; 437 ; 65536.0 ; 15 ; 0.0", false);
	SetTrieValue(hItemInfoTrie, "812_ammo", 1, false);

//Neon Annihilator
	SetTrieString(hItemInfoTrie, "813_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "813_index", 813, false);
	SetTrieValue(hItemInfoTrie, "813_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "813_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "813_level", 1, false);
	SetTrieString(hItemInfoTrie, "813_attribs", "146 ; 1.0 ; 438 ; 1.0 ; 15 ; 0.0 ; 138 ; 0.8 ; 436 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "813_ammo", -1, false);

//Promo Red-Tape Recorder
	SetTrieString(hItemInfoTrie, "831_classname", "tf_weapon_sapper", false);
	SetTrieValue(hItemInfoTrie, "831_index", 831, false);
	SetTrieValue(hItemInfoTrie, "831_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "831_quality", 1, false);
	SetTrieValue(hItemInfoTrie, "831_level", 1, false);
	SetTrieString(hItemInfoTrie, "831_attribs", "433 ; 0.5 ; 426 ; 0.0 ; 153 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "831_ammo", -1, false);

//Promo Huo Long Heater
	SetTrieString(hItemInfoTrie, "832_classname", "tf_weapon_minigun", false);
	SetTrieValue(hItemInfoTrie, "832_index", 832, false);
	SetTrieValue(hItemInfoTrie, "832_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "832_quality", 1, false);
	SetTrieValue(hItemInfoTrie, "832_level", 1, false);
	SetTrieString(hItemInfoTrie, "832_attribs", "430 ; 15.0 ; 431 ; 6.0 ; 153 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "832_ammo", 200, false);

//Promo Flying Guillotine
	SetTrieString(hItemInfoTrie, "833_classname", "tf_weapon_cleaver", false);
	SetTrieValue(hItemInfoTrie, "833_index", 833, false);
	SetTrieValue(hItemInfoTrie, "833_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "833_quality", 1, false);
	SetTrieValue(hItemInfoTrie, "833_level", 1, false);
	SetTrieString(hItemInfoTrie, "833_attribs", "435 ; 1.0 ; 437 ; 65536.0 ; 15 ; 0.0 ; 153 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "833_ammo", 1, false);

//Promo Neon Annihilator
	SetTrieString(hItemInfoTrie, "834_classname", "tf_weapon_fireaxe", false);
	SetTrieValue(hItemInfoTrie, "834_index", 834, false);
	SetTrieValue(hItemInfoTrie, "834_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "834_quality", 1, false);
	SetTrieValue(hItemInfoTrie, "834_level", 1, false);
	SetTrieString(hItemInfoTrie, "834_attribs", "146 ; 1.0 ; 438 ; 1.0 ; 15 ; 0.0 ; 138 ; 0.8 ; 436 ; 1.0 ; 153 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "834_ammo", -1, false);

//Bat Outta Hell
	SetTrieString(hItemInfoTrie, "939_classname", "saxxy", false);
	SetTrieValue(hItemInfoTrie, "939_index", 939, false);
	SetTrieValue(hItemInfoTrie, "939_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "939_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "939_level", 5, false);
	SetTrieString(hItemInfoTrie, "939_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "939_ammo", -1, false);

//Quackenbirdt
	SetTrieString(hItemInfoTrie, "947_classname", "tf_weapon_invis", false);
	SetTrieValue(hItemInfoTrie, "947_index", 947, false);
	SetTrieValue(hItemInfoTrie, "947_slot", 4, false);
	SetTrieValue(hItemInfoTrie, "947_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "947_level", 30, false);
	SetTrieString(hItemInfoTrie, "947_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "947_ammo", -1, false);

//Memory Maker
	SetTrieString(hItemInfoTrie, "954_classname", "saxxy", false);
	SetTrieValue(hItemInfoTrie, "954_index", 954, false);
	SetTrieValue(hItemInfoTrie, "954_slot", 2, false);
	SetTrieValue(hItemInfoTrie, "954_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "954_level", 50, false);
	SetTrieString(hItemInfoTrie, "954_attribs", "", false);
	SetTrieValue(hItemInfoTrie, "954_ammo", -1, false);

//Loose Cannon
	SetTrieString(hItemInfoTrie, "996_classname", "tf_weapon_cannon", false);
	SetTrieValue(hItemInfoTrie, "996_index", 996, false);
	SetTrieValue(hItemInfoTrie, "996_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "996_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "996_level", 10, false);
	SetTrieString(hItemInfoTrie, "996_attribs", "280 ; 17.0 ; 466 ; 2.0 ; 476 ; 1.5 ; 475 ; 1.5 ; 477 ; 1.0 ; 467 ; 1.0 ; 470 ; 0.5", false);
	SetTrieValue(hItemInfoTrie, "996_ammo", 16, false);

//Rescue Ranger
	SetTrieString(hItemInfoTrie, "997_classname", "tf_weapon_shotgun_building_rescue", false);
	SetTrieValue(hItemInfoTrie, "997_index", 997, false);
	SetTrieValue(hItemInfoTrie, "997_slot", 0, false);
	SetTrieValue(hItemInfoTrie, "997_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "997_level", 1, false);
	SetTrieString(hItemInfoTrie, "997_attribs", "280 ; 18.0 ; 469 ; 130.0 ; 474 ; 50.0 ; 3 ; 0.66 ; 77 ; 0.5 ; 472 ; 1.0", false);
	SetTrieValue(hItemInfoTrie, "997_ammo", 16, false);

//Vaccinator
	SetTrieString(hItemInfoTrie, "998_classname", "tf_weapon_medigun", false);
	SetTrieValue(hItemInfoTrie, "998_index", 998, false);
	SetTrieValue(hItemInfoTrie, "998_slot", 1, false);
	SetTrieValue(hItemInfoTrie, "998_quality", 6, false);
	SetTrieValue(hItemInfoTrie, "998_level", 8, false);
	SetTrieString(hItemInfoTrie, "998_attribs", "144 ; 3.0 ; 473 ; 3.0 ; 10 ; 1.5 ; 479 ; 0.34 ; 292 ; 1.0 ; 293 ; 2.0", false);
	SetTrieValue(hItemInfoTrie, "998_ammo", -1, false);

	SetTrieString(hItemInfoTrie, "850_attribs", "323 ; 1.0");	//deflector - "attack projectiles"
}
stock AddCustomHardcodedToTrie(Handle:trie)
{
//Upgradeable shotgun other classes
	SetTrieString(trie, "4199_classname", "tf_weapon_shotgun_soldier");
	SetTrieValue(trie, "4199_index", 199);
	SetTrieValue(trie, "4199_slot", 1);
	SetTrieValue(trie, "4199_quality", 6);
	SetTrieValue(trie, "4199_level", 1);
	SetTrieString(trie, "4199_attribs", "");
	SetTrieValue(trie, "4199_ammo", 32);

//valve rocket launcher
	SetTrieString(trie, "9018_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(trie, "9018_index", 18);
	SetTrieValue(trie, "9018_slot", 0);
	SetTrieValue(trie, "9018_quality", 8);
	SetTrieValue(trie, "9018_level", 100);
	SetTrieString(trie, "9018_attribs", "2 ; 1.15 ; 4 ; 1.5 ; 6 ; 0.85 ; 110 ; 15.0 ; 20 ; 1.0 ; 26 ; 50.0 ; 31 ; 5.0 ; 32 ; 0.30 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.15 ; 134 ; 2.0");
	SetTrieValue(trie, "9018_ammo", 200);

//valve sticky launcher
	SetTrieString(trie, "9020_classname", "tf_weapon_pipebomblauncher");
	SetTrieValue(trie, "9020_index", 20);
	SetTrieValue(trie, "9020_slot", 1);
	SetTrieValue(trie, "9020_quality", 8);
	SetTrieValue(trie, "9020_level", 100);
	SetTrieString(trie, "9020_attribs", "2 ; 1.15 ; 4 ; 1.5 ; 6 ; 0.85 ; 110 ; 15.0 ; 20 ; 1.0 ; 26 ; 50.0 ; 31 ; 5.0 ; 32 ; 0.30 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.15 ; 134 ; 2.0");
	SetTrieValue(trie, "9020_ammo", 200);

//valve sniper rifle
	SetTrieString(trie, "9014_classname", "tf_weapon_sniperrifle");
	SetTrieValue(trie, "9014_index", 14);
	SetTrieValue(trie, "9014_slot", 0);
	SetTrieValue(trie, "9014_quality", 8);
	SetTrieValue(trie, "9014_level", 100);
	SetTrieString(trie, "9014_attribs", "2 ; 1.15 ; 4 ; 1.5 ; 6 ; 0.85 ; 110 ; 15.0 ; 20 ; 1.0 ; 26 ; 50.0 ; 31 ; 5.0 ; 32 ; 0.30 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.15 ; 134 ; 2.0");
	SetTrieValue(trie, "9014_ammo", 200);

//valve scattergun
	SetTrieString(trie, "9013_classname", "tf_weapon_scattergun");
	SetTrieValue(trie, "9013_index", 13);
	SetTrieValue(trie, "9013_slot", 0);
	SetTrieValue(trie, "9013_quality", 8);
	SetTrieValue(trie, "9013_level", 100);
	SetTrieString(trie, "9013_attribs", "2 ; 1.15 ; 4 ; 1.5 ; 6 ; 0.85 ; 110 ; 15.0 ; 20 ; 1.0 ; 26 ; 50.0 ; 31 ; 5.0 ; 32 ; 0.30 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.15 ; 134 ; 2.0");
	SetTrieValue(trie, "9013_ammo", 200);

//valve flamethrower
	SetTrieString(trie, "9021_classname", "tf_weapon_flamethrower");
	SetTrieValue(trie, "9021_index", 21);
	SetTrieValue(trie, "9021_slot", 0);
	SetTrieValue(trie, "9021_quality", 8);
	SetTrieValue(trie, "9021_level", 100);
	SetTrieString(trie, "9021_attribs", "2 ; 1.15 ; 4 ; 1.5 ; 6 ; 0.85 ; 110 ; 15.0 ; 20 ; 1.0 ; 26 ; 50.0 ; 31 ; 5.0 ; 32 ; 0.30 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.15 ; 134 ; 2.0");
	SetTrieValue(trie, "9021_ammo", 400);

//valve syringe gun
	SetTrieString(trie, "9017_classname", "tf_weapon_syringegun_medic");
	SetTrieValue(trie, "9017_index", 17);
	SetTrieValue(trie, "9017_slot", 0);
	SetTrieValue(trie, "9017_quality", 8);
	SetTrieValue(trie, "9017_level", 100);
	SetTrieString(trie, "9017_attribs", "2 ; 1.15 ; 4 ; 1.5 ; 6 ; 0.85 ; 110 ; 15.0 ; 20 ; 1.0 ; 26 ; 50.0 ; 31 ; 5.0 ; 32 ; 0.30 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.15 ; 134 ; 2.0");
	SetTrieValue(trie, "9017_ammo", 300);

//valve minigun
	SetTrieString(trie, "9015_classname", "tf_weapon_minigun");
	SetTrieValue(trie, "9015_index", 15);
	SetTrieValue(trie, "9015_slot", 0);
	SetTrieValue(trie, "9015_quality", 8);
	SetTrieValue(trie, "9015_level", 100);
	SetTrieString(trie, "9015_attribs", "2 ; 1.15 ; 4 ; 1.5 ; 6 ; 0.85 ; 110 ; 15.0 ; 20 ; 1.0 ; 26 ; 50.0 ; 31 ; 5.0 ; 32 ; 0.30 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.15 ; 134 ; 2.0");
	SetTrieValue(trie, "9015_ammo", 400);

//valve revolver
	SetTrieString(trie, "9024_classname", "tf_weapon_revolver");
	SetTrieValue(trie, "9024_index", 24);
	SetTrieValue(trie, "9024_slot", 0);
	SetTrieValue(trie, "9024_quality", 8);
	SetTrieValue(trie, "9024_level", 100);
	SetTrieString(trie, "9024_attribs", "2 ; 1.15 ; 4 ; 1.5 ; 6 ; 0.85 ; 110 ; 15.0 ; 20 ; 1.0 ; 26 ; 50.0 ; 31 ; 5.0 ; 32 ; 0.30 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.15 ; 134 ; 2.0");
	SetTrieValue(trie, "9024_ammo", 100);

//valve shotgun engineer
	SetTrieString(trie, "9009_classname", "tf_weapon_shotgun_primary");
	SetTrieValue(trie, "9009_index", 9);
	SetTrieValue(trie, "9009_slot", 0);
	SetTrieValue(trie, "9009_quality", 8);
	SetTrieValue(trie, "9009_level", 100);
	SetTrieString(trie, "9009_attribs", "2 ; 1.15 ; 4 ; 1.5 ; 6 ; 0.85 ; 110 ; 15.0 ; 20 ; 1.0 ; 26 ; 50.0 ; 31 ; 5.0 ; 32 ; 0.30 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.15 ; 134 ; 2.0");
	SetTrieValue(trie, "9009_ammo", 100);

//valve medigun
	SetTrieString(trie, "9029_classname", "tf_weapon_medigun");
	SetTrieValue(trie, "9029_index", 29);
	SetTrieValue(trie, "9029_slot", 1);
	SetTrieValue(trie, "9029_quality", 8);
	SetTrieValue(trie, "9029_level", 100);
	SetTrieString(trie, "9029_attribs", "8 ; 1.15 ; 10 ; 1.15 ; 13 ; 0.0 ; 26 ; 50.0 ; 53 ; 1.0 ; 60 ; 0.85 ; 123 ; 1.5 ; 134 ; 2.0");
	SetTrieValue(trie, "9029_ammo", -1);

//ludmila
	SetTrieString(trie, "2041_classname", "tf_weapon_minigun");
	SetTrieValue(trie, "2041_index", 15);
	SetTrieValue(trie, "2041_slot", 0);
	SetTrieValue(trie, "2041_quality", 10);
	SetTrieValue(trie, "2041_level", 5);
	SetTrieString(trie, "2041_attribs", "29 ; 1 ; 86 ; 1.2 ; 5 ; 1.1");
	SetTrieValue(trie, "2041_ammo", 200);
	SetTrieString(trie, "2041_viewmodel", "models/weapons/c_models/c_v_ludmila/c_v_ludmila.mdl");

//spycrab pda
	SetTrieString(trie, "9027_classname", "tf_weapon_pda_spy");
	SetTrieValue(trie, "9027_index", 27);
	SetTrieValue(trie, "9027_slot", 3);
	SetTrieValue(trie, "9027_quality", 2);
	SetTrieValue(trie, "9027_level", 100);
	SetTrieString(trie, "9027_attribs", "128 ; 1.0 ; 412 ; 0.0 ; 70 ; 2.0 ; 53 ; 1.0 ; 68 ; -3.0 ; 400 ; 1.0 ; 134 ; 9.0");
	SetTrieValue(trie, "9027_ammo", -1);

//fire retardant suit (revolver does no damage)
	SetTrieString(trie, "2061_classname", "tf_weapon_revolver");
	SetTrieValue(trie, "2061_index", 61);
	SetTrieValue(trie, "2061_slot", 0);
	SetTrieValue(trie, "2061_quality", 10);
	SetTrieValue(trie, "2061_level", 5);
	SetTrieString(trie, "2061_attribs", "168 ; 1.0 ; 1 ; 0.0");
	SetTrieValue(trie, "2061_ammo", -1);

//valve cheap rocket launcher
	SetTrieString(trie, "8018_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(trie, "8018_index", 18);
	SetTrieValue(trie, "8018_slot", 0);
	SetTrieValue(trie, "8018_quality", 8);
	SetTrieValue(trie, "8018_level", 100);
	SetTrieString(trie, "8018_attribs", "2 ; 100.0 ; 4 ; 91.0 ; 6 ; 0.25 ; 110 ; 500.0 ; 26 ; 250.0 ; 31 ; 10.0 ; 107 ; 3.0 ; 97 ; 0.4 ; 134 ; 2.0");
	SetTrieValue(trie, "8018_ammo", 200);

//PCG cheap Community rocket launcher
	SetTrieString(trie, "7018_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(trie, "7018_index", 18);
	SetTrieValue(trie, "7018_slot", 0);
	SetTrieValue(trie, "7018_quality", 7);
	SetTrieValue(trie, "7018_level", 100);
	SetTrieString(trie, "7018_attribs", "26 ; 500.0 ; 110 ; 500.0 ; 6 ; 0.25 ; 4 ; 200.0 ; 2 ; 100.0 ; 97 ; 0.2 ; 134 ; 4.0");
	SetTrieValue(trie, "7018_ammo", 200);

//derpFaN
	SetTrieString(trie, "8045_classname", "tf_weapon_scattergun");
	SetTrieValue(trie, "8045_index", 45);
	SetTrieValue(trie, "8045_slot", 0);
	SetTrieValue(trie, "8045_quality", 8);
	SetTrieValue(trie, "8045_level", 99);
	SetTrieString(trie, "8045_attribs", "44 ; 1.0 ; 6 ; 0.25 ; 45 ; 2.0 ; 2 ; 10.0 ; 4 ; 100.0 ; 43 ; 1.0 ; 26 ; 500.0 ; 110 ; 500.0 ; 97 ; 0.2 ; 31 ; 10.0 ; 107 ; 3.0 ; 134 ; 4.0");
	SetTrieValue(trie, "8045_ammo", 200);

//Trilby's Rebel Pack - Texas Ten-Shot
	SetTrieString(trie, "2141_classname", "tf_weapon_shotgun_primary");	//used to be tf_weapon_sentry_revenge
	SetTrieValue(trie, "2141_index", 141);
	SetTrieValue(trie, "2141_slot", 0);
	SetTrieValue(trie, "2141_quality", 10);
	SetTrieValue(trie, "2141_level", 10);
	SetTrieString(trie, "2141_attribs", "4 ; 1.66 ; 19 ; 0.15 ; 76 ; 1.25 ; 96 ; 1.8 ; 134 ; 3");
	SetTrieValue(trie, "2141_ammo", 40);

//Trilby's Rebel Pack - Texan Love
	SetTrieString(trie, "2161_classname", "tf_weapon_shotgun_pyro");
	SetTrieValue(trie, "2161_index", 460);
	SetTrieValue(trie, "2161_slot", 1);
	SetTrieValue(trie, "2161_quality", 10);
	SetTrieValue(trie, "2161_level", 10);
	SetTrieString(trie, "2161_attribs", "2 ; 1.4 ; 106 ; 0.65 ; 6 ; 0.80 ; 146 ; 1.0 ; 97 ; 0.7 ; 69 ; 0.80 ; 45 ; 0.3 ; 106 ; 0.0");
	SetTrieValue(trie, "2161_ammo", 24);

//direct hit LaN
	SetTrieString(trie, "2127_classname", "tf_weapon_rocketlauncher_directhit");
	SetTrieValue(trie, "2127_index", 127);
	SetTrieValue(trie, "2127_slot", 0);
	SetTrieValue(trie, "2127_quality", 10);
	SetTrieValue(trie, "2127_level", 1);
	SetTrieString(trie, "2127_attribs", "3 ; 0.5 ; 103 ; 1.8 ; 2 ; 1.25 ; 114 ; 1.0 ; 67 ; 1.1");
	SetTrieValue(trie, "2127_ammo", 20);

//dalokohs bar Effect
	SetTrieString(trie, "2159_classname", "tf_weapon_lunchbox");
	SetTrieValue(trie, "2159_index", 159);
	SetTrieValue(trie, "2159_slot", 1);
	SetTrieValue(trie, "2159_quality", 6);
	SetTrieValue(trie, "2159_level", 1);
	SetTrieString(trie, "2159_attribs", "140 ; 50 ; 139 ; 1");
	SetTrieValue(trie, "2159_ammo", 1);

//fishcake Effect
	SetTrieString(trie, "2433_classname", "tf_weapon_lunchbox");
	SetTrieValue(trie, "2433_index", 433);
	SetTrieValue(trie, "2433_slot", 1);
	SetTrieValue(trie, "2433_quality", 6);
	SetTrieValue(trie, "2433_level", 1);
	SetTrieString(trie, "2433_attribs", "140 ; 50 ; 139 ; 1");
	SetTrieValue(trie, "2433_ammo", 1);

//The Army of One
	SetTrieString(trie, "2228_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(trie, "2228_index", 228);
	SetTrieValue(trie, "2228_slot", 0);
	SetTrieValue(trie, "2228_quality", 10);
	SetTrieValue(trie, "2228_level", 5);
//	SetTrieString(trie, "2228_attribs", "2 ; 5.0 ; 99 ; 3.0 ; 3 ; 0.25 ; 104 ; 0.3 ; 77 ; 0.0");
	SetTrieString(trie, "2228_attribs", "2 ; 5.0 ; 99 ; 3.0 ; 521 ; 1.0 ; 3 ; 0.25 ; 104 ; 0.3 ; 77 ; 0.0 ; 16 ; 0.0");
	SetTrieValue(trie, "2228_ammo", 0);
	SetTrieString(trie, "2228_model", "models/advancedweaponiser/fbomb/c_fbomb.mdl");
	SetTrieString(trie, "2228_viewmodel", "models/advancedweaponiser/fbomb/c_fbomb.mdl");

//Shotgun for all
	SetTrieString(trie, "2009_classname", "tf_weapon_sentry_revenge");
	SetTrieValue(trie, "2009_index", 141);
	SetTrieValue(trie, "2009_slot", 0);
	SetTrieValue(trie, "2009_quality", 0);
	SetTrieValue(trie, "2009_level", 1);
	SetTrieString(trie, "2009_attribs", "");
	SetTrieValue(trie, "2009_ammo", 32);

//Another weapon by Trilby- Fighter's Falcata
	SetTrieString(trie, "2193_classname", "tf_weapon_club");
	SetTrieValue(trie, "2193_index", 193);
	SetTrieValue(trie, "2193_slot", 2);
	SetTrieValue(trie, "2193_quality", 10);
	SetTrieValue(trie, "2193_level", 5);
	SetTrieString(trie, "2193_attribs", "6 ; 0.8 ; 2 ; 1.1 ; 15 ; 0 ; 98 ; -15");
	SetTrieValue(trie, "2193_ammo", -1);

//Khopesh Climber- MECHA! (the Slag)
	SetTrieString(trie, "2171_classname", "tf_weapon_club");
	SetTrieValue(trie, "2171_index", 171);
	SetTrieValue(trie, "2171_slot", 2);
	SetTrieValue(trie, "2171_quality", 10);
	SetTrieValue(trie, "2171_level", 11);
	SetTrieString(trie, "2171_attribs", "1 ; 0.9 ; 5 ; 1.95");
	SetTrieValue(trie, "2171_ammo", -1);
	SetTrieString(trie, "2171_model", "models/advancedweaponiser/w_sickle_sniper.mdl");
	SetTrieString(trie, "2171_viewmodel", "models/advancedweaponiser/w_sickle_sniper.mdl");

//Robin's new cheap Rocket Launcher
	SetTrieString(trie, "9205_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(trie, "9205_index", 205);
	SetTrieValue(trie, "9205_slot", 0);
	SetTrieValue(trie, "9205_quality", 8);
	SetTrieValue(trie, "9205_level", 100);
	SetTrieString(trie, "9205_attribs", "2 ; 10100.0 ; 4 ; 1100.0 ; 6 ; 0.25 ; 16 ; 250.0 ; 31 ; 10.0 ; 103 ; 1.5 ; 107 ; 2.0 ; 134 ; 2.0");
	SetTrieValue(trie, "9205_ammo", 200);

//Trilby's Rebel Pack - Rebel's Curse
	SetTrieString(trie, "2197_classname", "tf_weapon_wrench");
	SetTrieValue(trie, "2197_index", 197);
	SetTrieValue(trie, "2197_slot", 2);
	SetTrieValue(trie, "2197_quality", 10);
	SetTrieValue(trie, "2197_level", 13);
	SetTrieString(trie, "2197_attribs", "156 ; 1.0 ; 2 ; 1.05 ; 107 ; 1.1 ; 62 ; 0.90 ; 64 ; 0.90 ; 125 ; -10.0 ; 5 ; 1.2 ; 81 ; 0.75 ; 436 ; 1.0");
	SetTrieValue(trie, "2197_ammo", -1);
	SetTrieString(trie, "2197_model", "models/custom/weapons/rebelscurse/c_wrench_v2.mdl");
	SetTrieString(trie, "2197_viewmodel", "models/custom/weapons/rebelscurse/c_wrench_v2.mdl");

//Jar of Ants - Ant'eh'gen
	SetTrieString(trie, "2058_classname", "tf_weapon_jar");
	SetTrieValue(trie, "2058_index", 58);
	SetTrieValue(trie, "2058_slot", 1);
	SetTrieValue(trie, "2058_quality", 10);
	SetTrieValue(trie, "2058_level", 6);
	SetTrieString(trie, "2058_attribs", "149 ; 10.0 ; 134 ; 12.0");
	SetTrieValue(trie, "2058_ammo", 1);
	SetTrieString(trie, "2058_model", "models/custom/weapons/antehgen/urinejar.mdl");
	SetTrieString(trie, "2058_viewmodel", "models/custom/weapons/antehgen/urinejar.mdl");

//The Horsemann's Axe
	SetTrieString(trie, "9266_classname", "tf_weapon_sword");
	SetTrieValue(trie, "9266_index", 266);
	SetTrieValue(trie, "9266_slot", 2);
	SetTrieValue(trie, "9266_quality", 5);
	SetTrieValue(trie, "9266_level", 100);
	SetTrieString(trie, "9266_attribs", "15 ; 0 ; 26 ; 600.0 ; 2 ; 999.0 ; 107 ; 4.0 ; 109 ; 0.0 ; 57 ; 50.0 ; 69 ; 0.0 ; 68 ; -1 ; 53 ; 1.0 ; 27 ; 1.0 ; 180 ; -25 ; 219 ; 1.0 ; 134 ; 8.0");
	SetTrieValue(trie, "9266_ammo", -1);

//Goldslinger
	SetTrieString(trie, "5142_classname", "tf_weapon_robot_arm");
	SetTrieValue(trie, "5142_index", 142);
	SetTrieValue(trie, "5142_slot", 2);
	SetTrieValue(trie, "5142_quality", 6);
	SetTrieValue(trie, "5142_level", 25);
	SetTrieString(trie, "5142_attribs", "124 ; 1 ; 26 ; 25.0 ; 15 ; 0 ; 150 ; 1");
	SetTrieValue(trie, "5142_ammo", -1);
//	SetTrieString(trie, "5142_model", "models/custom/weapons/goldslinger/engineer_v3.mdl"); //horridly broken
//	SetTrieString(trie, "5142_model", "models/custom/weapons/goldslinger/c_engineer_gunslinger.mdl");	//also does not work
	SetTrieString(trie, "5142_viewmodel", "models/custom/weapons/goldslinger/c_engineer_gunslinger.mdl");


//TF2 BETA SECTION, THESE MAY NOT WORK AT ALL
//Beta Pocket Rocket Launcher
	SetTrieString(trie, "19010_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(trie, "19010_index", 127);
	SetTrieValue(trie, "19010_slot", 0);
	SetTrieValue(trie, "19010_quality", 4);
	SetTrieValue(trie, "19010_level", 25);
	SetTrieString(trie, "19010_attribs", "232 ; 6.0 ; 111 ; -10.0");
	SetTrieValue(trie, "19010_ammo", 20);

//Beta Quick Fix
	SetTrieString(trie, "186_classname", "tf_weapon_medigun");
	SetTrieValue(trie, "186_index", 29);
	SetTrieValue(trie, "186_slot", 1);
	SetTrieValue(trie, "186_quality", 4);
	SetTrieValue(trie, "186_level", 5);
	SetTrieString(trie, "186_attribs", "144 ; 2.0 ; 8 ; 1.4 ; 10 ; 1.4 ; 231 ; 2.0");
	SetTrieValue(trie, "186_ammo", -1);

//Pocket Shotgun
	SetTrieString(trie, "19011_classname", "tf_weapon_shotgun_soldier");
	SetTrieValue(trie, "19011_index", 10);
	SetTrieValue(trie, "19011_slot", 1);
	SetTrieValue(trie, "19011_quality", 4);
	SetTrieValue(trie, "19011_level", 10);
	SetTrieString(trie, "19011_attribs", "233 ; 1.20 ; 234 ; 1.3");
	SetTrieValue(trie, "19011_ammo", 32);

//Beta Split Equalizer 1
	SetTrieString(trie, "19012_classname", "tf_weapon_shovel");
	SetTrieValue(trie, "19012_index", 128);
	SetTrieValue(trie, "19012_slot", 2);
	SetTrieValue(trie, "19012_quality", 4);
	SetTrieValue(trie, "19012_level", 10);
	SetTrieString(trie, "19012_attribs", "235 ; 2.0 ; 236 ; 1.0");
	SetTrieValue(trie, "19012_ammo", -1);

//Beta Split Equalizer 2
	SetTrieString(trie, "19013_classname", "tf_weapon_shovel");
	SetTrieValue(trie, "19013_index", 128);
	SetTrieValue(trie, "19013_slot", 2);
	SetTrieValue(trie, "19013_quality", 4);
	SetTrieValue(trie, "19013_level", 10);
	SetTrieString(trie, "19013_attribs", "115 ; 1.0 ; 236 ; 1.0");
	SetTrieValue(trie, "19013_ammo", -1);

//Beta Sniper Rifle 1
	SetTrieString(trie, "19015_classname", "tf_weapon_sniperrifle");
	SetTrieValue(trie, "19015_index", 14);
	SetTrieValue(trie, "19015_slot", 0);
	SetTrieValue(trie, "19015_quality", 4);
	SetTrieValue(trie, "19015_level", 10);
	SetTrieString(trie, "19015_attribs", "237 ; 1.45 ; 222 ; 1.25 ; 223 ; 0.35");
	SetTrieValue(trie, "19015_ammo", 25);

//Beta Pocket Rocket Launcher 2
	SetTrieString(trie, "19016_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(trie, "19016_index", 127);
	SetTrieValue(trie, "19016_slot", 0);
	SetTrieValue(trie, "19016_quality", 4);
	SetTrieValue(trie, "19016_level", 25);
	SetTrieString(trie, "19016_attribs", "239 ; 1.15 ; 111 ; -10.0");
	SetTrieValue(trie, "19016_ammo", 20);

//Beta Pocket Rocket Launcher 2
	SetTrieString(trie, "19017_classname", "tf_weapon_rocketlauncher");
	SetTrieValue(trie, "19017_index", 127);
	SetTrieValue(trie, "19017_slot", 0);
	SetTrieValue(trie, "19017_quality", 4);
	SetTrieValue(trie, "19017_level", 25);
	SetTrieString(trie, "19017_attribs", "240 ; 0.5 ; 111 ; -10.0");
	SetTrieValue(trie, "19017_ammo", 20);

//Pocket Protector: Buff banner that builds rage by being healed, and gives minicrits for its buff but during buff, cannot gain health from being healed
	SetTrieString(trie, "2129_classname", "tf_weapon_buff_item");
	SetTrieValue(trie, "2129_index", 129);
	SetTrieValue(trie, "2129_slot", 1);
	SetTrieValue(trie, "2129_quality", 4);
	SetTrieValue(trie, "2129_level", 3);
	SetTrieString(trie, "2129_attribs", "116 ; 4");
	SetTrieValue(trie, "2129_ammo", -1);
}
PrepareAllModels()
{
	for (new i = 0; i <= 999999; i++)
	{
		decl String:modelname[PLATFORM_MAX_PATH];
		decl String:formatBuffer[32];
		Format(formatBuffer, sizeof(formatBuffer), "%d_model", i);
		if (GetTrieString(hItemInfoTrie, formatBuffer, modelname, sizeof(modelname)))
		{
			PrepareCustomWeaponModel(modelname, formatBuffer);
		}
		Format(formatBuffer, sizeof(formatBuffer), "%d_viewmodel", i);
		if (GetTrieString(hItemInfoTrie, formatBuffer, modelname, sizeof(modelname)))
		{
			PrepareCustomWeaponModel(modelname, formatBuffer);
		}
		Format(formatBuffer, sizeof(formatBuffer), "%d_model_pv", i);
		if (GetTrieString(hItemInfoTrie, formatBuffer, modelname, sizeof(modelname)))
		{
			PrepareCustomWeaponModel(modelname, formatBuffer);
		}
		Format(formatBuffer, sizeof(formatBuffer), "%d_model_hv", i);
		if (GetTrieString(hItemInfoTrie, formatBuffer, modelname, sizeof(modelname)))
		{
			PrepareCustomWeaponModel(modelname, formatBuffer);
		}
		Format(formatBuffer, sizeof(formatBuffer), "%d_model_rv", i);
		if (GetTrieString(hItemInfoTrie, formatBuffer, modelname, sizeof(modelname)))
		{
			PrepareCustomWeaponModel(modelname, formatBuffer);
		}
	}
}
stock PrepareCustomWeaponModel(const String:modelname[], const String:key[])
{
	decl String:modelfile[PLATFORM_MAX_PATH + 4];
	decl String:strLine[PLATFORM_MAX_PATH];
	Format(modelfile, sizeof(modelfile), "%s.dep", modelname);
	new Handle:hStream = INVALID_HANDLE;
	if (FileExists(modelfile))
	{
		// Open stream, if possible
		hStream = OpenFile(modelfile, "r");
		if (hStream == INVALID_HANDLE)
		{
			LogMessage("[TF2Items GiveWeapon]%s: Error, can't read file containing model dependencies %s", key, modelfile);
			return;
		}

		while(!IsEndOfFile(hStream))
		{
			// Try to read line. If EOF has been hit, exit.
			ReadFileLine(hStream, strLine, sizeof(strLine));

			// Cleanup line
			CleanString(strLine);

			// If file exists...
			if (!FileExists(strLine, true))
			{
				LogMessage("[TF2Items GiveWeapon]%s: File %s doesn't exist, skipping", key, strLine);
				continue;
			}

			// Precache depending on type, and add to download table
			if (StrContains(strLine, ".vmt", false) != -1)		PrecacheDecal(strLine, true);
			else if (StrContains(strLine, ".mdl", false) != -1)	PrecacheModel(strLine, true);
			else if (StrContains(strLine, ".pcf", false) != -1)	PrecacheGeneric(strLine, true);
			LogMessage("[TF2Items GiveWeapon]%s: Preparing %s", key, strLine);
			AddFileToDownloadsTable(strLine);
		}

		// Close file
		CloseHandle(hStream);
	}
	else if (FileExists(modelname, true) && StrContains(modelname, ".mdl", false) != -1)
	{
		PrecacheModel(modelname, true);
		LogMessage("[TF2Items GiveWeapon]%s: Preparing %s", key, modelname);
	}
	else LogMessage("[TF2Items GiveWeapon]%s: cannot find valid model %s, skipping", key, modelname);
}
stock CleanString(String:strBuffer[])
{
	// Cleanup any illegal characters
	new Length = strlen(strBuffer);
	for (new iPos=0; iPos<Length; iPos++)
	{
		switch(strBuffer[iPos])
		{
			case '\r': strBuffer[iPos] = ' ';
			case '\n': strBuffer[iPos] = ' ';
			case '\t': strBuffer[iPos] = ' ';
		}
	}

	// Trim string
	TrimString(strBuffer);
}

stock SetSpeshulAmmo(client, wepslot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (!IsValidEntity(weapon)) return;
	new type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (type < 0 || type > 31) return;
	SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, type);
}

stock GetSpeshulAmmo(client, wepslot)
{
	if (!IsValidClient(client)) return 0;
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (!IsValidEntity(weapon)) return 0;
	new type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (type < 0 || type > 31) return 0;
	return GetEntProp(client, Prop_Send, "m_iAmmo", _, type);
}

stock TF2_GetMetal(client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return 0;
	return GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);
}

stock TF2_SetMetal(client, metal)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return;
	SetEntProp(client, Prop_Send, "m_iAmmo", metal, _, 3);
}

/*stock SetNewAmmo(client, wepslot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	if (IsValidEntity(weapon))
	{
		new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1);
		SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, ammotype);
	}
}*/
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	if (TF2_IsPlayerInCondition(client, TFCond_Charging) && TF2_GetPlayerClass(client) != TFClass_DemoMan && (StrEqual(weaponname, "tf_weapon_wrench")
			|| StrEqual(weaponname, "tf_weapon_shovel")
			|| StrEqual(weaponname, "tf_weapon_bottle")
			|| StrEqual(weaponname, "tf_weapon_fists")
			|| strncmp(weaponname, "tf_weapon_bat", 13) == 0
			|| StrEqual(weaponname, "tf_weapon_bonesaw")
			|| StrEqual(weaponname, "tf_weapon_sword")
			|| StrEqual(weaponname, "tf_weapon_fireaxe")
			|| StrEqual(weaponname, "tf_weapon_robot_arm")
//			|| StrEqual(weaponname, "tf_weapon_bat_wood")
			|| StrEqual(weaponname, "tf_weapon_club")
//			|| StrEqual(weaponname, "tf_weapon_bat_fish")
			|| StrEqual(weaponname, "tf_weapon_stickbomb")
			|| StrEqual(weaponname, "tf_weapon_knife")))
	{
		TF2_RemoveCondition(client, TFCond_Charging);
		CreateTimer(0.4, Timer_ResetMeleeCrit, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);	//SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 0);
		DoResetChargeTimer(client, true);
	}
	if (StrEqual(weaponname, "tf_weapon_club") && GetEntProp(weapon, Prop_Send, "m_iEntityLevel") == (-128+11) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 171)
	{
		SickleClimbWalls(client);
	}
	return Plugin_Continue;
}
public Action:Timer_ResetMeleeCrit(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return Plugin_Stop;
	SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 0);
	return Plugin_Continue;
}
public SickleClimbWalls(client)
{
	if (!IsValidClient(client)) return;
//	if (GetPlayerClass(client) != 7) return;
//	if (!(g_iSpecialAttributes[client] & attribute_climbwalls)) return;

	decl String:classname[64];
	decl Float:vecClientEyePos[3];
	decl Float:vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);	 // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng);	   // Get the angle the player is looking

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if (!TR_DidHit(INVALID_HANDLE)) return;

	new TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
	GetEdictClassname(TRIndex, classname, sizeof(classname));
	if (!StrEqual(classname, "worldspawn")) return;

	decl Float:fNormal[3];
	TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
	GetVectorAngles(fNormal, fNormal);

	//PrintToChatAll("Normal: %f", fNormal[0]);

	if (fNormal[0] >= 30.0 && fNormal[0] <= 330.0) return;
	if (fNormal[0] <= -30.0) return;

	decl Float:pos[3];
	TR_GetEndPosition(pos);
	new Float:distance = GetVectorDistance(vecClientEyePos, pos);

	//PrintToChatAll("Distance: %f", distance);
	if (distance >= 100.0) return;

	new Float:fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
	fVelocity[2] = 600.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	ClientCommand(client, "playgamesound \"%s\"", "player\\taunt_clip_spin.wav");
	if (GetEntProp(client, Prop_Send, "m_nNumHealers") <= 0) return;
	for (new healer = 1; healer <= MaxClients; healer++)
	{
		if (!IsClientInGame(healer)) continue;
		if (!IsPlayerAlive(healer)) continue;
		new sec = GetPlayerWeaponSlot(healer, TFWeaponSlot_Secondary);
		GetEdictClassname(sec, classname, sizeof(classname));
		if (StrEqual(classname, "tf_weapon_medigun", false))	//it's a medigun
		{
			if (GetEntProp(sec, Prop_Send, "m_iItemDefinitionIndex") != 411 || client != GetEntPropEnt(sec, Prop_Send, "m_hHealingTarget"))
			{
				continue;
			}	//#TF2AttribStuffs
			TeleportEntity(healer, NULL_VECTOR, NULL_VECTOR, fVelocity);
		}
	}
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return (entity != data);
}
stock bool:IsValidClient(client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
//	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Register Native
	CreateNative("TF2Items_GiveWeapon", Native_GiveWeapon);
	CreateNative("TF2Items_CreateWeapon", Native_CreateWeapon);
	CreateNative("TF2Items_CheckWeapon", Native_CheckWeapon);
	CreateNative("TF2Items_CheckWeaponSlot", Native_CheckWeaponSlot);
	RegPluginLibrary("tf2items_giveweapon");
	return APLRes_Success;
}
public Native_GiveWeapon(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (!(IsValidClient(client) || IsPlayerAlive(client)))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[TF2Items] Invalid/dead target (%d) at the moment", client);
	}
	new weaponIndex = GetNativeCell(2);
	decl String:formatBuffer[32];
	new weaponSlot;
	Format(formatBuffer, 32, "%d_slot", weaponIndex);
	if (!GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "[TF2Items] Invalid Weapon Index (%d)", weaponIndex);
	}
	return GiveWeaponOfIndex(client, weaponIndex, weaponSlot);
}

public Native_CreateWeapon(Handle:plugin, numParams)
{
	decl String:formatBuffer[64];
	new desiredIndex = GetNativeCell(1);
	new weaponSlot;
	new bool:overwrite = GetNativeCell(10);

	Format(formatBuffer, 64, "%d_slot", desiredIndex);
	if (GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot) && !overwrite) ThrowNativeError(SP_ERROR_NATIVE, "[TF2Items] Weapon Index %d already in use, not overwritten", desiredIndex);

	new String:classname[64];
	GetNativeString(2, classname, sizeof(classname));
	Format(formatBuffer, 64, "%d_classname", desiredIndex);
	SetTrieString(hItemInfoTrie, formatBuffer, classname);

	new weaponIndex = GetNativeCell(3);
	Format(formatBuffer, 64, "%d_index", desiredIndex);
	SetTrieValue(hItemInfoTrie, formatBuffer, weaponIndex);

	weaponSlot = GetNativeCell(4);
	Format(formatBuffer, 64, "%d_slot", desiredIndex);
	SetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);

	new weaponQuality = GetNativeCell(5);
	Format(formatBuffer, 64, "%d_quality", desiredIndex);
	SetTrieValue(hItemInfoTrie, formatBuffer, weaponQuality);

	new weaponLevel = GetNativeCell(6);
	Format(formatBuffer, 64, "%d_level", desiredIndex);
	SetTrieValue(hItemInfoTrie, formatBuffer, weaponLevel);

	new String:weaponAttribs[256];
	GetNativeString(7, weaponAttribs, sizeof(weaponAttribs));
	Format(formatBuffer, 32, "%d_attribs", desiredIndex);
	SetTrieString(hItemInfoTrie, formatBuffer, weaponAttribs);

	new weaponAmmo = GetNativeCell(8);
	Format(formatBuffer, 64, "%d_ammo", desiredIndex);
	SetTrieValue(hItemInfoTrie, formatBuffer, weaponAmmo);

	new String:weaponModel[256];
	GetNativeString(9, weaponModel, sizeof(weaponModel));
	if (weaponModel[0] != '\0')
	{
		Format(formatBuffer, 32, "%d_model", desiredIndex);
		SetTrieString(hItemInfoTrie, formatBuffer, weaponModel);
	}
}
public Native_CheckWeapon(Handle:plugin, numParams)
{
	new index = GetNativeCell(1);
	new weaponSlot;
	decl String:formatBuffer[64];
	Format(formatBuffer, 64, "%d_slot", index);
	return GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot);
}
public Native_CheckWeaponSlot(Handle:plugin, numParams)
{
	new index = GetNativeCell(1);
	new weaponSlot;
	decl String:formatBuffer[64];
	Format(formatBuffer, 64, "%d_slot", index);
	if (GetTrieValue(hItemInfoTrie, formatBuffer, weaponSlot))
		return weaponSlot;
	else return ThrowNativeError(SP_ERROR_NATIVE, "[TF2Items] Weapon %d does not exist", index);
}
stock bool:TF2_SdkStartup()
{
	new Handle:hGameConf = LoadGameConfigFile("tf2items.randomizer");
	if (hGameConf == INVALID_HANDLE)
	{
		LogMessage("Couldn't load SDK functions (GiveWeapon). Make sure tf2items.randomizer.txt is in your gamedata folder! Restart server if you want wearable weapons.");
		return false;
	}
	if (hSDKEquipWearable == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::EquipWearable");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		hSDKEquipWearable = EndPrepSDKCall();
	}
//TODO: invalid handle checking
/*	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"CTFPlayer::RemoveWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSdkRemoveWearable = EndPrepSDKCall();*/

/*	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CTFPlayer::GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	hMaxHealth = EndPrepSDKCall();
	if (hMaxHealth == INVALID_HANDLE)
	{
		LogError("Could not initialize call for CTFPlayer::GetMaxHealth. Going with backup m_iMaxHealth.");
	}*/

	CloseHandle(hGameConf);
	bSDKStarted = true;
	return true;
}
stock TF2_EquipWearable(client, entity)
{
	if (bSDKStarted == false || hSDKEquipWearable == INVALID_HANDLE)
	{
		TF2_SdkStartup();
		LogMessage("Error: Can't call EquipWearable, SDK functions not loaded! If it continues to fail, reload plugin or restart server. Make sure your gamedata is intact!");
	}
	else
	{
		if (TF2_IsEntityWearable(entity)) SDKCall(hSDKEquipWearable, client, entity);
		else LogMessage("Error: Item %i isn't a valid wearable.", entity);
	}
}
stock bool:TF2_IsEntityWearable(entity)
{
	if (entity > MaxClients && IsValidEdict(entity))
	{
		new String:strClassname[32]; GetEdictClassname(entity, strClassname, sizeof(strClassname));
		return (strncmp(strClassname, "tf_wearable", 11, false) == 0 || strncmp(strClassname, "tf_powerup", 10, false) == 0);
	}

	return false;
}
stock TF2_GetMaxHealth(client)
{
	new maxhealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
	return ((maxhealth == -1 || maxhealth == 80896) ? GetEntProp(client, Prop_Data, "m_iMaxHealth") : maxhealth);
//	if (hMaxHealth != INVALID_HANDLE)
//		return SDKCall(hMaxHealth, client);
//	else return GetEntProp(client, Prop_Data, "m_iMaxHealth");		//backup
}
stock TF2_SetHealth(client, NewHealth)
{
	SetEntProp(client, Prop_Send, "m_iHealth", NewHealth);
	SetEntProp(client, Prop_Data, "m_iHealth", NewHealth);
}
stock RemovePlayerBack(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 57 || idx == 133 || idx == 231 || idx == 444 || idx == 642) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}
stock RemovePlayerBooties(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 405 || idx == 608) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				AcceptEntityInput(edict, "Kill");
			}
		}
	}
}
stock RemovePlayerTarge(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable_demoshield")) != -1)
	{
		new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
		if ((idx == 131 || idx == 406) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
		{
			AcceptEntityInput(edict, "Kill");
		}
	}
}
stock FindPlayerTarge(client)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable_demoshield")) != -1)
	{
		new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
		if ((idx == 131 || idx == 406) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
		{
			return edict;
		}
	}
	return -1;
}
stock GetPlayerWeaponSlot_Wearable(client, slot)
{
	new edict = MaxClients+1;
	if (slot == TFWeaponSlot_Secondary)
	{
		while((edict = FindEntityByClassname2(edict, "tf_wearable_demoshield")) != -1)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if ((idx == 131 || idx == 406) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				return edict;
			}
		}
	}
	edict = MaxClients+1;
	while((edict = FindEntityByClassname2(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (((slot == TFWeaponSlot_Primary && (idx == 405 || idx == 608)) || (slot == TFWeaponSlot_Secondary && (idx == 57 || idx == 133 || idx == 231 || idx == 444 || idx == 642))) && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(edict, Prop_Send, "m_bDisguiseWearable"))
			{
				return edict;
			}
		}
	}
	return -1;
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!IsPlayerAlive(client)) return Plugin_Continue;
	if ((buttons & IN_ATTACK2) && !(iLastButtons[client] & IN_ATTACK2))
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
		new idxslot2 = GetIndexOfWeaponSlot(client, TFWeaponSlot_Secondary);
		new wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new targe = -1;
		if ((buttons & IN_RELOAD) && GetEntityMoveType(client) != MOVETYPE_NONE && ((targe = FindPlayerTarge(client)) != -1) && hChargeTimer[client] == INVALID_HANDLE && GetEntPropFloat(client, Prop_Send, "m_flMaxspeed") > 1.01 && (class != TFClass_DemoMan || (wep == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) && (idxslot2 == 265 || idxslot2 == 20 || idxslot2 == 207 || idxslot2 == 130))))
		{
			new Float:chargetime;
			if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 327) chargetime = 2.0;
			else chargetime = 1.5;
			SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 100.0);
			if (class != TFClass_DemoMan) SetShieldBashUsed(targe, false);
			TF2_AddCondition(client, TFCond_Charging, chargetime);
			if (class != TFClass_DemoMan)
			{
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 750.0);
				CreateTimer(0.1, Timer_TargeCharging, GetClientUserId(client), TIMER_REPEAT);
			}
			if (IsValidEntity(wep))
			{
				new String:classname[64];
				GetEntityClassname(wep, classname, sizeof(classname));
				if (strncmp(classname, "tf_weapon", 9, false) == 0)
				{
					new Float:time = GetGameTime();
					new Float:old = GetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack");
					if (time > old) SetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack", time + 0.3);
					buttons &= ~IN_ATTACK2;
				}
			}
			hChargeTimer[client] = CreateTimer(chargetime, Timer_TargeReset, GetClientUserId(client));
		}
		else if (class != TFClass_Pyro && !GetEntProp(client, Prop_Send, "m_bRageDraining") && (GetEntityFlags(client) & FL_ONGROUND) && wep == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 594 && GetEntPropFloat(client, Prop_Send, "m_flRageMeter") >= 100.0)
		{
			DoActivateMmmph(client);
		}
		else if (class != TFClass_Engineer && !TF2_IsPlayerInCondition(client, TFCond_Taunting) && !TF2_IsPlayerInCondition(client, TFCond_Dazed) && (GetEntityFlags(client) & FL_ONGROUND) && wep == GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) && GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 589)
		{
			if (!TF2_IsPlayerInCondition(client, TFCond_Charging)) DoEurekaTaunt(client);
		}
	}
/*	if ((buttons & IN_FORWARD) && TF2_IsPlayerInCondition(client, TFCond_Charging) && TF2_GetPlayerClass(client) != TFClass_DemoMan)	//used to be TF2_GetPlayerConditionFlags(client) & TF_CONDFLAG_CHARGING
	{
		buttons &= ~IN_FORWARD;
	}*/
	iLastButtons[client] = buttons;
	return Plugin_Continue;
}
stock SetShieldBashUsed(shield, bool:used = true)
{
	new bashoffs = GetEntSendPropOffs(shield, "m_hWeaponAssociatedWith") + 28;
	if (bashoffs > 28) SetEntData(shield, bashoffs, used ? 1 : 0);
	return bashoffs > 28;
}
stock DoActivateMmmph(client)
{
	decl Float:vel[3];
	vel[0] = 0.0;
	vel[1] = 0.0;
	vel[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	SetEntProp(client, Prop_Send, "m_bRageDraining", 1);
	TF2_AddCondition(client, TFCond_DefenseBuffMmmph, 2.7);
	TF2_AddCondition(client, TFCond_CritMmmph, 10.0);
	new bool:megaheal = TF2_IsPlayerInCondition(client, TFCond_MegaHeal);
	TF2_RemoveCondition(client, TFCond_MegaHeal);
	TF2_StunPlayer(client, 2.5, 0.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
	if (megaheal) TF2_AddCondition(client, TFCond_MegaHeal, 0.1);
	if (GetClientHealth(client) < TF2_GetMaxHealth(client)) TF2_SetHealth(client, TF2_GetMaxHealth(client));
	decl String:sound[PLATFORM_MAX_PATH];
	new soundindex = GetRandomInt(1, 3);
	if (soundindex == 2) strcopy(sound, sizeof(sound), "vo/pyro_laughhappy01.wav");
	else Format(sound, sizeof(sound), "vo/pyro_paincrticialdeath0%d.wav", soundindex);
	EmitSoundToAll(sound, client);
}
stock DoEurekaTaunt(client)
{
	decl Float:vel[3];
	decl Float:pos[3];
	vel[0] = 0.0;
	vel[1] = 0.0;
	vel[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	new bool:megaheal = TF2_IsPlayerInCondition(client, TFCond_MegaHeal);
	TF2_RemoveCondition(client, TFCond_MegaHeal);
	TF2_StunPlayer(client, 2.1, 0.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT, 0);
	if (megaheal) TF2_AddCondition(client, TFCond_MegaHeal, 0.1);
//	EmitSoundToAll("weapons/drg_wrench_teleport.wav", client);
//	GetClientAbsOrigin(client, pos);
	EmitSoundToAll(")weapons/drg_wrench_teleport.wav", client, SNDCHAN_STATIC, 150, _, _, _, _, pos);
//-numClients 10 sample )weapons/drg_wrench_teleport.wav ent 0 channel 6 vol 1.00000 level 150 pitch 100 flags 0
//-numClients 9 sample )weapons/teleporter_send.wav ent 16 channel 6 vol 1.00000 level 74 pitch 100 flags 0
	CreateTimer(2.15, Timer_EurekaRespawn, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
public Action:Timer_EurekaRespawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;
	new Handle:message = StartMessageAll("PlayerTeleportHomeEffect");
	BfWriteByte(message, client);
	EndMessage();
	DoTeleportParticles(client);
/*	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		pos[2] += 10.0;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		// set particle stuff
		decl String:effect_name[35];
		strcopy(effect_name, sizeof(effect_name), "drg_wrenchmotron_teleport");
		DispatchKeyValue(particle, "effect_name", effect_name);
		new startpoint = CreateEntityByName("info_particle_system");
		if (IsValidEntity(startpoint))
		{
			pos[2] += 950.0;
			TeleportEntity(startpoint, pos, NULL_VECTOR, NULL_VECTOR);
			decl String:controlpoint[9];
			FormatEx(controlpoint, sizeof(controlpoint), "target%i", startpoint);
			DispatchKeyValue(startpoint, "targetname", controlpoint);
			DispatchKeyValue(particle, "cpoint1", controlpoint);
			//Three more control points exist: 0 128 0, -128 0 0, and 0 -128 0; 0 0 1024 is this one.
		}
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		new Handle:pack;
		CreateDataTimer(3.0, Timer_DeleteEurekaParticle, pack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(pack, EntIndexToEntRef(particle));
		WritePackCell(pack, EntIndexToEntRef(startpoint));
	}*/
	CreateTimer(0.2, Timer_EurekaRespawn2, userid, TIMER_FLAG_NO_MAPCHANGE);
	//TF2_RespawnPlayer(client);
	return Plugin_Continue;
}
public Action:Timer_EurekaRespawn2(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client)) return Plugin_Stop;
//	EmitSoundToAll("weapons/teleporter_send.wav", client);
	EmitSoundToAll(")weapons/teleporter_send.wav", client, SNDCHAN_STATIC, 74);
/*	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		decl Float:pos[3];
		GetClientAbsOrigin(client, pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		// set particle stuff
		decl String:effect_name[35];
		Format(effect_name, sizeof(effect_name), "teleported_%s", GetClientTeam(client) == (_:TFTeam_Blue) ? "blue" : "red");
		DispatchKeyValue(particle, "effect_name", effect_name);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		new Handle:pack;
		CreateDataTimer(4.0, Timer_DeleteEurekaParticle, pack);//, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(pack, EntIndexToEntRef(particle));
		WritePackCell(pack, INVALID_ENT_REFERENCE);
	}*/
	TF2_RespawnPlayer(client);
	return Plugin_Continue;
}
public Action:Timer_DeleteEurekaParticle(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new particle = EntRefToEntIndex(ReadPackCell(pack));
	new startpoint = EntRefToEntIndex(ReadPackCell(pack));
	if (particle > MaxClients && IsValidEntity(particle)) AcceptEntityInput(particle, "Kill");
	if (startpoint > MaxClients && IsValidEntity(startpoint)) AcceptEntityInput(startpoint, "Kill");
	return Plugin_Continue;
}
public Action:Timer_TargeCharging(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsPlayerAlive(client) || !TF2_IsPlayerInCondition(client, TFCond_Charging))
	{
		if (IsValidClient(client)) SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 0);
		return Plugin_Stop;
	}
	new Float:charge = GetEntPropFloat(client, Prop_Send, "m_flChargeMeter");
	if (charge <= 0)
	{
		SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 0);
		return Plugin_Stop;
	}
	if (GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 327) charge -= (0.1 / 2.0 * 100.0);
	else charge -= (0.1 / 1.5 * 100.0);
	if (charge <= 0) charge = 0.0;
	if (charge <= 33) SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 2);	//Full crit
	else if (charge <= 75) SetEntProp(client, Prop_Send, "m_iNextMeleeCrit", 1);	//Mini-crit
	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", charge);
	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 750.0);
	return Plugin_Continue;
}
public Action:Timer_TargeReset(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	DoResetChargeTimer(client, true);
}
stock DoResetChargeTimer(client, bool:end = false)
{
	ClearTimer(hChargeTimer[client]);
	if (end && TF2_GetPlayerClass(client) != TFClass_DemoMan) hChargeTimer[client] = CreateTimer(((GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 404) ? 6.0 : 12.0), Timer_TargeCharged, GetClientUserId(client));
}
public Action:Timer_TargeCharged(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	DoResetChargeTimer(client, false);
	if (IsValidClient(client))
	{
		EmitSoundToClient(client, "player/recharged.wav");
		SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 100.0);
	}
}
stock RandomPlayerOfClass(client, TFClassType:class)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (TF2_GetPlayerClass(i) != class) continue;
		return i;
	}
	return client;
}

//Returns true if timer handle was valid and was cleared, false otherwise
stock bool:ClearTimer(&Handle:timer, bool:autoClose = false)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer, autoClose);
		timer = INVALID_HANDLE;
		return true;
	}
	return false;
}

stock DoTeleportParticles(client)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	decl String:name[32];
	name = (GetClientTeam(client) == _:TFTeam_Blue ? "player_sparkles_blue" : "player_sparkles_red");
	if (TE_SetupTFParticle(name, pos, _, _, client, 3, 0, false))
		TE_SendToAll(0.0);
	name = (GetClientTeam(client) == _:TFTeam_Blue ? "teleported_blue" : "teleported_red");
	if (TE_SetupTFParticle(name, pos, _, _, client, 0, 0, false))
		TE_SendToAll(0.0);
}

stock bool:TE_SetupTFParticle(String:Name[],
			Float:origin[3] = NULL_VECTOR,
			Float:start[3] = NULL_VECTOR,
			Float:angles[3] = NULL_VECTOR,
			entindex = -1,
			attachtype = -1,
			attachpoint = -1,
			bool:resetParticles = true)
{
	// find string table
	new tblidx = FindStringTable("ParticleEffectNames");
	if (tblidx == INVALID_STRING_TABLE)
	{
		LogError("Could not find string table: ParticleEffectNames");
		return false;
	}
	// find particle index
	new String:tmp[256];
	new count = GetStringTableNumStrings(tblidx);
	new stridx = INVALID_STRING_INDEX;
	for (new i = 0; i < count; i++)
	{
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));
		if (StrEqual(tmp, Name, false))
		{
			stridx = i;
			break;
		}
	}
	if (stridx == INVALID_STRING_INDEX)
	{
		LogError("Could not find particle: %s", Name);
		return false;
	}

	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", start[0]);
	TE_WriteFloat("m_vecStart[1]", start[1]);
	TE_WriteFloat("m_vecStart[2]", start[2]);
	TE_WriteVector("m_vecAngles", angles);
	TE_WriteNum("m_iParticleSystemIndex", stridx);
	if (entindex != -1)
	{
		TE_WriteNum("entindex", entindex);
	}
	if (attachtype != -1)
	{
		TE_WriteNum("m_iAttachType", attachtype);
	}
	if (attachpoint != -1)
	{
		TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
	}
	TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
	return true;
}