/* 
Credits to 
Asherkin for Free2BeKicked http://forums.alliedmods.net/showthread.php?t=160049
*/

#pragma semicolon 1

#include <sourcemod>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "1.0.0"

static bIsF2P[MAXPLAYERS+1];

static Handle:hMinSlots;
static iMinSlots;

static bool:bTempBlock = false;

public Plugin:myinfo = {
	name        = "Extended Free2BeKicked",
	author      = "Asher \"asherkin\" Baker, extended by Monkeys",
	description = "Automatically kicks non-premium players based on certain settings",
	version     = PLUGIN_VERSION,
	url         = ""
};

public OnPluginStart()
{
	CreateConVar("ext_anti_f2p_version", PLUGIN_VERSION, "Extended Free2BeKicked", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	hMinSlots = CreateConVar("anti_f2p_minslots", "0", "Minimum amount of slots that need to be open before stopping F2P players from joining");
	iMinSlots = GetConVarInt(hMinSlots);
	HookConVarChange(hMinSlots, cbCvarChange);
	
	RegAdminCmd("sm_kick_f2p", cmdKickF2P, ADMFLAG_KICK, "Kicks a random F2P player");
	RegAdminCmd("sm_kick_last_f2p", cmdKickLastF2P, ADMFLAG_KICK, "Kicks the last joined F2P player");
	RegAdminCmd("sm_kick_first_f2p", cmdKickFirstF2P, ADMFLAG_KICK, "Kicks the first joined F2P player");
	RegAdminCmd("sm_temp_block_f2p", cmdTempBlockF2P, ADMFLAG_BAN, "<[float] duration in minutes> - Temporarily blocks all F2P connections, use -1 for an endless duration, 0 to disable.");
}

public OnClientPostAdminCheck(Client)
{
	bIsF2P[Client] = false; //Reset
	
	if (CheckCommandAccess(Client, "BypassPremiumCheck", ADMFLAG_ROOT, true))
	{
		return;
	}
	
	if (Steam_CheckClientSubscription(Client, 0) && !Steam_CheckClientDLC(Client, 459))
	{
		if(bTempBlock)
		{
			KickClient(Client, "Sorry, the server has temporarily blocked F2P TF2 accounts.");
			return;
		}
		if( GetClientCount(false) > (MaxClients - iMinSlots))
		{
			KickClient(Client, "Sorry, only Premium TF2 accounts can play on this server when it's this full.");
			return;
		}
		bIsF2P[Client] = true; //For future reference! Huzzzzah!
		return;
	}
	return;
}

public cbCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == hMinSlots)
	{
		iMinSlots = StringToInt(newValue);
	}
}

public Action:cmdKickF2P(Client, Args)
{
	for(new X = 1; X <= MaxClients; X++)
	{
		if(bIsF2P[X]) //Gotta make sure there's at least one to kick!
		{
			new iRand;
			do
			{
				iRand = GetRandomInt(1, MaxClients);
			} while(!bIsF2P[iRand]);
			KickClient(iRand, "Sorry, an admin randomly selected your F2P TF2 account to get kicked from the server.");
			bIsF2P[iRand] = false; //Reset
			break;
		}
	}
	return Plugin_Handled;
}

public Action:cmdKickLastF2P(Client, Args)
{
	new CurrentVictim = -1;
	new Float:CurrentVictimTime = -1.0;
	for(new X = 1; X <= MaxClients; X++)
	{
		if(bIsF2P[X]) //If he's F2P, check his online time, if it's less than the last guy's, switch!
		{
			if(CurrentVictim == -1)
			{
				CurrentVictim = X;
				CurrentVictimTime = GetClientTime(X);
			}
			else
				if(GetClientTime(X) <= CurrentVictimTime)
				{
					CurrentVictim = X;
					CurrentVictimTime = GetClientTime(X);
				}
		}
	}
	if(CurrentVictim != -1)
	{
		KickClient(CurrentVictim, "Sorry, an admin kicked the last joined F2P TF2 account (you) from the server.");
		bIsF2P[CurrentVictim] = false; //Reset
	}
	return Plugin_Handled;
}

public Action:cmdKickFirstF2P(Client, Args)
{
	new CurrentVictim = -1;
	new Float:CurrentVictimTime = -1.0;
	for(new X = 1; X <= MaxClients; X++)
	{
		if(bIsF2P[X]) //If he's F2P, check his online time, if it's less than the last guy's, switch!
		{
			if(CurrentVictim == -1)
			{
				CurrentVictim = X;
				CurrentVictimTime = GetClientTime(X);
			}
			else
				if(GetClientTime(X) > CurrentVictimTime)
				{
					CurrentVictim = X;
					CurrentVictimTime = GetClientTime(X);
				}
		}
	}
	if(CurrentVictim != -1)
	{
		KickClient(CurrentVictim, "Sorry, an admin kicked the first joined F2P TF2 account (you) from the server.");
		bIsF2P[CurrentVictim] = false; //Reset
	}
	return Plugin_Handled;
}

public Action:cmdTempBlockF2P(Client, Args)
{
	decl String:arg[255] = "0.0";
	GetCmdArg(1, arg, sizeof(arg));
	
	new Float:fDuration = StringToFloat(arg);
	
	if(fDuration == 0.0)
		bTempBlock = false;
	else
	if(fDuration == -1.0)
		bTempBlock = true;
	else
	{
		bTempBlock = true;
		CreateTimer(60.0 * fDuration, cbRemoveBlock);
	}
	
	return Plugin_Handled;
}

public Action:cbRemoveBlock(Handle:Timer)
{
	bTempBlock = false;
	return Plugin_Handled;
}