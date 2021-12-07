#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4downtown>
#define PLUGIN_VERSION "1.4"

	
#define MENUTITLE1 "虐待僵尸排行"//a rank all the count of zomibes cilent killed on the server
#define MENUTITLE2 "击杀特感排行"//a rank all the count of SI cilent killed on the server
#define MENUTITLE3 "精准爆头排行"//a rank all the count of cilent killed with a headshot on the server
#define MENUTITLE4 "近战狂魔排行"//a rank all the count of cilent killed with a melee on the server
#define MENUTITLE5 "伤痕累累排行"//a rank all the count of damage the cilent suffered on the server
#define MENUTITLE6 "黑枪之王排行"//a rank all the count of damage  the cilent give to his teammate on the server
#define MENUTITLE7 "无耻撩妹排行"//a rank all the count of cilent killed witchs on the server
#define MENUTITLE8 "怒怼坦克排行"//a rank all the count of damage the cilent give to a tank on the server
	
new Handle:h_menuzombie;
new Handle:h_menuallpzb;
new Handle:h_menuheadst;
new Handle:h_menumeleek;
new Handle:h_menudmgtak;
new Handle:h_menuffscor;
new Handle:h_menuwitch;
new Handle:h_menutank;
new String:StatisticsPath[255];
new Handle:Statistics = INVALID_HANDLE;
new Handle:CleanSave = INVALID_HANDLE;
new bool:IsAdmin[MAXPLAYERS+1]	= {false, ...};

#define MAXINDEX 256
new sortzombie[MAXINDEX];
new sortallpz[MAXINDEX];
new sortheadshot[MAXINDEX];
new sortmeleekill[MAXINDEX];
new sortdmgtaken[MAXINDEX];
new sortffshot[MAXINDEX];
new sortwitch[MAXINDEX];
new sorttank[MAXINDEX];
new	zombie[MAXPLAYERS+1];
new	Boomer[MAXPLAYERS+1];
new	Hunter[MAXPLAYERS+1];
new	Smoker[MAXPLAYERS+1];
new	Charger[MAXPLAYERS+1];
new	Spitter[MAXPLAYERS+1]; 
new	Jockey[MAXPLAYERS+1];
new	Witch[MAXPLAYERS+1];
new	TankBlood[MAXPLAYERS+1];
new	HeadShot[MAXPLAYERS+1];
new	DmgTaken[MAXPLAYERS+1];
new ShotFriend[MAXPLAYERS+1];
new Meleekill[MAXPLAYERS+1];

new allpzsav[MAXPLAYERS+1];

#define allPZ[%1]   		Boomer[%1] + Hunter[%1] + Smoker[%1] + Charger[%1] + Spitter[%1] + Jockey[%1]

static Initialization(i)
{
	zombie[i] = 0,
	Boomer[i] = 0,
	Hunter[i] = 0,
	Smoker[i] = 0,
	Charger[i] = 0,
	Spitter[i] = 0, 
	Jockey[i] = 0,
	Witch[i] = 0,
	TankBlood[i] = 0,
	HeadShot[i] = 0,
	DmgTaken[i] = 0,
	ShotFriend[i] = 0,
	Meleekill[i] = 0;
}



public Plugin:myinfo = 
{
	name = "击杀统计排行",//Kill Statistics Rank
	author = "C_D.og",
	description = "击杀统计排行",
	version = PLUGIN_VERSION,
	url = ".............."
}


public OnPluginStart()
{   
	RegConsoleCmd("sm_rank",Menu_Rank);
	CreateConVar("sm_statistics_version", PLUGIN_VERSION, "Statistics版本号", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CleanSave	= CreateConVar("sm_CleanSave", "30","清除多少天未进游戏的非管理员玩家的存档 0-不清除", FCVAR_PLUGIN, true, 0.0);//clean the rank of cilent after X days he haven't put in server,0 disable clean.the admin immune
	
	Statistics = CreateKeyValues("Statistics");
	BuildPath(Path_SM,StatisticsPath,sizeof(StatisticsPath),"data/statistic.log");
	
	if (FileExists(StatisticsPath))
	{
		FileToKeyValues(Statistics, StatisticsPath);
	}
	else
	{
		PrintToServer("[SM] 找不到玩家记录档: %s, 将重新建立!", StatisticsPath);//rebuild cilent rank
		KeyValuesToFile(Statistics, StatisticsPath);
	}
	//清理档案clean the rank file
	CreateTimer(1.0, CleanSaveFile);
	
	HookEvent("round_start", event_RoundStart);
	HookEvent("round_end", event_RoundEnd);
	HookEvent("player_left_start_area", eventPlayerLeftStart);
	HookEvent("player_hurt", Event_player_hurt);
	HookEvent("player_death",Event_playerdeath);//特感和witch-SI and witch
	HookEvent("player_changename",Event_PlayerChangename,EventHookMode_Pre);

}

public eventPlayerLeftStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("\x05【提示】\x01服务器已开启\x03总击杀排行统计\x01(输入\x04!rank\x01查看)");//announce the command to cilent to open the rank
}

