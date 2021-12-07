#include <sourcemod>

#define versao "v1.0"

#define NOME_AUTOR "Dk--"

public Plugin:myinfo = 
{
	name = "RR",
	author = NOME_AUTOR,
	description = "Dar restart Round",
	version = versao,
};

public OnPluginStart()
{
	RegConsoleCmd("sm_rr", RR)
}
		
public Action:RR(client, args)
{
	if(IsClientInGame(client))
	{
		ServerCommand("mp_restartgame 1");
		PrintCenterTextAll(" RESTART ROUND ");
	}
}
