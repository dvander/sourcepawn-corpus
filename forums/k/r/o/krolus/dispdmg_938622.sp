/*
It is reworked version of plugin "[TF2] Real-time Damage Display" by Wolfbane[3PG] (http://forums.alliedmods.net/showthread.php?t=98984)
*/

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define PLUGIN_VERSION "1.2.3"
#define MAXDMGHIST 5
#define TIMER_INTERVAL 0.2
#define DD_ENABLED 1
#define DD_DONE 2
#define DD_TAKEN 4
#define DD_SLIDE 8

//Declare global vars
new Handle:gcvar_enabled = INVALID_HANDLE;
new Handle:gcvar_triggerList = INVALID_HANDLE;
new Handle:gcvar_default = INVALID_HANDLE;
new g_player_old_health[MAXPLAYERS + 1];
new bool:g_ddEnabled[MAXPLAYERS],
	bool:g_ddDone[MAXPLAYERS],
	bool:g_ddTaken[MAXPLAYERS];
	//bool:g_ddSlide[MAXPLAYERS];

new Handle:g_DmgDoneTimer[MAXPLAYERS+1],
	Handle:g_DmgTakenTimer[MAXPLAYERS+1],
	g_DmgDoneHist[MAXPLAYERS+1][MAXDMGHIST+1],
	g_DmgTakenHist[MAXPLAYERS+1][MAXDMGHIST+1];
	
new Handle:HudMsgDmgDone = INVALID_HANDLE,
	Handle:HudMsgDmgTaken = INVALID_HANDLE;
	
new Float:g_H;

static const hud_color_normal[] = {255, 240, 90};

public Plugin:myinfo = {
 name = "Display Damage",
 author = "kroleg",
 description = "This plugin enables real-time damage display just above cross-hair location when dealing damage",
 version = PLUGIN_VERSION,
 url = "http://tf2.kz"
 }

 //Plugin start
public OnPluginStart(){
	gcvar_enabled = CreateConVar("sm_displaydamage_enabled", "1", "Displays damage inflicted on enemy. 0 - Disabled, 1 - Enabled", _, true, 0.0, true, 1.0)
	gcvar_default = CreateConVar("sm_displaydamage_default", "14", "The default setting for a player upon joining the server. 0 - Disabled, 1 - Enabled", _, false, 0.0, false, 1.0)
	gcvar_triggerList = CreateConVar("sm_displaydamage_triggers", "displaydamage dd", "Allows custom keywords to trigger displaying damage (Def. /displaydamage , /dd)", _, false, 0.0 , false, 1.0)

	//Initialize displayEnabled to default setting
	/*new def = GetConVarInt(gcvar_default);
	for(new i =0; i< MaxClients; i++){
		if ((def & DD_ENABLED))
			g_ddEnabled[i] = true;
		else
			g_ddEnabled[i] = false;
		if ((def & DD_DONE))
			g_ddDone[i] = true;
		else
			g_ddDone[i] = false;
		if ((def & DD_TAKEN))
			g_ddTaken[i] = true;
		else
			g_ddTaken[i] = false;
	}*/

	RegisterTriggers() //Registers triggers based on gcvar_triggerList
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre)

	HudMsgDmgDone = CreateHudSynchronizer();
	HudMsgDmgTaken = CreateHudSynchronizer();

	// 1 = enable all //2 enable "done" //4 enable "taken"

	g_H = 0.5 - MAXDMGHIST * 0.05;
}
 
public OnMapStart(){
	for(new i =1; i<= MaxClients; i++){
		g_ddEnabled[i] = false;
		g_ddDone[i] = true;
		g_ddTaken[i] = true;
		g_DmgDoneTimer[i] = INVALID_HANDLE;
		g_DmgTakenTimer[i] = INVALID_HANDLE;
	}
}

public OnMapEnd(){
	for(new i =1; i<= MaxClients; i++){
		if (g_DmgDoneTimer[i] != INVALID_HANDLE){
			CloseHandle(g_DmgDoneTimer[i]);
			g_DmgDoneTimer[i] = INVALID_HANDLE;
		}
		if (g_DmgTakenTimer[i]!=INVALID_HANDLE){
			CloseHandle(g_DmgTakenTimer[i]);
			g_DmgTakenTimer[i] = INVALID_HANDLE;
		}
	}
}

