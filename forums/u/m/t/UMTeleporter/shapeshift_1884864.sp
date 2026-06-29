/*
 *			Made by Plex (aka Use My Teleporter)
 */

/* Update July 14th, 2016
 * Recompiled (I believe this fixed issues others were having)
 * Misc changes/fixes I cannot remember.
 */

/* Update September 4th 2014
 * Fixed a case where players would lose weapons (ShapeShifting inside a solid object such as a friendly sentry/dispenser.)
 * The plugin simply prevents ShapeShifting in solids.
 * Added a failure sound
 */

/* Update August 24th 2014
 * Fixed medic healing exploit
 * Fixed sm_shapeshift_version being saved to plugin.shapeshift.cfg
 * Fixed error log msg
 */

/* Update April 10th 2014
 * Added OnShapeShift which allows plugins to prevent shapeshifting initiated by users
 * as well as modify the target class
 */

/* Update Feb 20th 2014
 * Fixed ShapeShift not activating in enemy respawn areas
 */

/* Update Jan 16th 2014
 * Fixed shapeshift spawn exploit
 */

/* Update Jan 2nd 2014
 * Fixed bonk bug/exploit
 */

/* Update Jan 2nd 2014
 * Added force, cooldown natives, by request
 */

/* Update Dec 29th 2013:
 * Added sm_shapeshift_no_engie_metal
 */

/* Update Dec 23rd 2013:
 * Fixed the breaking of attachment points
 */

/* Update Oct 5th 2013:
 * Added class menu support for Arena game mode, via command !shape/!sm_shapeshift
 */
 
/* Update July 23rd 2013:
 * Fixed a respawn timer bypass exploit
 */
 
/* Update Feb 7th 2013:
 * Fixed a weapon regeneration bug. If the client had FL_NOTARGET applied,
 * regeneration would not occur.
 * sm_shapeshift_tag is now 0 by default.
 */

/* Update Feb 3nd 2013:
 * Fixed a health exploit oversight	(less health scout -> heavy = more health.
									Permitting health up scaling only if originally max health) 
 * By request, added the ability to force players to stay shapeshifted to a certain class.
 * Changed admin commands to use ShowActivity2
 */

/* Update Feb 1st 2013:
 * Added To/From class limitations
 * Added _force command
 * Addd force switch weaps to fix rare civi bug
 * Fixed handle leak
 * Added sm_shapeshift and 'shape' commands/binds for Arena mode
 */

#include <sdktools>
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <shapeshift_funcs>

#define PLUGIN_VERSION	"1.5.5"

#define MDL_ATTACHPOINT_FIX		"models/bots/headless_hatman.mdl"
#define FAILURE_SOUND			"ui/message_update.wav"

#define TELEFUNC_MSGTAG			"[ShapeShift] "
#define	TELEFUNC_GLOBAL_REPLY_CHAT

#define FADE_DELAY		0.5
#define SHAPESHIFT_SPAWN_DELAY			0.3

new Handle:cvar_Version;
new Handle:cvar_Enabled;
new Handle:cvar_Cooldown;
new Handle:cvar_AdminOnly;
new Handle:cvar_Tag;
new Handle:cvar_Sound;
new Handle:cvar_DisplayReady;
new Handle:cvar_Regen;
new Handle:cvar_NewClip;
new Handle:cvar_Effects;
new Handle:cvar_PunishMode;
new Handle:cvar_PunishTime;
new Handle:cvar_FromClass;
new Handle:cvar_ToClass;
new Handle:cvar_NoEngineerMetal;
new Handle:svTags;

new bool:g_bEnabled, Float:g_fCooldown, bool:g_bAdminOnly, bool:g_bTag;
new bool:g_bMapLoaded, String:g_sSound[PLATFORM_MAX_PATH];
new g_iDisplayReady, bool:g_bRegen, bool:g_bNewClip;
new bool:g_bEffects, g_iPunishMode, Float:g_fPunishTime;
new g_iFromClass, g_iToClass;

enum ShapeShiftData	{
	Float:lastUseTime,
	bool:inRespawn,
	bool:regenCheck,
	TFClassType:lockedClass,
	Float:fTempDisable
};

new SData[MAXPLAYERS+1][ShapeShiftData];

// Preserve only bad conditions
// Jarate, Bleeding, Mad Milk, Fire, Stun, Fan O War effect...
new TFCond:PreserveConditions[] = {
	TFCond_Jarated,
	TFCond_Bleeding,
	TFCond_Milked,
	TFCond_OnFire,
	// Removed, this is now for the Bonk drink apparently?
	// Don't want to preserve that
	//TFCond_Bonked,
	TFCond_Dazed,
	TFCond_MarkedForDeath
};

