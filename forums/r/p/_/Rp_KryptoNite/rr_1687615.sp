#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Easy Restart Game",
	author = "KryptoNite[IL]",
	version = "1.0",
	url = "http://css.vgames.co.il/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_rr" ,command_rr ,ADMFLAG_GENERIC)
}

public Action:command_rr(client, args)
{
	ServerCommand("mp_restartgame 1");
	PrintToChatAll("\x04[SM] %N \x01Proceed Restart Round in\x04 1\x01 Second!" ,client);
}