//This function will register say hooks based on the trigger cvar
public RegisterTriggers(){
 decl String:triggers[64][64]
 decl String:cvarVal[512]
 GetConVarString(gcvar_triggerList, cvarVal, 512)
 new count = ExplodeString(cvarVal, " ", triggers, 64, 64)
 for (new i=0; i<count; i++)
	RegConsoleCmd(triggers[i],PlayerTogglePlugin, "Allows player to toggle Real-Time Damage Display on or off for themselves.", _)
}
 
 //Reset all settings to default
public OnClientPostAdminCheck(client){
	/*new def = GetConVarInt(gcvar_default);
	if (def & DD_ENABLED)
		g_ddEnabled[client] = true;
	else
		g_ddEnabled[client] = false;
	if (def & DD_DONE)
		g_ddDone[client] = true;
	else
		g_ddDone[client] = false;
	if (def & DD_TAKEN)
		g_ddTaken[client] = true;
	else
		g_ddTaken[client] = false;*/
	g_ddEnabled[client] = false;
 }
 
 //Toggles a player's damage display mode
public Action:PlayerTogglePlugin(client,args){
	if(GetConVarInt(gcvar_enabled)==0){
			PrintToChat(client, "\x04*** The admin has disabled this command ***");
			return Plugin_Handled;
		}	

	switch (g_ddEnabled[client])
	{
		case 0:{
			PrintToChat(client, "\x05Real-time Damage Display [ON]"); 
			g_ddEnabled[client] = true;
		}
		case 1:{
			PrintToChat(client, "\x05Real-time Damage Display [OFF]");       
			g_ddEnabled[client] = false;
		}    		
	}
	return Plugin_Handled;
}
 
 //This function executes on every game frame, and keeps track of players' health
public OnGameFrame(){
for (new client = 1; client <= MaxClients; client++) 
	if (IsClientInGame(client)) 
		g_player_old_health[client] = GetClientHealth(client);
}
 
//This function triggers when a player is damaged
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){	
	if (!GetConVarInt(gcvar_enabled)) return;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!attacker)
		return

	//new damage = g_player_old_health[victim] - GetEventInt(event,"health");
	new damage = g_player_old_health[victim] - GetClientHealth(victim);

	if (damage) {
		//Determine if enemy was killed
		new bool:killshot = !GetEventInt(event, "health");
		if (g_ddEnabled[attacker] && g_ddDone[attacker] && victim != attacker && !(GetEntProp(victim, Prop_Send, "m_nPlayerCond")&8)) {
			new ddhl = MAXDMGHIST;
			//смещаем хистори вверх
			if (g_DmgDoneHist[attacker][ddhl] != 0) {
				for (new i=1; i<MAXDMGHIST;i++){
					g_DmgDoneHist[attacker][i] = g_DmgDoneHist[attacker][i+1];
				}
			}
			//добавляем новый дамаг
			g_DmgDoneHist[attacker][ddhl] = damage;	
			//отображаем
			new String:sDmgHist[64];
			for (new i=1; i<=ddhl;i++){
				if (g_DmgDoneHist[attacker][i]){
					Format(sDmgHist, sizeof(sDmgHist), "%s%d\n", sDmgHist,g_DmgDoneHist[attacker][i]);
				} else{
					Format(sDmgHist, sizeof(sDmgHist), "%s\n", sDmgHist);
				}
			}
			if (!killshot)
				SetHudTextParams(-1.0, g_H, TIMER_INTERVAL, hud_color_normal[0], hud_color_normal[1], hud_color_normal[2], 10);
			else
				SetHudTextParams(-1.0, g_H, TIMER_INTERVAL, 255, 0, 0, 10);
			ShowSyncHudText(attacker, HudMsgDmgDone, "%s", sDmgHist);
			//убиваем старый таймер если он есть
			if (g_DmgDoneTimer[attacker] != INVALID_HANDLE)
				CloseHandle(g_DmgDoneTimer[attacker]);
			//стартуем новый таймер
			g_DmgDoneTimer[attacker] = CreateTimer(TIMER_INTERVAL,  Timer_RefreshDmgDone, attacker, TIMER_REPEAT);
		}
		if (g_ddEnabled[victim] && g_ddTaken[victim]){
			//смещаем хистори вниз
			if (g_DmgTakenHist[victim][1] != 0) {
				for (new i=MAXDMGHIST; i>1;i--){
					g_DmgTakenHist[victim][i] = g_DmgTakenHist[victim][i-1];
				}
			}
			//добавляем новый дамаг
			g_DmgTakenHist[victim][1] = damage;	
			//отображаем
			new String:sDmgHist[64];
			for (new i=1; i<=MAXDMGHIST;i++){
				if (g_DmgTakenHist[victim][i]){
					Format(sDmgHist, sizeof(sDmgHist), "%s-%d\n", sDmgHist,g_DmgTakenHist[victim][i]);
				} else{
					Format(sDmgHist, sizeof(sDmgHist), "%s\n", sDmgHist);
				}
			}
			SetHudTextParams(-1.0, 0.51, TIMER_INTERVAL, hud_color_normal[0], hud_color_normal[1], hud_color_normal[2], 10);
			ShowSyncHudText(victim, HudMsgDmgTaken, "%s", sDmgHist);
			if (g_DmgTakenTimer[victim]!=INVALID_HANDLE)
				CloseHandle(g_DmgTakenTimer[victim]);
			//стартуем новый таймер
			g_DmgTakenTimer[victim] = CreateTimer(TIMER_INTERVAL,  Timer_RefreshDmgTaken, victim, TIMER_REPEAT);
		}	
	}
}

