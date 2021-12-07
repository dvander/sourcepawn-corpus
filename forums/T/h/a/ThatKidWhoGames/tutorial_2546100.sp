#include <sourcemod>
#include <tf2_stocks>

ConVar cv_BlueTeam;
ConVar cv_RedTeam;

new bool:bBlueTeamCvar;
new bool:bRedTeamCvar;

public OnPluginStart()
{
	// Replace with whatever command you want to block for a team
	AddCommandListener(CommandBlock, "command_you_want_to_block");

	cv_BlueTeam = CreateConVar("sm_command_block_blue", "1", "Block the blue team from using the command?", _, true, 0.0, true, 1.0);
	bBlueTeamCvar = GetConVarBool(cv_BlueTeam);

	cv_RedTeam = CreateConVar("sm_command_block_red", "1", "Block the blue team from using the command?", _, true, 0.0, true, 1.0);
	bRedTeamCvar = GetConVarBool(cv_RedTeam);
}

public Action CommandBlock(int client, const char[] command, int argc)
{
	if (IsValidClient(client))
	{
		if (bBlueTeamCvar && TF2_GetClientTeam(client) == TFTeam_Blue)
		{
			return Plugin_Stop;
			// Blocks the command for the client on the blue team
		}
		else if (bRedTeamCvar && TF2_GetClientTeam(client) == TFTeam_Red)
		{
			return Plugin_Stop;
			// Blocks the command for the client on the red team			
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true) 
{ 
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client))) 
	{ 
		return false; 
	}
	return true;
}