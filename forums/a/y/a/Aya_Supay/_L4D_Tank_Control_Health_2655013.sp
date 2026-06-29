#define PLUGIN_VERSION		"1.0"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D] Tank Control Health
*	Author	:	JOSHE GATITO SPARTANSKII >>>
*	Descr.	:	control the tanks health mode based on players number.
*	Link	:	https://github.com/JosheGatitoSpartankii09

========================================================================================
	Change Log:

1.0 (09-05-2019)
	- Initial release
========================================================================================
	Description:
	Self-explained.
	
	Commands:
    "nothing"
	
	Settings (ConVars):
	"l4d_tank_control_hp"	- Do we need to control tank HP ? ( 0 - No / 1 - Yes)
	"l4d_tank_spawn_hp"	- HP of tank to set
	
	Credits:
	
    Dragokas - for the Colors in translation file tutorial.
	
======================================================================================*/


#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

/*Int*/
int TankBasicHP;

/*bools*/

bool g_bLeft4Dead2;

/*ConVars*/

ConVar g_ConVarControlHP;
ConVar g_ConVarHP;
ConVar g_ConVarZTankHealth;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;		
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D] Tank Control Health",
	author = "JOSHE GATITO SPARTANSKII >>>",
	description = "control the tanks health mode based on players number.",
	version = PLUGIN_VERSION,
	url = "https://github.com/JosheGatitoSpartankii09"
}

public void OnPluginStart()
{
	g_ConVarControlHP = CreateConVar("l4d_tank_control_hp","1", "Do we need to control tank HP ? ( 0 - No / 1 - Yes)", CVAR_FLAGS);
	g_ConVarHP = CreateConVar( "l4d_tank_spawn_hp", "4000", "HP of tank to set", CVAR_FLAGS);
	
	HookEvent("tank_spawn", eTankSpawn);
	HookEvent("player_spawn", ePlayerSpawn, EventHookMode_Post);

	TankBasicHP = g_ConVarHP.IntValue;

	g_ConVarZTankHealth = FindConVar("z_tank_health");
	g_ConVarZTankHealth.AddChangeHook(ConVarChanged_Cvars);
	
	AutoExecConfig(true, "[L4D] Tank Control Health");
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar != null)
	{
		int oldval = StringToInt(oldValue);
		int newval = StringToInt(newValue);
		if(oldval != newval)
		{
			for ( int i = 1; i <= MaxClients; i++ )
			{
				if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && IsTank(i))
				{
					SetPlayerHealth(i,newval,false);
				}
			}
		}
	}
}

public void eTankSpawn(Event event, char[] event_name, bool dontBroadcast)
{
	if (g_ConVarControlHP.BoolValue)
	{
		int UserId = event.GetInt("userid");
		int client = GetClientOfUserId(UserId);
		
		int survivorcount = 0;
		int SetTankHP;
		
		if ( survivorcount > 0 ) survivorcount = 0;
		
		for ( int i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientConnected(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) )  
			{
				survivorcount++;
			}
		}	
		
		if (client)
		{
			SetTankHP = TankBasicHP * survivorcount;
			SetConVarInt( FindConVar("z_tank_health"), SetTankHP, false, false );
			CPrintToChatAll("{cyan}!The number of survivors has changed! Tank Health: {green}%d", SetTankHP);
		}
	}
}

public void ePlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	if (UserId != 0) {
		int client = GetClientOfUserId(UserId);
		if (client != 0) {
			if (IsTank(client)) {
				SetPlayerHealth(client, g_ConVarZTankHealth.IntValue,true);				
			}
		}
	}
}

//code by https://forums.alliedmods.net/showthread.php?t=66154&page=8

void SetPlayerHealth(int client, int amount, bool ResetMax)
{
	if(amount >= 1)
	{
		SetEntProp(client, Prop_Send, "m_iMaxHealth", amount);
		SetEntProp(client, Prop_Send, "m_iHealth", amount);
	}
	if(ResetMax)
	{
		SetEntityHealth(client, amount);
	}
}

bool IsTank(int client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5 ))
			return true;
	}
	return false;
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