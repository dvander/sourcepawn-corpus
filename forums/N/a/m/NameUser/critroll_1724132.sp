/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <tf2>
 
new NoRoll[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Crit Roll",
	author = "Pierce 'NameUser' Strine",
	description = "Lets you roll a dice for crits",
	version = "0.1",
	url = "http://www.klaykinsquad.com/"
}

public OnPluginStart()
{
    RegConsoleCmd("sm_critroll", Command_Crits);
}

public OnClientPutInServer(client)
{
NoRoll[client] = -1; // Nope.avi
}

public Action:Command_Crits(client, args)
{

new String:name2[64]; 
GetClientName(client, name2, sizeof(name2));
new random = GetRandomInt(1, 5);

	if (NoRoll[client] == 1)
	{
		PrintToChat(client, "%s , please wait before rolling for crits again!", name2);
		return Plugin_Handled;
	}
	else if (random == 1)
		{
		PrintToChatAll("%s rolled and got critical hits for 20 Seconds!", name2);
		TF2_AddCond(client, 11)
		NoRoll[client] = 1;
		CreateTimer(180.0, canRandom, client);
		}
	
	else if (random >= 2)
	{
		PrintToChatAll("%s rolled and died!", name2);
		SlapPlayer(client, 5000, false);
		NoRoll[client] = 1;
		CreateTimer(180.0, canRandom, client);
	}
return Plugin_Handled;
}

public Action:canRandom(Handle:timer, any:client)
{
NoRoll[client] = -1;
}

stock TF2_AddCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) {
        SetConVarFlags(cvar, flags^FCVAR_NOTIFY);
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "addcond %i", cond);
    if(!enabled) {
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
}
stock TF2_RemoveCond(client, cond) {
    new Handle:cvar = FindConVar("sv_cheats"), bool:enabled = GetConVarBool(cvar), flags = GetConVarFlags(cvar);
    if(!enabled) {
        SetConVarFlags(cvar, flags^FCVAR_NOTIFY);
        SetConVarBool(cvar, true);
    }
    FakeClientCommand(client, "removecond %i", cond);
    if(!enabled) {
        SetConVarBool(cvar, false);
        SetConVarFlags(cvar, flags);
    }
}