//This function handles displaying the damage to the attacker
public Action:Timer_RefreshDmgDone(Handle:timer, any:client){
	if (!IsClientInGame(client)) {
		g_DmgDoneTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	SetHudTextParams(-1.0, g_H, TIMER_INTERVAL, 255, 240, 90, 255);
	//moving all dmg's "up"
	for (new i=1; i<MAXDMGHIST;i++){
		g_DmgDoneHist[client][i] = g_DmgDoneHist[client][i+1];
	}
	g_DmgDoneHist[client][MAXDMGHIST] = 0;
	//building dmghist string
	new String:sDmgHist[64];
	for (new i=1; i<=MAXDMGHIST;i++){
		if (g_DmgDoneHist[client][i]){
			Format(sDmgHist, sizeof(sDmgHist), "%s%d\n", sDmgHist,g_DmgDoneHist[client][i]);
		} else{
			Format(sDmgHist, sizeof(sDmgHist), "%s\n", sDmgHist);
		}
	}
	ShowSyncHudText(client, HudMsgDmgDone, "%s", sDmgHist);
	/*new bool:stopshow = true;
	for (new i=1; i<=MAXDMGHIST;i++){
		if (g_DmgDoneHist[client][i]) {
			stopshow = false;
			break;
		}
	}
	if (stopshow)
		return Plugin_Stop;*/
		
	return Plugin_Continue;
}

public Action:Timer_RefreshDmgTaken(Handle:timer, any:client){
	if (!IsClientConnected(client)) {
		g_DmgTakenTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	//смещаем хистори вниз
	for (new i=MAXDMGHIST; i>1;i--){
		g_DmgTakenHist[client][i] = g_DmgTakenHist[client][i-1];
	}
	g_DmgTakenHist[client][1] = 0;
	//отображаем
	new String:sDmgHist[64];
	for (new i=1; i<=MAXDMGHIST;i++){
		if (g_DmgTakenHist[client][i]){
			Format(sDmgHist, sizeof(sDmgHist), "%s-%d\n", sDmgHist,g_DmgTakenHist[client][i]);
		} else{
			Format(sDmgHist, sizeof(sDmgHist), "%s\n", sDmgHist);
		}
	}
	SetHudTextParams(-1.0, 0.51, TIMER_INTERVAL, 255, 240, 90, 10);
	ShowSyncHudText(client, HudMsgDmgTaken, "%s", sDmgHist);
	
	/*new bool:stopshow = true;
	for (new i=1; i<=MAXDMGHIST[client];i++){
		if (g_DmgTakenHist[client][i]) {
			stopshow = false;
			break;
		}
	}
	if (stopshow)
		return Plugin_Stop;*/

	return Plugin_Continue;
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (g_DmgDoneTimer[client] != INVALID_HANDLE){
		CloseHandle(g_DmgDoneTimer[client]);
		g_DmgDoneTimer[client] = INVALID_HANDLE;
	}
	if (g_DmgTakenTimer[client]!=INVALID_HANDLE){
		CloseHandle(g_DmgTakenTimer[client]);
		g_DmgDoneTimer[client] = INVALID_HANDLE;
	}
}