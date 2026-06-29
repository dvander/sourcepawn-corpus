#include <sourcemod>
#include <sdktools>
#include <clientprefs_stocks>
public Plugin myinfo = {
	name = "toggle game_text hud client side",
	author = "xnet",
	description = "",
	version = "1.0",
	url = ""
}
Cookie Cookie_ToggleHud = null;
bool g_bHideHud[MAXPLAYERS+1] = {false,...};
public void OnPluginStart(){
	Cookie_ToggleHud = new Cookie("Toggle_GameTextHud", "", CookieAccess_Private);
	HookUserMessage(GetUserMessageId("HudMsg"), OnHudMsg, true);  
	RegConsoleCmd("sm_togglehud", Command_ToggleHUD);
}
public Action Command_ToggleHUD(int client, int args){
	
	if(!IsClientInGame(client)) 
		return Plugin_Handled;
	
	g_bHideHud[client] = !g_bHideHud[client];
	
	if(AreClientCookiesCached(client)){	
		Cookie_ToggleHud.SetBool(client,g_bHideHud[client] ? true:false);
		PrintToChat(client,"%s ,ClientPrefs Save->SU",g_bHideHud[client] ? "Disable HUD" : "Enable HUD")
	}else PrintToChat(client,"%s ,ClientPrefs Save-> Your cookies not yet cached please try again later",g_bHideHud[client] ? "Disable HUD" : "Enable HUD")
	
	
	return Plugin_Handled;
}

public void OnClientDisconnect(int client){
	g_bHideHud[client] = false;
}

public void OnClientCookiesCached(int client){
	g_bHideHud[client] = Cookie_ToggleHud.GetBool(client);
}

public Action OnHudMsg(UserMsg msg_id, Protobuf msg, int[] players, int playersNum, bool reliable, bool init){
	for (int i = 0; i < playersNum; i++){
		if (g_bHideHud[players[i]]){
			for (int x = i; x < playersNum-1; x++){
				players[x] = players[x+1];
			}
			playersNum--;
			i--;
		}
	}
	return (playersNum > 0) ? Plugin_Changed : Plugin_Stop;
}
