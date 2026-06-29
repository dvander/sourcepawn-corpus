/*
GPLv2
GPLv3
admin_hp.sp

!hp HP management
by dogwong
version: 2.3
release date: 2010-10-10
note: This plugin provides server admin an interface to quickly recover HP for survivors or infected, real player or AI.
In the newer version of this plugin, health regeneration and health recovery point(!ahp) let players able to stand still for HP restoration or built up a recovery point using a first aid kit to heal everyone in the area.
caution: -
While this plugin is in development, this plugin is written / compiled with SourceMod 1.3, as I remember....

!hp生命管理
作者: dogwong
版本: 2.3
推出日期: 2010-10-10
介紹: 此插件提供管理員一個方便回血的介面, 可快速分別地為真人/電腦, 倖存者隊/感染者隊回血, 
後期新版本加入自動補血及回血點功能, 玩家只需站在原地即可自動回血, 及手持藥包可建立回血點, 為附近隊友回血
注意: -
開發此插件時所使用的環境是SourceMod 1.3, 我印象中...

Codes after this comment block are copied from original sp file.
此段註解後的代碼是從原裝的sp檔案中複製
==========================================
*/

#include <sourcemod>
#include <sdktools>
#include "edlib.sp"
#define PLUGIN_VERSION    "2.4 (11:27 12/03/21)"
#define CVAR_FLAGS FCVAR_PLUGIN
/*
1.0.0.3 (11:11 8/1/10)
2.0.0.0 (12:07 4/7/10)
2.0.0.3 (15:29 10/10/10)

*/
new Handle:hp_on_hpregeneration;
new Handle:hp_regeneration_timer;
new Handle:hp_fill_point_timer;
new player_pos[64];
new hp_not_change_time[64];
new last_time_hp[64];
new greenColor[4]	= {0, 255, 0, 20};
new blueColor[4]	= {0, 200, 255, 20};
new Float:hp_fill_point[3];
new Float:hp_fill_time_left = 0.0;
new String:buf[512];

public Plugin:myinfo =
{
	name = "Admin HP",
	author = "dogwong/Marco Chan",//我的第3個插件
	description = "將玩家回血, 加血上限等等",
	version = PLUGIN_VERSION,
	url = "http://www.poheart.com/space.php?uid=4411"
}
public OnPluginStart(){
	RegAdminCmd("hp", restore_hp, ADMFLAG_GENERIC, "回復hp選單");
	RegAdminCmd("hp_all_survivor", restore_hp_2, ADMFLAG_GENERIC, "把所有倖存者回復hp");
	RegAdminCmd("hp_all_real_survivor", restore_hp_3, ADMFLAG_GENERIC, "把真人倖存者回復hp");
	RegAdminCmd("hp_all_bot_survivor", restore_hp_4, ADMFLAG_GENERIC, "把電腦倖存者回復hp");
	RegAdminCmd("hp_all_specal_infected", restore_hp_5, ADMFLAG_GENERIC, "把所有特感回復hp");
	RegAdminCmd("hp_all_real_specal_infected", restore_hp_6, ADMFLAG_GENERIC, "把真人特感回復hp");
	RegAdminCmd("hp_all_bot_specal_infected", restore_hp_7, ADMFLAG_GENERIC, "把電腦特感回復hp");
	RegAdminCmd("hp_all", restore_hp_8, ADMFLAG_GENERIC, "把所有人回復hp");
	RegAdminCmd("hp_all_real", restore_hp_9, ADMFLAG_GENERIC, "把所有真人回復hp");
	RegAdminCmd("hp_all_bot", restore_hp_10, ADMFLAG_GENERIC, "把所有電腦回復hp");
	RegConsoleCmd("hp_ver", version);
	LoadTranslations("adminhp.phrases");
}

