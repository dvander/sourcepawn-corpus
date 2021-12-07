#pragma semicolon 1
#pragma dynamic 65536
#define REQUIRE_PLUGIN
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <ircrelay>
#include <atac>
#define REQUIRE_EXTENSIONS
#include <sdktools>
#undef REQUIRE_EXTENSIONS

#define YELLOW 0x01
#define TEAMCOLOR 0X03
#define GREEN 0x04
#define ATAC_VERSION "2.0.0"

public Plugin:myinfo =
{
	name = "Advanced Team Attack Control",
	author = "FlyingMongoose",
	description = "Advanced Team Attack Control: Source",
	version = ATAC_VERSION,
	url = "http://www.steamfriends.com/"
};

new Handle:cvarATACEnabled;
new Handle:cvarATACAdminImmunity;
new Handle:cvarATACNextSpawnPunishDelay;
new Handle:cvarATACAction;
new Handle:cvarATACTACount;
new Handle:cvarATACTKCount;
new Handle:cvarATACKarmaCount;
new Handle:cvarATACKarmaKills;
new Handle:cvarATACBanType;
new Handle:cvarATACBanTime;
new Handle:cvarATACTakeNextAction;
new Handle:cvarATACKickLimit;
new Handle:cvarATACBanLimit;
new Handle:cvarATACIgnoreBots;
new Handle:cvarATACVerbose;
new Handle:cvarATACHLXEnabled;
new Handle:cvarATACIrcRelay;

new bool:g_isHooked;

new String:atacFile[PLATFORM_MAX_PATH];
new Handle:atacKV;

new Handle:atacMenu;
new Handle:atacImmuneMenu;

new bool:g_ircRelay;

new g_DamageTime[MAXPLAYERS+1][MAXPLAYERS+1];

new bool:killed[MAXPLAYERS+1][MAXPLAYERS+1];
new bool:attacked[MAXPLAYERS+1][MAXPLAYERS+1];

new taCounter[MAXPLAYERS+1];
new tkCounter[MAXPLAYERS+1];
new kickCounter[MAXPLAYERS+1];
new banCounter[MAXPLAYERS+1];
new karmaCounter[MAXPLAYERS+1];

new PlayerSlots;

stock SetClientHealth(client, amount)
{
	new HPOffs = FindDataMapOffs(client,"m_iHealth");
	SetEntData(client,HPOffs,amount,true);
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("ATACGetMax",Native_ATACGetMax);
	CreateNative("ATACGetClient",Native_ATACGetClient);
	CreateNative("ATACSetClient",Native_ATACSetClient);
	CreateNative("ATACGetVerbose",Native_ATACGetVerbose);
	CreateNative("RegisterPunishment",Native_RegisterPunishment);
	CreateNative("UnregisterPunishment",Native_UnregisterPunishment);
	CreateNative("ATACGetPunishDelay",Native_ATACGetPunishDelay);

	MarkNativeAsOptional("IrcMessage");
	MarkNativeAsOptional("RegisterIrcCommand");
	MarkNativeAsOptional("IrcGetCmdArgc");
	MarkNativeAsOptional("IrcGetCmdArgv");

	return true;
}

public Native_ATACGetPunishDelay(Handle:plugin,numParams){
	return _:GetConVarInt(cvarATACNextSpawnPunishDelay);
}

public Native_ATACGetVerbose(Handle:plugin,numParams){
	return _:GetConVarInt(cvarATACVerbose);
}

public Native_UnregisterPunishment(Handle:plugin,numParams){
	decl String:itemToRemove[32];
	decl String:MenuInfo[128];
	IntToString(GetNativeCell(1),itemToRemove,sizeof(itemToRemove));
	new menuItems = GetMenuItemCount(atacMenu);
	
	for(new i = 0; i < menuItems; ++i){
		GetMenuItem(atacMenu, i, MenuInfo, sizeof(MenuInfo));
		if(strcmp(MenuInfo,itemToRemove) == 0){
			RemoveMenuItem(atacMenu, i);
		}
	}
	CloseHandle(Handle:GetNativeCell(1));
}

public Native_RegisterPunishment(Handle:plugin,numParams){
	new len1;
	GetNativeStringLength(1,len1);
	new len2;
	GetNativeStringLength(2,len2);

	decl String:ForwardName[len1+1], String:DisplayName[len2+1];
	GetNativeString(1, ForwardName, len1+1);
	GetNativeString(2, DisplayName, len2+1);

	new Handle:ATACMenuForward = CreateForward(ET_Ignore, Param_Cell, Param_Cell);

	if(ATACMenuForward != INVALID_HANDLE)
	{
		new Function:func = GetFunctionByName(plugin, ForwardName);

		if (func == INVALID_FUNCTION)
		{
			decl String:PluginName[64];
			GetPluginInfo(plugin, PlInfo_Name, PluginName, sizeof(PluginName));

			return ThrowNativeError(23,"Could not find \"%s\" in \"^s\"", ForwardName, PluginName);
		}

		if(!AddToForward(ATACMenuForward, plugin, func))
		{
			return ThrowNativeError(23,"Failed to add functions to private forward.");
		}

		IntToString(_:ATACMenuForward, ForwardName, len1+1);
		
		AddMenuItem(atacMenu,ForwardName,DisplayName);
		
	} else {
		ThrowNativeError(23,"Failed to create forward.");
	}
	return _:ATACMenuForward;
}

public Native_ATACGetMax(Handle:plugin,numParams){
	new param = GetNativeCell(1);
	switch(param){
		case 1:
			return _:GetConVarInt(cvarATACTACount);
		case 2:
			return _:GetConVarInt(cvarATACTKCount);
		case 3:
			return _:GetConVarInt(cvarATACKarmaCount);
	}
	return -1;
}

public Native_ATACGetClient(Handle:plugin,numParams){
	new param = GetNativeCell(1);
	new index = GetNativeCell(2);
	switch(param){
		case 1:
			return _:taCounter[index];
		case 2:
			return _:tkCounter[index];
		case 3:
			return _:karmaCounter[index];
	}
	return -1;
}

public Native_ATACSetClient(Handle:plugin,numParams){
	new param = GetNativeCell(1);
	new index = GetNativeCell(2);
	new value = GetNativeCell(3);
	
	new tkCount = GetConVarInt(cvarATACTKCount);
	
	if(param == 1){
		taCounter[index] = value;
		if(GetConVarInt(cvarATACTACount) > 0){
			for(new victim = 1; victim <= PlayerSlots; ++victim){
				HandleTeamAttack(victim,index);
				attacked[index][victim] = false;
				return false;
			}
		}else{
			return true;
		}
	} else if(param == 2){
		tkCounter[index] = value;
		for(new victim = 1; victim <= PlayerSlots; ++victim){
			if(killed[index][victim]){
				if(tkCount > 0 && tkCounter[index] >= tkCount){
					TKAction(index,victim);
					tkCounter[index] = 0;
					killed[index][victim] = false;
					return false;
				}else{
					killed[index][victim] = false;
					return true;
				}
			}
		}
	} else if(param == 3){
		if(tkCounter[index] > 0){
			karmaCounter[index] = value;
			return HandleKarma(index);
		}
	}
	return false;
}