public Event_player_hurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));//被攻击victim
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));//攻击方attacker
	if( 0 < victim <= MaxClients && IsClientInGame(victim) && 0 < attacker <=MaxClients && IsClientInGame(attacker)) 
	{
		if(GetClientTeam(attacker) == GetClientTeam(victim) && GetClientTeam(victim) != 3 && attacker != victim)
			ShotFriend[attacker] += GetEventInt(event, "dmg_health");
	}
}

public OnEntityCreated(entity, const String:classname[])
{
    if (entity <= 0 || entity > 2048) return;
    SDKHook(entity, SDKHook_TraceAttack, SDK_TraceAttack);
}

public Action:SDK_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2) return Plugin_Continue; 
	if (victim <= MaxClients || victim > 2048 || !IsValidEdict(victim)) return Plugin_Continue; 
	if (hitgroup == 1) ++HeadShot[attacker];
	return Plugin_Continue;
}  

public OnClientDisconnect(Client)
{
	if(!IsFakeClient(Client))
	{
		savedata(Client);
		Initialization(Client);
	}
}

public OnClientPostAdminCheck(Client)
{
	if(!IsFakeClient(Client))
	{
		Initialization(Client);
		new AdminId:admin = GetUserAdmin(Client);
		if(admin != INVALID_ADMIN_ID)
			IsAdmin[Client] = true;
	}
}

/* 玩家更改名字*///when client change his name
public Action:Event_PlayerChangename(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:oldname[256];
	decl String:newname[256];
	GetEventString(event, "oldname", oldname, sizeof(oldname));
	GetEventString(event, "newname", newname, sizeof(newname));
	//Initialization(target);
	/* 读取玩家 *///load cilent save rank 
	decl String:names[MAX_NAME_LENGTH]="";
	GetClientName(target, names, sizeof(names));
	KvJumpToKey(Statistics, names, false);

	KvGoBack(Statistics);
	return Plugin_Continue;
}

public Event_playerdeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));	


	if(0 < killer <=MaxClients && IsClientInGame(killer) && GetClientTeam(killer) == 2)
	{
		decl String:commonbuffer[48]; 
		new commonent = GetEventInt(event, "entityid");
		GetEntityNetClass(commonent, commonbuffer, sizeof(commonbuffer));
		if(StrEqual(commonbuffer,"Witch"))
			++Witch[killer];
		if(0 < victim <=MaxClients && IsClientInGame(victim))
		{
			new iClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
			switch(iClass)
			{
				case 1: ++Smoker[killer];//smoker	
				case 2: ++Boomer[killer]; //boomer
				case 3: ++Hunter[killer];//hunter
				case 4: ++Spitter[killer];//spitter
				case 5: ++Jockey[killer];//jockey
				case 6: ++Charger[killer]; //charger
			}
		}
	}
}