new TFCond:RemoveConditions[] = {
	//TFCond_Healing
	TFCond_Zoomed	// Prevents sniper shapeshift crash
};

new Float:ConditionTimes[] = {
	10.0,
	10.0,
	10.0,
	10.0,
	10.0,
	10.0
};

new TFCond:ClientConditions[MAXPLAYERS+1][sizeof(PreserveConditions)];

new FadeSteps[] = { 255, 128, 64, 48, 24, 0 };

new UserMsg:fadeMsg;

new Handle:g_hForwardShapeShift = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "ShapeShift",
	author = "Plex (aka Use My Teleporter)",
	description = "ShapeShift",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/groups/NewJetpack"
}

public chgEnabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = StringToInt(newValue) > 0;
	if (g_bEnabled) ApplyTag();
	else RemoveTag();
}
public chgCooldown(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_fCooldown = StringToFloat(newValue); }
public chgAdminOnly(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_bAdminOnly = StringToInt(newValue) > 0; }
public chgTag(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bTag = StringToInt(newValue) > 0;
	if (!g_bTag)
		RemoveTag();
}
public chgSound(Handle:convar, const String:oldValue[], const String:newValue[]) {
	strcopy(g_sSound, sizeof(g_sSound), newValue);
	if (g_bMapLoaded)
		PrecacheSound(g_sSound);
}
public chgDisplayReady(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_iDisplayReady = StringToInt(newValue); }
public chgRegen(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_bRegen = StringToInt(newValue) > 0; }
public chgNewClip(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_bNewClip = StringToInt(newValue) > 0; }
public chgEffects(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_bEffects = StringToInt(newValue) > 0; }
public chgPunishMode(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_iPunishMode = StringToInt(newValue); }
public chgPunishTime(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_fPunishTime = StringToFloat(newValue); }
public chgFromClass(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_iFromClass = ClassesToFlags(newValue); }
public chgToClass(Handle:convar, const String:oldValue[], const String:newValue[])
{ g_iToClass = ClassesToFlags(newValue); }

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
   CreateNative("ShapeShift_Cooldown", Native_Cooldown);
   CreateNative("ShapeShift_ResetCooldown", Native_ResetCooldown);
   CreateNative("ShapeShift_Force", Native_Force);
   return APLRes_Success;
}

public Native_Cooldown(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	if (SData[client][lastUseTime] != 0.0
			&& (SData[client][lastUseTime] + g_fCooldown) > GetGameTime())
		return _:((SData[client][lastUseTime] + g_fCooldown) - GetGameTime());
	return _:-1.0;
}

public Native_ResetCooldown(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	SData[client][lastUseTime] = GetGameTime();
	return 0;
}

public Native_Force(Handle:plugin, numParams) {
	new client = GetNativeCell(1);
	new TFClassType:tfclass = GetNativeCell(2);
	DoShapeShift(client, TF2_GetPlayerClass(client), tfclass);
	return 0;
}

