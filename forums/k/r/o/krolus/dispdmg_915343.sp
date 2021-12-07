/*
It is reworking version of plugin "[TF2] Real-time Damage Display" by Wolfbane[3PG] (http://forums.alliedmods.net/showthread.php?t=98984)
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define MAXDMGHIST 5
#define TIMER_INTERVAL 0.2

//Declare global vars
new Handle:cvar_pluginEnabled = INVALID_HANDLE;
//new Handle:cvar_toggleSlide = INVALID_HANDLE;
new Handle:cvar_triggerList = INVALID_HANDLE;
//new Handle:cvar_default = INVALID_HANDLE;
new g_player_old_health[MAXPLAYERS + 1];
new bool:g_DisplayDmgDone[MAXPLAYERS]
new bool:g_DisplayDmgTaken[MAXPLAYERS]
//static bool:g_critical=false

//new generation slide effect :D
new g_DmgDoneTimers[MAXPLAYERS+1];
new g_DmgTakenTimers[MAXPLAYERS+1];
new g_DmgDoneTimerTick[MAXPLAYERS+1];
new g_DmgTakenTimerTick[MAXPLAYERS+1];
new g_DmgDoneHist[MAXPLAYERS+1][MAXDMGHIST+1];
new g_DmgTakenHist[MAXPLAYERS+1][MAXDMGHIST+1];
new g_DmgDoneHistLength[MAXPLAYERS+1];
new g_DmgTakenHistLength[MAXPLAYERS+1];

new Handle:HudMsgDmgDone;
new Handle:HudMsgDmgTaken;
new Float:g_H;
//Plugin definitions
public Plugin:myinfo = {
 name = "Display Damage",
 author = "kroleg",
 description = "This plugin enables real-time damage display just above cross-hair location when dealing damage",
 version = PLUGIN_VERSION,
 url = "http://tf2.kz"
 }

 //Plugin start
public OnPluginStart(){
	cvar_pluginEnabled = CreateConVar("displaydamage_enabled", "1", "Displays damage inflicted on enemy. 0 - Disabled, 1 - Enabled", _, true, 0.0, true, 1.0)
	//cvar_toggleSlide = CreateConVar("realtimedamage_slide", "1", "Animates damage display with an upward slide. 0 - Disable, 1 - Enable", _, true, 0.0, true, 1.0)
	//cvar_default = CreateConVar("realtimedamage_default", "1", "The default setting for a player upon joining the server. 0 - Disabled, 1 - Enabled", _, false, 0.0, false, 1.0)
	cvar_triggerList = CreateConVar("displaydamage_triggers", "showdamage displaydamage dd", "Allows custom keywords to trigger displaying damage (Def. !showdamage, /showdamage, !displaydamage, /displaydamage)", _, false, 0.0 , false, 1.0)

	//Initialize displayEnabled to default setting
	//new def = GetConVarInt(cvar_default)
	for(new i =0; i< MaxClients; i++){
		g_DisplayDmgDone[i] = false;
		g_DisplayDmgTaken[i] = false;
	}

	RegisterTriggers() //Registers triggers based on cvar_triggerList
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre)
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookEvent("player_connect", Event_PlayerDisconnect);

	HudMsgDmgDone = CreateHudSynchronizer();
	HudMsgDmgTaken = CreateHudSynchronizer();
	for (new i=1; i<=MaxClients;i++){
		g_DmgDoneHistLength[i] = MAXDMGHIST;
		g_DmgTakenHistLength[i] = MAXDMGHIST;
	}
	
	g_H = 0.5 - MAXDMGHIST * 0.05;
}
 
//This function will register say hooks based on the trigger cvar
public RegisterTriggers(){
 decl string: triggers[64][64]
 decl String: cvarVal[512]
 GetConVarString(cvar_triggerList, cvarVal, 512)
 new count = ExplodeString(cvarVal, " ", triggers, 64, 64)
 for (new i=0; i<count; i++)
	RegConsoleCmd(triggers[i],PlayerTogglePlugin, "Allows player to toggle Real-Time Damage Display on or off for themselves.", _)
}
 
 //Reset g_DisplayDmgDone back to default
 public OnClientDisconnect(client){
	g_DisplayDmgDone[client] = false;
	g_DisplayDmgTaken[client] = false;
 }
 
 //Toggles a player's damage display mode
public Action:PlayerTogglePlugin(client,args){
	if(GetConVarInt(cvar_pluginEnabled)==0)
		{
			PrintToChat(client, "\x04*** The admin has disabled this command ***");
			return Plugin_Handled;
		}	

	new player = g_DisplayDmgDone[client]
	//Switch statements only allow one command
	switch (player)
	{
		case 0:{
			PrintToChat(client, "\x05Real-time Damage Display [ON]"); 
			g_DisplayDmgDone[client] = true;
			g_DisplayDmgTaken[client] = true;
		}
		case 1:{
			PrintToChat(client, "\x05Real-time Damage Display [OFF]");       
			g_DisplayDmgDone[client] = false;
			g_DisplayDmgTaken[client] = false;
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
 //Calculates the amount and then calls DisplayDamage
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){	
	if (!GetConVarInt(cvar_pluginEnabled)) return;
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!attacker)
		return
		
	//new damage = g_player_old_health[victim] - GetEventInt(event,"health");
	new damage = g_player_old_health[victim] - GetClientHealth(victim);

	if (damage) {
		//Determine if enemy was killed
		new bool:killShot = !GetEventInt(event, "health");
		if (g_DisplayDmgDone[attacker] && victim != attacker){
			new ddhl = g_DmgDoneHistLength[attacker];
			//смещаем хистори вверх
			if (g_DmgDoneHist[attacker][ddhl] != 0) {
				for (new i=1; i<g_DmgDoneHistLength[attacker];i++){
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
			SetHudTextParams(-1.0, g_H, TIMER_INTERVAL, 255, 240, 90, 10);
			ShowSyncHudText(attacker, HudMsgDmgDone, "%s", sDmgHist);
			//делаем пометочку что добавлен еще один таймер
			g_DmgDoneTimers[attacker] += 1 ;
			//
			//PrintToChat(attacker,"added t, now %d",g_DmgDoneTimers[attacker]);
			//стартуем новый таймер
			new Handle:pack
			CreateDataTimer(TIMER_INTERVAL,  RefreshDmgDone, pack, TIMER_REPEAT)
			WritePackCell(pack, attacker)
			WritePackCell(pack, damage)
			//WritePackFloat(pack, y1)
			WritePackCell(pack, killShot)
		}
		if (g_DisplayDmgTaken[victim]){
			//смещаем хистори вниз
			if (g_DmgTakenHist[victim][1] != 0) {
				for (new i=g_DmgDoneHistLength[victim]; i>1;i--){
					g_DmgTakenHist[victim][i] = g_DmgTakenHist[victim][i-1];
				}
			}
			//добавляем новый дамаг
			g_DmgTakenHist[victim][1] = damage;	
			//отображаем
			new String:sDmgHist[64];
			for (new i=1; i<=g_DmgTakenHistLength[victim];i++){
				if (g_DmgTakenHist[victim][i]){
					Format(sDmgHist, sizeof(sDmgHist), "%s-%d\n", sDmgHist,g_DmgTakenHist[victim][i]);
				} else{
					Format(sDmgHist, sizeof(sDmgHist), "%s\n", sDmgHist);
				}
			}
			SetHudTextParams(-1.0, 0.51, TIMER_INTERVAL, 255, 240, 90, 10);
			ShowSyncHudText(victim, HudMsgDmgTaken, "%s", sDmgHist);
			//делаем пометочку что добавлен еще один таймер
			g_DmgTakenTimers[victim] += 1 ;
			//PrintToChat(victim,"<%s>",sDmgHist);
			//стартуем новый таймер
			new Handle:pack
			CreateDataTimer(TIMER_INTERVAL,  RefreshDmgTaken, pack, TIMER_REPEAT)
			WritePackCell(pack, victim)
			//WritePackCell(pack, damage)
			//WritePackFloat(pack, y1)
			//WritePackCell(pack, killShot)
		}	
	}
}

//This function handles displaying the damage to the attacker
public Action:RefreshDmgDone(Handle:timer, Handle:pack){
	//new r=0, b=125, g=125
	ResetPack(pack)
	new client = ReadPackCell(pack)
	//new damage = ReadPackCell(pack)
	//yVal = ReadPackFloat(pack)
	//new bool:kCheck = ReadPackCell(pack)
	//if (timer != g_TimersDmgDone[client]) return;
	if (!IsClientConnected(client) || g_DmgDoneTimers[client] > 1) {
		g_DmgDoneTimers[client] -= 1;
		//PrintToChat(client,"del t, now %d",g_DmgDoneTimers[client]);
		return Plugin_Stop;
	}
	
	SetHudTextParams(-1.0, g_H, TIMER_INTERVAL, 255, 240, 90, 255);
	//moving all dmg's "up"
	for (new i=1; i<g_DmgDoneHistLength[client];i++){
		g_DmgDoneHist[client][i] = g_DmgDoneHist[client][i+1];
	}
	//PrintToChat(client,"Dmoved");
	g_DmgDoneHist[client][g_DmgDoneHistLength[client]] = 0;
	//PrintToChat(client,"Dmg %d = %d",g_DmgDoneHistLength[client],g_DmgDoneHist[client][g_DmgDoneHistLength[client]]);
	//building dmghist string
	new String:sDmgHist[64];
	for (new i=1; i<=g_DmgDoneHistLength[client];i++){
		if (g_DmgDoneHist[client][i]){
			Format(sDmgHist, sizeof(sDmgHist), "%s%d\n", sDmgHist,g_DmgDoneHist[client][i]);
		} else{
			Format(sDmgHist, sizeof(sDmgHist), "%s\n", sDmgHist);
		}
	}
	//PrintToChat(client,"DSbuilded : <%s>",sDmgHist);
	ShowSyncHudText(client, HudMsgDmgDone, "%s", sDmgHist);
	/*new bool:stopshow = true;
		for (new i=1; i<=g_DmgDoneHistLength[client];i++){
			if (g_DmgDoneHist[client][i]) {
				stopshow = true;
				break;
			}
		}
	if (stopshow) return Plugin_Stop;*/
	return Plugin_Continue;
}