//round start 进行排行来让玩家看到上一章节的情况, 刚开始的时候会人数不足需要提示Ranking to allow players to see the last chapter of the situation, at the beginning of the lack of numbers need to be prompted

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	KvGotoFirstSubKey(Statistics);
	new statsEntries = 1; //人数统计cilent statistics
	new statsChecked = 0;
	while (KvGotoNextKey(Statistics))
		statsEntries++;
	KvRewind(Statistics);
	//如果人数小于2则无法排行.提示给排行函数一个信息.来正常化前期排行If the number is less than 2, it cannot be ranked. Prompt for a message to the ranking function. To normalize the early ranks

	KvGotoFirstSubKey(Statistics);
	decl String:rankname[statsEntries][65];
	decl sortarray[statsEntries];

	
	while (statsChecked < statsEntries)
	{
		sortarray[statsChecked] = statsChecked;
		KvGetSectionName(Statistics, rankname[statsChecked], 65); //复制名字copy name
		sortzombie[statsChecked] = KvGetNum(Statistics,"zombie",0);
		sortallpz[statsChecked]  =  KvGetNum(Statistics,"allpz",0);
		sortheadshot[statsChecked] = KvGetNum(Statistics,"headshot",0);
		sortmeleekill[statsChecked] = KvGetNum(Statistics,"kmelee",0);
		sortdmgtaken[statsChecked] = KvGetNum(Statistics,"dmgtaken",0);
		sortffshot[statsChecked] = KvGetNum(Statistics,"ffs",0);
		sortwitch[statsChecked]  = KvGetNum(Statistics,"witch",0);
		sorttank[statsChecked]  = KvGetNum(Statistics,"tankblood",0);
		statsChecked++;
		KvGotoNextKey(Statistics);
	}
	KvRewind(Statistics);

	decl String:minfo[64];
	SortCustom1D(sortarray,statsEntries,SortFuncBack1);
	h_menuzombie = CreateMenu(allhandlement);
	SetMenuTitle(h_menuzombie,MENUTITLE1);
	for(new i = 0 ; i < statsEntries; i++)
	{
		Format(minfo,64,"No.%d %s (%d)",i+1,rankname[sortarray[i]],sortzombie[sortarray[i]]);
		AddMenuItem(h_menuzombie,"info",minfo,ITEMDRAW_DISABLED);
	}
	SortCustom1D(sortarray,statsEntries,SortFuncBack2);
	h_menuallpzb = CreateMenu(allhandlement);
	SetMenuTitle(h_menuallpzb,MENUTITLE2);
	for(new i = 0 ; i < statsEntries; i++)
	{
		Format(minfo,64,"No.%d %s (%d)",i+1,rankname[sortarray[i]],sortallpz[sortarray[i]]);
		AddMenuItem(h_menuallpzb,"info",minfo,ITEMDRAW_DISABLED);
	}
	SortCustom1D(sortarray,statsEntries,SortFuncBack3);
	h_menuheadst = CreateMenu(allhandlement);
	SetMenuTitle(h_menuheadst,MENUTITLE3);
	for(new i = 0 ; i < statsEntries; i++)
	{
		Format(minfo,64,"No.%d %s (%d)",i+1,rankname[sortarray[i]],sortheadshot[sortarray[i]]);
		AddMenuItem(h_menuheadst,"info",minfo,ITEMDRAW_DISABLED);
	}
	SortCustom1D(sortarray,statsEntries,SortFuncBack4);
	h_menumeleek = CreateMenu(allhandlement);
	SetMenuTitle(h_menumeleek,MENUTITLE4);
	for(new i = 0 ; i < statsEntries; i++)
	{
		Format(minfo,64,"No.%d %s (%d)",i+1,rankname[sortarray[i]],sortmeleekill[sortarray[i]]);
		AddMenuItem(h_menumeleek,"info",minfo,ITEMDRAW_DISABLED);
	}
	SortCustom1D(sortarray,statsEntries,SortFuncBack5);
	h_menudmgtak = CreateMenu(allhandlement);
	SetMenuTitle(h_menudmgtak,MENUTITLE5);
	for(new i = 0 ; i < statsEntries; i++)
	{
		Format(minfo,64,"No.%d %s (%d)",i+1,rankname[sortarray[i]],sortdmgtaken[sortarray[i]]);
		AddMenuItem(h_menudmgtak,"info",minfo,ITEMDRAW_DISABLED);
	}
	SortCustom1D(sortarray,statsEntries,SortFuncBack6);
	h_menuffscor = CreateMenu(allhandlement);
	SetMenuTitle(h_menuffscor,MENUTITLE6);
	for(new i = 0 ; i < statsEntries; i++)
	{
		Format(minfo,64,"No.%d %s (%d)",i+1,rankname[sortarray[i]],sortffshot[sortarray[i]]);
		AddMenuItem(h_menuffscor,"info",minfo,ITEMDRAW_DISABLED);
	}
	SortCustom1D(sortarray,statsEntries,SortFuncBack7);
	h_menuwitch = CreateMenu(allhandlement);
	SetMenuTitle(h_menuwitch,MENUTITLE7);
	for(new i = 0 ; i < statsEntries; i++)
	{
		Format(minfo,64,"No.%d %s (%d)",i+1,rankname[sortarray[i]],sortwitch[sortarray[i]]);
		AddMenuItem(h_menuwitch,"info",minfo,ITEMDRAW_DISABLED);
	}
	SortCustom1D(sortarray,statsEntries,SortFuncBack8);
	h_menutank = CreateMenu(allhandlement);
	SetMenuTitle(h_menutank,MENUTITLE8);
	for(new i = 0 ; i < statsEntries; i++)
	{
		Format(minfo,64,"No.%d %s (%d)",i+1,rankname[sortarray[i]],sorttank[sortarray[i]]);
		AddMenuItem(h_menutank,"info",minfo,ITEMDRAW_DISABLED);
	}
	AddMenuItem(h_menuzombie, "back", "返回主菜单");//back to main menu
	AddMenuItem(h_menuallpzb, "back", "返回主菜单");
	AddMenuItem(h_menuheadst, "back", "返回主菜单");
	AddMenuItem(h_menumeleek, "back", "返回主菜单");
	AddMenuItem(h_menudmgtak, "back", "返回主菜单");
	AddMenuItem(h_menuffscor, "back", "返回主菜单");
	AddMenuItem(h_menuwitch,  "back", "返回主菜单");
	AddMenuItem(h_menutank,   "back", "返回主菜单");
}
public allhandlement(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select)
	{	
		decl String:item[16];
		GetMenuItem(menu, param, item, sizeof(item));
		if(StrEqual(item, "back"))
		{
			MenuFunc_Rank(Client);
		}
	}
}