public OnPluginStart() {
	ResetForAll();
	
	// OnShapeShift(client, from_class, target_class)
	g_hForwardShapeShift = CreateGlobalForward("OnShapeShift",
			ET_Event, Param_Cell, Param_Cell, Param_CellByRef);
	
	svTags = FindConVar("sv_tags");
	fadeMsg = GetUserMessageId("Fade");
	
	cvar_Version = CreateConVar("sm_shapeshift_version", PLUGIN_VERSION, "ShapeShift Version",
		FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookConVarChange(cvar_Enabled = CreateConVar("sm_shapeshift_enabled", "1",
		"Enable Shapeshift"), chgEnabled);
	HookConVarChange(cvar_Cooldown = CreateConVar("sm_shapeshift_cooldown", "30.0",
		"Shapeshift cooldown time", true), chgCooldown);
	HookConVarChange(cvar_AdminOnly = CreateConVar("sm_shapeshift_adminonly", "0",
		"Limit Shapeshift to admins"), chgAdminOnly);
	HookConVarChange(cvar_Tag = CreateConVar("sm_shapeshift_tag", "0",
		"Apply Shapeshift server tag"), chgTag);
	HookConVarChange(cvar_Sound = CreateConVar("sm_shapeshift_sound",
		"npc/ichthyosaur/water_growl5.wav", "Shapeshift Sound"), chgSound);
	HookConVarChange(cvar_DisplayReady = CreateConVar("sm_shapeshift_displayready",
		"1", "Display method when Shapeshift is ready", true), chgDisplayReady);
	HookConVarChange(cvar_Regen = CreateConVar("sm_shapeshift_allowregen",
		"0", "Allow same-class Shapeshifting (regeneration)"), chgRegen);
	HookConVarChange(cvar_NewClip = CreateConVar("sm_shapeshift_newclip",
		"0", "Permit new clip (you get ammo from nothing)"), chgNewClip);
	HookConVarChange(cvar_Effects = CreateConVar("sm_shapeshift_effects", "1",
		"Shapeshift graphical/sound effects"), chgEffects);
	HookConVarChange(cvar_PunishMode = CreateConVar("sm_shapeshift_punishmode", "0",
		"Shapeshift usage punishment mode", true), chgPunishMode);
	HookConVarChange(cvar_PunishTime = CreateConVar("sm_shapeshift_punishtime", "6.0",
		"Shapeshift punishment time", true), chgPunishTime);
	HookConVarChange(cvar_FromClass = CreateConVar("sm_shapeshift_disable_fromclass", "",
		"Disable Shapeshifting from certain classes"), chgFromClass);
	HookConVarChange(cvar_ToClass = CreateConVar("sm_shapeshift_disable_toclass", "",
		"Disable Shapeshifting to certain classes"), chgToClass);
	cvar_NoEngineerMetal = CreateConVar("sm_shapeshift_no_engie_metal", "0", "No metal refresh on engineer ShapeShift");
	g_bEnabled = GetConVarInt(cvar_Enabled) > 0;
	g_fCooldown = GetConVarFloat(cvar_Cooldown);
	g_bAdminOnly = GetConVarInt(cvar_AdminOnly) > 0;
	g_bTag = GetConVarInt(cvar_Tag) > 0;
	GetConVarString(cvar_Sound, g_sSound, sizeof(g_sSound));
	g_iDisplayReady = GetConVarInt(cvar_DisplayReady);
	g_bRegen = GetConVarInt(cvar_Regen) > 0;
	g_bNewClip = GetConVarInt(cvar_NewClip) > 0;
	g_bEffects = GetConVarInt(cvar_Effects) > 0;
	g_iPunishMode = GetConVarInt(cvar_PunishMode);
	g_fPunishTime = GetConVarFloat(cvar_PunishTime);
	decl String:temp[256];
	GetConVarString(cvar_FromClass, temp, sizeof(temp));
	g_iFromClass = ClassesToFlags(temp);
	GetConVarString(cvar_ToClass, temp, sizeof(temp));
	g_iToClass = ClassesToFlags(temp);
	
	AddCommandListener(JoinClassHook, "joinclass");
	AddCommandListener(JoinClassHook, "join_class");

	RegAdminCmd("sm_shapeshift_force", Command_Force, ADMFLAG_CHEATS, "Force ShapeShift on a client.");
	RegAdminCmd("sm_shapeshift_lock", Command_Lock, ADMFLAG_CHEATS, "Lock a client into staying a certain class");
	
	RegConsoleCmd("sm_shapeshift", Command_ShapeShift, "Useful for Arena mode");
	RegConsoleCmd("shape", Command_ShapeShift, "Useful for Arena mode");

	HookEvent("post_inventory_application", Event_PostInventoryApp);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawnPre, EventHookMode_Pre);

	HookRespawns();

	AutoExecConfig();
}

// Fixes version cfg bug
public OnConfigsExecuted() {
	SetConVarString(cvar_Version, PLUGIN_VERSION);
}

public Action:JoinClassHook(client, const String:command[], argc) {
	decl String:argString[64];
	GetCmdArgString(argString, sizeof(argString));

	if (SData[client][lockedClass] != TFClass_Unknown)
		return ReplyCmd(client, "You are locked into your current class.");

	if (!g_bEnabled || (g_bAdminOnly && !HasAccess(client)) || !IsPlayerAlive(client)
		|| (!IsArenaMode() && SData[client][inRespawn])) return Plugin_Continue;
	
	return HandleShapeShiftCommand(client, argString);
}