public Action:RefreshDmgTaken(Handle:timer, Handle:pack){
	//new r=0, b=125, g=125
	ResetPack(pack)
	new client = ReadPackCell(pack)
	//new damage = ReadPackCell(pack)
	//yVal = ReadPackFloat(pack)
	//new bool:kCheck = ReadPackCell(pack)
	//if (timer != g_TimersDmgDone[client]) return;
	if ( g_DmgTakenTimers[client] > 1 || !IsClientConnected(client)) {
		g_DmgTakenTimers[client] -= 1;
		//PrintToChat(client,"del t, now %d",g_DmgDoneTimers[client]);
		return Plugin_Stop;
	}
	
	//смещаем хистори вниз
	for (new i=g_DmgDoneHistLength[client]; i>1;i--){
		g_DmgTakenHist[client][i] = g_DmgTakenHist[client][i-1];
	}
	g_DmgTakenHist[client][1] = 0;
	//отображаем
	new String:sDmgHist[64];
	for (new i=1; i<=g_DmgTakenHistLength[client];i++){
		if (g_DmgTakenHist[client][i]){
			Format(sDmgHist, sizeof(sDmgHist), "%s-%d\n", sDmgHist,g_DmgTakenHist[client][i]);
		} else{
			Format(sDmgHist, sizeof(sDmgHist), "%s\n", sDmgHist);
		}
	}
	SetHudTextParams(-1.0, 0.51, TIMER_INTERVAL, 255, 240, 90, 10);
	ShowSyncHudText(client, HudMsgDmgTaken, "%s", sDmgHist);
	return Plugin_Continue;
}


public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast){
	new userid = GetEventInt(event,"userid");
	new client = GetClientOfUserId(userid);

	g_DisplayDmgDone[client] = false; 
	g_DisplayDmgTaken[client] = false; 
}