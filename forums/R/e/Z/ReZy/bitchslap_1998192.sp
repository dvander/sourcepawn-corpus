#include <sourcemod>
#include <sdktools>
 
#define PLUGIN_VERSION "1.1.0"
 
new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hDamage = INVALID_HANDLE;
new Handle:g_hMaxSlap = INVALID_HANDLE;
new Handle:g_hSlapSpeed = INVALID_HANDLE;
 
new bool:g_bIsEnabled = false;
new g_iSlapDamage;
new g_iMaxSlaps;
new Float:g_fSlapInterval;
 
 
public Plugin:myinfo =
{
        name = "BitchSlap",
        author = "ReZy",
        description = "Bitchslap a Person",
        version = PLUGIN_VERSION,
        url = ""
}

 
public OnPluginStart()
{
        g_hEnabled = CreateConVar("sm_enable_bitchslap", "1", "This enabled or disabled the bitchslap command (0 = Off : 1 = On).", FCVAR_NONE, true, 0.0, true, 1.0);
        HookConVarChange(g_hEnabled, OnSettingsChange);
        g_hDamage = CreateConVar("sm_bitchslap_damage", "10", "This changes the damage of bitchslap", FCVAR_NONE, true, 0.0, true, 300.0);
        HookConVarChange(g_hDamage, OnSettingsChange);
        g_hMaxSlap = CreateConVar("sm_bitchslap_maxspeed", "20", "This changes max slaps bitchslap does", FCVAR_NONE, true, 0.0);
        HookConVarChange(g_hMaxSlap, OnSettingsChange);
        g_hSlapSpeed = CreateConVar("sm_bitchslap_slapspeed", "0.25", "This changes the slap speed of bitchslap", FCVAR_NONE, true, 0.1, true, 1.0);
        HookConVarChange(g_hSlapSpeed, OnSettingsChange);
 
        g_bIsEnabled = GetConVarBool(g_hEnabled);
        g_iSlapDamage = GetConVarInt(g_hDamage);
        g_iMaxSlaps = GetConVarInt(g_hMaxSlap);
        g_fSlapInterval = GetConVarFloat(g_hSlapSpeed);
 
        RegAdminCmd("sm_bitchslap", Command_BitchSlap, ADMFLAG_ROOT, "Bitchslap a Person");
}

 
public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
    if (cvar == g_hEnabled)
    {
       g_bIsEnabled = bool:StringToInt(newvalue);
       g_iSlapDamage = StringToInt(newvalue);
       g_iMaxSlaps = StringToInt(newvalue);
       g_fSlapInterval = Float:StringToInt(newvalue);
    }
}

 
public Action:Command_BitchSlap(iClient, iArgs)
{
	if (!g_bIsEnabled)
	{
		ReplyToCommand(iClient, "[SM] Error: All the features in this plugin have been disabled.");
		return Plugin_Handled;
	}
 
	if (iArgs < 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_bitchslap <player> <number of times>");
		return Plugin_Handled;
	}
	
	
	decl String:sArg[64];
	decl String:sArg2[64];
	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
 
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
    sArg,
    iClient,
    target_list,
    MAXPLAYERS,
    COMMAND_FILTER_DEAD,
    target_name,
    sizeof(target_name),
    tn_is_ml)) <= 0)
    {
    ReplyToTargetError(iClient, target_count);
    return Plugin_Handled;
    }
   
	if (StringToInt(sArg2) > g_iMaxSlaps)
    {
        ReplyToCommand(iClient, "[SM] Error: You can only slap him twenty times!");
 
        return Plugin_Handled;
    }
 
	new iCount = 0, Float:fDelay = g_fSlapInterval;
 
	while (iCount < StringToInt(sArg2))
	{
		CreateTimer(fDelay, Timer_Slap, GetClientSerial(iClient));
 
		fDelay += g_fSlapInterval;
		iCount++
	}

	return Plugin_Handled;
}


public Action:Timer_Slap(Handle:timer, any:iBuffer)
{
	new iClient = GetClientFromSerial(iBuffer);

	if (IsPlayerAlive(iClient) && (1 <= iClient <= MaxClients))
	{
		SlapPlayer(iClient, g_iSlapDamage, true);
    }
	else
	{
		timer = INVALID_HANDLE;

		KillTimer(timer);
	}
}

