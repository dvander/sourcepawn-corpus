#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.03.3"
#define MAX_CLIENTS 64
#define COLOR_DEFAULT 0x01
#define COLOR_GREEN 0x04

public Plugin:myinfo ={
	name = "DoD:S Infos Bad Rate",
	author = "Misery, X@IDER, playboycyberclub",
	description = "Control players rates",
	version = PLUGIN_VERSION,
	url = "http://evoteam.freeforums.org"
};

new Handle:dod_CvarRate_freeze_enable = INVALID_HANDLE;
new Handle:dod_CvarNet_times = INVALID_HANDLE;
new Handle:dod_CvarNet_action = INVALID_HANDLE;
new Handle:dod_CvarNet_in_max = INVALID_HANDLE;
new Handle:dod_CvarNet_out_max = INVALID_HANDLE;
new Handle:dod_CvarNet_loss_max = INVALID_HANDLE;
new Handle:dod_CvarNet_choke_max = INVALID_HANDLE;
new Handle:dod_CvarNet_ping_max = INVALID_HANDLE;
new Handle:sv_minrate = INVALID_HANDLE;
new Handle:sv_maxrate = INVALID_HANDLE;
new Handle:sv_mincmdrate = INVALID_HANDLE;
new Handle:sv_maxcmdrate = INVALID_HANDLE;
new Handle:sv_minupdaterate = INVALID_HANDLE;
new Handle:sv_maxupdaterate = INVALID_HANDLE;
new Handle:Tim = INVALID_HANDLE;

new ifGood[MAX_CLIENTS];
new NetWarnings[MAX_CLIENTS];