Action:HandleShapeShiftCommand(client, String:argString[]) {
	if (SData[client][fTempDisable] >= GetGameTime()) return Plugin_Continue;
	
	new team = GetClientTeam(client);
	if (team != 2 && team != 3) return Plugin_Continue;
	if (SData[client][lastUseTime] != 0.0
		&& (SData[client][lastUseTime] + g_fCooldown) > GetGameTime()) {
		new remaining = RoundFloat(
			(SData[client][lastUseTime] + g_fCooldown) - GetGameTime());
		if (remaining < 1) remaining = 1;
		EmitSoundToClient(client, FAILURE_SOUND);
		return ReplyCmd(client, "You can shapeshift again in %d seconds.", remaining);
	}
	
	decl Float:origin[3];
	GetClientAbsOrigin(client, origin);
	
	decl Float:mipos[3]; decl Float:mapos[3];
	CalculatePlayerHitbox(client, mipos, mapos);
	origin[2] += 0.5;
	TR_TraceHullFilter(origin, origin, mipos, mapos, MASK_SOLID, TSolid, client);
	if (TR_DidHit()) {
		EmitSoundToClient(client, FAILURE_SOUND);
		return ReplyCmd(client, "You cannot ShapeShift inside solid objects.");
	}
	origin[2] -= 0.5;

	new TFClassType:currentClass = TF2_GetPlayerClass(client);	
	new TFClassType:targetClass = StrContains(argString, "regen", false) > -1
		? currentClass
		: StringToClass(argString);
	
	if (g_iFromClass > 0) {		// Can player change FROM this class?
		if ((1 << (_:currentClass-1)) & g_iFromClass) {
			EmitSoundToClient(client, FAILURE_SOUND);
			return ReplyCmd(client, "Cannot change while this class.");
		}
	}

	if (g_iToClass > 0) {		// To the target class?
		if ((1 << (_:targetClass-1)) & g_iToClass) {
			EmitSoundToClient(client, FAILURE_SOUND);
			return ReplyCmd(client, "Cannot change to that class.");
		}
	}

	if (!g_bRegen && targetClass == currentClass) {
		EmitSoundToClient(client, FAILURE_SOUND);
		return ReplyCmd(client, "Regen disabled. Can't change to same class!");
	}

	if (targetClass == TFClass_Unknown) {
		ReplyCmd(client, "No class specified, choosing random.");
		targetClass = currentClass;
		while (targetClass == currentClass)
			targetClass = TFClassType:GetRandomInt(1, 9);
	}
	
	new modifiedTargetClass = _:targetClass;
	
	decl Action:forwardResult;
	Call_StartForward(g_hForwardShapeShift);
	Call_PushCell(client);
	Call_PushCell(_:currentClass);
	Call_PushCellRef(modifiedTargetClass);
	Call_Finish(forwardResult);

	if (forwardResult == Plugin_Changed)
		targetClass = TFClassType:modifiedTargetClass;
	else if (forwardResult == Plugin_Handled)
		return Plugin_Continue;
	else if (forwardResult == Plugin_Stop)
		return Plugin_Handled;

	DoShapeShift(client, currentClass, targetClass);

	return ReplyCmd(client, "-Shapeshift Activated-");
}

