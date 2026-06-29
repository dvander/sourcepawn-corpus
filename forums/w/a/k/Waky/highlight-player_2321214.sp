#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0"
#define URL "www.area-community.net"
#define AUTOR "Waky"
#define NAME "Highlight"
#define DESCRIPTION "Give CT´s the possibility to highlight T´s"

bool g_bHighlight[MAXPLAYERS+1] = false;

public Plugin:myinfo = 
{
	name = NAME,
	author = AUTOR,
	description = DESCRIPTION,
	version = PLUGIN_VERSION,
	url = URL
}
public OnPluginStart(){
	RegConsoleCmd("sm_hl",Command_Highlight);
}
public Action:Command_Highlight(client,args){
	if(IsClientValid(client)){
		if(GetClientTeam(client) != 3) return Plugin_Handled;
		char sTarget[128];
		GetCmdArg(1,sTarget,sizeof(sTarget));
		int target = FindTarget(client,sTarget,true,true);
		if(IsClientValid(target)){
			
				if(g_bHighlight[target]){
					g_bHighlight[target] = false;
					SetEntityRenderColor(target,255,255,255,255);
				}else{
					g_bHighlight[target] = true;
					SetEntityRenderColor(target,0,255,0,255);
				}
		}
	}
	return Plugin_Handled;
}
stock bool:IsClientValid(client){
	if(client > 0 && client <= MaxClients && IsClientInGame(client)){
		return true;
	}
	return false;
}