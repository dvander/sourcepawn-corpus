#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "stuck",
	author = "meng",
	version = "0.7",
	description = "allows players to type !stuck to move freely for a few seconds",
	url = ""
};

new Handle:RoundStartTimer;
new bool:CmdAllowed[MAXPLAYERS+1];

public OnPluginStart(){
	HookEvent("round_start", EventRoundStart);
	RegConsoleCmd("say", CmdSay);
	RegConsoleCmd("say_team", CmdSay);
}

public EventRoundStart(Handle:event, const String:name[],bool:dontBroadcast){
	for (new i = 1; i <= MaxClients; i++)
		CmdAllowed[i] = true;
	if (RoundStartTimer != INVALID_HANDLE)
		KillTimer(RoundStartTimer);
	RoundStartTimer = CreateTimer(30.0, RestrictCmd);
}

public Action:RestrictCmd(Handle:timer, any:client){
	for (new i = 1; i <= MaxClients; i++)
		CmdAllowed[i] = false;
	RoundStartTimer = INVALID_HANDLE;
}

public Action:CmdSay(client, args){
	if (args > 0){
		new String:line[16];
		GetCmdArg(1, line, sizeof(line));
		if (StrEqual(line, "!stuck", false)){
			if (CmdAllowed[client] && IsPlayerAlive(client)){
				decl Float:ClientOrigin[3], Float:TempClientOrigin[3], Float:distance;
				GetClientAbsOrigin(client, ClientOrigin);
				for (new i = 1; i <= MaxClients; i++){
					if (i != client && IsClientInGame(i) && IsPlayerAlive(i)){
						GetClientAbsOrigin(i, TempClientOrigin);
						distance = GetVectorDistance(ClientOrigin, TempClientOrigin);
						if (distance < 50.0){
							Free(client);
							Free(i);
							break;
						}
					}
				}
				CmdAllowed[client] = false;
			}
			else
				PrintToChat(client, "\x04[SM] Command currently restricted!");
		}
	}
}

Free(client){
	PrintToChat(client, "\x04[SM] Unstuck! You have 3 seconds to move!");
	SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
	SetEntityRenderMode(client, RENDER_TRANSADD);
	SetEntityRenderColor(client, 177, 177, 177, 117);
	CreateTimer(3.0, Reset, client);
}

public Action:Reset(Handle:timer, any:client){
	if (IsClientInGame(client)){
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}