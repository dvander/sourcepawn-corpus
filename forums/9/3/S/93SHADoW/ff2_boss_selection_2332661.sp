#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>

#define FF2BOSS_VERSION "1.10"

new String:Incoming[MAXPLAYERS+1][64];
new bool:IsBossSelected[MAXPLAYERS+1];
new nextBoss = -1;
new Float:FindNextBossAt;
new Float:ShowBossPanelAt[MAXPLAYERS+1];
#define INACTIVE 100000000.0

public Plugin:myinfo = {
	name = "Freak Fortress 2: Boss Selection",
	description = "Allows players select their bosses by /ff2boss",
	author = "RainBolt Dash, Powerlord, SHADoW NiNE TR3S",
	version = FF2BOSS_VERSION,
};

public OnPluginStart()
{
	new version[3];
	FF2_GetFF2Version(version);
	if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<6)))
	{
		SetFailState("This version of FF2 Boss Selection requires at least FF2 v1.10.6!");
	}

	LogMessage("Freak Fortress 2: Boss Selection v%s Loading", FF2BOSS_VERSION);
	HookEvent("arena_round_start", Event_RoundStart);
	RegConsoleCmd("ff2_boss", Command_SetMyBoss, "Set my boss");
	RegConsoleCmd("ff2boss", Command_SetMyBoss, "Set my boss");
	RegConsoleCmd("hale_boss", Command_SetMyBoss, "Set my boss");
	RegConsoleCmd("haleboss", Command_SetMyBoss, "Set my boss");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("ff2boss.phrases");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!FF2_IsFF2Enabled())
	{
		return Plugin_Continue;
	}
	FindNextBossAt=GetEngineTime()+0.5;
	return Plugin_Continue;
}

public OnGameFrame()
{
	FF2Boss_Tick(GetEngineTime());
}

public FF2Boss_Tick(Float:gameTime)
{
	if(gameTime>=FindNextBossAt)
	{
		new NextInLine=1;
		new MaxQueuePts=FF2_GetQueuePoints(1);
		decl points;
		for(new client=2;client<=MaxClients;client++)
		{
			if (FF2_GetBossIndex(client)==-1)
			{
				points = FF2_GetQueuePoints(client);
				if (points>MaxQueuePts)
				{
					NextInLine=client;
					MaxQueuePts=points;
				}
			}
		}
		
		if (CheckCommandAccess(NextInLine, "ff2_boss", 0, true))
		{
			if(!IsBossSelected[NextInLine])
			{
				ShowBossPanelAt[NextInLine]=GetEngineTime()+9.0;
			}
		}
		FindNextBossAt=INACTIVE;
	}
	for(new client=1;client<=MaxClients;client++)
	{
		if(client<=0 || client>MaxClients)
			continue;
		if(gameTime >= ShowBossPanelAt[client])
		{
			if(IsVoteInProgress())
			{
				ShowBossPanelAt[client]=GetEngineTime()+5.0;
				return;
			}
			Command_SetMyBoss(client,0);
			ShowBossPanelAt[client]=INACTIVE;
			return;
		}
	}
}

public OnClientPutInServer(client)
{
	IsBossSelected[client]=false;
	strcopy(Incoming[client], sizeof(Incoming[]), "");
}

public OnClientDisconnect(client)
{
	if(client==nextBoss)
	{
		ShowBossPanelAt[client]=INACTIVE;
	}
	
	IsBossSelected[client]=false;
	strcopy(Incoming[client], sizeof(Incoming[]), "");
}

public Action:Command_SetMyBoss(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "ff2boss_ingame_only");
		return Plugin_Handled;
	}
	
	if(!CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "ff2boss_noaccess");
		return Plugin_Handled;
	}
	
	decl String:spclName[64];
	decl Handle:BossKV;
	
	if(args)
	{
		decl String:bossName[64];
		GetCmdArgString(bossName, sizeof(bossName));
		for (new config;(BossKV=FF2_GetSpecialKV(config,true));config++)
		{
			if (KvGetNum(BossKV, "blocked",0)) continue;
			if(KvGetNum(BossKV, "hidden",0)) continue;
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
	
	for(new config;(BossKV=FF2_GetSpecialKV(config,true));config++)
	{
		if(KvGetNum(BossKV, "blocked",0)) continue;
		if(KvGetNum(BossKV, "hidden",0)) continue;
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

public Action:FF2_OnSpecialSelected(boss, &SpecialNum, String:SpecialName[], bool:preset)
{
	if(preset)
	{
		return Plugin_Continue;
	}

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