public Action:Command_Force(client, args) {
	decl String:target[MAX_NAME_LENGTH], String:className[32];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	decl TFClassType:targetClass;

	if (GetCmdArgs() < 2) {
		ReplyToCommand(client, "sm_shapeshift_force <target> <class>");
		return Plugin_Handled;
	}
		
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, className, sizeof(className));
	
	targetClass = StringToClass(className);
	if (targetClass == TFClass_Unknown) {
		ReplyToCommand(client, "Invalid class specified, choosing random.");
		targetClass = TFClassType:GetRandomInt(1, 9);
	}
	
	if ((target_count = ProcessTargetString(target, client, target_list,
			MAXPLAYERS, COMMAND_FILTER_ALIVE,
			target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++) {
		DoShapeShift(target_list[i], TF2_GetPlayerClass(target_list[i]), targetClass);
		ShowActivity2(client, TELEFUNC_MSGTAG, "ShapeShifting %N", target_list[i]);
	}

	ReplyToCommand(client, "Forced %d targets to ShapeShift", target_count);
	return Plugin_Handled;
}

public Action:Command_Lock(client, args) {
	decl String:target[MAX_NAME_LENGTH], String:className[32];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	decl TFClassType:targetClass;

	if (GetCmdArgs() < 2) {
		ReplyToCommand(client, "sm_shapeshift_lock <target> <class>");
		return Plugin_Handled;
	}
		
	GetCmdArg(1, target, sizeof(target));
	GetCmdArg(2, className, sizeof(className));
	
	targetClass = StringToClass(className);
	
	if ((target_count = ProcessTargetString(target, client, target_list,
			MAXPLAYERS, COMMAND_FILTER_ALIVE,
			target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++) {
		if (targetClass != TFClass_Unknown) {
			new TFClassType:currentClass = TF2_GetPlayerClass(target_list[i]);
			if (currentClass != targetClass)
				DoShapeShift(target_list[i],
					currentClass, targetClass, false);
			SData[target_list[i]][lockedClass] = targetClass;
			ShowActivity2(client, TELEFUNC_MSGTAG, "Class locking %N", target_list[i]);
		} else {
			SData[target_list[i]][lockedClass] = TFClass_Unknown;
			ShowActivity2(client, TELEFUNC_MSGTAG, "Class unlocking %N", target_list[i]);
		}
	}

	if (targetClass != TFClass_Unknown)
		ReplyToCommand(client, "Locked %d targets to that class.", target_count);
	else
		ReplyToCommand(client, "Unlocked class-changing for %d targets.", target_count);

	return Plugin_Handled;
}

public Action:Command_ShapeShift(client, args) {
	decl String:argString[64];
	GetCmdArgString(argString, sizeof(argString));

	if (SData[client][lockedClass] != TFClass_Unknown)
		return ReplyCmd(client, "You are locked into your current class.");

	if (!g_bEnabled)
		return ReplyCmd(client, "ShapeShift disabled");
	if (g_bAdminOnly && !HasAccess(client))
		return ReplyCmd(client, "Access denied");
	if (!IsPlayerAlive(client))
		return ReplyCmd(client, "You must be alive");
	
	// Arena support
	if (IsArenaMode()) {
		ShowVGUIPanel(client, GetClientTeam(client) == 2 ? "class_red" : "class_blue");
		return Plugin_Handled;
	}

	HandleShapeShiftCommand(client, argString);

	return Plugin_Handled;
}

// Fixes healing exploit
public Action:Timer_FixMedigun(Handle:timer, any:clientSerial) {
	new client = GetClientFromSerial(clientSerial);
	if (client < 1 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client))
		return;
	new weap = GetPlayerWeaponSlot(client, 1);
	if (weap > MaxClients && IsValidEntity(weap)) SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weap);
}

public Action:Timer_Fade(Handle:timer, any:dp) {
	ResetPack(dp);
	new client = ReadPackCell(dp);
	new index = ReadPackCell(dp);
	if (!IsClientInGame(client)) { CloseHandle(dp); return Plugin_Stop; }
	if (index < 1) { StopFade(client); CloseHandle(dp); return Plugin_Stop; }
	SetPackPosition(dp, 0);
	WritePackCell(dp, client);
	WritePackCell(dp, index-1);
	StopFade(client);
	DoFade(client, FadeSteps[index]);
	return Plugin_Continue;
}

public Action:Timer_DisplayReady(Handle:timer, any:client) {
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		switch (g_iDisplayReady) {
		case 2:
			ReplyCmd(client, "Shapeshift ready");
		case 3:
			PrintCenterText(client, "Shapeshift ready");
		default:
			PrintHintText(client, "Shapeshift ready");
		}
	}
}

TimedParticle(ent, String:name[], Float:pos[3], Float:time) {
	new particle = CreateEntityByName("info_particle_system");
	if (!IsValidEntity(particle)) return;
	DispatchKeyValue(particle, "effect_name", name);
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");

	if (ent > 0) {
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, particle, 0);
	}
	CreateTimer(time, Timer_ParticleEnd, particle);
}

public Action:Timer_ParticleEnd(Handle:timer, any:particle) {
	if (!IsValidEntity(particle)) return;
	new String:classn[32];
	GetEdictClassname(particle, classn, sizeof(classn));
	if (strcmp(classn, "info_particle_system") != 0) return;
	RemoveEdict(particle);
}

public Event_PostInventoryApp(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (SData[client][regenCheck])	CreateTimer(0.1, Timer_PostInventory, client);
	SData[client][regenCheck] = false;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	ResetForAll();
	HookRespawns();	
}

public Event_PlayerSpawnPre(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SData[client][fTempDisable] = GetGameTime() + SHAPESHIFT_SPAWN_DELAY;
}

// Removes a perma crit exploit. I might need to do some other cond checks as well
// I've changed how the player is 'shapeshifted,' so this might not be
// necessary anymore
public Action:Timer_PostInventory(Handle:timer, any:client) {
	if (!PlayerReallyAlive(client)) return;
	TF2_RemoveCondition(client, TFCond_CritHype);
}

public InRespawn(ent, client) {
	if (client > MaxClients) return;
	if (GetEntProp(ent, Prop_Data, "m_iTeamNum") == GetClientTeam(client))
		SData[client][inRespawn] = true;
}

