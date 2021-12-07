#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.9.2"

/*
	Version 1.9.1a:
		Fixed invalid target causing errors
	
	Version 1.9.2:
		Improved for loop for target detection
		Added gamemode & map detection for determining what to give players
			- Default is single pistol, smg & health pack
			- Pills instead of packs in Bleedout
			- No packs in Healthpackalypse
			- Only katana & pack in Four Swordsmen of the Apocalypse
			- Only chainsaw & pack in Chainsaws
			- No smg on c1m1_hotel
			- Theres 3 remaining mutations left (unless valve adds more).. they are currently "default"
*/

public Plugin:myinfo =
{
	name			= "L4D SM Respawn",
	author			= "AtomicStryker, Ivailosp & Dirka_Dirka",
	description	= "Let's you respawn Players by console",
	version			= PLUGIN_VERSION,
	url				= "http://forums.alliedmods.net/showpost.php?p=1250945&postcount=166"
}

static Float:g_pos[3];
static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hBecomeGhost = INVALID_HANDLE;
static Handle:hState_Transition = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

public OnPluginStart()
{
	decl String:game_name[24];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{
		SetFailState("Plugin supports Left 4 Dead and L4D2 only.");
	}

	LoadTranslations("common.phrases");
	hGameConf = LoadGameConfigFile("l4drespawn");
	
	CreateConVar("l4d_sm_respawn_version", PLUGIN_VERSION, "L4D SM Respawn Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_BAN, "sm_respawn <player1> [player2] ... [playerN] - respawn all listed players and teleport them where you aim");

	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hBecomeGhost = EndPrepSDKCall();
		if (hBecomeGhost == INVALID_HANDLE) LogError("L4D_SM_Respawn: BecomeGhost Signature broken");

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		hState_Transition = EndPrepSDKCall();
		if (hState_Transition == INVALID_HANDLE) LogError("L4D_SM_Respawn: State_Transition Signature broken");
	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drespawn.txt , you FAILED AT INSTALLING");
	}
}

public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Respawn player(s). Usage: sm_respawn <player1> [player2] ... [playerN]");
		return Plugin_Handled;
	}
	
	decl player_id, String:player[64];
	
	for(new i=1; i<=args; i++)
	{
		GetCmdArg(i, player, sizeof(player));
		player_id = FindTarget(client, player);
		
		// OH MY GOD.. THIS WAS SOO HARD - Dirka_Dirka
		if (player_id == -1) {
			ReplyToCommand(client, "[SM] Invalid player name '%s'.", player);
			return Plugin_Continue;
		}
		
		switch(GetClientTeam(player_id))
		{
			case 2:
			{
				SDKCall(hRoundRespawn, player_id);
				GiveItems(player_id);
				
				if(!SetTeleportEndPoint(client) || client == player_id)
				{
					return Plugin_Handled;
				}
				PerformTeleport(client,player_id,g_pos);
			}
			
			case 3:
			{
				decl String:game_name[24];
				GetGameFolderName(game_name, sizeof(game_name));
				if (StrEqual(game_name, "left4dead", false)) return Plugin_Handled;
			
				SDKCall(hState_Transition, player_id, 8);
				SDKCall(hBecomeGhost, player_id, 1);
				SDKCall(hState_Transition, player_id, 6);
				SDKCall(hBecomeGhost, player_id, 1);
			}
		}
	}
	return Plugin_Handled;
}

stock GiveItems(client) {
	decl String:sMP_Gamemode[24];
	new Handle:hMP_Gamemode = FindConVar("mp_gamemode");
	if (hMP_Gamemode != INVALID_HANDLE)
		GetConVarString(hMP_Gamemode, sMP_Gamemode, sizeof(sMP_Gamemode));
	else
		ThrowError("Cannot find convar mp_gamemode");
	
	// first remove any the player has..
	new entity;
	for (new i=0; i<4; i++) {
		entity = GetPlayerWeaponSlot(client, i);
		if (IsValidEdict(entity)) {
			RemovePlayerItem(client, entity);
			RemoveEdict(entity);
		}
	}
	
	new bool:bAllowSMG, bool:bAllowPistol, bool:bAllowFAK;
	decl String:sMap[PLATFORM_MAX_PATH];
	GetCurrentMap(sMap, PLATFORM_MAX_PATH);
	
	// SMG is allowed on all maps except (remove smg in mutations that don't allow it below):
	if (!StrEqual(sMap, "c1m1_hotel", true))
		bAllowSMG = true;
	
	// Allow or disallow all weapons based upon mutation.. also give any special case weapons:
	if (StrEqual(sMP_Gamemode, "mutation3", true)) {
		CheatCommand(client, "give", "pain_pills");
		bAllowPistol = true;
	} else if (StrEqual(sMP_Gamemode, "mutation5", true)) {
		bAllowFAK = true;
		bAllowSMG = false;
		CheatCommand(client, "give", "katana");
	} else if (StrEqual(sMP_Gamemode, "mutation7", true)) {
		bAllowFAK = true;
		bAllowSMG = false;
		CheatCommand(client, "give", "chainsaw");
	} else if (StrEqual(sMP_Gamemode, "mutation11", true)) {
		bAllowPistol = true;
	} else {
		bAllowPistol = true;
		bAllowFAK = true;
	}
	
	// Default weapons.. give if allowed:
	if (bAllowPistol)
		CheatCommand(client, "give", "pistol");
	if (bAllowSMG)
		CheatCommand(client, "give", "smg");
	if (bAllowFAK)
		CheatCommand(client, "give", "first_aid_kit");
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients || !entity;
} 

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3], Float:vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		decl Float:vBuffer[3], Float:vStart[3];

		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		new Float:Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		PrintToChat(client, "[SM] %s", "Could not teleport player after respawn");
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);
	return true;
}

PerformTeleport(client, target, Float:pos[3])
{
	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
	pos[2]+=40.0;
	
	LogAction(client,target, "\"%L\" teleported \"%L\" after respawning him" , client, target);
}

stock CheatCommand(client, String:command[], String:arguments[]="")
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}