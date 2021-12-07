#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>

#define VERSION "1.8"

new String:Incoming[MAXPLAYERS+1][64];

new bool:IsBossSelected[MAXPLAYERS+1];

new g_NextHale = -1;
new Handle:g_NextHaleTimer = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Boss Selection",
	description = "Allows players select their bosses by /ff2boss",
	author = "RainBolt Dash, Powerlord, SHADoW NiNE TR3S",
	version = VERSION,
};

public OnPluginStart()
{
	HookEvent("teamplay_round_start", event_round_start);
	RegConsoleCmd("ff2_boss", Command_SetMyBoss, "Set my boss");
	RegConsoleCmd("ff2boss", Command_SetMyBoss, "Set my boss");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("ff2_boss_selection");
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(2.0,Timer_FF2Panel1);
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	IsBossSelected[client]=false;
	strcopy(Incoming[client], sizeof(Incoming[]), "");
}

public OnClientDisconnect(client)
{
	if (client == g_NextHale)
	{
		KillTimer(g_NextHaleTimer);
		Timer_FF2Panel1(INVALID_HANDLE);
	}
	IsBossSelected[client]=false;
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
		if(!IsBossSelected[maxclient])
		{
			g_NextHaleTimer = CreateTimer(20.0,Timer_FF2Panel2,maxclient, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action:Timer_FF2Panel2(Handle:hTimer,any:client)
{
	if(IsVoteInProgress())
	{
		g_NextHaleTimer = CreateTimer(5.0,Timer_FF2Panel2,client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}
	Command_SetMyBoss(client,0);
	return Plugin_Continue;
}

public Action:Command_SetMyBoss(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "ff2boss_ingame_only");
		return Plugin_Handled;
	}
	
	if (!CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "ff2boss_noaccess");
		return Plugin_Handled;
	}
	
	decl String:spclName[64];
	decl Handle:BossKV;
	
	if(args)
	{
		new String:bossName[64];
		GetCmdArgString(bossName, sizeof(bossName));
		for (new i = 0; (BossKV=FF2_GetSpecialKV(i,true)); i++)
		{
			if (KvGetNum(BossKV, "blocked",0)) continue;
			KvGetString(BossKV, "name", spclName, sizeof(spclName));

			if(StrContains(bossName, spclName, false)!=-1)
			{
				IsBossSelected[client]=true;
				strcopy(Incoming[client], sizeof(Incoming[]), spclName);
				CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossselected", spclName);
				return Plugin_Handled;
			}
			
			KvGetString(BossKV, "filename", spclName, sizeof(spclName));
			if(StrContains(bossName, spclName, false)!=-1)
			{
				IsBossSelected[client]=true;
				KvGetString(BossKV, "name", spclName, sizeof(spclName));
				strcopy(Incoming[client], sizeof(Incoming[]), spclName);
				CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossselected", spclName);
				return Plugin_Handled;
			}	
		}
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossnotfound");
		return Plugin_Handled;
	}	
	
	new Handle:dMenu = CreateMenu(Command_SetMyBossH);
	SetMenuTitle(dMenu, "%t","ff2boss_title");
	
	new String:s[256];
	Format(s, sizeof(s), "%t", "ff2boss_random_option");
	AddMenuItem(dMenu, "Random Boss", s);
	
	for (new i = 0; (BossKV=FF2_GetSpecialKV(i,true)); i++)
	{
		if (KvGetNum(BossKV, "blocked",0)) continue;
		KvGetString(BossKV, "name", spclName, 64);
		AddMenuItem(dMenu,spclName,spclName);
		
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
			CloseHandle(menu);
		}
		
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
				{
					IsBossSelected[param1]=true;
					Incoming[param1] = "";
					CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_randomboss", Incoming[param1]);
				}
				default:
				{
					IsBossSelected[param1]=true;
					GetMenuItem(menu, param2, Incoming[param1], sizeof(Incoming[]));
					CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_bossselected", Incoming[param1]);
				}
			}
		}
	}
}

public Action:FF2_OnSpecialSelected(boss, &SpecialNum, String:SpecialName[])
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if (!boss && !StrEqual(Incoming[client], ""))
	{
		IsBossSelected[client]=false;
		strcopy(SpecialName, sizeof(Incoming[]), Incoming[client]);
		Incoming[client] = "";
		return Plugin_Changed;
	}
	return Plugin_Continue;
}