public OnPluginStart(){
	LoadTranslations("plugin.badrate");
	
        CreateConVar("sm_dodratemanager_version", PLUGIN_VERSION, "Dod Infos Badrate version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_DONTRECORD);
	dod_CvarRate_freeze_enable = CreateConVar("sm_rate_freeze_enable", "1", "Enable/disable freeze if player have a Badrate");
	dod_CvarNet_times = CreateConVar("sm_net_times", "3", "Warning before action (0 to permanent)");
	dod_CvarNet_action = CreateConVar("sm_net_action", "kickid %d Network troubles", "Do some action with player with bad networking");
	dod_CvarNet_in_max = CreateConVar("sm_net_in_max", "30000.0", "Maximum allowed incoming trafic for client");
	dod_CvarNet_out_max = CreateConVar("sm_net_out_max", "30000.0", "Maximum allowed outgoing trafic for client");
	dod_CvarNet_loss_max = CreateConVar("sm_net_loss_max", "75.0", "Maximum allowed loss");
	dod_CvarNet_choke_max = CreateConVar("sm_net_choke_max", "90.0", "Maximum allowed choke");
	dod_CvarNet_ping_max = CreateConVar("sm_net_ping_max", "250.0", "Maximum allowed ping");
	
	sv_minrate = FindConVar("sv_minrate");
	sv_maxrate = FindConVar("sv_maxrate");
	sv_mincmdrate = FindConVar("sv_mincmdrate");
	sv_maxcmdrate = FindConVar("sv_maxcmdrate");
	sv_minupdaterate = FindConVar("sv_minupdaterate");
	sv_maxupdaterate = FindConVar("sv_maxupdaterate");
	
	RegConsoleCmd("say", console_say);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_disconnect",PlayerDisconnectEvent);
	
	AutoExecConfig(true,"plugin.badrate");
}

public OnMapStart(){
	if(Tim != INVALID_HANDLE){
		CloseHandle(Tim);
		Tim = INVALID_HANDLE;
	}
	Tim = CreateTimer(15.0,NetCheck,0,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd(){
	if(Tim != INVALID_HANDLE){
		CloseHandle(Tim);
		Tim = INVALID_HANDLE;
	}
}

public Action:NetCheck(Handle:timer, any:value){
	new maxwarn = GetConVarInt(dod_CvarNet_times);
	new Float:min = GetConVarFloat(dod_CvarNet_in_max);
	new Float:mout = GetConVarFloat(dod_CvarNet_out_max);
	new Float:mping = GetConVarFloat(dod_CvarNet_ping_max);
	new Float:mloss = GetConVarFloat(dod_CvarNet_loss_max);
	new Float:mchoke = GetConVarFloat(dod_CvarNet_choke_max);
	new Float:din,Float:dout,Float:dping,Float:dloss,Float:dchoke;
	new bool:in_flux,bool:out,bool:ping,bool:loss,bool:choke;
	
	decl String:action[96];
	decl String:name[32];
	GetConVarString(dod_CvarNet_action,action,96);
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i) && !IsFakeClient(i)){
			din = GetClientAvgData(i, NetFlow_Outgoing);
			dout = GetClientAvgData(i, NetFlow_Incoming);
			dping = 1000.0*GetClientAvgLatency(i, NetFlow_Both);
			dchoke = 100.0*GetClientAvgChoke(i, NetFlow_Both);
			dloss = 100.0*GetClientAvgLoss(i, NetFlow_Both);
			in_flux = (13 & 1) && (din > min);
			out = (13 & 2) && (dout > mout);
			ping = (13 & 4) && (dping > mping);
			loss = (13 & 8) && (dloss > mloss);
			choke = (13 & 16) && (dchoke > mchoke);
			
			GetClientName(i, name, 31);
			if(in_flux) PrintToChat(i,"%t","Incoming chat",COLOR_DEFAULT,COLOR_GREEN,din,COLOR_DEFAULT,COLOR_GREEN,min,COLOR_DEFAULT);
			if(out) PrintToChat(i,"%t","Outgoing chat",COLOR_DEFAULT,COLOR_GREEN,dout,COLOR_DEFAULT,COLOR_GREEN,mout,COLOR_DEFAULT);
			if(ping) PrintToChat(i,"%t","Ping chat",COLOR_DEFAULT,COLOR_GREEN,dping,COLOR_DEFAULT,COLOR_GREEN,mping,COLOR_DEFAULT);
			if(loss) PrintToChat(i,"%t","Loss chat",COLOR_DEFAULT,COLOR_GREEN,dping,COLOR_DEFAULT,COLOR_GREEN,mping,COLOR_DEFAULT);
			if(choke) PrintToChat(i,"%t","Choke chat",COLOR_DEFAULT,COLOR_GREEN,dping,COLOR_DEFAULT,COLOR_GREEN,mping,COLOR_DEFAULT);
			if(in_flux || out || ping || loss || choke){
				if((NetWarnings[i]++ == maxwarn) && strlen(action)){
					ServerCommand(action,GetClientUserId(i));
					NetWarnings[i] = 0;
				}
			}else NetWarnings[i] = 0;
		}
	}
	return Plugin_Handled;
}

public CheckForRate(client,String:variable[],Handle:minvar,Handle:maxvar){
	new r = 0;
	if(IsClientInGame(client) && !IsFakeClient(client)){
		new String:rate[10],String:nrmrate[10];
		new Rate,MinRate;
		GetClientInfo(client, variable, rate, 9);
		Rate = StringToInt(rate);
		IntToString(Rate,nrmrate,9);
		MinRate = GetConVarInt(minvar);
		
		if(MinRate && (Rate < MinRate) || !StrEqual(rate,nrmrate)) r = -Rate;
	}
	return r;
}

