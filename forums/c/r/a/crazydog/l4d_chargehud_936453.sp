/*
* L4D Recharge HUD (c) 2009 Jonah Hirsch
* 
* 
* Shows recharge time for Boomers, Smokers, and Tanks in a HUD
* 
* 
* Changelog								
* ------------	
* 1.5.4
*  - Bug fix
* 1.5.3
*  - Bug fix
* 1.5.2
*  - Fixed possible bug with variables used to set which recharges to show
* 1.5.1
*  - Added FCVAR_DONTRECORD to verison cvar
* 1.5
*  - Fixed bug where incorrect people would see the HUD
* 1.4
*  - l4d_chargehud_display and l4d_chargehud_admindisplay are updated as they are changed instead of on plugin reload
* 1.3
*  - All timers are killed on round end
*  - Added l4d_chargehud_smoker_hit, l4d_chargehud_smoker_miss, l4d_chargehud_boomer, l4d_chargehud_tank, l4d_chargehud_display, l4d_chargehud_admindisplay
* 1.2
*  - Times will no longer go negative
*  - All times are reset on round end
* 1.1
*  - Recharge menu now shows itself to spectators too
*  - Timer should stop now
* 1.0									
*  - Initial Release			
* 		
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.5.4"

new smokerDelay
new boomerDelay
new tankDelay
new timeleft[MAXPLAYERS]
new Handle:timerH[MAXPLAYERS]
new bool:released[MAXPLAYERS] = false
new Handle:menuTimer = INVALID_HANDLE
new Handle:abilityHUD = INVALID_HANDLE
new bool:isData
new Handle:l4d_chargehud_smoker_hit
new Handle:l4d_chargehud_smoker_miss
new Handle:l4d_chargehud_boomer
new Handle:l4d_chargehud_tank
new Handle:l4d_chargehud_display
new Handle:l4d_chargehud_admindisplay
new bool:smokerhit, bool:smokermiss, bool:boomer, bool:tank, display, bool:admindisplay

public Plugin:myinfo = 
{
	name = "L4D Infected Ability HUD",
	author = "Crazydog",
	description = "Shows rechareg time for SI abilities",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

public OnPluginStart(){
	HookEvent("ability_use", StartTimer)
	HookEvent("tongue_release", startSmokerTimer)
	HookEvent("player_death", resetTimeleft)
	HookEvent("player_spawn", resetTimeleft)
	HookEvent("round_end", resetAlltimeleft)
	smokerDelay = GetConVarInt(FindConVar("tongue_hit_delay"))
	boomerDelay = GetConVarInt(FindConVar("z_vomit_interval"))
	tankDelay = GetConVarInt(FindConVar("z_tank_throw_interval"))
	l4d_chargehud_smoker_hit = CreateConVar("l4d_chargehud_smoker_hit", "1", "Enable timer for successful smoker pulls?", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	l4d_chargehud_smoker_miss = CreateConVar("l4d_chargehud_smoker_miss", "1", "Enable timer for missed smoker pulls?", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	l4d_chargehud_boomer = CreateConVar("l4d_chargehud_boomer", "1", "Enable timer for boomers?", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	l4d_chargehud_tank = CreateConVar("l4d_chargehud_tank", "1", "Enable timer for tanks?", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	l4d_chargehud_display = CreateConVar("l4d_chargehud_display", "1", "Who should see the HUD? 0=nobody, 1=infected, 2=survivors, 3=spectators, 4=infected + survivors, 5=infected + spectators, 6=survivors + spectators, 7=everybody", FCVAR_NOTIFY, true, 0.0, true, 7.0)
	HookConVarChange(l4d_chargehud_display, displayChange)
	l4d_chargehud_admindisplay = CreateConVar("l4d_chargehud_admindisplay", "0", "Should admins always see the times?", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	HookConVarChange(l4d_chargehud_admindisplay, adminDisplayChange)
	AutoExecConfig(true, "l4d_chargehud")
	CreateConVar("l4d_chargehud_version", PLUGIN_VERSION, "Recharge HUD Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public OnMapStart(){
	smokerhit = GetConVarBool(l4d_chargehud_smoker_hit)
	smokermiss = GetConVarBool(l4d_chargehud_smoker_miss)
	boomer = GetConVarBool(l4d_chargehud_boomer)
	tank = GetConVarBool(l4d_chargehud_tank)
	display = GetConVarInt(l4d_chargehud_display)
	admindisplay = GetConVarBool(l4d_chargehud_admindisplay)
}

public OnMapEnd(){
}

public Action:StartTimer(Handle:event, const String:name[], bool:dontBroadcast){
	new String:ability[128]
	GetEventString(event, "ability", ability, sizeof(ability))
	new userid = GetEventInt(event, "userid")
	new client = GetClientOfUserId(userid)
	if(smokermiss){
		if(StrContains(ability, "tongue") != -1){
			released[client] = false
			new type = GetEventInt(event, "context")
			if(type == 0){
				new smokerDelayShort = GetConVarInt(FindConVar("tongue_miss_delay"))
				timeleft[client] = smokerDelayShort
				timerH[client] = CreateTimer(1.0, abilityTimer, client, TIMER_REPEAT)
				menuTimer = CreateTimer(1.0, showAbilityHUD, _, TIMER_REPEAT)
			}
		}
	}
	
	if(boomer){
		if(StrContains(ability, "vomit") != -1){
			timeleft[client] = boomerDelay
			timerH[client] = CreateTimer(1.0, abilityTimer, client, TIMER_REPEAT)
			menuTimer = CreateTimer(1.0, showAbilityHUD, _, TIMER_REPEAT)
		}
	}
	
	if(tank){
		if(StrContains(ability, "throw") != -1){
			timeleft[client] = tankDelay
			timerH[client] = CreateTimer(1.0, abilityTimer, client, TIMER_REPEAT)
			menuTimer = CreateTimer(1.0, showAbilityHUD, _, TIMER_REPEAT)
		}
	}
	
}

public Action:startSmokerTimer(Handle:event, const String:name[], bool:dontBroadcast){
	if(smokerhit){
		new userid = GetEventInt(event, "userid")
		new client = GetClientOfUserId(userid)
		if(!released[client]){
			timeleft[client] = smokerDelay
			timerH[client] = CreateTimer(1.0, abilityTimer, client, TIMER_REPEAT)
			menuTimer = CreateTimer(1.0, showAbilityHUD, _, TIMER_REPEAT)
			released[client] = true
		}
	}
}

public Action:abilityTimer(Handle:timer, any:client){
	if (IsClientInGame(client) && !IsFakeClient(client)){
		if(!IsPlayerAlive(client)){
			if(timerH[client] != INVALID_HANDLE){
				KillTimer(timerH[client])
			}
			CloseHandle(abilityHUD)
			return
		}
		timeleft[client]--
		if(timeleft[client] == 0){
			KillTimer(timerH[client])
			CloseHandle(abilityHUD)
		}
	}
}

public Action:showAbilityHUD(Handle:timer){
	new bool:showHUD = false
	isData = false
	new String:name[MAX_NAME_LENGTH]
	abilityHUD = CreatePanel()
	SetPanelTitle(abilityHUD, "Recharge Times:")
	new String:HUDtext[256]
	for (new i=1; i<=MaxClients; i++)
	{
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
			if(timeleft[i] > 0){
				isData = true
				GetClientName(i, name, MAX_NAME_LENGTH)
				Format(HUDtext, sizeof(HUDtext), "%s: %i", name, timeleft[i])
				DrawPanelItem(abilityHUD, HUDtext)
			}else if(!isData){
				isData = false
			}
		}
	}
	if(!isData){
		return Plugin_Stop
	}
	for(new i=1; i<MaxClients; i++){
		showHUD = false
		new team = GetClientTeam(i)
		if(display == 0){
			showHUD = false
		}else
		if(display == 1){
			if(team == 3){
				showHUD = true
			}
		}else
		if(display == 2){
			if(team == 2){
				showHUD = true
			}
		}else
		if(display == 3){
			if(team == 1){
				showHUD = true
			}
		}else
		if(display == 4){
			if(team == 3 || team == 2){
				showHUD = true
			}
		}else
		if(display == 5){
			if(team == 3 || team == 1){
				showHUD = true
			}
		}else
		if(display == 6){
			if(team == 2 || team == 1){
				showHUD = true
			}
		}else
		if(display == 7){
			showHUD = true
		}
	
		if(admindisplay){
			if(GetUserAdmin(i) != INVALID_ADMIN_ID){
				showHUD = true
			}
		}
		
		if(isData && showHUD){
			SendPanelToClient(abilityHUD, i, HUDhandler, 1)
		}
	}
	return Plugin_Continue
}

public HUDhandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public Action:resetTimeleft(Handle:event, const String:name[], bool:dontBroadcast){
	new userid = GetEventInt(event, "userid")
	new client = GetClientOfUserId(userid)
	timeleft[client] = 0
}

public Action:resetAlltimeleft(Handle:event, const String:name[], bool:dontBroadcast){
	for (new i=1; i<=MaxClients; i++)
	{
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
			timeleft[i] = 0
			if(timerH[i] != INVALID_HANDLE){
				KillTimer(timerH[i])
				KillTimer(menuTimer)
			}
		}
	}
}

public displayChange(Handle:conver, const String:oldValue[], const String:newValue[]){
	display = StringToInt(newValue)
}

public adminDisplayChange(Handle:conver, const String:oldValue[], const String:newValue[]){
	if(StringToInt(newValue) == 1){
		admindisplay = true
	}else{
		admindisplay = false
	}
}
