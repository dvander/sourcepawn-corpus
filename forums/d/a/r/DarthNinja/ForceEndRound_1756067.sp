#include <sourcemod>
#include <sdktools>

new const String:PLUGIN_VERSION[] = "1.0.1";

public Plugin:myinfo = 
{
	name = "[TF2] Force End Round",
	author = "DarthNinja",
	description = ".",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_force_end_round_version", PLUGIN_VERSION, "k", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_fer", ForceGameEnd, ADMFLAG_BAN, "sm_fer [team]");
	RegAdminCmd("sm_forceendround", ForceGameEnd, ADMFLAG_BAN, "sm_forceendround [team]");
	LoadTranslations("common.phrases");
}

public Action:ForceGameEnd(client, args)
{
	if (args != 0 && args != 1)
	{
		ReplyToCommand(client, "sm_fer / sm_forceendround [Winning Team: Red/Blue/None]");
		return Plugin_Handled;
	}
	
	new iEnt = -1;
	iEnt = FindEntityByClassname(iEnt, "game_round_win");
	
	if (iEnt < 1)
	{
		iEnt = CreateEntityByName("game_round_win");
		if (IsValidEntity(iEnt))
			DispatchSpawn(iEnt);
		else
		{
			ReplyToCommand(client, "Unable to find or create a game_round_win entity!");
			return Plugin_Handled;
		}
	}
	
	new iWinningTeam = 0;
	if (client) 
		iWinningTeam = GetClientTeam(client);
	
	if (args == 1)
	{
		decl String:buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
	
		if (StrEqual(buffer, "blue", false))
			iWinningTeam = 3;
		else if (StrEqual(buffer, "red", false))
			iWinningTeam = 2;
		else if (StrEqual(buffer, "none", false))
			iWinningTeam = 0;
	}
	
	if (iWinningTeam == 1)
		iWinningTeam --;
		
	SetVariantInt(iWinningTeam);
	AcceptEntityInput(iEnt, "SetTeam");
	AcceptEntityInput(iEnt, "RoundWin");
	
	return Plugin_Handled;
}