public CheckClient(client){
	if(IsClientInGame(client) && !IsFakeClient(client)){
		new rate = CheckForRate(client,"rate",sv_minrate,sv_maxrate);
		new cmdrate = CheckForRate(client,"cl_cmdrate",sv_mincmdrate,sv_maxcmdrate);
		new updrate = CheckForRate(client,"cl_updaterate",sv_minupdaterate,sv_maxupdaterate);
		new Handle:mSayPanel = CreatePanel();
		if(rate || cmdrate || updrate){
			decl String:buff[1024],String:info[7][128];
			Format(buff,sizeof(buff),"%t","Rate title",client);
			SetPanelTitle(mSayPanel,buff);
			Format(buff,sizeof(buff),"%t","Rate info",client);
			new n = ExplodeString(buff,"\n",info,7,128);
			for(new i=0;i<=n;i++)
				DrawPanelItem(mSayPanel,info[i],ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE);	
			if(rate){
				Format(buff,sizeof(buff),"rate %d",GetConVarInt((rate < 0)?sv_minrate:sv_maxrate));
				DrawPanelItem(mSayPanel,buff,ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE);
			}
			if(cmdrate){
				Format(buff,sizeof(buff),"cl_cmdrate %d",GetConVarInt((rate < 0)?sv_mincmdrate:sv_maxcmdrate));
				DrawPanelItem(mSayPanel,buff,ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE);
			}
			if(updrate){
				Format(buff,sizeof(buff),"cl_updaterate %d",GetConVarInt((rate < 0)?sv_minupdaterate:sv_maxupdaterate));
				DrawPanelItem(mSayPanel,buff,ITEMDRAW_DISABLED|ITEMDRAW_RAWLINE);
			}
			SendPanelToClient(mSayPanel, client, Handler_DoNothing, 8);
			CloseHandle(mSayPanel);
			
			PrintToChat(client, "\x01\x04[BadRate]\x01 Type in chat : \x01\x04rate\x01 and \x01\x04netstat\x01");
			SetEntityRenderColor(client, 255, 140, 140, 255);
			if(GetConVarBool(dod_CvarRate_freeze_enable)) SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 0.0);
			ifGood[client] = 0;
		}else if(ifGood[client] == 0){
			decl String:title[100];
			Format(title, sizeof(title), "INFO CONFIG");
			SetPanelTitle(mSayPanel, title);
			DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);
			
			decl String:updateOk[256];
			Format(updateOk, sizeof(updateOk),"%t", "ConfigOK");
			DrawPanelText(mSayPanel, updateOk);
			DrawPanelItem(mSayPanel, "", ITEMDRAW_SPACER);
			
			SetPanelCurrentKey(mSayPanel, 6);
			DrawPanelItem(mSayPanel, "Close", ITEMDRAW_CONTROL);
			SendPanelToClient(mSayPanel, client, Handler_DoNothing, 8);
			CloseHandle(mSayPanel);
			
			SetEntityRenderColor(client, 255, 255, 255, 255);
			if(GetConVarBool(dod_CvarRate_freeze_enable)) SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
			ifGood[client] = 1;
		}
	}
}

bool:IsValidCmdRate(String:CmdRate[]){
	new len = strlen(CmdRate);
	for(new i=0;i<len;i++)
		if(!IsCharNumeric(CmdRate[i]))
			return false;
	return true;
}

CheckPingMasked(client){
	if(!IsClientInGame(client) || IsFakeClient(client))
		return;
	decl String:cmdRate[32];
	GetClientInfo(client, "cl_cmdrate", cmdRate, sizeof(cmdRate));
	IsValidCmdRate(cmdRate);
	if(!IsValidCmdRate(cmdRate)){
		decl String:cl_Name[64];
		GetClientName(client, cl_Name, sizeof(cl_Name));
		PrintToChatAll("%c[Infos cfg]%c %s was Kicked -> ping masking (cmdrate: %6s)", COLOR_GREEN, COLOR_DEFAULT, cl_Name, cmdRate);
		ServerCommand("sm_kick #%d %d \"[Infos cfg] Kicked -> ping masking\"", GetClientUserId(client), 60);
		LogAction(0, client, "\"%L\" Kicked -> ping masking", client);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	CheckClient(GetClientOfUserId(GetEventInt(event,"userid")));
	CheckPingMasked(GetClientOfUserId(GetEventInt(event,"userid")));
}

public PlayerDisconnectEvent(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client !=0 && !IsClientInGame(client)) ifGood[client] = 0;
}

