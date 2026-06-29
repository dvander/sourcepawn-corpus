// Add respawn timer info to show how long til respawn!

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <clientprefs>
//#include <sdkhooks>

#define PLUGIN_VERSION	"1.1.2"

public Plugin:myinfo =
{
	name = "[TF2] Ghost Mode",
	author = "FlaminSarge",
	description = "Don't wait around to respawn!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

#define POWER_FLY	(1 << 0)
#define POWER_TELE	(1 << 1)

#define OVERLAY_DEFAULT			0
#define OVERLAY_INVULNERABLE	0
#define OVERLAY_BLACKWHITE		1
#define OVERLAY_BINOCULARS		2
#define OVERLAY_TELEPORT		3
#define OVERLAY_DRUGGED			4
#define OVERLAY_OBSERVATION		5
#define OVERLAY_BLOOD			6

new bDead[MAXPLAYERS + 1];
new Float:saveVec[MAXPLAYERS + 1][3];
new Float:saveAng[MAXPLAYERS + 1][3];
new Float:saveVel[MAXPLAYERS + 1][3];
new Handle:hCvarEnableMode;
new Handle:hCvarAllowToggle;
new Handle:hCvarAlpha;
new Handle:hCvarThirdperson;
new Handle:hCvarGhostTaunt;
new Handle:hCvarGhostPowers;
new Handle:hCvarOverlay;
new Handle:hCookieGhost;
new bool:bShown[MAXPLAYERS + 1];
//new Handle:hSpaceBarTimer[MAXPLAYERS + 1];

public OnPluginStart()
{
	CreateConVar("ghostmode_version", PLUGIN_VERSION, "[TF2] Ghost Mode version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	HookEvent("teamplay_round_win", End);
	HookEvent("teamplay_round_active", Active);
	HookEvent("arena_round_start", Active);
	HookEvent("player_death", Death);
	HookEvent("player_spawn", Spawn);
	HookEvent("player_changeclass", Spawn2);
	hCvarEnableMode		=	CreateConVar("ghostmode_enablemode",	"1",	"0-disabled; 1-enabled; 2-arena only", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	hCvarAllowToggle	=	CreateConVar("ghostmode_allowtoggle",	"1",	"0-don't allow toggling; 1-allow toggling; 2-allow toggling, but not in arena", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	hCvarAlpha			=	CreateConVar("ghostmode_alpha",			"70",	"Alpha value to set ghosts at", FCVAR_PLUGIN, true, 0.0, true, 255.0);
	hCvarThirdperson	=	CreateConVar("ghostmode_thirdperson",	"0",	"Ghosts are in thirdperson or not", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvarGhostTaunt		=	CreateConVar("ghostmode_taunt",			"1",	"0-Ghosts cannot taunt (for high fives, etc); 1-Ghosts can taunt", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvarGhostPowers	=	CreateConVar("ghostmode_powers",		"3",	"1-Fly (hold altfire); 2-Teleport to team (primary fire); 3-both; 0-None", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	hCvarOverlay		=	CreateConVar("ghostmode_overlay",		"0",	"Which overlay to use to signify death?", FCVAR_PLUGIN, true, 0.0, true, 6.0);
	hCookieGhost		=	RegClientCookie("ghostmode", "Ghost mode status", CookieAccess_Protected);
	RegAdminCmd("sm_ghosttoggle", Cmd_ToggleGhost, 0);
	RegAdminCmd("sm_ghostmode", Cmd_ToggleGhost, 0);
	RegAdminCmd("sm_ghostm", Cmd_ToggleGhost, 0);
	RegAdminCmd("tf_redie", Cmd_ToggleGhost, 0);
	AddCommandListener(Taunt, "+use_action_slot_item_server");
	AddCommandListener(Taunt, "use_action_slot_item_server");
	AddCommandListener(Taunt, "+taunt");
	AddCommandListener(Taunt, "taunt");
	LoadTranslations("common.phrases");
//	for (new client = 1; client <= MaxClients; client++)
//	{
//		if (IsClientInGame(client)) SDKHook(client, SDKHook_Touch, OnTouch);
//	}
}

public Action:Taunt(client, const String:command[], args)
{
	if (bDead[client] == 2 && !GetConVarBool(hCvarGhostTaunt)) return Plugin_Handled;
	return Plugin_Continue;
}

public OnMapStart()
{
	IsArena(true);
	for (new i = 0; i <= MaxClients; i++)
	{
		bShown[i] = false;
	}
}

stock bool:CheckForEnable()
{
	new cvenabled = GetConVarInt(hCvarEnableMode);
	if (cvenabled == 1) return true;
	if (cvenabled == 2 && IsArena()) return true;
	return false;
}

stock GetClientCookie_Safe(client, Handle:cookie, String:buffer[], maxlen)
{
	if (!AreClientCookiesCached(client))
	{
		GetConVarString(hCvarEnableMode, buffer, maxlen);
		return;
	}
	GetClientCookie(client, cookie, buffer, maxlen);
}

public Action:Cmd_ToggleGhost(client, args)
{
	if (client <= 0)
	{
		ReplyToCommand(client, "[SM] Command is in-game only.");
		return Plugin_Handled;
	}
	if (!CheckCommandAccess(client, "ghostmode", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}
	new togg = GetConVarInt(hCvarAllowToggle);
	if (togg == 0 || (togg == 2 && IsArena()))
	{
		ReplyToCommand(client, "[SM] You cannot toggle GhostMode, as toggling is disabled.");
		return Plugin_Handled;
	}
	decl String:cookie[32];
	if (!AreClientCookiesCached(client))
	{
		ReplyToCommand(client, "[SM] Unable to change your GhostMode preference right now, sorry.");
		return Plugin_Handled;
	}
	if (args > 0)
	{
		GetCmdArg(1, cookie, sizeof(cookie));
	}
	new bool:toggle = bool:StringToInt(cookie);
	if (args < 1)
	{
		GetClientCookie(client, hCookieGhost, cookie, sizeof(cookie));
		toggle = !StringToInt(cookie);
	}
	if (toggle) SetClientCookie(client, hCookieGhost, "1");
	else SetClientCookie(client, hCookieGhost, "0");
	ReplyToCommand(client, "[SM] You %s GhostMode.", toggle ? "enabled" : "disabled");
	return Plugin_Handled;
}

public OnGameFrame()
{
	decl String:classname[64];
	decl Float:pos[3];
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (IsPlayerAlive(client)) continue;
		if (bDead[client] != 2) continue;
		new ent = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
		if (IsValidEntity(ent) && GetEntityClassname(ent, classname, sizeof(classname)) && StrEqual(classname, "obj_teleporter", false) && TF2_GetObjectMode(ent) == TFObjectMode_Entrance)
		{
			new iExit = FindTeleporterExit(ent);
			if (!IsValidEntity(iExit)) continue;
			GetEntPropVector(iExit, Prop_Send, "m_vecOrigin", pos);
			pos[2] += 12.05;
			TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

/*public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	decl Float:pos[3];
	decl String:classname[64];
	if (!IsClientInGame(client)) return Plugin_Continue;
	if (IsPlayerAlive(client)) return Plugin_Continue;
	if (!bDead[client]) return Plugin_Continue;
	new ent = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	if (IsValidEntity(ent) && GetEntityClassname(ent, classname, sizeof(classname)) && StrEqual(classname, "obj_teleporter", false) && TF2_GetObjectMode(ent) == TFObjectMode_Entrance)
	{
		new iExit = FindTeleporterExit(ent);
		if (!IsValidEntity(iExit)) return Plugin_Continue;
		GetEntPropVector(iExit, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 12.05;
		TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Continue;
}*/

stock FindTeleporterExit(entity = -1)
{
	new i = -1;
	while ((i = FindEntityByClassname(i, "obj_teleporter")) != -1)
	{
		if (TF2_GetObjectMode(i) == TFObjectMode_Exit && (entity == -1 || GetEntPropEnt(i, Prop_Send, "m_hBuilder") == GetEntPropEnt(entity, Prop_Send, "m_hBuilder"))) return i;
	}
	return -1;
}

stock bool:IsArena(bool:reset = false)
{
	static bool:arena;
	static bool:found;
	if (reset)
	{
		arena = false;
		found = false;
	}
	if (!found)
	{
		if (FindEntityByClassname(-1, "tf_logic_arena") != -1) arena = true;
		else arena = false;
		found = true;
	}
	return arena;
}

/*public TF2_OnConditionAdded(client, TFCond:cond)
{
	if (!bDead[client]) return;
	if (cond != TFCond_Teleporting) return;
	TF2_RemoveCondition(client, TFCond_Teleporting);
	decl Float:pos[3];
	new iExit = FindTeleporterExit();
	if (!IsValidEntity(iExit)) return;
	GetEntPropVector(iExit, Prop_Send, "m_vecOrigin", pos);
	pos[2] += 12.05;
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}*/

stock bool:ShouldClientBecomeGhost(client)
{
	new togg = GetConVarInt(hCvarAllowToggle);
	if (togg == 0 || (togg == 2 && IsArena())) return CheckForEnable();
	decl String:cookie[32];
	GetClientCookie_Safe(client, hCookieGhost, cookie, sizeof(cookie));
	if (cookie[0] == '\0') return CheckForEnable();
	return bool:StringToInt(cookie);
}

public Death(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
//	if (!CheckForEnable()) return;
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new deathflags = GetEventInt(hEvent, "death_flags");
	if (!IsValidClient(client) || IsFakeClient(client)) return;
	if ((GameRules_GetRoundState() != RoundState_RoundRunning && GameRules_GetRoundState() != RoundState_Stalemate)) return;
	if (!CheckCommandAccess(client, "ghostmode", 0, true)) return;
	if (!ShouldClientBecomeGhost(client)) return;
	if (deathflags & TF_DEATHFLAG_DEADRINGER)
	{
		SpawnFakeGhost(client);
		return;
	}
	bDead[client] = 1;
	GetClientAbsOrigin(client, saveVec[client]);
	GetClientAbsAngles(client, saveAng[client]);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", saveVel[client]);
	CreateTimer(0.1, Timer_Respawn, GetClientUserId(client));
}

stock SpawnFakeGhost(client)
{
	new ent = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(ent))
	{
		new Float:pos[3], Float:angles[3];
		decl String:model[PLATFORM_MAX_PATH], String:skin[2];
		GetClientModel(client, model, sizeof(model));
		GetClientAbsOrigin(client, pos);
		GetClientAbsAngles(client, angles);
		angles[0] = 0.0;
		angles[2] = 0.0;
		TeleportEntity(ent, pos, angles, NULL_VECTOR);
		IntToString(GetEntProp(client, Prop_Send, "m_nSkin"), skin, sizeof(skin));
		DispatchKeyValue(ent, "skin", skin);
		DispatchKeyValue(ent, "model", model);
		DispatchKeyValueVector(ent, "angles", angles);
		DispatchSpawn(ent);
		SetEntProp(ent, Prop_Send, "m_nSequence", GetEntProp(client, Prop_Send, "m_nSequence"));
		SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
		SetEntProp(ent, Prop_Send, "m_nSolidType", 0);
		SetEntityRenderMode(ent, RENDER_TRANSALPHA);
		SetEntityRenderColor(ent, _, _, _, GetConVarInt(hCvarAlpha));
		CreateTimer(8.0, Timer_KillDRFake, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_KillDRFake(Handle:timer, any:ref)
{
	new ent = EntRefToEntIndex(ref);
	if (IsValidEntity(ent)) AcceptEntityInput(ent, "Kill");
}

public Action:Timer_Respawn(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	if (GameRules_GetRoundState() != RoundState_RoundRunning && GameRules_GetRoundState() != RoundState_Stalemate)
	{
		bDead[client] = 0;
		return;
	}
	TF2_RespawnPlayer(client);
}

public Spawn2(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(client)) return;
	if (IsPlayerAlive(client)) bDead[client] = 0;
}

public Action:Spawn(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
//	if (!CheckForEnable()) return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(client)) return Plugin_Continue;
	if (!CheckCommandAccess(client, "ghostmode", 0, true)) return Plugin_Continue;
	if ((GameRules_GetRoundState() != RoundState_RoundRunning && GameRules_GetRoundState() != RoundState_Stalemate) || !IsPlayerAlive(client) || GetClientTeam(client) <= _:TFTeam_Spectator || bDead[client] != 1 || GetEntityRenderMode(client) == RENDER_TRANSALPHA)
	{
		SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
		SetEntProp(client, Prop_Send, "m_nSolidType", 2);
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, _, _, _, _);
		bDead[client] = 0;
		DoOverlay(client, "");
		return Plugin_Continue;
	}
	TeleportEntity(client, saveVec[client], saveAng[client], saveVel[client]);
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 1);
	SetEntProp(client, Prop_Send, "m_nSolidType", 0);
//	SetEntProp(client, Prop_Send, "m_nSolidType", SOLID_NONE);
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
	SetEntityRenderColor(client, _, _, _, GetConVarInt(hCvarAlpha));
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
	SetEntPropEnt(client, Prop_Send, "m_hLastWeapon", -1);
	bDead[client] = 2;
	if (!bShown[client])
	{
		PrintToChat(client, "[SM] You are now a ghost! sm_ghosttoggle to disable/enable.");
		bShown[client] = true;
	}
	switch (GetConVarInt(hCvarOverlay))
	{
		case OVERLAY_INVULNERABLE:
		{
			DoOverlay(client, GetClientTeam(client) == _:TFTeam_Blue ? "effects/invuln_overlay_blue" : "effects/invuln_overlay_red");
		}
		case OVERLAY_BLACKWHITE:
		{
			DoOverlay(client, "debug/yuv");
		}
		case OVERLAY_BINOCULARS:
		{
			DoOverlay(client, "combine_binocoverlay");
		}
		case OVERLAY_TELEPORT: // Red/Blue Teleport Shimmer (also theres tp_eyefx/tpeye which is green)
		{
			DoOverlay(client, GetClientTeam(client) == _:TFTeam_Blue ? "tp_eyefx/tpeye3" : "tp_eyefx/tpeye2");
		}
		case OVERLAY_DRUGGED: // Drugged distortion
		{
			DoOverlay(client, "tp_eyefx/tp_eyefx");
		}
		case OVERLAY_OBSERVATION: // As if looking through a glass Observation window from Portal
		{
			DoOverlay(client, "glass/glasswindow_refract01");
		}
		case OVERLAY_BLOOD: // Red/Blue Blood (also theres effects/mh_blood1)
		{
			DoOverlay(client, GetClientTeam(client) == _:TFTeam_Blue ? "effects/mh_blood3" : "effects/mh_blood2");
		}
		default:
		{
			DoOverlay(client, GetClientTeam(client) == _:TFTeam_Blue ? "effects/invuln_overlay_blue" : "effects/invuln_overlay_red");
		}
	}
	if (GetConVarBool(hCvarThirdperson))
	{
		CreateTimer(0.0, Timer_Thirdperson, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Handled;
}

public Action:Timer_Thirdperson(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	if (IsPlayerAlive(client)) return;
	if (!GetConVarBool(hCvarThirdperson)) return;
	SetVariantInt(2);
	AcceptEntityInput(client, "SetForcedTauntCam");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	static lastbuttons[MAXPLAYERS + 1];
	if (!IsValidClient(client)) return Plugin_Continue;
	new lb = lastbuttons[client];
	lastbuttons[client] = buttons;
	if (IsPlayerAlive(client)) return Plugin_Continue;
	if (bDead[client] != 2) return Plugin_Continue;
	new MoveType:mt = GetEntityMoveType(client);
	new powers = GetConVarInt(hCvarGhostPowers);
	if (mt == MOVETYPE_FLY)
	{
		new bt = (buttons & (IN_JUMP|IN_DUCK));
		new Float:max = GetEntPropFloat(client, Prop_Data, "m_flMaxspeed");
		new Float:curr = GetEntPropFloat(client, Prop_Send, "m_flFallVelocity") * -1;
		if (max > 320) max = 320.0;
		if (bt == IN_JUMP)
		{
			if (curr <= max * -1 + 20) vel[2] = max / 2;
			else vel[2] = max;
		}
		if (bt == IN_DUCK)
		{
			if (curr >= max - 20) vel[2] = max / -2;
			else vel[2] = max * -1;
		}
	}
	if ((buttons & IN_ATTACK2) && (powers & POWER_FLY))
	{
		if (mt != MOVETYPE_FLY)
		{
			SetEntityMoveType(client, MOVETYPE_FLY);
		}
	}
	else if (mt != MOVETYPE_WALK)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	if ((buttons & IN_ATTACK) && !(lb & IN_ATTACK) && (powers & POWER_TELE))
	{
		//TeleportToRandomPlayer(client);
		TeleportToNextPlayer(client);
	}
	return Plugin_Changed;
}

stock TeleportToNextPlayer(client)
{
	static prev[MAXPLAYERS + 1];
	if (!IsValidClient(client)) { prev[client] = 0; return; }
	new team = GetClientTeam(client);
	decl String:classname[64];
	new count = 0;
	new target = prev[client];
	for (new i = prev[client]+1; count <= MaxClients; i++, count++)
	{
		if (i > MaxClients) i = 0;
		if (i == 0) continue;
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) != team) continue;
		if (GetEntProp(i, Prop_Send, "m_bDucked") || GetEntProp(i, Prop_Send, "m_bDucking")) continue;
		new ent = GetEntPropEnt(i, Prop_Send, "m_hGroundEntity");
		if (IsValidEntity(ent) && GetEntityClassname(ent, classname, sizeof(classname)) && StrEqual(classname, "obj_teleporter", false) && TF2_GetObjectMode(ent) == TFObjectMode_Entrance) continue;
		target = i;
		break;
	}
	if (!IsValidClient(target))
	{
		prev[client] = 0;
		return;
	}
	decl Float:pos[3], Float:ang[3];
	GetClientAbsOrigin(target, pos);
	GetClientAbsAngles(target, ang);
	TeleportEntity(client, pos, ang, NULL_VECTOR);
	prev[client] = target;
}

stock TeleportToRandomPlayer(client)
{
	new count = 0;
	new players[MAXPLAYERS];
	new team = GetClientTeam(client);
	decl String:classname[64];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (GetClientTeam(i) != team) continue;
		if (GetEntProp(i, Prop_Send, "m_bDucked") || GetEntProp(i, Prop_Send, "m_bDucking")) continue;
		new ent = GetEntPropEnt(i, Prop_Send, "m_hGroundEntity");
		if (IsValidEntity(ent) && GetEntityClassname(ent, classname, sizeof(classname)) && StrEqual(classname, "obj_teleporter", false) && TF2_GetObjectMode(ent) == TFObjectMode_Entrance) continue;
		players[count] = i;
		count++;
	}
	if (count <= 0) return;
	new target = players[GetRandomInt(0, count - 1)];
	if (!IsValidClient(target)) return;
	decl Float:pos[3], Float:ang[3];
	GetClientAbsOrigin(target, pos);
	GetClientAbsAngles(target, ang);
	TeleportEntity(client, pos, ang, NULL_VECTOR);
}

public End(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
//	if (!CheckForEnable()) return;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client)) continue;
		if (!IsPlayerAlive(client)) continue;
		if (GetClientTeam(client) <= _:TFTeam_Spectator) continue;
		if (bDead[client] == 2) SetEntityMoveType(client, MOVETYPE_WALK);
		bDead[client] = 0;
	}
}

public Active(Handle:hEvent, String:strName[], bool:bDontBroadcast)
{
//	if (!CheckForEnable()) return;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client)) continue;
		if (!IsPlayerAlive(client)) continue;
		if (GetClientTeam(client) <= _:TFTeam_Spectator) continue;
		bDead[client] = 0;
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock DoOverlay(client, String:material[] = "")
{
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		new iFlags = GetCommandFlags("r_screenoverlay");
		SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);
		if (!StrEqual(material, "")) ClientCommand(client, "r_screenoverlay \"%s\"", material);
		else ClientCommand(client, "r_screenoverlay \"\"");
		SetCommandFlags("r_screenoverlay", iFlags);
	}
}
