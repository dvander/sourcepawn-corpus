#include <sourcemod>
#include <sdktools>
#include <levelmod>

new g_iMaxLevel = 0;

public OnPluginStart()
{
	RegAdminCmd("clm_showlist", Command_ShowList, ADMFLAG_ROOT);
}

public lm_OnClientLevelUp(client, level)
{
	//Always keep all clients on the same level (just an example)
	LogMessage("%N leveled up to %i", client, level);
	if(level > g_iMaxLevel) {
		g_iMaxLevel = level;
		
		for(new i = 1; i <= MaxClients; i++) {		
			if(IsClientConnected(i) && IsClientInGame(i) && i != client && lm_GetClientLevel(i) < level) {
				lm_SetClientLevel(i, level);
				lm_SetClientXP(i, 0);
			}
		}	
	}
}


public Action:Command_ShowList(client, args)
{
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientConnected(i) && IsClientInGame(i)) {
			new xp = lm_GetClientXP(i);
			new xpMax = lm_GetClientXPMax(i);
			new level = lm_GetClientLevel(i);

			ReplyToCommand(client, "%N is Level %i (XP: %i/%i)", i, level, xp, xpMax);
		}
	}
	
	return Plugin_Handled;
}