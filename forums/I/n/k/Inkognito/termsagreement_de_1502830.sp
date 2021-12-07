/*
 * Name: Terms Agreement
 * By: MaTTe (aka mateo10)
 * Bug fix by: Kigen
 * Mod by Inkognito
 *
 * Notes: My first SM plugin!
*/

#include <sourcemod>

#define VERSION "1.3"

public Plugin:myinfo =
{
	name = "Terms Agreement",
	author = "MaTTe",
	description = "On connect, a player needs to agree the terms, or he will be kicked!",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

#define MAX_PLAYERS 256

new bool:gClientSpawned[MAXPLAYERS+1];
new bool:gClientAgreed[MAXPLAYERS+1];
new Handle:BuildMenuTimer[MAX_PLAYERS+1];
new Handle:ReminderMenuTimer[MAX_PLAYERS+1];
new Handle:WarningMenuTimer[MAX_PLAYERS+1];

public OnPluginStart()
{
	CreateConVar("termsagreement_version", VERSION, "Terms And Agreement Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_spawn", HookClientSpawn, EventHookMode_Post);
}

public OnClientDisconnect(client)
{
	gClientSpawned[client] = false;
	gClientAgreed[client] = false;
	if (BuildMenuTimer[client] != INVALID_HANDLE)
	{
		KillTimer(BuildMenuTimer[client])
		BuildMenuTimer[client] = INVALID_HANDLE
	}
	if (ReminderMenuTimer[client] != INVALID_HANDLE)
	{
		KillTimer(ReminderMenuTimer[client])
		ReminderMenuTimer[client] = INVALID_HANDLE
	}
	if (WarningMenuTimer[client] != INVALID_HANDLE)
	{
		KillTimer(WarningMenuTimer[client])
		WarningMenuTimer[client] = INVALID_HANDLE
	}
}

public onClientPutInServer(client)
{
	gClientSpawned[client] = false;
}

public HookClientSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(iUserId);

	if(gClientSpawned[client] == false && gClientAgreed[client] == false && !IsFakeClient(client))
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

	new String:szReadData[128];

	new Handle:hMenu = CreatePanel();

	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szReadData, sizeof(szReadData)))
	{
		DrawPanelText(hMenu, szReadData);
	}

	SetPanelTitle(hMenu, "Spielregeln");

	DrawPanelItem(hMenu, "Zustimmen");
	DrawPanelItem(hMenu, "Ablehnen");

	SendPanelToClient(hMenu, client, Menu_Handler, 60);

	CloseHandle(hMenu);

	CloseHandle(hFile);

	BuildMenuTimer[client] = CreateTimer(60.0, InitReminder, client);

}

public Action:InitReminder(Handle:timer, any:client)
{
	if(gClientAgreed[client] == false && IsClientInGame(client) == true)
	{	
		Menu_Reminder(client);
	}
	BuildMenuTimer[client] = INVALID_HANDLE
}

public Menu_Reminder(client)
{
	new String:szTermsFile[256];
	BuildPath(Path_SM, szTermsFile, sizeof(szTermsFile), "configs/terms.txt");
	new Handle:hFile = OpenFile(szTermsFile, "rt");

	if(hFile == INVALID_HANDLE)
	{
		return;
	}

	new String:szReadData[128];

	new Handle:hMenu = CreatePanel();

	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szReadData, sizeof(szReadData)))
	{
		DrawPanelText(hMenu, szReadData);
	}

	SetPanelTitle(hMenu, "Spielregeln - Erinnerung");

	DrawPanelItem(hMenu, "Zustimmen");
	DrawPanelItem(hMenu, "Ablehnen");

	SendPanelToClient(hMenu, client, Menu_Handler, 30);

	CloseHandle(hMenu);

	CloseHandle(hFile);

	ReminderMenuTimer[client] = CreateTimer(30.0, InitWarning, client);

}

public Action:InitWarning(Handle:timer, any:client)
{
	if(gClientAgreed[client] == false && IsClientInGame(client) == true)
	{	
		Menu_Warning(client);
	}
	ReminderMenuTimer[client] = INVALID_HANDLE
}

public Menu_Warning(client)
{
	new String:szTermsFile[256];
	BuildPath(Path_SM, szTermsFile, sizeof(szTermsFile), "configs/termswarning.txt");
	new Handle:hFile = OpenFile(szTermsFile, "rt");

	if(hFile == INVALID_HANDLE)
	{
		return;
	}

	new String:szReadData[128];

	new Handle:hMenu = CreatePanel();

	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szReadData, sizeof(szReadData)))
	{
		DrawPanelText(hMenu, szReadData);
	}

	SetPanelTitle(hMenu, "Spielregeln - Warnung");

	DrawPanelItem(hMenu, "Zustimmen");
	DrawPanelItem(hMenu, "Ablehnen");

	SendPanelToClient(hMenu, client, Menu_Handler, 15);

	CloseHandle(hMenu);

	CloseHandle(hFile);

	WarningMenuTimer[client] = CreateTimer(15.0, InitKick, client);

}

public Action:InitKick(Handle:timer, any:client)
{
	if(gClientAgreed[client] == false && IsClientInGame(client) == true)
	{	
		KickClient(client, "Du hast den Regeln nicht zugestimmt!");
	}
	WarningMenuTimer[client] = INVALID_HANDLE	
}

public Menu_Handler(Handle:hMenu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			PrintToChat(param1, "\x04Danke, dass Du unsere Regeln akzeptiert hast. Bitte halte Dich auch daran!");
			gClientAgreed[param1] = true;
		}
		else if(param2 == 2)
		{
			KickClient(param1, "Du hast die Regeln nicht akzeptiert!");
		}
	}
}