public SortFuncBack1(elem1, elem2, const array[], Handle:hndl)
{
	if(sortzombie[elem1] > sortzombie[elem2]) return -1; 
	else if(sortzombie[elem1]<sortzombie[elem2]) return 1; 
	else return 0;
}
public SortFuncBack2(elem1, elem2, const array[], Handle:hndl)
{
	if(sortallpz[elem1] > sortallpz[elem2]) return -1; 
	else if(sortallpz[elem1]<sortallpz[elem2]) return 1; 
	else return 0;
}
public SortFuncBack3(elem1, elem2, const array[], Handle:hndl)
{
	if(sortheadshot[elem1] > sortheadshot[elem2]) return -1; 
	else if(sortheadshot[elem1]<sortheadshot[elem2]) return 1; 
	else return 0;
}
public SortFuncBack4(elem1, elem2, const array[], Handle:hndl)
{
	if(sortmeleekill[elem1] > sortmeleekill[elem2]) return -1; 
	else if(sortmeleekill[elem1]<sortmeleekill[elem2]) return 1; 
	else return 0;
}
public SortFuncBack5(elem1, elem2, const array[], Handle:hndl)
{
	if(sortdmgtaken[elem1] > sortdmgtaken[elem2]) return -1; 
	else if(sortdmgtaken[elem1]<sortdmgtaken[elem2]) return 1; 
	else return 0;
}
public SortFuncBack6(elem1, elem2, const array[], Handle:hndl)
{
	if(sortffshot[elem1] > sortffshot[elem2]) return -1; 
	else if(sortffshot[elem1]<sortffshot[elem2]) return 1; 
	else return 0;
}
public SortFuncBack7(elem1, elem2, const array[], Handle:hndl)
{
	if(sortwitch[elem1] > sortwitch[elem2]) return -1; 
	else if(sortwitch[elem1]<sortwitch[elem2]) return 1; 
	else return 0;
}
public SortFuncBack8(elem1, elem2, const array[], Handle:hndl)
{
	if(sorttank[elem1] > sorttank[elem2]) return -1; 
	else if(sorttank[elem1]<sorttank[elem2]) return 1; 
	else return 0;
}
public event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new Client = 1; Client <= MaxClients; Client++)
	{
		if(!IsClientInGame(Client) ||IsFakeClient(Client) || GetClientTeam(Client) !=2) return;
		savedata(Client);
	}
	CloseHandle(h_menuzombie);
	CloseHandle(h_menuallpzb);
	CloseHandle(h_menuheadst);
	CloseHandle(h_menumeleek);
	CloseHandle(h_menudmgtak);
	CloseHandle(h_menuffscor);
	CloseHandle(h_menuwitch);
	CloseHandle(h_menutank);
}


