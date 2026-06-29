#include <sourcemod>
#include <sdktools> 
#include <dbi.inc>

public Plugin:myinfo =
{
	name = "Teleport",
	author = "The Count",
	description = "Teleport one person to another.",
	version = "1.0",
	url = ""
}

new String:arg1[32];
new String:arg2[32];
new String:name1[32];
new String:name2[32];
new targ1;
new targ2;

public OnPluginStart(){

RegAdminCmd("sm_teleport", Command_Teleport, ADMFLAG_SLAY, "Teleports a player.");

}

public Action:Command_Teleport (client, args) {
if(args == 1){
targ1 = client;
GetCmdArg(1, arg1, sizeof(arg1));
targ2 = FindTarget(client, arg1);
}else{
if(args != 2){
PrintToChat(client, "[SM] Usage: sm_teleport (Player1) (Player2)");
return Plugin_Handled;
}else{
GetCmdArg(1, arg1, sizeof(arg1));
targ1 = FindTarget(client, arg1);
GetCmdArg(2, arg2, sizeof(arg2));
targ2 = FindTarget(client, arg2);
}
}
// By now the targets have been assigned to appropriate variables.
new Float:vec[3];
GetClientAbsOrigin(targ2, vec);
TeleportEntity(targ1, vec, NULL_VECTOR, NULL_VECTOR);
GetClientName(targ1, name1, sizeof(name1));
GetClientName(targ2, name2, sizeof(name2));
PrintToChatAll("[SM] %s was teleported to %s.", name1, name2);
return Plugin_Handled;
}
