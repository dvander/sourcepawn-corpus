/*
	STUFF THAT MAKES THIS WORK
*/
#pragma semicolon 1 
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <zps>

/*
	DEFINES
*/
#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "[ZPS] Pills Cure (Redux)"

// Cvars
new Handle:cvar_infectiontime = INVALID_HANDLE;
new Handle:cvar_curetype = INVALID_HANDLE;

// Check if player already got his notification
new bool:ClientGotInfo[MAXPLAYERS+1];


/*
	Plugin:myinfo = {}
*/
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "JonnyBoy0719",
	description = "Cures the infection, or simply delays it.",
	version = PLUGIN_VERSION,
	url = "http://reperio-studios.net/"
};

/*
	OnPluginStart()
*/
public OnPluginStart()
{
	// What game is this
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if (!StrEqual(game_name, "zps", false))
	{
		SetFailState("Plugin supports Zombie Panic! Source only.");
		return;
	}

	// Cvars
	CreateConVar("sm_pillscure_version", PLUGIN_VERSION, "Plugin version of Infection Rate Changer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_infectiontime = CreateConVar("sm_pillscure_time", "35", "If the cure type is set to 0, then this will apply (this counts in seconds)", FCVAR_PLUGIN, true, 0.0, true, 140.0);
	cvar_curetype = CreateConVar("sm_pillscure_type", "1", "Set the type of \"cure\" the pills will do if infected | 0=delay infection, 1=cure infection", FCVAR_PLUGIN, true, 0.0, true, 1.0);
}

/*
	Action:PlayerSpawned()
*/
public Action:PlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	ClientGotInfo[client] = false;
}

/*
	Action:OnPlayerRunCmd()
*/
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_USE) == IN_USE) 
	{
		if (!ValidatePlayer(client))
			return;

		buttons &= ~IN_USE;

		// Lets grab the entity
		new ent = TraceClientViewEntity(client);

		if (ent == -1)
			return;

		new String:name[32];
		GetEdictClassname(ent, name, sizeof(name));

		if (IsValidClassname(ent, "item_healthvial"))
		{
			buttons = IN_USE;

			new clienthp = GetClientHealth(client);
			if (clienthp < 100)
			{
				if (GetInfection(client) == 0)
					return;

				if (ClientGotInfo[client])
					return;

				// They got the info, don't spam it
				ClientGotInfo[client] = true;

				if (GetConVarInt(cvar_curetype) == 1)
				{
					SetInfection(client, 0);
					CPrintToChat(client, "You have been {green}cured{default} from the infection.");
				}
				else
				{
					SetInfection(client, 0);
					CPrintToChat(client, "Your infection is gone, {blue}for now{default}...");
					CreateTimer(GetConVarFloat(cvar_infectiontime), ReInfect_Player, client);
				}

				CreateTimer(3.0, ReEnableInfo, client);
			}
		}

		if (!StrEqual(name, "worldspawn"))
			buttons = IN_USE;
	}
}

/*
	Action:Reset_Back()
*/
public Action:ReEnableInfo(Handle:timer, any:client)
{
	ClientGotInfo[client] = false;
	return Plugin_Stop;
}

/*
	Action:Reset_Back()
*/
public Action:ReInfect_Player(Handle:timer, any:client)
{
	SetInfection(client, 1);
	return Plugin_Stop;
}

/*
	ValidatePlayer()
*/
ValidatePlayer(client)
{
	// Sorry server, but you are not welcome here!
	if (client == 0)
		return false;

	// Checks if the player is in-game, connected and not a bot
	if(!IsClientInGame(client)
		|| IsFakeClient(client)
		|| !IsClientConnected(client))
		return false;

	return true;
}

/*
	bool:IsValidClassname()
*/
static bool:IsValidClassname(entity, String:classname[]) {
    decl String:iClassname[MAX_NAME_LENGTH];
    GetEdictClassname(entity, iClassname, sizeof(iClassname));
    return bool:StrEqual(iClassname, classname, false);
}

/*
	TraceClientViewEntity()
*/
stock TraceClientViewEntity(client)
{
	new Float:Origin[3],
		Float:Rotation[3];
	GetClientEyePosition(client, Origin);
	GetClientEyeAngles(client, Rotation);
	new	Handle:tr = TR_TraceRayFilterEx(Origin, Rotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	new	pEntity	= -1;
	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}
	CloseHandle(tr);
	return -1;
}

/*
	bool:TRDontHitSelf()
*/
public bool:TRDontHitSelf(entity, mask, any:data)
{
	if (entity == data) return false;
	return true;
}