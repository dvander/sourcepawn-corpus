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

#define CVAR_FLAGS FCVAR_NOTIFY

/*Int*/
int TankBasicHP = 0;
/*bools*/
bool g_bLeft4Dead2 = false, bHooked = false;
/*ConVars*/
ConVar g_ConVarControlHP, g_ConVarHP, g_Diffuculty;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		g_bLeft4Dead2 = false;		
	}
	else if (engine == Engine_Left4Dead2)
	{
		g_bLeft4Dead2 = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D] Tank Control Health",
	author = "JOSHE GATITO SPARTANSKII >>>(A partially rewritten by BloodyBlade)",
	description = "control the tanks health mode based on players number.",
	version = PLUGIN_VERSION,
	url = "https://github.com/JosheGatitoSpartankii09"
}

public void OnPluginStart()
{
	CreateConVar("l4d_tank_control_hp_version", PLUGIN_VERSION, "[L4D] Tank Control Health plugin version", CVAR_FLAGS);
	g_ConVarControlHP = CreateConVar("l4d_tank_control_hp","1", "Do we need to control tank HP ? ( 0 - No / 1 - Yes)", CVAR_FLAGS);
	g_ConVarHP = CreateConVar( "l4d_tank_spawn_hp", "4000", "HP of tank to set", CVAR_FLAGS);

	AutoExecConfig(true, "[L4D] Tank Control Health");

	g_ConVarControlHP.AddChangeHook(ConVarChanged_PluginOn);
	g_ConVarHP.AddChangeHook(ConVarChanged_Cvars);
	g_Diffuculty = FindConVar("z_difficulty");
}

public void OnConFigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_PluginOn(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	TankBasicHP = g_ConVarHP.IntValue;
	if(StringToInt(oldValue) != StringToInt(newValue))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidTank(i))
			{
				SetPlayerHealth(i);
			}
		}
	}
}

void IsAllowed()
{
	bool bPluginOn = g_ConVarControlHP.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		ConVarChanged_Cvars(null, "", "");
		HookEvent("player_spawn", ePlayerSpawn, EventHookMode_Post);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_spawn", ePlayerSpawn, EventHookMode_Post);
	}
}

void ePlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidTank(client))
	{
		SetPlayerHealth(client);
	}
}

//code by https://forums.alliedmods.net/showthread.php?t=66154&page=8

void SetPlayerHealth(int client)
{
    int survivorcount = 0, iSetTankHP = 0;
    float fMultiple = 0.0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidSurv(i))  
        {
            survivorcount++;
        }
    }

    char cDifficulty[16];
    g_Diffuculty.GetString(cDifficulty, sizeof(cDifficulty));
    if(StrEqual(cDifficulty, "Easy", false))
    {
        fMultiple = 0.5;
    }
    else if(StrEqual(cDifficulty, "Medium", false) || (g_bLeft4Dead2 && StrEqual(cDifficulty, "Normal", false)))
    {
        fMultiple = 1.0;
    }
    else if(StrEqual(cDifficulty, "Hard", false))
    {
        fMultiple = 1.5;
    }
    else if(StrEqual(cDifficulty, "Expert", false) || (g_bLeft4Dead2 && StrEqual(cDifficulty, "Impossible", false)))
    {
        fMultiple = 2.0;
    }

    iSetTankHP = RoundToCeil(TankBasicHP * fMultiple * survivorcount);
    SetEntProp(client, Prop_Send, "m_iMaxHealth", iSetTankHP);
    SetEntProp(client, Prop_Send, "m_iHealth", iSetTankHP);
    CPrintToChatAll("{cyan}!The number of survivors has changed! Tank Health: {green}%d", iSetTankHP);
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client);
}

stock bool IsValidSurv(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2 && !IsFakeClient(client);
}

stock bool IsValidTank(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == (g_bLeft4Dead2 ? 8 : 5);
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
