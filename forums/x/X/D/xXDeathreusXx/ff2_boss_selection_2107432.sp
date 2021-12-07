#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>

#define VERSION "1.8"

new String:Incoming[MAXPLAYERS+1][64];
new Handle:cvarAdminOnly;
new bool:bAdminOnly;
new Handle:cvarAuto;
new bool:bAuto;
new Handle:cvarAdminFlag;
new sAdmin;

new g_NextHale = -1;
new Handle:g_NextHaleTimer = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Boss Selection",
	description = "Allows players select their bosses by /ff2boss",
	author = "RainBolt Dash and Powerlord, small edit by Deatherus",
	version = VERSION,
};

public OnPluginStart()
{
	cvarAdminOnly = CreateConVar("ff2_boss_foradmins", "0", "Only admins with the designated flag in ff2_boss_flag can use it. 1=Yes 0=No", FCVAR_PLUGIN);
	cvarAuto = CreateConVar("ff2_boss_auto", "1", "Automatically display the menu to players? 1=Yes 0=No", FCVAR_PLUGIN);
	cvarAdminFlag = CreateConVar("ff2_boss_flag", "a", "What flag defines an admin who can use this if ff2_boss_foradmins is 1?", FCVAR_PLUGIN);
	HookEvent("teamplay_round_start", event_round_start);
	RegConsoleCmd("ff2_boss", Command_SetMyBoss, "Set my boss");
	RegConsoleCmd("ff2boss", Command_SetMyBoss, "Set my boss");
	HookConVarChange(cvarAdminOnly, CvarChange);
	HookConVarChange(cvarAuto, CvarChange);
	HookConVarChange(cvarAdminFlag, CvarChange);
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("ff2_boss_selection");
}

/*
public OnMapStart()
{
	for (new i = 0; i <= MaxClients; i++)
		strcopy(Incoming[i], sizeof(Incoming[]), "");
		//Incoming[i] = -1;
		
}
*/

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarAdminOnly)
		bAdminOnly = bool:StringToInt(newValue);
	if (convar == cvarAuto)
		bAuto = bool:StringToInt(newValue);
	if (convar == cvarAdminFlag)
		sAdmin = StringToInt(newValue);
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if((bAuto)==true)
		CreateTimer(2.0,Timer_FF2Panel1);
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	strcopy(Incoming[client], sizeof(Incoming[]), "");
	//Incoming[client] = -1;
}

public OnClientDisconnect(client)
{
	if (client == g_NextHale)
	{
		KillTimer(g_NextHaleTimer);
		Timer_FF2Panel1(INVALID_HANDLE);
	}
	
	strcopy(Incoming[client], sizeof(Incoming[]), "");
}

public Action:Timer_FF2Panel1(Handle:hTimer)
{
	new maxclient=1;
	new maxpoints=FF2_GetQueuePoints(1);
	decl points;
	for(new client=2; client <= MaxClients; client++)
		if (FF2_GetBossIndex(client)==-1)
		{
			points = FF2_GetQueuePoints(client);
			if (points>maxpoints)
			{
				maxclient=client;
				maxpoints=points;
			}
		}
		
	if (CheckCommandAccess(maxclient, "ff2_boss", 0, true))
	{
		g_NextHaleTimer = CreateTimer(5.0,Timer_FF2Panel2,maxclient, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:Timer_FF2Panel2(Handle:hTimer,any:client)
{
	Command_SetMyBoss(client,0);
	return Plugin_Continue;
}


public Action:Command_SetMyBoss(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if ((bAdminOnly)==true)
	{
		new AdminId:admin = GetUserAdmin(client);
		if((admin == INVALID_ADMIN_ID) || !GetAdminFlag(admin, GetConVarInt(sAdmin)))
			return Plugin_Continue;
		ReplyToCommand(client, "%t", "No Access");
		return Plugin_Handled;
	}
	
	decl String:Special_Name[64];
	decl Handle:BossKV;
	new Handle:dMenu = CreateMenu(Command_SetMyBossH);
	SetMenuTitle(dMenu, "%t","ff2boss_selected");
	for (new i = 0; (BossKV=FF2_GetSpecialKV(i,true)); i++)
	{
		if (KvGetNum(BossKV, "blocked",0)) continue;
		KvGetString(BossKV, "name", Special_Name, 64);
		AddMenuItem(dMenu,Special_Name,Special_Name);
	}
	SetMenuExitButton(dMenu, true);
	DisplayMenu(dMenu, client, 20);
	return Plugin_Handled;
}


public Command_SetMyBossH(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			// No more handle leaks!
			CloseHandle(menu);
		}
		
		case MenuAction_Select:
		{
			GetMenuItem(menu, param2, Incoming[param1], sizeof(Incoming[]));
			ReplyToCommand(param1, "[FF2] Set your boss to %s", Incoming[param1]);
		}
	}
}

public Action:FF2_OnSpecialSelected( index, &SpecialNum, String:SpecialName[])
{
	new client=GetClientOfUserId(FF2_GetBossUserId(index));
	if (!index && !StrEqual(Incoming[client], ""))
	{
		strcopy(SpecialName, sizeof(Incoming[]), Incoming[client]);
		Incoming[client] = "";
		return Plugin_Changed;
	}
	return Plugin_Continue;
}