new String:weapon[32];
public Action:restore_hp(client, args){
	if (client>0){
		new Handle:hPl = CreateMenu(join_game_meun);
		Format(buf, sizeof(buf), "%T", "誰要回復hp?", client);
		SetMenuTitle(hPl, buf);
		Format(buf, sizeof(buf), "%T", "自己", client);
		AddMenuItem(hPl, "option1", buf);
		Format(buf, sizeof(buf), "%T", "所有倖存者", client);
		AddMenuItem(hPl, "option2", buf);
		Format(buf, sizeof(buf), "%T", "真人倖存者", client);
		AddMenuItem(hPl, "option3", buf);
		Format(buf, sizeof(buf), "%T", "電腦倖存者", client);
		AddMenuItem(hPl, "option4", buf);
		Format(buf, sizeof(buf), "%T", "所有特感", client);
		AddMenuItem(hPl, "option5", buf);
		Format(buf, sizeof(buf), "%T", "真人特感", client);
		AddMenuItem(hPl, "option6", buf);
		Format(buf, sizeof(buf), "%T", "電腦特感", client);
		AddMenuItem(hPl, "option7", buf);
		Format(buf, sizeof(buf), "%T", "所有人", client);
		AddMenuItem(hPl, "option8", buf);
		Format(buf, sizeof(buf), "%T", "所有真人", client);
		AddMenuItem(hPl, "option9", buf);
		Format(buf, sizeof(buf), "%T", "所有電腦", client);
		AddMenuItem(hPl, "option10", buf);
		DisplayMenu(hPl, client, 60);
	} else {
		Format(buf, sizeof(buf), "%T\n%T\n%T\n%T\n%T\n%T", "!hp只供遊戲內玩家使用, 伺服器端請使用以下指令:", LANG_SERVER, "hp_all_survivor - 把所有倖存者回復hp", LANG_SERVER, "hp_all_real_survivor - 把真人倖存者回復hp", LANG_SERVER, "hp_all_bot_survivor - 把電腦倖存者回復hp", LANG_SERVER, "要回復特感血請將survivor改為specal_infected", LANG_SERVER, "要回復所有人請刪除_survivor", LANG_SERVER);
		PrintToServer(buf);
	}
	return Plugin_Handled;
}
public join_game_meun(Handle:menu, MenuAction:action, client, itemNum){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);	
	decl String:name[128];
	GetClientName(client, name, sizeof(name)); 
	if ( action == MenuAction_Select ){
		if(itemNum == 0){
			if (IsClientInGame( client )){
				if (IsClientConnected( client )) {	//&& !IsFakeClient( i )
					CheatCommand(client, "give", "health", "", "");
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把自己回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把自己回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		} else if(itemNum == 1){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==2 ) {	//&& !IsFakeClient( i )
						CheatCommand(i, "give", "health", "", "");
					}
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把所有倖存者回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把所有倖存者回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		} else if(itemNum == 2){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==2 && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						CheatCommand(i, "give", "health", "", "");
					}
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把真人倖存者回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把真人倖存者回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		} else if(itemNum == 3){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==2 && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						CheatCommand(i, "give", "health", "", "");
					}
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把電腦倖存者回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把電腦倖存者回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		} else if(itemNum == 4){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==3) {	//&& !IsFakeClient( i )
						CheatCommand(i, "give", "health", "", "");
					}
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把所有特感回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把所有特感回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		} else if(itemNum == 5){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==3 && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						CheatCommand(i, "give", "health", "", "");
					}
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把真人特感回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把真人特感回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		} else if(itemNum == 6){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && GetClientTeam(i)==3 && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						CheatCommand(i, "give", "health", "", "");
					}
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把電腦特感回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把電腦特感回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		} else if(itemNum == 7){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i )) {	//&& !IsFakeClient( i )
						CheatCommand(i, "give", "health", "", "");
					}
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把所有人回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把所有人回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		} else if(itemNum == 8){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						CheatCommand(i, "give", "health", "", "");
					}
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把所有真人回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把所有真人回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		} else if(itemNum == 9){
			for( new i = 1; i < GetMaxClients(); i++ ) {
				if (IsClientInGame( i )){
					if (IsClientConnected( i ) && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
						CheatCommand(i, "give", "health", "", "");
					}
				}
			}
			PrintToChatAllTranslated1I("管理員[N]把所有電腦回滿血", "[SM] ", "", client);
			Format(buf, sizeof(buf), "[SM] %T", "管理員[N]把所有電腦回滿血", LANG_SERVER, client);
			PrintToServer(buf);
		}
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
}
public Action:restore_hp_2(client, args){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);	
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2) {	//&& !IsFakeClient( i )
					CheatCommand(i, "give", "health", "", "");
				}
			}
		}
		PrintToChatAllTranslated("伺服器把所有倖存者回滿血", "[SM] ", "");
		Format(buf, sizeof(buf), "[SM] %T", "伺服器把所有倖存者回滿血", LANG_SERVER);
		PrintToServer(buf);
	} else {
		Format(buf, sizeof(buf), "%T", "此指令只供伺服器端使用", client);
		PrintToChat(client, buf);
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_3(client, args){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2 && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
					CheatCommand(i, "give", "health", "", "");
				}
			}
		}
		PrintToChatAllTranslated("伺服器把真人倖存者回滿血", "[SM] ", "");
		Format(buf, sizeof(buf), "[SM] %T", "伺服器把真人倖存者回滿血", LANG_SERVER);
		PrintToServer(buf);
	} else {
		Format(buf, sizeof(buf), "%T", "此指令只供伺服器端使用", client);
		PrintToChat(client, buf);
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_4(client, args){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==2 && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
					CheatCommand(i, "give", "health", "", "");
				}
			}
		}
		PrintToChatAllTranslated("伺服器把電腦倖存者回滿血", "[SM] ", "");
		Format(buf, sizeof(buf), "[SM] %T", "伺服器把電腦倖存者回滿血", LANG_SERVER);
		PrintToServer(buf);
	} else {
		Format(buf, sizeof(buf), "%T", "此指令只供伺服器端使用", client);
		PrintToChat(client, buf);
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_5(client, args){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==3) {	//&& !IsFakeClient( i )
					CheatCommand(i, "give", "health", "", "");
				}
			}
		}
		PrintToChatAllTranslated("伺服器把所有特感回滿血", "[SM] ", "");
		Format(buf, sizeof(buf), "%T", "伺服器把所有特感回滿血", client);
		PrintToServer(buf);
	} else {
		Format(buf, sizeof(buf), "%T", "此指令只供伺服器端使用", client);
		PrintToChat(client, buf);
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_6(client, args){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==3 && !IsFakeClient(i) ) {	//&& !IsFakeClient( i )
					CheatCommand(i, "give", "health", "", "");
				}
			}
		}
		PrintToChatAllTranslated("伺服器把真人特感回滿血", "[SM] ", "");
		Format(buf, sizeof(buf), "%T", "伺服器把真人特感回滿血", client);
		PrintToServer(buf);
	} else {
		Format(buf, sizeof(buf), "%T", "此指令只供伺服器端使用", client);
		PrintToChat(client, buf);
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_7(client, args){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && GetClientTeam(i)==3 && IsFakeClient(i) ) {	//&& !IsFakeClient( i )
					CheatCommand(i, "give", "health", "", "");
				}
			}
		}
		PrintToChatAllTranslated("伺服器把電腦特感回滿血", "[SM] ", "");
		Format(buf, sizeof(buf), "%T", "伺服器把電腦特感回滿血", client);
		PrintToServer(buf);
	} else {
		Format(buf, sizeof(buf), "%T", "此指令只供伺服器端使用", client);
		PrintToChat(client, buf);
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_8(client, args){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i )) {
					CheatCommand(i, "give", "health", "", "");
				}
			}
		}
		PrintToChatAllTranslated("伺服器把所有人回滿血", "[SM] ", "");
		Format(buf, sizeof(buf), "%T", "伺服器把所有人回滿血", client);
		PrintToServer(buf);
	} else {
		Format(buf, sizeof(buf), "%T", "此指令只供伺服器端使用", client);
		PrintToChat(client, buf);
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_9(client, args){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && !IsFakeClient(i) ) {
					CheatCommand(i, "give", "health", "", "");
				}
			}
		}
		PrintToChatAllTranslated("伺服器把所有真人回滿血", "[SM] ", "");
		Format(buf, sizeof(buf), "%T", "伺服器把所有真人回滿血", client);
		PrintToServer(buf);
	} else {
		Format(buf, sizeof(buf), "%T", "此指令只供伺服器端使用", client);
		PrintToChat(client, buf);
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action:restore_hp_10(client, args){
	new flags_give = GetCommandFlags("give");
	//SetCommandFlags("give", flags_give & ~FCVAR_CHEAT);
	if (client<=0){
		for( new i = 1; i < GetMaxClients(); i++ ) {
			if (IsClientInGame( i )){
				if (IsClientConnected( i ) && IsFakeClient(i) ) {
					CheatCommand(i, "give", "health", "", "");
				}
			}
		}
		PrintToChatAllTranslated("伺服器把所有電腦回滿血", "[SM] ", "");
		Format(buf, sizeof(buf), "%T", "伺服器把所有電腦回滿血", client);
		PrintToServer(buf);
	} else {
		Format(buf, sizeof(buf), "%T", "此指令只供伺服器端使用", client);
		PrintToChat(client, buf);
	}
	//SetCommandFlags("give", flags_give|FCVAR_CHEAT);
	return Plugin_Handled;
}
new buttons;
public Action:version(client, args){
	if (client>0){
		Format(buf, sizeof(buf), "%T", "hp回復v", client, PLUGIN_VERSION);
		PrintToChat(client, buf);
	} else {
		Format(buf, sizeof(buf), "%T", "hp回復v", LANG_SERVER, PLUGIN_VERSION);
		PrintToServer(buf);
	}
	return Plugin_Handled;
}
bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
 	return false;
}
bool:IsPlayerGrapEdge(client)
{
 	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	return false;
}
