#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>

new String:Incoming[MAXPLAYERS+1][64];
new Handle:cvarAdminOnly;
new bool:bAdminOnly;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Boss Selection",
	description = "Allows players select their bosses by /ff2boss",
	author = "RainBolt Dash",
};

public OnPluginStart()
{
	cvarAdminOnly = CreateConVar("ff2_boss_foradmins", "0", "Only admins with Generic flag can use it", FCVAR_PLUGIN);
	HookEvent("teamplay_round_start", event_round_start);
	RegConsoleCmd("ff2_boss", Command_SetMyBoss);
	RegConsoleCmd("ff2boss", Command_SetMyBoss);
	LoadTranslations("ff2_boss_selection");
}

public OnMapStart()
{
	for (new i = 0; i <= MaxClients; i++)
		strcopy(Incoming[i], 64, "");
		//Incoming[i] = -1;
		
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((bAdminOnly=GetConVarBool(cvarAdminOnly)))
		CreateTimer(2.0,Timer_FF2Panel1);
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	strcopy(Incoming[client], 64, "");
	//Incoming[client] = -1;
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
	CreateTimer(20.0,Timer_FF2Panel2,GetClientUserId(maxclient));
	return Plugin_Continue;
}

public Action:Timer_FF2Panel2(Handle:hTimer,any:userid)
{
	new client=GetClientOfUserId(userid);
	Command_SetMyBoss(client,0);
	return Plugin_Continue;
}


public Action:Command_SetMyBoss(client, args)
{
	if (bAdminOnly)
	{
		new AdminId:admin = GetUserAdmin(client);
		if((admin == INVALID_ADMIN_ID) || !GetAdminFlag(admin, Admin_Generic))
			return Plugin_Continue;
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