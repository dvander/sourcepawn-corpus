/*
* Rage counter (c) 2009 Jonah Hirsch
* 
* 
* Counts ragequits in l4d, displays on quit
* 
*  
* Changelog
* ------------
* 2.1
* - Added support for versus/scavenge mutations (will continue to update in the future)
* - ragemaps.txt now includes passing, sacrifice, and no mercy by default
* 2.0
* - Changed version numbers to match between plugins
* 1.1
*  - Added support for scavenge (teamversus/teamscavenge is implied)
*  - Added sm_ragestats - prints all rage stats through one command
* 1.0
*  - Added Left4Dead 2 Support 
*
* 		
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "2.1"

new raged
new String:ragedid[128]
new String:phraseStart[128] = "\x04[Rage Counter]\x01 There"
new rages
static String:MaxRagesFile[128];
new Handle:fileHandle = INVALID_HANDLE
new Handle:MaxRageHandle = INVALID_HANDLE
new Handle:sm_rage_autoreset = INVALID_HANDLE
new Handle:sm_rage_enable = INVALID_HANDLE
new Handle:sm_rage_versuscheck = INVALID_HANDLE
new bool:exemptRage
new bool:exemptRage2

new String:GmaxRages[64], String:GtotalRages[64], String:GtotalGames[64], String:GrageTime[64]

public Plugin:myinfo = 
{
	name = "Rage Counter",
	author = "Crazydog",
	description = "Counts ragequits in l4d",
	version = PLUGIN_VERSION,
	url = "http://theelders.net"
}

public OnPluginStart(){
	HookEvent("player_disconnect", RageCount, EventHookMode_Pre)
	//HookEvent("player_connect", ResetRaged)
	RegConsoleCmd("sm_rages", Command_Rages, "Gets # of rages")
	RegConsoleCmd("sm_maxrages", Command_MaxRages, "Gets highest # of rages")
	RegConsoleCmd("sm_avgrages", Command_AvgRages, "Gets average # of rages per game")
	RegConsoleCmd("sm_totalrages", Command_TotalRages, "Gets total # of rages")
	RegConsoleCmd("sm_totalgames", Command_TotalGames, "Gets total # of games")
	RegConsoleCmd("sm_ragetime", Command_RageTime, "Gets average connection time of ragequitters")
	RegConsoleCmd("sm_ragestats", Command_RageStats, "Prints all rage stats")
	sm_rage_autoreset = CreateConVar("sm_rage_autoreset", "1", "Reset rages when a new game starts? 0=off, 1=use ragemaps.txt, 2=only maps with m1_ in name, 3=use ragemaps.txt and maps with m1_ in name", FCVAR_NOTIFY, true, 0.0, true, 3.0)
	sm_rage_enable = CreateConVar("sm_rage_enable", "1", "Enable Rage Counter? 1=yes(on) 0=no(off)", _, true, 0.0, true, 1.0)
	sm_rage_versuscheck = CreateConVar("sm_rage_versuscheck", "1", "Disable plugin if not versus mode? 1=yes 0=no", FCVAR_NOTIFY, true, 0.0, true, 1.0)
	CreateConVar("sm_rage_version", PLUGIN_VERSION, "Rage Counter Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	RegAdminCmd("sm_rage_reset", Command_ResetRages, ADMFLAG_KICK, "resets rage count")
	RegAdminCmd("sm_rage_resettotal", Command_ResetTotalRages, ADMFLAG_KICK, "resets total rages")
	RegAdminCmd("sm_rage_resetgames", Command_ResetTotalGames, ADMFLAG_KICK, "resets total games")
	RegAdminCmd("sm_rage_resetmax", Command_ResetMaxRages, ADMFLAG_KICK, "resets max rages")
	RegAdminCmd("sm_rage_resettimes", Command_ResetRageTime, ADMFLAG_KICK, "resets average rage time")
	RegAdminCmd("sm_exemptrage", Command_ExemptRage, ADMFLAG_KICK, "Exempts the next quit from counting as a rage") 
	HookConVarChange(FindConVar("mp_gamemode"), gamemodeChange)
	//RegAdminCmd("sm_rage", Command_AddRage, ADMFLAG_KICK, "Debug: adds one rage")
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"/configs/ragemaps.txt");
	if(!FileExists(path)){
		fileHandle = OpenFile(path,"a");
		WriteFileLine(fileHandle,"c1m1_hotel");
		WriteFileLine(fileHandle,"c2m1_highway");
		WriteFileLine(fileHandle,"c3m1_plankcountry");
		WriteFileLine(fileHandle,"c4m1_milltown_a");
		WriteFileLine(fileHandle,"c5m1_waterfront");
		WriteFileLine(fileHandle,"c6m1_riverbank");
		WriteFileLine(fileHandle,"c7m1_docks");
		WriteFileLine(fileHandle,"c8m1_apartment");
		CloseHandle(fileHandle);
	}
	BuildPath(Path_SM, MaxRagesFile, PLATFORM_MAX_PATH, "data/maxrages.txt")
	MaxRageHandle = OpenFile(MaxRagesFile, "a")
	CloseHandle(MaxRageHandle)
	AutoExecConfig(true, "plugin.rage")
	exemptRage = false;
	exemptRage2 = false;
}


public RageCount(Handle:event, const String:name[], bool:dontBroadcast){
	if(GetConVarInt(sm_rage_enable) == 1){
		new client_id = GetEventInt(event, "userid")
		new client = GetClientOfUserId(client_id)
		new String:steamid[128]
		if (client == 0){
				return
		}
		if(exemptRage){
			exemptRage = false
			return
		}
		if(exemptRage2){
			exemptRage2 = false;
			return
		}
		GetClientAuthString(client, steamid, sizeof(steamid))
		if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientTimingOut(client) && !IsClientInKickQueue(client)){
			if(client != raged && !StrEqual(steamid, ragedid)){
				rages++;
				readRageFile()
				new totalRagesInt = StringToInt(GtotalRages)
				totalRagesInt++
				IntToString(totalRagesInt, GtotalRages, sizeof(GtotalRages))
				new Float:rageTimeFloat = StringToFloat(GrageTime)
				rageTimeFloat += GetClientTime(client)
				FloatToString(rageTimeFloat, GrageTime, sizeof(GrageTime))
				writeRageFile()
				new String:maxRages[64]
				MaxRageHandle = OpenFile(MaxRagesFile, "r")
				ReadFileString(MaxRageHandle, maxRages, sizeof(maxRages))
				CloseHandle(MaxRageHandle)
				new maxRagesInt = StringToInt(maxRages)
				if(rages > maxRagesInt){
					readRageFile()
					IntToString(rages, GmaxRages, sizeof(GmaxRages))
					writeRageFile()
					PrintToChatAll("\x04[Rage Counter]\x03 Rage quit record broken!")
				}
				
				if(rages == 1){
					PrintToChatAll("%s has been \x04%i\x01 rage quit", phraseStart, rages)
				}else{	
					PrintToChatAll("%s have been \x04%i\x01 rage quits", phraseStart, rages)
				}
				raged = client
				ragedid = steamid
			}
		}
	}
}

public Action:Command_Rages(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		if(rages == 1){
			ReplyToCommand(client, "%s has been \x04%i\x01 rage quit", phraseStart, rages)
		}else{	
			ReplyToCommand(client, "%s have been \x04%i\x01 rage quits", phraseStart, rages)
		}
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:Command_MaxRages(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		ReplyToCommand(client, "\x04[Rage Counter]\x01 The highset number of rages in one game is \x04%s", GmaxRages)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:Command_AvgRages(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		new Float:totalRages = StringToFloat(GtotalRages)
		new Float:totalGames = StringToFloat(GtotalGames)
		if(totalGames == 0){
			ReplyToCommand(client, "\x04[Rage Counter]\x01 No games have been played yet! Average cannot be calculated")
			return Plugin_Handled
		}
		new Float:average = totalRages/totalGames
		ReplyToCommand(client, "\x04[Rage Counter]\x01 The average number of rages per game is \x04%f", average)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:Command_TotalRages(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		ReplyToCommand(client, "\x04[Rage Counter]\x01 The total number of rages is \x04%s", GtotalRages)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:Command_TotalGames(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		ReplyToCommand(client, "\x04[Rage Counter]\x01 The total number of games is \x04%s", GtotalGames)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:Command_RageTime(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		
		if(StringToInt(GtotalRages) == 0){
			ReplyToCommand(client, "\x04[Rage Counter]\x01 No rages have happened yet! Rage time cannot be calculated")
			return Plugin_Handled
		}
		
		new time = StringToInt(GrageTime)
		time = time / StringToInt(GtotalRages)
		
		new hours = time / 3600
		new remainder = time % 3600
		new minutes = remainder / 60
		new seconds = remainder % 60
		
		new String:hrpre[1], String:minpre[1], String:secpre[1]
		
		if (hours < 10){
			hrpre = "0"
		}else{
			hrpre = ""
		}
		
		if (minutes < 10){
			minpre = "0"
		}else{
			minpre = ""
		}
		
		if (seconds < 10){
			secpre = "0"
		}else{
			secpre = ""
		}
		ReplyToCommand(client, "\x04[Rage Counter]\x01 The average rage time is \x04%s%i:%s%i:%s%i", hrpre, hours, minpre, minutes, secpre, seconds)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public OnClientAuthorized(client, const String:auth[]){
	if(GetConVarInt(sm_rage_enable) == 1){
		if (client == 0){
				return
		}
		if(raged == client){
			raged = -1
		}
		if(StrEqual(ragedid, auth)){
			ragedid = ""
		}
	}
}

public OnMapStart(){
	new Handle:gamemodeHandle = FindConVar("mp_gamemode")
	new String:gamemode[64]
	new bool:validmode = false
	GetConVarString(gamemodeHandle, gamemode, sizeof(gamemode))
	if(GetConVarInt(sm_rage_versuscheck) == 1){
		new String:gamemodes[7][32] = {"versus", "scavenge", "mutation11", "mutation12", "mutation18", "mutation19", "mutation13"}
		GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode))
		//if(StrContains(gamemode, "versus", false) == -1 && StrContains(gamemode, "scavenge", false) == -1){
		for (new i = 0; i < sizeof(gamemodes); i++) { 
			if(strcmp(gamemode,gamemodes[i]) == 0){
				validmode = true
				break;
			}
		} 
		if(!validmode){ 
			if(GetConVarInt(sm_rage_enable) != 0){
				LogMessage("Versus or Scavenge not detected! Plugin Disabled")
				SetConVarInt(sm_rage_enable, 0)
			}
		}else{
			if(GetConVarInt(sm_rage_enable) != 1){
				LogMessage("Versus or Scavenge detected! Plugin Enabled")
				SetConVarInt(sm_rage_enable, 1)
			}
		}
	}
	if(GetConVarInt(sm_rage_enable) == 1){
		exemptRage = false;
		exemptRage2 = false;
		new String:map[128], bool:gameAdded
		gameAdded = false
		GetCurrentMap(map, sizeof(map))
		if(GetConVarInt(sm_rage_autoreset) == 1 || GetConVarInt(sm_rage_autoreset) == 3){
			decl String:path[PLATFORM_MAX_PATH],String:line[128];
			BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"/configs/ragemaps.txt");
			fileHandle=OpenFile(path,"r");
			while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
			{
				new len = strlen(line);
				if (line[len-1] == '\n')
					{	
						line[len-1] = '\0';
					}  
				if(strcmp(line, map, false) == 0 || StrContains(gamemode, "scavenge", false) != -1){
					rages = 0
					if(!gameAdded){
						addGame()
						gameAdded = true
					}
					
				}
			}
			CloseHandle(fileHandle);
			return
		}
		if(GetConVarInt(sm_rage_autoreset) == 2 || GetConVarInt(sm_rage_autoreset) == 3){
			if (StrContains(map, "m1_") != -1 || StrContains(gamemode, "scavenge", false) != -1)
			{
				rages = 0
				if(!gameAdded){
					addGame()
					gameAdded = true
				}
			}
		}
	}
}

public Action:Command_ResetRages(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		rages = 0
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:Command_ResetTotalRages(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		GtotalRages = "0"
		writeRageFile()
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:Command_ResetTotalGames(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		GtotalGames = "0"
		writeRageFile()
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:Command_ResetMaxRages(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		GmaxRages = "0"
		writeRageFile()
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:Command_ResetRageTime(client, args){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		GrageTime = "0"
		writeRageFile()
		return Plugin_Handled
	}
	return Plugin_Handled
}

public addGame(){
	if(GetConVarInt(sm_rage_enable) == 1){
		readRageFile()
		new totalGamesInt = StringToInt(GtotalGames)
		totalGamesInt++
		IntToString(totalGamesInt, GtotalGames, sizeof(GtotalGames))
		writeRageFile()
	}
}

public readRageFile(){
	if(GetConVarInt(sm_rage_enable) == 1){
		new len
		new Handle:TotalRageHandle = OpenFile(MaxRagesFile, "r")
		ReadFileLine(TotalRageHandle, GmaxRages, sizeof(GmaxRages))
		ReadFileLine(TotalRageHandle, GtotalRages, sizeof(GtotalRages))
		ReadFileLine(TotalRageHandle, GtotalGames, sizeof(GtotalGames))
		ReadFileLine(TotalRageHandle, GrageTime, sizeof(GrageTime))
		if(StrEqual(GmaxRages,""))
			GmaxRages = "0"
		if(StrEqual(GtotalRages,""))
			GtotalRages = "0"
		if(StrEqual(GtotalGames,""))
			GtotalGames = "0"		
		if(StrEqual(GrageTime, ""))
			GrageTime = "0"
		len = strlen(GmaxRages);
		if (GmaxRages[len-1] == '\n'){	
			GmaxRages[len-1] = '\0';
		}  
		len = strlen(GtotalRages);
		if (GtotalRages[len-1] == '\n'){	
			GtotalRages[len-1] = '\0';
		}  
		len = strlen(GtotalGames);
		if (GtotalGames[len-1] == '\n'){	
			GtotalGames[len-1] = '\0';
		}  	
		len = strlen(GrageTime)
		if(GrageTime[len-1] == '\n'){
			GrageTime[len-1] = '\0';
		}
		CloseHandle(TotalRageHandle)
	}
}

public writeRageFile(){
	if(GetConVarInt(sm_rage_enable) == 1){
		new Handle:rewriteHandle = OpenFile(MaxRagesFile, "w+")
		WriteFileLine(rewriteHandle, GmaxRages)
		WriteFileLine(rewriteHandle, GtotalRages)
		WriteFileLine(rewriteHandle, GtotalGames)
		WriteFileLine(rewriteHandle, GrageTime)
		CloseHandle(rewriteHandle)
	}
}

public gamemodeChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(GetConVarInt(sm_rage_versuscheck) == 1){
		new String:gamemode[64]
		GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode))
		if(StrContains(gamemode, "versus", false) == -1 && StrContains(gamemode, "scavenge", false) == -1){
			if(GetConVarInt(sm_rage_enable) != 0){
				LogMessage("Versus or Scavenge not detected! Plugin Disabled")
				SetConVarInt(sm_rage_enable, 0)
			}
		}else{
			if(GetConVarInt(sm_rage_enable) != 1){
				LogMessage("Versus or Scavenge detected! Plugin Enabled")
				SetConVarInt(sm_rage_enable, 1)
			}
		}
	}
}

public Action:Command_ExemptRage(client, args){
	exemptRage = true;
	exemptRage2 = true;
	return Plugin_Handled
}

public Action:Command_RageStats(client, args){
	Command_Rages(client, args)
	Command_MaxRages(client, args)
	Command_AvgRages(client, args)
	Command_TotalRages(client, args)
	Command_TotalGames(client, args)
	Command_RageTime(client, args)
}

/*public Action:Command_AddRage(client, args){
	rages++
}*/