//**************************************************存储save rank*************************************************************************
savedata(Client)
{
	decl String:names[MAX_NAME_LENGTH];
	GetClientName(Client,names,sizeof(names));	
	KvJumpToKey(Statistics,names,true);	
	zombie[Client] = KvGetNum(Statistics,"zombie",0);
	zombie[Client] += GetEntProp(Client, Prop_Send, "m_checkpointZombieKills");
	KvSetNum(Statistics,"zombie",zombie[Client]);

	allpzsav[Client] = KvGetNum(Statistics,"allpz",0);
	allpzsav[Client] += allPZ[Client];
	KvSetNum(Statistics,"allpz",allpzsav[Client]);

	Witch[Client] += KvGetNum(Statistics,"witch",0);
	KvSetNum(Statistics,"witch",Witch[Client]);

	TankBlood[Client]  = KvGetNum(Statistics,"tankblood",0);
	TankBlood[Client] += GetEntProp(Client, Prop_Send, "m_checkpointDamageToTank");
	KvSetNum(Statistics,"tankblood",TankBlood[Client]);

	HeadShot[Client]  += KvGetNum(Statistics,"headshot",0);
	KvSetNum(Statistics,"headshot",HeadShot[Client]);


	DmgTaken[Client] = KvGetNum(Statistics,"dmgtaken",0);
	DmgTaken[Client] += GetEntProp(Client, Prop_Send, "m_checkpointDamageTaken");
	KvSetNum(Statistics,"dmgtaken",DmgTaken[Client]);
	
	Meleekill[Client] = KvGetNum(Statistics,"kmelee",0);
	Meleekill[Client] += GetEntProp(Client, Prop_Send, "m_checkpointMeleeKills");
	KvSetNum(Statistics,"kmelee",Meleekill[Client]);

	ShotFriend[Client] += KvGetNum(Statistics,"ffs",0);
	KvSetNum(Statistics,"ffs",ShotFriend[Client]);
	
	decl String:DisconnectDate[128] = "";
	if(IsAdmin[Client])
		FormatTime(DisconnectDate, sizeof(DisconnectDate), "%j:1-%Y/%m/%d %H:%M:%S");
	else
		FormatTime(DisconnectDate, sizeof(DisconnectDate), "%j:0-%Y/%m/%d %H:%M:%S");

	KvSetString(Statistics,"DATE", DisconnectDate);

	KvRewind(Statistics);
	KeyValuesToFile(Statistics,StatisticsPath);
}



//******************************************************************************************************
//清理档案clean rank
public Action:CleanSaveFile(Handle:timer)
{
	decl String:section[256];
	decl String:curDayStr[8] = "";
	decl String:curYearStr[8] = "";

	FormatTime(curDayStr,sizeof(curDayStr),"%j");
	FormatTime(curYearStr,sizeof(curYearStr),"%Y");

	new curDay	= StringToInt(curDayStr);
	new curYear	= StringToInt(curYearStr);
	new delDays	= GetConVarInt(CleanSave);


	KvGotoFirstSubKey(Statistics);

	new statsEntries = 1;
	new statsChecked = 0;

	while (KvGotoNextKey(Statistics))
	{
		statsEntries++;
	}
	PrintToServer("[SM] 今天是%d年的第%d天,存档总计:%d个,清理进行中...", curYear, curDay, statsEntries);//Today is year %d day%d day, rank total:%d, clean in progress ...
	KvRewind(Statistics);
	KvGotoFirstSubKey(Statistics);
	while (statsChecked < statsEntries)
	{
		statsChecked++;

		KvGetSectionName(Statistics, section, 256);

		decl String:lastConnStr[128] = "";
		KvGetString(Statistics,"DATE",lastConnStr,sizeof(lastConnStr),"Failed");

		if (!StrEqual(lastConnStr, "Failed", false)) 
		{
			decl String:lastDayStr[8], String:IsAdminStr[8], String:lastYearStr[8];

			lastDayStr[0] = lastConnStr[0];
			lastDayStr[1] = lastConnStr[1];
			lastDayStr[2] = lastConnStr[2];
			new lastDay	= StringToInt(lastDayStr);

			IsAdminStr[0] = lastConnStr[4];
			new isAdmin = StringToInt(IsAdminStr);

			lastYearStr[0] = lastConnStr[6];
			lastYearStr[1] = lastConnStr[7];
			lastYearStr[2] = lastConnStr[8];
			lastYearStr[3] = lastConnStr[9];
			new lastYear = StringToInt(lastYearStr);

			new daysSinceVisit = (curDay+((curYear-lastYear)*365)) - lastDay;
			PrintToServer("%s, admin:%d, date:%s, %d天未上线", section, isAdmin, lastConnStr, daysSinceVisit);//%s, admin:%d, date:%s,%d days not online
			

			if (daysSinceVisit > delDays-1 && delDays != 0)
			{
				if (isAdmin==1)
				{
					KvGotoNextKey(Statistics);
					PrintToServer("[SM] 略过删除 %s 的存档! (原因: 管理员)", section);//Skip rank for%s! (Reason: Administrator)
				}
				else
				{
					KvDeleteThis(Statistics);
					PrintToServer("[SM] 删除 %s 的存档! (原因: %d天未进入游戏)", section, daysSinceVisit);//Delete rank for%s! (Reason: No game entered in%d days)
				}
			}
			else KvGotoNextKey(Statistics);
		}
		else KvDeleteThis(Statistics);
	}

	KvRewind(Statistics);
	KeyValuesToFile(Statistics, StatisticsPath);
	return Plugin_Handled;
}

