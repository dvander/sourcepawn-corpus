#include <sourcemod>
#include <sdkhooks>

#define VERSION "1.0.0"

new Handle:g_Cvar_ThirdPersonAllowed;
new bool:g_bThirdPerson[MAXPLAYERS+1];

public Plugin:myinfo = {
	name			= "[CSGO] Third Person",
	author			= "thecount & Powerlord",
	description		= "Switch between first person and third person",
	version			= VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=241532"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_tp", Command_Thirdperson, "Sets thirdperson.");
	RegConsoleCmd("sm_fp", Command_Firstperson, "Sets firstperson.");
	
	g_Cvar_ThirdPersonAllowed = FindConVar("sv_allow_thirdperson");
}

public OnConfigsExecuted()
{
	SetConVarBool(g_Cvar_ThirdPersonAllowed, true);
	for (new i = 1; i <= MaxClients; i++)
	{
		g_bThirdPerson[i] = false;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamage_Post);
}

public OnClientDisconnected(client)
{
	g_bThirdPerson[client] = false;
}

public Action:Command_Thirdperson (client, args) {
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
	}
	else if (IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] Thirdperson");
		ClientCommand(client, "thirdperson");
		g_bThirdPerson[client] = true;
	}
	else
	{
		ReplyToCommand(client, "%t", "Target must be alive");
	}
	return Plugin_Handled;
}

public Action:Command_Firstperson (client, args) {
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
	}
	else if (IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] Firstperson");
		ClientCommand(client, "firstperson");
		g_bThirdPerson[client] = false;
	}
	else
	{
		ReplyToCommand(client, "%t", "Target must be alive");
	}
	return Plugin_Handled;
}

public OnTakeDamage_Post(victim, attacker, inflictor, Float:damage, damagetype, weapon, const Float:damageForce[3], const Float:damagePosition[3])
{
	if (victim <= 0 || victim > MaxClients)
	{
		return;
	}
	
	if (g_bThirdPerson[victim] && GetClientHealth(victim) <= RoundToNearest(damage))
	{
		PrintToChat(victim, "[SM] Firstperson");
		ClientCommand(victim, "firstperson");
		g_bThirdPerson[victim] = false;
	}
}