new Handle:g_ATACLoaded;
new Handle:g_ATACUnloaded;

public OnPluginStart()
{
	LoadTranslations("atac.phrases");
	CreateConVar("atac_version",ATAC_VERSION, _,FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarATACEnabled = CreateConVar("atac_enabled","1","Turns ATAC On/Off and makes it respond to FF",FCVAR_PLUGIN,true,0.0,true,1.0);
	cvarATACAdminImmunity = CreateConVar("atac_immunity","1","Turns admin immunity On/Off",FCVAR_PLUGIN,true,0.0,true,1.0);
	cvarATACNextSpawnPunishDelay = CreateConVar("atac_nextspawnpunishdelay","6","Number of seconds after a spawn a punishment other than forgive/not forgive will take action",FCVAR_PLUGIN,true,3.0,true,10.0);
	cvarATACAction = CreateConVar("atac_action","1","What action is taken after TK limit is reached\n2 = ban for atac_bantime many minutes\n1 = kick.",FCVAR_PLUGIN,true,0.0,false);
	cvarATACBanType = CreateConVar("atac_bantype","0","When banning, use Steam ID or IP\n0 = Steam ID\n1 = IP",FCVAR_PLUGIN,true,0.0,true,1.0);
	cvarATACBanTime = CreateConVar("atac_bantime","60","How many minutes a player is banned for too many TKs\n0 = permanent\n>0 = number of minutes",FCVAR_PLUGIN,true,0.0,false);
	cvarATACTACount = CreateConVar("atac_talimit","10","Number of Team Attacks to equal a Team Kill\n0 = off",FCVAR_PLUGIN,true,0.0,false);
	cvarATACTKCount = CreateConVar("atac_tklimit","3","Number of Team Kills before action is taken",FCVAR_PLUGIN,true,0.0,false);
	cvarATACKarmaCount = CreateConVar("atac_maxkarma","5","Number of 'events' that will reduce tk's by 1",FCVAR_PLUGIN,true,0.0,false);
	cvarATACKarmaKills = CreateConVar("atac_karmakills","1","Amount of karma to award for a kill (disabled if 0)",FCVAR_PLUGIN,true,0.0,true,1.0);
	cvarATACTakeNextAction = CreateConVar("atac_nextaction","1","If set this will cause the plugin to take the next level of atac_action after a 'limit' is reached",FCVAR_PLUGIN,true,0.0,true,1.0);
	cvarATACKickLimit = CreateConVar("atac_kicklimit","3","Number of kicks until next level of atac_action is taken",FCVAR_PLUGIN,true,0.0,false);
	cvarATACBanLimit = CreateConVar("atac_banlimit","3","How many times a temporary ban must occur on the same SteamID/IP before bcoming permanent.",FCVAR_PLUGIN,true,0.0,false);
	cvarATACIgnoreBots = CreateConVar("atac_ignorebots","1","1 = TK/TA against bots counter, 0 = TK/TA against bots ignored",FCVAR_PLUGIN,true,0.0,true,1.0);
	cvarATACVerbose = CreateConVar("atac_verbose","1","0: No output\n1: Only show to users involved\n2: Only show to team mates.\n3: Show to team mates and admins\n4: Show to admins and users involved\n5: show to admins only\n6: Show to everyone",FCVAR_PLUGIN,true,0.0,true,6.0);
	cvarATACIrcRelay = CreateConVar("atac_ircrelay","0","Display kicks and bans to IRC Relay",FCVAR_PLUGIN,true,0.0,true,1.0);
	cvarATACHLXEnabled = CreateConVar("atac_hlxenabled","0","Enables/disables HLStatsX logging for punish/forgive.",FCVAR_PLUGIN,true,0.0,true,1.0);
	BuildPath(Path_SM,atacFile,sizeof(atacFile),"data/atac_stored.txt");
	atacKV = CreateKeyValues("atac");
	if(FileExists(atacFile)){
		FileToKeyValues(atacKV,atacFile);
	}
	AutoExecConfig(true,"atac","sourcemod");
	HookConVarChange(cvarATACEnabled,ATACEnabledChange);
	g_ATACLoaded = CreateGlobalForward("OnATACLoaded",ET_Event);
	g_ATACUnloaded = CreateGlobalForward("OnATACUnloaded",ET_Event);
	
	CreateTimer(3.0,OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer){
	PlayerSlots = GetMaxClients();
	RegConsoleCmd("sm_kickcount",Command_KickCount);
	RegConsoleCmd("sm_bancount",Command_BanCount);
	RegConsoleCmd("sm_tkcount",Command_TKCount);
	RegConsoleCmd("sm_tacount",Command_TACount);
	RegConsoleCmd("sm_tkstatus",Command_TKStatus);
	RegConsoleCmd("sm_karmahelp",Command_KarmaHelp);
	
	RegAdminCmd("sm_tkme",Command_TKMe,ADMFLAG_RCON);
	RegAdminCmd("sm_tame",Command_TAMe,ADMFLAG_RCON);
	RegAdminCmd("sm_karmame",Command_KarmaMe,ADMFLAG_RCON);
	RegAdminCmd("sm_resettk",Command_TKReset,ADMFLAG_RCON);
	RegAdminCmd("sm_resetta",Command_TAReset,ADMFLAG_RCON);
	RegAdminCmd("sm_resetkarma",Command_KarmaReset,ADMFLAG_RCON);
	
	atacMenu = CreateMenu(PunishmentMenuSelected);
	atacImmuneMenu = CreateMenu(PunishmentMenuSelected);
	SetMenuExitButton(atacMenu,false);
	SetMenuExitButton(atacImmuneMenu,false);
	CreateATACMenu();
	CreateATACImmuneMenu();
	
	Call_StartForward(g_ATACLoaded);
	Call_Finish();
}

public OnPluginEnd(){
	Call_StartForward(g_ATACUnloaded);
	Call_Finish();
}
public PrunePlayers(Handle:kv){
	KvRewind(kv);
	new RightNow = GetTime();
	if(!KvGotoFirstSubKey(kv)){
		return;
	}
	for(;;){
		new LastPlayTime = KvGetNum(kv,"time");
		new TimeDifference = RightNow - LastPlayTime;
		new ResetTime = (GetConVarInt(cvarATACBanTime) * (GetConVarInt(cvarATACBanLimit) + 1));
		new currentTime = RoundFloat(float(TimeDifference) / 60.0);
		if(currentTime >= ResetTime){
			if(KvDeleteThis(kv) < 1){
				return;
			}
		}else if(!KvGotoNextKey(kv)){
			return;
		}
	}
}

public OnMapStart()
{
	PrunePlayers(atacKV);
}

public Action:Command_KarmaReset(client,args){
	if(args < 1){
		ReplyToCommand(client,"[SM] Usage: sm_resetkarma <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1,arg,sizeof(arg));
	new target = FindTarget(client,arg);
	if(target <= 0){
		return Plugin_Handled;
	}
	GetClientName(target,arg,sizeof(arg));

	ResetKarma(target);

	ShowActivity(client, "%t","Reset Karma",arg);
	LogMessage("\"%L\" reset \"%L\"'s karma",client, target);

	return Plugin_Handled;
}

ResetKarma(client){
	karmaCounter[client] = 0;
}

public Action:Command_TAReset(client,args){
	if(args < 1){
		ReplyToCommand(client,"[SM] Usage: sm_resetta <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1,arg,sizeof(arg));
	new target = FindTarget(client,arg);
	if(target <= 0){
		return Plugin_Handled;
	}
	GetClientName(target, arg, sizeof(arg));

	ResetTA(target);

	ShowActivity(client, "%t","Reset TA", arg);
	LogMessage("\"%L\" reset \"%L\"'s team attacks", client, target);

	return Plugin_Handled;
}

ResetTA(client){
	taCounter[client] = 0;
}

public Action:Command_TKReset(client,args){
	if(args < 1){
		ReplyToCommand(client,"[SM] Usage: sm_resettk <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1,arg,sizeof(arg));
	new target = FindTarget(client,arg);
	if(target <= 0){
		return Plugin_Handled;
	}
	GetClientName(target, arg, sizeof(arg));

	ResetTK(target);

	ShowActivity(client, "%t","Reset TK", arg);
	LogMessage("\"%L\" reset \"%L\"'s team kills.", client, target);

	return Plugin_Handled;
}

ResetTK(client){
	tkCounter[client] = 0;
}

public Action:Command_TAMe(client,args){
	taCounter[client]++;
	HandleTeamAttack(client,client);
	return Plugin_Handled;
}

public Action:Command_TKMe(client,args){
	killed[client][client] = true;
	ForgiveMenu(client,client,"you");
	return Plugin_Handled;
}

public Action:Command_KarmaMe(client,args){
	karmaCounter[client]++;
	if(!HandleKarma(client)){
		PrintToChat(client,"%t","Debug Karma",karmaCounter[client],GetConVarInt(cvarATACKarmaCount));
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

StoreInfo(client){
	if(!IsFakeClient(client)){
		if(client != 0){
			decl String:SteamID[64];
			decl String:clientIP[30];
			new Time = GetTime();
			GetClientAuthString(client,SteamID,64);
			GetClientIP(client,clientIP,30,true);
			KvRewind(atacKV);
			if(GetConVarBool(cvarATACBanType)){
				if(!KvJumpToKey(atacKV,clientIP,false)){
					KvRewind(atacKV);
					KvJumpToKey(atacKV,clientIP,true);
					KvSetNum(atacKV,"karma",karmaCounter[client]);
					KvSetNum(atacKV,"ta",taCounter[client]);
					KvSetNum(atacKV,"tk",tkCounter[client]);
					KvSetNum(atacKV,"kicks",kickCounter[client]);
					KvSetNum(atacKV,"bans",banCounter[client]);
					KvSetNum(atacKV,"time",Time);
				}else{
					KvRewind(atacKV);
					KvJumpToKey(atacKV,clientIP);
					KvSetNum(atacKV,"karma",karmaCounter[client]);
					KvSetNum(atacKV,"ta",taCounter[client]);
					KvSetNum(atacKV,"tk",tkCounter[client]);
					KvSetNum(atacKV,"kicks",kickCounter[client]);
					KvSetNum(atacKV,"bans",banCounter[client]);
					new LastPlayTime = KvGetNum(atacKV,"time");
					new TimeDifference = Time - LastPlayTime;
					new ResetTime = (GetConVarInt(cvarATACBanTime) * (GetConVarInt(cvarATACBanLimit) + 1));
					new currentTime = RoundFloat(float(TimeDifference) / 60.0);
					if(currentTime < ResetTime){
						KvSetNum(atacKV,"time",LastPlayTime);
					}else{
						KvSetNum(atacKV,"time",Time);
					}
				}
			}else{
				if(!KvJumpToKey(atacKV,SteamID,false)){
					KvRewind(atacKV);
					KvJumpToKey(atacKV,SteamID,true);
					KvSetNum(atacKV,"karma",karmaCounter[client]);
					KvSetNum(atacKV,"ta",taCounter[client]);
					KvSetNum(atacKV,"tk",tkCounter[client]);
					KvSetNum(atacKV,"kicks",kickCounter[client]);
					KvSetNum(atacKV,"ban",banCounter[client]);
					KvSetNum(atacKV,"time",Time);
				}else{
					KvRewind(atacKV);
					KvJumpToKey(atacKV,SteamID);
					KvSetNum(atacKV,"karma",karmaCounter[client]);
					KvSetNum(atacKV,"ta",taCounter[client]);
					KvSetNum(atacKV,"tk",tkCounter[client]);
					KvSetNum(atacKV,"kicks",kickCounter[client]);
					KvSetNum(atacKV,"bans",banCounter[client]);
					new LastPlayTime = KvGetNum(atacKV,"time");
					new TimeDifference = Time - LastPlayTime;
					new ResetTime = (GetConVarInt(cvarATACBanTime) * (GetConVarInt(cvarATACBanLimit) + 1));
					new currentTime = RoundFloat(float(TimeDifference) / 60.0);
					if(currentTime < ResetTime){
						KvSetNum(atacKV,"time",LastPlayTime);
					}else{
						KvSetNum(atacKV,"time",Time);
					}
				}
			}
			for(new i = 1; i <= PlayerSlots; ++i){
				killed[client][i] = false;
			}
		}
	}
}

public OnClientDisconnect(client){
	StoreInfo(client);
}

public Action:Command_KarmaHelp(client,args){
	if(client != 0){
		new bool:OptionOn = GetConVarBool(cvarATACEnabled);
		if(OptionOn){
			decl String:KarmaHelpTitle[256];
			decl String:KarmaHelp1[256];
			decl String:KarmaHelp2[256];
			decl String:KarmaHelp3[256];
			decl String:KarmaExitOption[32];
			
			Format(KarmaHelpTitle,sizeof(KarmaHelpTitle),"%t","Karma Help Title");
			Format(KarmaHelp1,sizeof(KarmaHelp1),"%t","Karma Help 1");
			Format(KarmaHelp2,sizeof(KarmaHelp2),"%t","Karma Help 2",GetConVarInt(cvarATACKarmaCount));
			Format(KarmaHelp3,sizeof(KarmaHelp3),"%t","Karma Help 3",karmaCounter[client]);
			Format(KarmaExitOption,sizeof(KarmaExitOption),"0: %t","Exit Panel");
			
			new Handle:KarmaHelpPanel = CreatePanel();
			
			SetPanelTitle(KarmaHelpPanel,KarmaHelpTitle);
			DrawPanelText(KarmaHelpPanel," ");
			DrawPanelText(KarmaHelpPanel,KarmaHelp1);
			DrawPanelText(KarmaHelpPanel," ");
			DrawPanelText(KarmaHelpPanel,KarmaHelp2);
			DrawPanelText(KarmaHelpPanel," ");
			DrawPanelText(KarmaHelpPanel,KarmaHelp3);
			DrawPanelText(KarmaHelpPanel," ");
			DrawPanelText(KarmaHelpPanel,KarmaExitOption);
			SendPanelToClient(KarmaHelpPanel,client,TKStatusHandler, MENU_TIME_FOREVER);
			CloseHandle(KarmaHelpPanel);
		}
	}
}

public Action:Command_TKStatus(client,args){
	if(client != 0){
		new bool:OptionOn = GetConVarBool(cvarATACEnabled);
		if(OptionOn){
			decl String:clientName[100];
			decl String:panelTitle[255];
			decl String:panelKarmaCount[255];
			decl String:panelTACount[255];
			decl String:panelTKCount[255];
			decl String:panelKickCount[255];
			decl String:panelBanCount[255];
			decl String:panelExitOption[32];
			new Handle:TKStatusPanel = CreatePanel();

			GetClientName(client,clientName,100);
			new karmaCount = GetConVarInt(cvarATACKarmaCount);
			new taCount = GetConVarInt(cvarATACTACount);
			new tkCount = GetConVarInt(cvarATACTKCount);
			new kickCount = GetConVarInt(cvarATACKickLimit);
			new banCount = GetConVarInt(cvarATACBanLimit);
			Format(panelTitle,sizeof(panelTitle),"%t","TK Status Title",clientName);
			Format(panelKarmaCount,sizeof(panelKarmaCount),"%t","Karma Count",karmaCounter[client],karmaCount);
			Format(panelTACount,sizeof(panelTACount),"%t","TA Count",taCounter[client],taCount);
			Format(panelTKCount,sizeof(panelTKCount),"%t","TK Count",tkCounter[client],tkCount);
			Format(panelKickCount,sizeof(panelKickCount),"%t","Kick Count",kickCounter[client],kickCount);
			Format(panelBanCount,sizeof(panelBanCount),"%t","Ban Count",banCounter[client],banCount);
			Format(panelExitOption,sizeof(panelExitOption),"0: %t","Exit Panel");

			SetPanelTitle(TKStatusPanel,panelTitle);
			DrawPanelText(TKStatusPanel," ");
			DrawPanelText(TKStatusPanel,panelKarmaCount);
			DrawPanelText(TKStatusPanel,panelTACount);
			DrawPanelText(TKStatusPanel,panelTKCount);
			DrawPanelText(TKStatusPanel,panelKickCount);
			DrawPanelText(TKStatusPanel,panelBanCount);
			DrawPanelText(TKStatusPanel," ");
			DrawPanelText(TKStatusPanel,panelExitOption);

			SendPanelToClient(TKStatusPanel,client,TKStatusHandler, MENU_TIME_FOREVER);

			CloseHandle(TKStatusPanel);
		}
	}
	return Plugin_Handled;
}

public TKStatusHandler(Handle:menu, MenuAction:action, param1, param2){

}

public Action:Command_BanCount(client,args){
	if(client !=0){
		new bool:OptionOn = GetConVarBool(cvarATACEnabled);
		if(OptionOn){
			new banCount = GetConVarInt(cvarATACBanLimit);
			ReplyToCommand(client,"%c[ATAC]%c %t",GREEN,YELLOW,"Ban Count",banCounter[client],banCount);
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:Command_KickCount(client,args){
	if(client != 0){
		new bool:OptionOn = GetConVarBool(cvarATACEnabled);
		if(OptionOn){
			new kickCount = GetConVarInt(cvarATACKickLimit);
			ReplyToCommand(client,"%c[ATAC]%c %t",GREEN,YELLOW,"Kick Count",kickCounter[client],kickCount);
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:Command_TACount(client,args){
	if(client != 0){
		new bool:OptionOn = GetConVarBool(cvarATACEnabled);
		if(OptionOn){
			new taCount = GetConVarInt(cvarATACTACount);
			ReplyToCommand(client,"%c[ATAC]%c %t",GREEN,YELLOW,"TA Count",taCounter[client],taCount);
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:Command_TKCount(client,args){
	if(client != 0){
		new bool:OptionOn = GetConVarBool(cvarATACEnabled);
		if(OptionOn){
			new tkCount = GetConVarInt(cvarATACTKCount);
			ReplyToCommand(client,"%c[ATAC]%c %t",GREEN,YELLOW,"TK Count",tkCounter[client],tkCount);
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public ATACEnabledChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarInt(cvarATACEnabled) != 1){
		if(g_isHooked == true){
			UnhookEvent("player_hurt",ev_PlayerHurt);
			UnhookEvent("player_death",ev_PlayerDeath);
			g_isHooked = false;
		}
	}else if(g_isHooked == false){
		HookEvent("player_hurt",ev_PlayerHurt);
		HookEvent("player_death",ev_PlayerDeath);

		g_isHooked = true;
	}
}

public OnConfigsExecuted(){
	if(GetConVarBool(cvarATACEnabled) && !g_isHooked){ // MOD BY LAMDACORE  && !g_isHooked  // this is very important otherwise the events would be hooked again on every mapchange and that causes multiple eventcalls instead of one eventcall
		g_isHooked = true;
		HookEvent("player_hurt",ev_PlayerHurt);
		HookEvent("player_death",ev_PlayerDeath);
	}
	g_ircRelay = GetConVarBool(cvarATACIrcRelay);
}

CreateATACImmuneMenu(){
	decl String:StrForgive[100];
	decl String:StrNotForgive[100];
	Format(StrForgive,sizeof(StrForgive),"%t","Menu Forgive");
	AddMenuItem(atacImmuneMenu,"Forgive",StrForgive);
	Format(StrNotForgive,sizeof(StrNotForgive),"%t","Menu Do Not Forgive");
	AddMenuItem(atacImmuneMenu,"Punish",StrNotForgive);
}

CreateATACMenu(){
	decl String:StrForgive[100];
	decl String:StrNotForgive[100];

	Format(StrForgive,sizeof(StrForgive),"%t","Menu Forgive");
	AddMenuItem(atacMenu,"Forgive",StrForgive);

	Format(StrNotForgive,sizeof(StrNotForgive),"%t","Menu Do Not Forgive");
	AddMenuItem(atacMenu,"Punish",StrNotForgive);

}

public ev_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){
	new userid = GetEventInt(event,"userid");
	new userid2 = GetEventInt(event,"attacker");
	new victim = GetClientOfUserId(userid);
	new attacker = GetClientOfUserId(userid2);
	attacked[attacker][victim] = true;
	if(attacker != 0){
		if(GetConVarInt(cvarATACTACount) > 0){
			HandleTeamAttack(victim,attacker);
		}
	}
}

bool:HandleKarma(client){
	if(client != 0){
		new maxKarma = GetConVarInt(cvarATACKarmaCount);
		if(karmaCounter[client] >= maxKarma && tkCounter[client] > 0){
			--tkCounter[client];
			karmaCounter[client] = maxKarma;
			PrintToConsole(client,"[ATAC] %t %t","Earned Karma",karmaCounter[client],maxKarma,"Now Have TK",tkCounter[client],GetConVarInt(cvarATACTKCount));
			PrintToChat(client,"%c[ATAC]%c %t %t",GREEN,YELLOW,"Earned Karma",karmaCounter[client],maxKarma,"Now Have TK",tkCounter[client],GetConVarInt(cvarATACTKCount));
			karmaCounter[client] = 0;
			return true;
		}
		return false;
	}
	return false;
}

HandleKarmaKills(attacker,victim){
	new attackerTeam = GetClientTeam(attacker);
	new victimTeam = GetClientTeam(victim);
	if(attackerTeam != victimTeam){
		new maxKarma = GetConVarInt(cvarATACKarmaCount);
		if(maxKarma > 0 && tkCounter[attacker] > 0){
			karmaCounter[attacker] = karmaCounter[attacker] + GetConVarInt(cvarATACKarmaKills);
			if(!HandleKarma(attacker)){
				PrintToConsole(attacker,"[ATAC] %t %t","Earned Karma",karmaCounter[attacker],maxKarma,"Killing Enemy");
				PrintToChat(attacker,"%c[ATAC]%c %t %t",GREEN,YELLOW,"Earned Karma",karmaCounter[attacker],maxKarma,"Killing Enemy");
				// BEGIN MOD BY LAMDACORE
				decl String:victimName[64];
				decl String:attackerName[64];
				GetClientName(victim,victimName,64);
				GetClientName(attacker,attackerName,64);
				LogToGame("[ATAC] %s(Team:%d) earned %d/%d Karma for killing %s(Team:%d)", attackerName, attackerTeam, karmaCounter[attacker], maxKarma, victimName, victimTeam);
				// END MOD BY LAMDACORE
			}
		}
	}
}

public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	if(GetConVarInt(cvarATACTKCount) > 0){
		decl String:victimName[64];
		decl String:attackerName[64];
		new userid = GetEventInt(event,"userid");
		new userid2 = GetEventInt(event,"attacker");
		new victim = GetClientOfUserId(userid);
		new attacker = GetClientOfUserId(userid2);
		if(attacker != 0 && victim != 0 && IsClientConnected(attacker) && IsClientConnected(victim) && victim != attacker){
			new bool:IgnoreBots = GetConVarBool(cvarATACIgnoreBots);
			if(IgnoreBots){
				if(IsFakeClient(victim) || IsFakeClient(attacker)){
					return;
				}
			}

			if(GetConVarBool(cvarATACKarmaKills) && GetConVarInt(cvarATACKarmaCount) > 0){
				HandleKarmaKills(attacker,victim);
			}

			new victimTeam = GetClientTeam(victim);
			new attackerTeam = GetClientTeam(attacker);
			if(victimTeam==attackerTeam){
				GetClientName(attacker,attackerName,64);
				// BEGIN MOD BY LAMDACORE
				GetClientName(victim,victimName,64);
				LogToGame("[ATAC] %s(Team:%d) was teamkilled from %s(Team:%d).", victimName, victimTeam, attackerName, attackerTeam);
				// END MOD BY LAMDACORE
				killed[attacker][victim] = true;
				// BEGIN MOD BY LAMDACORE
				CleaningMultipleKilledState(attacker,victim);
				// END MOD BY LAMDACORE
				PrintToConsole(victim,"[ATAC] %t","You Were Team Killed",attackerName);
				PrintToChat(victim,"%c[ATAC]%c %t",GREEN,YELLOW,"You Were Team Killed",attackerName);
				ForgiveMenu(victim,attacker,attackerName);
			}
		}
	}
}

// BEGIN MOD BY LAMDACORE
CleaningMultipleKilledState(newAttacker,victim)
{
	for(new attacker = 1; attacker <= PlayerSlots; ++attacker)
	{
		if (attacker == newAttacker)
		{
			continue;
		}
		killed[attacker][victim] = false;
	}
}
// END MOD BY LAMDACORE

HandleTeamAttack(victim,attacker){
	decl String:victimName[64];
	decl String:attackerName[64];
	if(attacker != 0 && victim != 0 && IsClientConnected(attacker) && IsClientConnected(victim) && victim != attacker){
		new bool:IgnoreBots = GetConVarBool(cvarATACIgnoreBots);
		if(IgnoreBots){
			if(IsFakeClient(victim) || IsFakeClient(attacker)){
				return;
			}
		}
		new victimTeam = GetClientTeam(victim);
		new attackerTeam = GetClientTeam(attacker);
		if(victimTeam==attackerTeam){
			GetClientName(victim,victimName,64);
			GetClientName(attacker,attackerName,64);
			new taCount = GetConVarInt(cvarATACTACount);
			if(taCount > 0){
				new currentTime = GetTime();
				if(currentTime - g_DamageTime[attacker][victim] > 0){
					g_DamageTime[attacker][victim] = currentTime;
					taCounter[attacker]++;
					if(taCounter[attacker] > taCount){
						taCounter[attacker] = taCount;
					}

					TextOutput2(attacker,victim,"Team Attack",taCounter[attacker],taCount);

					if(taCounter[attacker] == taCount){
						tkCounter[attacker]++;
						new tkCount = GetConVarInt(cvarATACTKCount);
						if(tkCounter[attacker] > tkCount){
							tkCounter[attacker] = tkCount;
						}

						TextOutput2(attacker,victim,"Team Kill",tkCounter[attacker],tkCount);

						if(tkCount > 0 && tkCounter[attacker] == tkCount){
							TKAction(attacker,victim);
							tkCounter[attacker] = 0;
						}
						taCounter[attacker] = 0;
					}
				}
			}
		}
	}
	attacked[attacker][victim] = false;
}

public Action:ForgiveMenu(victim,attacker,const String:attackerName[64]){
	if(GetConVarBool(cvarATACAdminImmunity)){
		new AdminId:attackerAdmin = GetUserAdmin(attacker);
		new AdminId:victimAdmin = GetUserAdmin(victim);
		if(attackerAdmin != INVALID_ADMIN_ID && !CanAdminTarget(victimAdmin, attackerAdmin)){
			if(GetAdminFlag(attackerAdmin, Admin_Custom6, Access_Real) || GetAdminFlag(attackerAdmin, Admin_Custom6, Access_Effective)){
				// BEGIN MOD BY LAMDACORE if an immunity admin was the TKer, the killed flag must be resetted, too
				killed[attacker][victim] = false;
				// END MOD BY LAMDACORE
				return;
			}else{
				SetMenuTitle(atacImmuneMenu,"[ATAC] %t","You Were Team Killed",attackerName);
				DisplayMenu(atacImmuneMenu,victim,MENU_TIME_FOREVER);
			}
		}else{
				SetMenuTitle(atacMenu,"[ATAC] %t","You Were Team Killed",attackerName);
				DisplayMenu(atacMenu,victim,MENU_TIME_FOREVER);
		}
	}else{
		SetMenuTitle(atacMenu,"[ATAC] %t","You Were Team Killed",attackerName);
		DisplayMenu(atacMenu,victim,MENU_TIME_FOREVER);
	}
}

public PunishmentMenuSelected(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select){
		decl String:SelectionInfo[64];
		decl String:SelectionDispText[256];
		new SelectionStyle;
		GetMenuItem(menu,param2,SelectionInfo,sizeof(SelectionInfo),SelectionStyle, SelectionDispText,sizeof(SelectionDispText));
		decl String:clientName[64];
		decl String:attackerName[64];
		GetClientName(param1,clientName,64);
		new bool:hlxEnabled = GetConVarBool(cvarATACHLXEnabled);
		if(strcmp(SelectionInfo,"Forgive") == 0){
			for(new attacker = 1; attacker <= PlayerSlots; ++attacker){
				if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0 && attacker != param1){
					killed[attacker][param1] = false;

					TextOutput(1,attacker,param1,"Forgiven");
					// BEGIN MOD BY LAMDACORE
					new attackerTeam = GetClientTeam(attacker);
					new victimTeam = GetClientTeam(param1);
					GetClientName(attacker,attackerName,64);
					LogToGame("[ATAC] %s(Team:%d) was forgiven for TKing %s(Team:%d)", attackerName, attackerTeam, clientName, victimTeam);
					// END MOD BY LAMDACORE
					if(hlxEnabled){
						decl String:attackerSteamID[64];
						GetClientName(attacker,attackerName,64);
						GetClientAuthString(attacker, attackerSteamID, 64);
						LogToGame("\"%s<%d><%s><ATAC>\" triggered \"Forgiven_For_TeamKill\"",attackerName,GetClientUserId(attacker),attackerSteamID);
					}
				}
			}
		}else if(strcmp(SelectionInfo,"Punish") == 0){
			new tkCount = GetConVarInt(cvarATACTKCount);
			for(new attacker = 1; attacker <= PlayerSlots; ++attacker){
				if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0 && attacker != param1){
					GetClientName(attacker,attackerName,64);
					tkCounter[attacker]++;
					if(tkCount > 0 && tkCounter[attacker] >= tkCount){
						if(TKAction(attacker,param1)){
							return;
						}
						tkCounter[attacker] = 0;
						killed[attacker][param1] = false;
					}else{
						killed[attacker][param1] = false;
					}

					TextOutput2(attacker,param1,"Not Forgiven",tkCounter[attacker],tkCount);
					// BEGIN MOD BY LAMDACORE
					new attackerTeam = GetClientTeam(attacker);
					new victimTeam = GetClientTeam(param1);
					GetClientName(attacker,attackerName,64);
					LogToGame("[ATAC] %s(Team:%d) was NOT forgiven for TKing %s(Team:%d)", attackerName, attackerTeam, clientName, victimTeam);
					// END MOD BY LAMDACORE
					if(hlxEnabled){
						decl String:attackerSteamID[64];
						GetClientName(attacker,attackerName,64);
						GetClientAuthString(attacker, attackerSteamID, 64);
						LogToGame("\"%s<%d><%s><ATAC>\" triggered \"Punished_For_TeamKill\"",attackerName,GetClientUserId(attacker),attackerSteamID);
					}
				}
			}
		}else{
			new Handle:ATAC_Menu = Handle:StringToInt(SelectionInfo);
			if(ATAC_Menu != INVALID_HANDLE){
				for(new attacker = 1; attacker <= PlayerSlots; ++attacker){
					if(IsClientConnected(attacker) && IsClientInGame(attacker) && killed[attacker][param1] && attacker != 0 && attacker != param1){
						Call_StartForward(ATAC_Menu);
						Call_PushCell(param1);
						Call_PushCell(attacker);
						Call_Finish();
						if(hlxEnabled){
							decl String:attackerSteamID[64];
							GetClientName(attacker,attackerName,64);
							GetClientAuthString(attacker, attackerSteamID, 64);
							LogToGame("\"%s<%d><%s><ATAC>\" triggered \"Punished_For_TeamKill\"",attackerName,GetClientUserId(attacker),attackerSteamID);
						}
						killed[attacker][param1] = false;
					}
				}
			}
		}
	}
}

bool:TKAction(attacker,victim){
	new tkaction = GetConVarInt(cvarATACAction);
	if(tkaction != 0){
		new TakeNextAction = GetConVarInt(cvarATACTakeNextAction);
		decl String:attackerName[64];
		GetClientName(attacker,attackerName,64);
		decl String:SteamID[64];
		GetClientAuthString(attacker,SteamID,64);
		if(tkaction == 1){
			if(IsClientConnected(attacker)){
				kickCounter[attacker]++;
				new bool:doKick = true;
				if(TakeNextAction == 1){
					if(NextAction(attacker,victim)){
						doKick = false;
						return true;
					}
				}
				if(!doKick){
					return true;
				}else{
					ATACKickClient(attacker,victim);
					return true;
				}
			}
			return true;
		}
		if(tkaction == 2){
			ATACBanClient(attacker,victim);
			return true;
		}
	}
	return false;
}

ATACKickClient(attacker,victim){
	tkCounter[attacker] = 0;
	taCounter[attacker] = 0;
	StoreInfo(attacker);
	KickClient(attacker,"[ATAC] %t","You Were Kicked");
	if(g_ircRelay){
		decl String:attackerName[64];
		GetClientName(attacker,attackerName,64);
		decl String:SteamID[64];
		GetClientAuthString(attacker,SteamID,64);
		decl String:IrcMsg[1600];
		Format(IrcMsg,sizeof(IrcMsg),"\x02[ATAC]\x0F %t","IRC TK Kick",attackerName,SteamID);
		PrintToServer(IrcMsg);
		IrcMessage(CHAN_MASTER,IrcMsg);
	}
	TextOutput(3,attacker,victim,"TK Kick");
}

ATACBanClient(attacker,victim){
	karmaCounter[attacker] = 0;
	taCounter[attacker] = 0;
	tkCounter[attacker] = 0;
	kickCounter[attacker] = 0;
	banCounter[attacker]++;
	StoreInfo(attacker);
	decl String:clientIP[30];
	decl String:attackerName[64];
	GetClientIP(attacker,clientIP,30,true);
	GetClientName(attacker,attackerName,64);
	new BanTime = GetConVarInt(cvarATACBanTime);
	if(g_ircRelay){
		decl String:SteamID[64];
		GetClientAuthString(attacker,SteamID,64);
		ServerCommand("irc_showbans 0; wait");
		decl String:IrcMsg[1600];
		Format(IrcMsg,sizeof(IrcMsg),"\x02[ATAC]\x0F %t","IRC TK Ban",attackerName,SteamID);
		PrintToServer(IrcMsg);
		IrcMessage(CHAN_MASTER,IrcMsg);
	}
	if(banCounter[attacker] >= GetConVarInt(cvarATACBanLimit) && GetConVarInt(cvarATACBanLimit) != 0){
		if(GetConVarBool(cvarATACBanType)){
			ServerCommand("sm_banip \"%d\" %s \"[ATAC] %t\"",0,clientIP,"Ban Reason");
		}else{
			ServerCommand("sm_ban \"%s\" \"%d\" \"[ATAC] %t\"",attackerName,0,"Ban Reason");
		}
		banCounter[attacker] = 0;
	}else{
		if(GetConVarBool(cvarATACBanType)){
			ServerCommand("sm_banip \"%d\" %s \"[ATAC] %t\"",BanTime,clientIP,"Ban Reason");
		}else{
			ServerCommand("sm_ban \"%s\" \"%d\" \"[ATAC] %t\"",attackerName,BanTime,"Ban Reason");
		}
	}
	if(g_ircRelay){
		ServerCommand("wait; irc_showbans 1");
	}
	TextOutput(3,attacker,victim,"TK Ban");
}

bool:NextAction(attacker,victim){
	new ATACAction = GetConVarInt(cvarATACAction);
	if(ATACAction != 0){
		decl String:SteamID[64];
		GetClientAuthString(attacker,SteamID,64);
		decl String:clientIP[30];
		GetClientIP(attacker,clientIP,30,true);
		new KickLimit = GetConVarInt(cvarATACKickLimit);
		decl String:attackerName[64];
		GetClientName(attacker,attackerName,64);
		if(ATACAction == 1){
			kickCounter[attacker]++;
			if(kickCounter[attacker] >= KickLimit){
				kickCounter[attacker] = KickLimit;
			}
			if(kickCounter[attacker] >= KickLimit){
				ATACBanClient(attacker,victim);
				return true;
			}else{
				kickCounter[attacker]++;
				new TakeNextAction = GetConVarInt(cvarATACTakeNextAction);
				new bool:doKick = true;
				if(TakeNextAction == 1){
					if(NextAction(attacker,victim)){
						doKick = false;
						return true;
					}
				}
				if(!doKick){
					return true;
				}else{
					ATACKickClient(attacker,victim);
					return true;
				}
			}
		}else if(ATACAction == 2){
			if(kickCounter[attacker] >= KickLimit){
				kickCounter[attacker] = KickLimit;
			}
			if(kickCounter[attacker] >= KickLimit){
				ATACBanClient(attacker,victim);
				return true;
			}	
		}	
		return false;
	}
	return false;
}

TextOutput(PhraseVal,attacker,victim,const String:Phrase[]){
	if(IsClientInGame(attacker) && IsClientInGame(victim)){
		if(PhraseVal == 1){
			decl String:attackerName[64];
			decl String:victimName[64];
			GetClientName(attacker,attackerName,sizeof(attackerName));
			GetClientName(victim,victimName,sizeof(victimName));
			new Verbose = GetConVarInt(cvarATACVerbose);
	
			if(Verbose == 1){
				PrintToConsole(victim,"[ATAC] %t",Phrase,victimName,attackerName);
				PrintToChat(victim,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,victimName,attackerName);
				PrintToConsole(attacker,"[ATAC] %t",Phrase,victimName,attackerName);
				PrintToChat(attacker,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,victimName,attackerName);
			}else if(Verbose == 2){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players) && GetClientTeam(players) == GetClientTeam(victim)){
						PrintToConsole(players,"[ATAC] %t",Phrase,victimName,attackerName);
						PrintToChat(players,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,victimName,attackerName);
					}
				}
			}else if(Verbose == 3){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players) && (GetUserAdmin(players) != INVALID_ADMIN_ID || GetClientTeam(players) == GetClientTeam(victim))){
						PrintToConsole(players,"[ATAC] %t",Phrase,victimName,attackerName);
						PrintToChat(players,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,victimName,attackerName);
					}
				}
			}else if(Verbose == 4){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players) && GetUserAdmin(players) != INVALID_ADMIN_ID || players == victim && players == attacker){
						PrintToConsole(players,"[ATAC] %t",Phrase,victimName,attackerName);
						PrintToChat(players,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,victimName,attackerName);
					}
				}
			}else if(Verbose == 5){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players) && GetUserAdmin(players) != INVALID_ADMIN_ID){
						PrintToConsole(players,"[ATAC] %t",Phrase,victimName,attackerName);
						PrintToChat(players,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,victimName,attackerName);
					}
				}
			}else if(Verbose == 6){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players)){
						PrintToConsole(players,"[ATAC] %t",Phrase,victimName,attackerName);
					}
				}
				PrintToChatAll("%c[ATAC]%c %t",GREEN,YELLOW,Phrase,victimName,attackerName);
			}
		}else if(PhraseVal == 2){
			decl String:attackerName[64];
			decl String:victimName[64];
			GetClientName(attacker,attackerName,sizeof(attackerName));
			GetClientName(victim,victimName,sizeof(victimName));
			new Verbose = GetConVarInt(cvarATACVerbose);
	
			if(Verbose == 1){
				PrintToConsole(victim,"[ATAC] %t",Phrase,attackerName,victimName);
				PrintToChat(victim,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,victimName);
				PrintToConsole(attacker,"[ATAC] %t",Phrase,attackerName,victimName);
				PrintToChat(attacker,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,victimName);
			}else if(Verbose == 2){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players) && GetClientTeam(players) == GetClientTeam(victim)){
						PrintToConsole(players,"[ATAC] %t",Phrase,attackerName,victimName);
						PrintToChat(players,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,victimName);
					}
				}
			}else if(Verbose == 3){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players) && GetUserAdmin(players) != INVALID_ADMIN_ID || GetClientTeam(players) == GetClientTeam(victim)){
						PrintToConsole(players,"[ATAC] %t",Phrase,attackerName,victimName);
						PrintToChat(players,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,victimName);
					}
				}
			}else if(Verbose == 4){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players) && GetUserAdmin(players) != INVALID_ADMIN_ID || players == victim && players == attacker){
						PrintToConsole(players,"[ATAC] %t",Phrase,attackerName,victimName);
						PrintToChat(players,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,victimName);
					}
				}
			}else if(Verbose == 5){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players) && GetUserAdmin(players) != INVALID_ADMIN_ID){
						PrintToConsole(players,"[ATAC] %t",Phrase,attackerName,victimName);
						PrintToChat(players,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,victimName);
					}
				}
			}else if(Verbose == 6){
				for(new players = 1; players <= PlayerSlots; ++players){
					if(IsClientConnected(players) && IsClientInGame(players)){
						PrintToConsole(players,"[ATAC] %t",Phrase,attackerName,victimName);
					}
				}
				PrintToChatAll("%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,victimName);
			}
		}else if(PhraseVal == 3){
			decl String:attackerName[64];
			GetClientName(attacker, attackerName, sizeof(attackerName));
			new Verbose = GetConVarInt(cvarATACVerbose);
			if(Verbose == 1){
				PrintToConsole(attacker,"[ATAC] %t",Phrase,attackerName);
				PrintToChat(attacker,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName);
				PrintToConsole(victim,"[ATAC] %t",Phrase,attackerName);
				PrintToChat(victim,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName);
			}
			if(Verbose == 2){
				for(new i = 1; i <= PlayerSlots; ++i){
					if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(victim)){
						PrintToConsole(i,"[ATAC] %t",Phrase,attackerName);
						PrintToChat(i,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName);
					}
				}
			}
			if(Verbose == 3){
				for(new i = 1; i <= PlayerSlots; ++i){
					if(IsClientConnected(i) && IsClientInGame(i) && (GetUserAdmin(i) != INVALID_ADMIN_ID || GetClientTeam(i) == GetClientTeam(victim))){
						PrintToConsole(i,"[ATAC] %t",Phrase,attackerName);
						PrintToChat(i,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName);
					}
				}
			}
			if(Verbose == 4){
				for(new i = 1; i <= PlayerSlots; ++i){
					if(IsClientConnected(i) && IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID || i == victim || i == attacker){
						PrintToConsole(i,"[ATAC] %t",Phrase,attackerName);
						PrintToChat(i,"%c[ATAC%]%c %t",GREEN,YELLOW,Phrase,attackerName);
					}
				}
			}
			if(Verbose == 5){
				for(new i = 1; i <= PlayerSlots; ++i){
					if(IsClientConnected(i) && IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID){
						PrintToConsole(i,"[ATAC] %t",Phrase,attackerName);
						PrintToChat(i,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName);
					}
				}
			}
			if(Verbose == 6){
				for(new i = 1; i <= PlayerSlots; ++i){
					if(IsClientConnected(i) && IsClientInGame(i)){
						PrintToConsole(i,"[ATAC] %t",Phrase,attackerName);
					}
				}
				PrintToChatAll("%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName);
			}
		}
	}
}
TextOutput2(attacker,victim,const String:Phrase[],val1,val2){
	if(IsClientInGame(attacker) && IsClientInGame(victim)){
		decl String:attackerName[64];
		GetClientName(attacker, attackerName, sizeof(attackerName));
		
		new Verbose = GetConVarInt(cvarATACVerbose);
		
		if(Verbose == 1){
			PrintToConsole(victim,"[ATAC] %t",Phrase,attackerName,val1,val2);
			PrintToChat(victim,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,val1,val2);
			PrintToConsole(attacker,"[ATAC] %t",Phrase,attackerName,val1,val2);
			PrintToChat(attacker,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,val1,val2);
		}
		if(Verbose == 2){
			for(new i = 1; i <= PlayerSlots; ++i){
				if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(victim) && GetClientTeam(i) == GetClientTeam(attacker)){
					PrintToConsole(i,"[ATAC] %t",Phrase,attackerName,val1,val2);
					PrintToChat(i,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,val1,val2);
				}
			}
		}
		if(Verbose == 3){
			for(new i = 1; i <= PlayerSlots; ++i){
				if(IsClientConnected(i) && IsClientInGame(i) && (GetUserAdmin(i) != INVALID_ADMIN_ID || GetClientTeam(i) == GetClientTeam(attacker) && GetClientTeam(i) == GetClientTeam(victim))){
					PrintToConsole(i,"[ATAC] %t",Phrase,attackerName,val1,val2);
					PrintToChat(i,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,val1,val2);
				}
			}
		}
		if(Verbose == 4){
			for(new i = 1; i <= PlayerSlots; ++i){
				if(IsClientConnected(i) && IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID || i == victim || i == attacker){
					PrintToConsole(i,"[ATAC] %t",Phrase,attackerName,val1,val2);
					PrintToChat(i,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,val1,val2);
				}
			}
		}
		if(Verbose == 5){
			for(new i = 1; i <= PlayerSlots; ++i){
				if(IsClientConnected(i) && IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID){
					PrintToConsole(i,"[ATAC] %t",Phrase,attackerName,val1,val2);
					PrintToChat(i,"%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,val1,val2);
				}
			}
		}
		if(Verbose == 6){
			for(new i = 1; i <= PlayerSlots; ++i){
				if(IsClientConnected(i) && IsClientInGame(i)){
					PrintToConsole(i,"[ATAC] %t",Phrase,attackerName,val1,val2);
				}
			}
			PrintToChatAll("%c[ATAC]%c %t",GREEN,YELLOW,Phrase,attackerName,val1,val2);
		}
	}
}