public Action:Menu_Rank(Client,args)
{
	MenuFunc_Rank(Client);
	return Plugin_Handled;
}


//排行主菜单Rank main Menu
public Action:MenuFunc_Rank(Client)
{
	new Handle:menu = CreatePanel();
	decl String:line[256];
	new String:Chose[4];
	Chose = (IsAdmin[Client])?"是":"否";//yes : no
	Format(line, sizeof(line),"☆当前统计\n小僵尸击杀:%d  近战击杀:%d  爆头击杀:%d  \n黑枪伤害:%d          受到伤害:%d  \nBoomer:%d   Hunter:%d   Smoker:%d   \nSpitter:%d   Charger:%d   Jockey:%d   \n玷污Witch妹纸:%d   \n对坦克造成的伤害:%d   \n☆历史统计",
	//☆ Current statistics \ Zombie Kill:%d melee Kill:%d hit head kill:%d \ Shot damage:%d damage:%d \nboomer:%d hunter:%d smoker:%d \nspitter:%d Charge r:%d jockey:%d Tainted Witch paper:%d damage to Tanks:%d \n☆ historical statistics
	GetEntProp(Client, Prop_Send, "m_checkpointZombieKills"),GetEntProp(Client, Prop_Send, "m_checkpointMeleeKills"),HeadShot[Client],ShotFriend[Client],GetEntProp(Client, Prop_Send, "m_checkpointDamageTaken"),Boomer[Client],Hunter[Client],Smoker[Client],Spitter[Client],Charger[Client],Jockey[Client],Witch[Client],GetEntProp(Client, Prop_Send, "m_checkpointDamageToTank"));
	SetPanelTitle(menu, line);
	DrawPanelItem(menu, MENUTITLE1); //统计分数后排行a rank all the count of SI cilent killed on the server
	DrawPanelItem(menu, MENUTITLE2); //特感击杀排行a rank all the count of cilent killed with a headshot on the server
	DrawPanelItem(menu, MENUTITLE3); //爆头率排行a rank all the count of cilent killed with a melee on the server
	DrawPanelItem(menu, MENUTITLE4); //近战排行a rank all the count of damage the cilent suffered on the server
	DrawPanelItem(menu, MENUTITLE5); //受到伤害排行a rank all the count of damage the cilent suffered on the server
	DrawPanelItem(menu, MENUTITLE6); //黑枪排行a rank all the count of damage  the cilent give to his teammate on the server
	DrawPanelItem(menu, MENUTITLE7); //女巫击杀排行a rank all the count of cilent killed witchs on the server
	DrawPanelItem(menu, MENUTITLE8); //坦克血量排行a rank all the count of damage the cilent give to a tank on the server
	FormatTime(line, sizeof(line), "%H:%M:%S");
	Format(line,sizeof(line),"当前时间:[%s]",line);//time now
	DrawPanelText(menu,line);
	DrawPanelItem(menu,"关闭", ITEMDRAW_DISABLED);//exit

	SendPanelToClient(menu, Client, MenuHandler_Rank, MENU_TIME_FOREVER);
	CloseHandle(menu);
	return Plugin_Handled;
}

public MenuHandler_Rank(Handle:menu, MenuAction:action, Client, param)
{
	if (action == MenuAction_Select)
	{
		MenuFunc_RankDisplay(Client,param);
	}
}


//子菜单,每个排行一个列表submenus, each rank a list
public Action:MenuFunc_RankDisplay(Client,indexs)
{
	switch(indexs)
	{
		case 1:DisplayMenu(h_menuzombie,Client,20);
		case 2:DisplayMenu(h_menuallpzb,Client,20);
		case 3:DisplayMenu(h_menuheadst,Client,20);
		case 4:DisplayMenu(h_menumeleek,Client,20);
		case 5:DisplayMenu(h_menudmgtak,Client,20);
		case 6:DisplayMenu(h_menuffscor,Client,20);
		case 7:DisplayMenu(h_menuwitch,Client ,20);
		case 8:DisplayMenu(h_menutank,Client  ,20);
	}
}
