/*
 * Name: Terms Agreement
 * By: MaTTe (aka mateo10)
 *
 * Notes: My first SM plugin!
*/

#include <sourcemod>

#define VERSION "1.1"

public Plugin:myinfo =
{
	name = "Terms Agreement",
	author = "MaTTe",
	description = "On connect, a player needs to agree the terms, or he will be kicked!",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

new bool:gClientSpawned[33];
new bool:gClientAgreed[33];

public OnPluginStart()
{
	CreateConVar("termsagreement_version", VERSION, "Terms And Agreement Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_spawn", HookClientSpawn, EventHookMode_Post);
}

public OnClientDisconnect(client)
{
	gClientSpawned[client] = false;
	gClientAgreed[client] = false;
}

public onClientPutInServer(client)
{
	gClientSpawned[client] = false;
}

public HookClientSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(iUserId);

	if(gClientSpawned[client] == false && gClientAgreed[client] == false)
	{
		Menu_Build(client);
		gClientSpawned[client] = true;
	}
}

public Menu_Build(client)
{
	new String:szTermsFile[256];
	BuildPath(Path_SM, szTermsFile, sizeof(szTermsFile), "configs/terms.txt");
	new Handle:hFile = OpenFile(szTermsFile, "rt");

	if(hFile == INVALID_HANDLE)
	{
		return;
	}

	new String:szTerms[512];
	new String:szReadData[128];

	new Handle:hMenu = CreatePanel();

	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szReadData, sizeof(szReadData)))
	{
		DrawPanelText(hMenu, szReadData);
	}

	SetPanelTitle(hMenu, "Terms Agreement");

	DrawPanelItem(hMenu, "I Agree");
	DrawPanelItem(hMenu, "I Disagree");

	SendPanelToClient(hMenu, client, Menu_Handler, 60);

	CloseHandle(hMenu);

	CloseHandle(hFile);
}

public Menu_Handler(Handle:hMenu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			PrintToChat(param1, "\x04You have agreed to the terms and you are therefore allowed to play on the server.");
			gClientAgreed[param1] = true;
		}
		else if(param2 == 2)
		{
			KickClient(param1, "You disagreed to the terms");
		}
	}
}