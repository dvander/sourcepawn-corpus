#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name		= "[TF2] Round End",
	author		= "Dr. McKay",
	description	= "Forces the round to end",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
};

public OnPluginStart() {
	RegAdminCmd("sm_roundend", Command_RoundEnd, ADMFLAG_CHANGEMAP, "Ends the round");
}

public Action:Command_RoundEnd(client, args) {
	if(args != 1) {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_roundend <red/blue/stalemate>");
		return Plugin_Handled;
	}
	
	decl String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new team = 0;
	if(StrEqual(arg1, "red", false)) {
		team = 2;
	} else if(StrEqual(arg1, "blue", false)) {
		team = 3;
	} else if(StrEqual(arg1, "stalemate", false)) {
		team = 0;
	} else {
		ReplyToCommand(client, "\x04[SM] \x01Usage: sm_roundend <red/blue/stalemate>");
		return Plugin_Handled;
	}
	
	new entity = FindEntityByClassname(-1, "game_round_win");
	if(entity == -1) {
		entity = CreateEntityByName("game_round_win");
		DispatchSpawn(entity);
	}
	
	SetVariantInt(team);
	AcceptEntityInput(entity, "SetTeam");
	AcceptEntityInput(entity, "RoundWin");
	return Plugin_Handled;
}