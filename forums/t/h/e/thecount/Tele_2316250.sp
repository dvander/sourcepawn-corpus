#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Tele",
	author = "The Count",
	description = "Tele with your friends.",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071"
};

public OnPluginStart(){
	RegConsoleCmd("sm_tele", Cmd_Tele, "Teleport to a random player.");
}

public OnMapStart(){
	PrecacheSound("ambient/energy/zap5.wav", true);
	PrecacheSound("ambient/energy/zap6.wav", true);
	PrecacheSound("ambient/energy/zap7.wav", true);
	PrecacheSound("ambient/energy/zap8.wav", true);
	PrecacheSound("ambient/energy/zap9.wav", true);
}

public Action:Cmd_Tele(client, args){
	if(!IsPlayerAlive(client)){
		return Plugin_Handled;
	}
	new clients[MAXPLAYERS + 1], counter = -1, team = GetClientTeam(client);
	for(new i=1;i<=MaxClients;i++){
		if(i != client && IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i)){
			counter++;
			clients[counter] = i;
		}
	}
	if(counter == -1){
		PrintToChat(client, "[SM] No suitable targets found.");
		return Plugin_Handled;
	}
	new Float:pos[3];
	GetClientAbsOrigin(clients[GetRandomInt(0, counter)], pos);
	TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
	new String:path[128];Format(path, sizeof(path), "ambient/energy/zap%d.wav", GetRandomInt(5, 9));
	EmitSoundToAll(path, client, SNDCHAN_AUTO, SNDLEVEL_MINIBIKE);
	return Plugin_Handled;
}