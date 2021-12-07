#pragma semicolon 1
#include <sdktools>
#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_NAME			"[TF2] Explosive Arrows"
#define PLUGIN_AUTHOR		"Tak (Chaosxk), edit by RavensBro, took part of PowerLord Huntsman Hell plugin"
#define PLUGIN_DESCRIPTION	"Are your arrows too weak? Buff them up!."
#define PLUGIN_VERSION		"1.32"
#define PLUGIN_URL			"http://forums.alliedmods.net/showthread.php?t=203146"

#define spirite "spirites/zerogxplode.spr"

new String:g_Sounds_Explode[][] = {"weapons/explode1.wav", "weapons/explode2.wav", "weapons/explode3.wav" };

new Handle:g_Enabled = INVALID_HANDLE;
new Handle:g_Dmg = INVALID_HANDLE;
new Handle:g_Radius = INVALID_HANDLE;
new Handle:g_Join = INVALID_HANDLE;
//new Handle:g_Flag = INVALID_HANDLE;
new Handle:g_Type = INVALID_HANDLE;
//new Handle:g_Delay = INVALID_HANDLE;

//new Float:g_pos[3];
new Float:deathpos[MAXPLAYERS + 1][3];
new bool:g_Arrows[MAXPLAYERS+1];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf")) {
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public OnPluginStart() {
	CreateConVar("tf2_explarrows_version", PLUGIN_VERSION, "Version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	g_Enabled = CreateConVar("sm_explarrows_enabled", "1", "Enables/Disables explosive arrows.");
	g_Dmg = CreateConVar("sm_explarrows_damage", "50", "How much damage should the arrows do?");
	g_Radius = CreateConVar("sm_explarrows_radius", "200", "What should the radius of damage be?");
	g_Join = CreateConVar("sm_explarrows_join", "0", "Should explosive arrows be on when joined? Off = 0, Public = 1, Admins = 2");
//	g_Flag = CreateConVar("sm_explarrows_flag", "b", "What admin flag should be associated with sm_explarrowsme and sm_explarrows_join?");
	g_Type = CreateConVar("sm_explarrows_type", "0", "What type of arrows to explode? (0 - Both, 1 - Huntsman arrows, 2 - Crusader's crossbow bolts");
//	g_Delay = CreateConVar("sm_explarrows_delay", "0", "Delay before arrow explodes");

	RegConsoleCmd("sm_explarrowsme", Command_ArrowsMe, "Turn on explosive arrows for yourself.");
	RegAdminCmd("sm_explarrows", Command_Arrows, ADMFLAG_GENERIC, "Usage: sm_explarrows <client> <On: 1 ; Off = 0>.");

//	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_death", Player_Death);

	LoadTranslations("common.phrases");
	AutoExecConfig(true, "explosivearrows_fix");
}

public OnMapStart() {
	PrecacheModel(spirite, true);
	PrecacheSound("weapons/explode1.wav", true);
	PrecacheSound("weapons/explode2.wav", true);
	PrecacheSound("weapons/explode3.wav", true);	
}

public Action:Player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!g_Enabled)
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client))
		return;
	GetClientAbsOrigin(client, deathpos[client]);
}
public OnClientPostAdminCheck(client) {
	g_Arrows[client] = false;
	deathpos[client][0] = 0.0;
	deathpos[client][1] = 0.0;
	deathpos[client][2] = 0.0;
	new joincvar = GetConVarInt(g_Join);
	switch (joincvar) {
		case 2: {
			g_Arrows[client] = CheckCommandAccess(client, "sm_explarrows_join_access", ADMFLAG_GENERIC, true);
		}
		case 1: {
			g_Arrows[client] = true;
		}
	}
}
public Action:Command_ArrowsMe(client, args) {
	if(!g_Enabled)
		return Plugin_Handled;
	if(!IsValidClient(client))
		return Plugin_Handled;
	g_Arrows[client] = !g_Arrows[client];
	ReplyToCommand(client, "[SM] You have %s explosive arrows.", g_Arrows[client] ? "enabled" : "disabled");
	return Plugin_Handled;
}

public Action:Command_Arrows(client, args) {
	if(!g_Enabled || !IsValidClient(client)) return Plugin_Continue;
	
	decl String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new button = StringToInt(arg2);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(args < 2)
	{
		ReplyToCommand(client, "Usage: sm_arrows <client> <On: 1 ; Off = 0>");
		return Plugin_Handled;
	}
	
	if(args == 2)
	{
		for(new i = 0; i < target_count; i++)
		{
			if(IsValidClient(target_list[i]))			
			{
				new target = (target_list[i]);
				if(button == 1)
				{
					g_Arrows[target] = (target_list[i]) == 1;
					ShowActivity2(client, "[SM] ", "%N has given %s explosive arrows.", client, target_name);
				}
				if(button == 0)
				{
					g_Arrows[target] = (target_list[i]) == 0;
					ShowActivity2(client, "[SM] ", "%N has removed %s explosive arrows.", client, target_name);
				}
			}
		}
	}
	return Plugin_Handled;
}

public OnEntityCreated(entity, const String:classname[]) {
	if(!g_Enabled)
		return;
	new bool:arrow = StrEqual(classname, "tf_projectile_arrow");
	new bool:bolt = StrEqual(classname, "tf_projectile_healing_bolt");
	if (!bolt && !arrow)
		return;
	new type = GetConVarInt(g_Type);
	if (!type || (type == 1 && arrow) || (type == 2 && bolt)) {
		SDKHook(entity, SDKHook_StartTouch, Arrow_Explode);
	}
}

public Arrow_Explode(entity, other)
{
	new Float:origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	new team = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	new explosion = CreateEntityByName("env_explosion");
	
	if (!IsValidEntity(explosion))
	{
		return;
	}
	
	new String:teamString[2];
	new String:magnitudeString[6];
	new String:radiusString[5];
	IntToString(team, teamString, sizeof(teamString));
	
	GetConVarString(g_Dmg, magnitudeString, sizeof(magnitudeString));
	GetConVarString(g_Radius, radiusString, sizeof(radiusString));
	
	DispatchKeyValue(explosion, "iMagnitude", magnitudeString);
	DispatchKeyValue(explosion, "iRadiusOverride", radiusString);
	DispatchKeyValue(explosion, "TeamNum", teamString);
	
	SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", owner);
	
	TeleportEntity(explosion, origin, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(explosion);
	
	AcceptEntityInput(explosion, "Explode");
	// Destroy it after a tenth of a second so it still exists during OnTakeDamagePost
	CreateTimer(0.1, Timer_DestroyExplosion, EntIndexToEntRef(explosion), TIMER_FLAG_NO_MAPCHANGE);
	
	new random = GetRandomInt(0, sizeof(g_Sounds_Explode)-1);
	EmitSoundToAll(g_Sounds_Explode[random], entity, SNDCHAN_WEAPON, _, _, _, _, _, origin);
}
public Action:Timer_DestroyExplosion(Handle:timer, any:explosionRef)
{
	new explosion = EntRefToEntIndex(explosionRef);
	if (explosion != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(explosion, "Kill");
	}
	
	return Plugin_Continue;
}
stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients || (!IsClientInGame(iClient))) 
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}