public OutRespawn(ent, client) {
	if (client > MaxClients) return;
	SData[client][inRespawn] = false;
}

DoShapeShift(client, TFClassType:currentClass, TFClassType:targetClass, bool:readyTimer=true) {
	if (currentClass == TFClass_Engineer)
		KillBuildings(client);			// Else they'll keep em

	new oldAmmo1 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 4, 4);
	new oldAmmo2 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 8, 4);
	
	// Originally used timers to reapply Conditions, so stored globally
	// Might be necessary again, not sure

	for (new i = 0; i < sizeof(PreserveConditions); i++)
		ClientConditions[client][i] = TFCond:-1;
	new count = 0;
	for (new i = 0; i < sizeof(PreserveConditions); i++) {
		if (TF2_IsPlayerInCondition(client, PreserveConditions[i])) {
			ClientConditions[client][count++] = PreserveConditions[i];
		}
	}
	for (new i = 0; i < sizeof(RemoveConditions); i++)
		TF2_RemoveCondition(client, RemoveConditions[i]);

	new oldFlags = GetEntityFlags(client);
	SetEntityFlags(client, oldFlags & ~FL_NOTARGET);	// Remove notarget if it was there
														// for whatever reason, weapons won't be
														// regenerated if FL_NOTARGET is set.
	
	new oldHealth = GetClientHealth(client);
	TF2_RegeneratePlayer(client);	// Prevents rare crash & gets ammo maxs
	new oldMaxHealth = GetClientHealth(client);

	// now get the maxs, since the current ammo = max
	new oldMaxAmmo1 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 4, 4);
	new oldMaxAmmo2 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 8, 4);

	TF2_SetPlayerClass(client, targetClass, false, true);
	SData[client][regenCheck] = true;
	SetEntityHealth(client, 1);			// otherwise, if health > max health, you
										// keep current health with RegeneratePlayer
										// getting the new max health requires doing this
	TF2_RegeneratePlayer(client);
	SetEntityFlags(client, oldFlags);
	
	// Fix attachment points
	SetVariantString(MDL_ATTACHPOINT_FIX);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	//SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	
	new newMaxAmmo1 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 4, 4);
	new newMaxAmmo2 = GetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 8, 4);

	// If old ammo == oldmaxammo, then use newmaxammmo
	// Avoids rounding 

	new scaled1 = RoundFloat(oldMaxAmmo1 == oldAmmo1 ? float(newMaxAmmo1) :
		float(oldAmmo1) * (float(newMaxAmmo1) / float(oldMaxAmmo1)));

	new scaled2 = RoundFloat(oldMaxAmmo2 == oldAmmo2 ? float(newMaxAmmo2) :
		float(oldAmmo2) * (float(newMaxAmmo2) / float(oldMaxAmmo2)));

	new ws1 = GetPlayerWeaponSlot(client, 0);
	new ws2 = GetPlayerWeaponSlot(client, 1);
	new clipMain = -1, clip2nd = -1;
	if (ws1 > 0)
		clipMain = GetEntData(ws1, FindSendPropInfo("CTFWeaponBase", "m_iClip1"));
	if (ws2 > 0)
		clip2nd = GetEntData(ws2, FindSendPropInfo("CTFWeaponBase", "m_iClip1"));

	if (!g_bNewClip) {
		// Setting to 0 bugs certain weapons
		if (clipMain > -1)
			SetEntData(ws1, FindSendPropInfo("CTFWeaponBase", "m_iClip1"), 1);
		if (clip2nd > -1)
			SetEntData(ws2, FindSendPropInfo("CTFWeaponBase", "m_iClip1"), 1);
	}
	
	SetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 4,
		scaled1);
	SetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 8,
		scaled2);
	
	// Engies shouldn't get metal
	if (GetConVarBool(cvar_NoEngineerMetal) && targetClass == TFClass_Engineer)
		SetEntData(client, FindSendPropOffs("CTFPlayer", "m_iAmmo") + 12, 0, 4);
	
	new newMaxHealth = GetClientHealth(client);
	new Float:scaledHealth = oldHealth >= oldMaxHealth ? float(newMaxHealth) :
		float(oldHealth) * (float(newMaxHealth) / float(oldMaxHealth));
	new convertedHealth = RoundFloat(scaledHealth);

	// Prevent Scaling Up health == bad == free health
	// Only permit this if full health in the first place
	if (convertedHealth > oldHealth
		&& oldHealth < oldMaxHealth) convertedHealth = oldHealth;

	if (convertedHealth < 1) convertedHealth = 1;
	SetEntityHealth(client, convertedHealth);
	
	for (new i = 0; i < sizeof(PreserveConditions); i++) {
		if (ClientConditions[client][i] == TFCond:-1) break;
		if (ClientConditions[client][i] == TFCond_OnFire) {
			TF2_IgnitePlayer(client, client); continue;
		}
		TF2_AddCondition(client, ClientConditions[client][i], ConditionTimes[i]);
	}
	
	for (new i = 0; i < sizeof(RemoveConditions); i++)
		TF2_RemoveCondition(client, RemoveConditions[i]);
	
	SetEntPropEnt(client, Prop_Send, "m_bFeignDeathReady", 0);
	if (currentClass == targetClass) {
		SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 0.0);
		SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 0.0);
	}
	
	if (targetClass == TFClass_Medic) {
		CreateTimer(0.2, Timer_FixMedigun, GetClientSerial(client));
	}

	SData[client][lastUseTime] = GetGameTime();
	
	if (g_bEffects) {
		decl Float:origin[3];
		GetClientAbsOrigin(client, origin);
		
		EmitSoundToAll(g_sSound, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,
			0.9, SNDPITCH_NORMAL, -1, origin, NULL_VECTOR, true, 0.0);
	
		StopFade(client);
		DoFade(client, 255);

		decl Float:special[3];
		decl Float:top[3];
		GetClientEyePosition(client, special);
		special[2] += 11.0;
		top = special;
		top[2] -= 30.0;

		if (GetClientTeam(client) == 2) {
			TimedParticle(client, "teleporter_red_entrance_level1", origin, 4.0);
			TimedParticle(client, "player_sparkles_red", special, 3.0);
			TimedParticle(client, "player_dripsred", special, 3.5);
			TimedParticle(client, "player_dripsred", top, 3.5);
			TimedParticle(client, "critical_rocket_red", top, 3.0);
			TimedParticle(client, "player_recent_teleport_red", top, 3.5);
		}
		else {
			TimedParticle(client, "teleporter_blue_entrance_level1", origin, 4.0);
			TimedParticle(client, "player_sparkles_blue", special, 3.0);
			TimedParticle(client, "player_drips_blue", special, 3.5);
			TimedParticle(client, "player_drips_blue", top, 3.5);
			TimedParticle(client, "critical_rocket_blue", top, 3.0);
			TimedParticle(client, "player_recent_teleport_blue", top, 3.5);
		}

		new Handle:dp = CreateDataPack();
		WritePackCell(dp, client);
		WritePackCell(dp, sizeof(FadeSteps)-1);
		CreateTimer(FADE_DELAY, Timer_Fade, dp, TIMER_REPEAT);
	}

	new slot;
	if ((slot = GetPlayerWeaponSlot(client, 0)) > -1)
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", slot);
	
	DoPunish(client);

	if (readyTimer && g_iDisplayReady > 0)
		CreateTimer(g_fCooldown, Timer_DisplayReady, client);
}

