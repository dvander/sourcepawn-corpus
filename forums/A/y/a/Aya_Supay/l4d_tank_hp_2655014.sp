#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

ConVar hBasicTankHP;
ConVar hAddTankHP;
int TankBasicHP;
int TankAddHP;

public void OnPluginStart()
{
	hBasicTankHP = CreateConVar("l4d_basic_hp", "4000", "Tank basic health", CVAR_FLAGS);
	hAddTankHP = CreateConVar("l4d_add_hp", "1000", "each additional player Tank increases health", CVAR_FLAGS);

	TankBasicHP = hBasicTankHP.IntValue;
	TankAddHP = hAddTankHP.IntValue;	
	
	HookEvent("player_activate", ePlayerAct);
	HookEvent("player_disconnect", ePlayerDisct);
	
	AutoExecConfig(true, "l4d_tank_hp", "sourcemod");
}

public void OnMapStart()
{
	TankBasicHP = hBasicTankHP.IntValue;
	TankAddHP = hAddTankHP.IntValue;
}

public void ePlayerAct(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	if (UserId != 0) {
		int client = GetClientOfUserId(UserId);
		if (client != 0 && !IsFakeClient(client)) {
		    CreateTimer(0.1, ResetTankHp, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public void ePlayerDisct(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	if (UserId != 0) {
		int client = GetClientOfUserId(UserId);
		if (client != 0 && !IsFakeClient(client)) {
		    CreateTimer(3.0, ResetTankHp, TIMER_FLAG_NO_MAPCHANGE);
        }
    }		
}

public Action ResetTankHp(Handle timer)
{
	int SetTankHP, iPlayersCount;
	
	TankBasicHP = hBasicTankHP.IntValue;
	TankAddHP = hAddTankHP.IntValue;
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) )
		{
			iPlayersCount++;
		}
	}
	
	if (iPlayersCount <= 4) iPlayersCount = 4;
	
	SetTankHP = TankAddHP * iPlayersCount + TankBasicHP;
	
	SetConVarInt(FindConVar("z_tank_health"), SetTankHP, false, false);
	CPrintToChatAll("{cyan}!The number of survivors has changed! Tank Health: {green}%d", SetTankHP);
}

/**
*   @note Used for in-line string translation.
*
*   @param  iClient     Client Index, translation is apllied to.
*   @param  format      String formatting rules. By default, you should pass at least "%t" specifier.
*   @param  ...            Variable number of format parameters.
*   @return char[192]    Resulting string. Note: output buffer is hardly limited.
*/
stock char[] Translate(int iClient, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    return buffer;
}

/**
*   @note Prints a message to a specific client in the chat area. Supports named colors in translation file.
*
*   @param  iClient     Client Index.
*   @param  format        Formatting rules.
*   @param  ...            Variable number of format parameters.
*   @no return
*/
stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

/**
*   @note Prints a message to all clients in the chat area. Supports named colors in translation file.
*
*   @param  format        Formatting rules.
*   @param  ...            Variable number of format parameters.
*   @no return
*/
stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

/**
*   @note Converts named color to control character. Used internally by string translation functions.
*
*   @param  char[]        Input/Output string for convertion.
*   @param  maxLen        Maximum length of string buffer (includes NULL terminator).
*   @no return
*/
stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
} 
