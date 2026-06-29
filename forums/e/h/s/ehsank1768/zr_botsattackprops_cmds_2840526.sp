#include <sdktools>
//#include <morecolors>


public Plugin:myinfo = 
{
	name = "[ZR] Zombie Bots: Prop Attack CMDS",
	author = "Khebre",
	description = "Cmds used by BOTS Attacking props",
	version = "1.0"
}

int buttonFlags[MAXPLAYERS + 1];

public OnPluginStart()
{
	RegConsoleCmd("+sm_gouse", Command_ForceUse, "Force +use briefly");
	RegConsoleCmd("-sm_gouse", Command_MinusForceUse, "Force +use briefly");
	RegConsoleCmd("+sm_goattack", Command_ForceAttack, "Force +attack briefly");
	RegConsoleCmd("-sm_goattack", Command_MinusForceAttack, "Force +attack briefly");
}
bool IsValidAliveClient(int client)
{
    return (client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}
public Action Command_ForceAttack(int client, int args)
{
    if (!IsValidAliveClient(client)) return Plugin_Handled;
    PlusAttack(client, 0);
    return Plugin_Handled;
}

public Action Command_ForceUse(int client, int args)
{
    if (!IsValidAliveClient(client)) return Plugin_Handled;
    PlusUse(client, 0);
    return Plugin_Handled;
}
public Action Command_MinusForceAttack(int client, int args)
{
    if (!IsValidAliveClient(client)) return Plugin_Handled;
    MinusAttack(client, 0);
    return Plugin_Handled;
}
public Action Command_MinusForceUse(int client, int args)
{
    if (!IsValidAliveClient(client)) return Plugin_Handled;
    MinusUse(client, 0);
    return Plugin_Handled;
}
// +use (E)
public Action PlusUse(int client, any puppet)
{
    buttonFlags[client] |= IN_USE;
    return Plugin_Handled;
}

public Action MinusUse(int client, any puppet)
{
    buttonFlags[client] &= ~IN_USE;
    return Plugin_Handled;
}
// Attack mouse button 1
public Action PlusAttack(int client, any puppet)
{
    buttonFlags[client] |= IN_ATTACK;
    return Plugin_Handled;
}

public Action MinusAttack(int client, any puppet)
{
    buttonFlags[client] &= ~IN_ATTACK;
    return Plugin_Handled;
}
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (client >= 1 && client <= MaxClients && IsClientInGame(client))
    {
        buttons |= buttonFlags[client];
        
    }
    return Plugin_Continue;
}