DoPunish(client) {
	switch (g_iPunishMode) {
		case 0: { }
		case 1: {
			TF2_StunPlayer(client, g_fPunishTime, 0.0,
				TF_STUNFLAG_BONKSTUCK | TF_STUNFLAG_NOSOUNDOREFFECT, 0);
		} case 2: {
			TF2_StunPlayer(client, g_fPunishTime, 0.5,
				TF_STUNFLAG_LIMITMOVEMENT | TF_STUNFLAG_SLOWDOWN, 0);
		} case 3: {
			TF2_StunPlayer(client, g_fPunishTime, 0.0,
				TF_STUNFLAGS_BIGBONK, 0);
		} case 4: {
			TF2_StunPlayer(client, g_fPunishTime, 0.0,
				TF_STUNFLAG_THIRDPERSON | TF_STUNFLAG_NOSOUNDOREFFECT, 0);
		} default: {
			TF2_StunPlayer(client, g_fPunishTime, 0.0,
				TF_STUNFLAGS_LOSERSTATE, 0);
		}
	}
}

DoFade(client, amount) {
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(fadeMsg, clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 255);
	BfWriteShort(message, (0x0002));
	BfWriteByte(message, 255);
	BfWriteByte(message, 255);
	BfWriteByte(message, 255);
	BfWriteByte(message, amount);
	
	EndMessage();
}