public OnClientSettingsChanged(client){
	if(IsClientInGame(client) && GetClientTeam(client)){
		ifGood[client] = 0;
		CheckClient(client);
		CheckPingMasked(client);
	}
}

public Action:console_say(client, args){
	if(client != 0){
		decl String:text[192];
		if(!GetCmdArgString(text, sizeof(text)))
			return Plugin_Continue;
		new startidx = 0;
		if(text[strlen(text)-1] == '"'){
			text[strlen(text)-1] = '\0';
			startidx = 1;
		}
		if(strcmp(text[startidx], "rate", false) == 0 || strcmp(text[startidx], "!rate", false) == 0) Rates(client);
		if(strcmp(text[startidx], "netstat", false) == 0 || strcmp(text[startidx], "!netstat", false) == 0) Netstat(client);
	}
	return Plugin_Continue;
}

public Rates(client){
	new String:interp[10],String:update[10],String:cmd[10],String:rate[10],String:name[32];
	new ID;
	PrintToChat(client,"-------------------------------------------------------------------");
	PrintToChat(client,"    ID | rate    | cmdrate | updrate | interp | name");
	PrintToChat(client,"-------|---------|---------|---------|--------|--------------------");
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i) && !IsFakeClient(i)){	
			decl String:Bad[3] = "   ";
			GetClientInfo(i, "rate", rate, 9);
			GetClientInfo(i, "cl_cmdrate",cmd, 9);
			GetClientInfo(i, "cl_updaterate", update, 9);
			GetClientInfo(i, "cl_interp", interp, 9);
			GetClientName(i, name, 31);
			ID = GetClientUserId(i);
			if(CheckForRate(i,"rate",sv_minrate,sv_maxrate)) Bad[0] = '*';
			if(CheckForRate(i,"cl_cmdrate",sv_mincmdrate,sv_maxcmdrate)) Bad[1] = '*';
			if(CheckForRate(i,"cl_updaterate",sv_minupdaterate,sv_maxupdaterate)) Bad[2] = '*';
			PrintToChat(client,"#%5d | %6s%c | %6s%c | %6s%c | %6s | %s",ID,rate,Bad[0],cmd,Bad[1],update,Bad[2],interp,name);
		}
	}	
	PrintToChat(client,"-------------------------------------------------------------------");	
}

public Netstat(client){
	PrintToChat(client,"---------------------------------------------------------------------------------");
	PrintToChat(client,"    ID |  choke |   loss |   ping |   in (b/s) |  out (b/s) | name");
	PrintToChat(client,"-------|--------|--------|--------|------------|------------|--------------------");
	new String:name[32];
	new Float:choke,Float:loss,Float:ping,Float:din,Float:dout;
	new ID;
	for(new i=1;i<=MaxClients;i++){
		if(IsClientInGame(i) && !IsFakeClient(i)){
			ID = GetClientUserId(i);
			GetClientName(i, name, 31);
			choke = 100.0*GetClientAvgChoke(i, NetFlow_Both);
			loss = 100.0*GetClientAvgLoss(i, NetFlow_Both);
			ping = 1000.0*GetClientAvgLatency(i, NetFlow_Both);
			din = GetClientAvgData(i, NetFlow_Outgoing);
			dout = GetClientAvgData(i, NetFlow_Incoming);
			PrintToChat(client,"#%5d | %5.1f%% | %5.1f%% | %6.1f | %10.1f | %10.1f | %s",ID,choke,loss,ping,din,dout,name);
		}
	}
	PrintToChat(client,"---------------------------------------------------------------------------------");	
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2){
	/* Do nothing */
}