StopFade(client) {
	new clients[2];
	clients[0] = client;	
	
	new Handle:message = StartMessageEx(fadeMsg, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();	
}

KillBuildings(client) {
	new maxentities = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxentities; i++) {
		if (!IsValidEntity(i)) continue;
		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		
		if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectDispenser") == 0 || strcmp(netclass, "CObjectTeleporter") == 0) {
			if (GetEntDataEnt2(i, FindSendPropOffs("CObjectSentrygun","m_hBuilder")) == client)
			{
				SetVariantInt(9999);
				AcceptEntityInput(i, "RemoveHealth");
			}
		}
    }
}

ClassesToFlags(const String:sclass[]) {
	if (strlen(sclass) < 1) return 0;
	new tFlags = 0;
	new String:strBreak[9][50];
	new count = ExplodeString(sclass, ",", strBreak,
		sizeof(strBreak), sizeof(strBreak[]));
	for (new i = 0; i < count; i++) {
		new TFClassType:tClass = StringToClass(strBreak[i]);
		if (tClass == TFClass_Unknown) continue;
		tFlags |= (1 << (_:tClass - 1));
	}
	return tFlags;
}

HookRespawns() {
	new index = -1;
	while ((index = FindEntityByClassname(index, "func_respawnroom")) != -1) {
		SDKHook(index, SDKHook_Touch, InRespawn);
		SDKHook(index, SDKHook_EndTouch, OutRespawn);
	}
}

bool:HasAccess(player) {
	return CheckCommandAccess(player, "sm_shapeshift_access", ADMFLAG_CHEATS);
}

bool:PlayerReallyAlive(i) {
	if (!IsClientInGame(i) || !IsPlayerAlive(i)) return false;
	return true;
}

public OnMapStart() {
	g_bMapLoaded = true;
	ResetForAll();
	PrecacheSound(g_sSound);
	PrecacheSound(FAILURE_SOUND);
	ApplyTag();
	HookRespawns();
	
	AutoExecConfig();
}

public OnMapEnd() {
	g_bMapLoaded = false;
}

ApplyTag() {
	if (!g_bEnabled || !g_bTag) return;
	decl String:alteredTags[256];
	decl String:currentTags[256];
	GetConVarString(svTags, currentTags, sizeof(currentTags));
	if (StrContains(currentTags, "shapeshift", false) == -1) {
		Format(alteredTags, sizeof(alteredTags), "%s,shapeshift", currentTags);
		SetConVarString(svTags, alteredTags);
	}
}

RemoveTag() {
	decl String:currentTags[256];
	GetConVarString(svTags, currentTags, sizeof(currentTags));
	if (StrContains(currentTags, "shapeshift", false) > -1) {
		ReplaceString(currentTags, sizeof(currentTags), "shapeshift", "", false);
		SetConVarString(svTags, currentTags);
	}
}

public OnClientConnected(client) {
	ResetForClient(client);
	SData[client][lockedClass] = TFClass_Unknown;
}

ResetForAll() {
	for (new i = 0; i <= MAXPLAYERS; i++)
		ResetForClient(i);
}

ResetForClient(client) {
	SData[client][lastUseTime] = 0.0;
	SData[client][inRespawn] = false;
	SData[client][regenCheck] = true;
	SData[client][fTempDisable] = 0.0;
}

bool:IsArenaMode() {
	return FindEntityByClassname(-1, "tf_logic_arena") > -1;
}

Action:ReplyCmd(client, String:tmsg[], any:...) {
	decl String:msg[250];
	VFormat(msg, sizeof(msg), tmsg, 3);
	decl String:msgtag[32];
	#if defined TELEFUNC_MSGTAG
	Format(msgtag, sizeof(msgtag), "%s", TELEFUNC_MSGTAG);
	#else
	msgtag = "SM"
	#endif

	#if defined TELEFUNC_GLOBAL_REPLY_CHAT
		if (client > 0)
			PrintToChat(client, "%s%s", msgtag, msg);
		else
			ReplyToCommand(client, "%s%s", msgtag, msg);
	#else
		ReplyToCommand(client, "%s%s", msgtag, msg);
	#endif
	return Plugin_Handled;
}

public bool:TSolid(ent, mask, any:client) {
	return ent != client && (ent < 1 || ent > MaxClients);
}

// FROM: ResizePlayers.sp, modified
CalculatePlayerHitbox(client, Float:outMin[3], Float:outMax[3]) {
	new Float:flMult = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	//new Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	// Slightly modified so tracehull doesn't hit walls
	new Float:vecTF2PlayerMin[3] = { -24.0, -24.0, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.0,  24.0, 82.5 };
	ScaleVector(vecTF2PlayerMin, flMult);
	ScaleVector(vecTF2PlayerMax, flMult);
	outMin = vecTF2PlayerMin;
	outMax = vecTF2PlayerMax;
}