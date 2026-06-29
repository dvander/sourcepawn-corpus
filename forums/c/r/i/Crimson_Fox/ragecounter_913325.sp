/*
* Rage counter (c) 2009 Jonah Hirsch
* 
* 
* Counts ragequits in l4d, displays on quit
* 
*  
* Changelog								
* ------------	
* 1.5
*  - Fixed bug where rages would sometimes not be counted
* 1.4.1
*  - Typo! :D
* 1.4 
*  - sm_ragemap_autoreset updated
* 1.3 
*  - Added:
* 		sm_rage_autoreset
* 		sm_rage_reset
*  - Rages will now reset on maps specified in addons/sourcemod/configs/ragemaps.txt
* 1.2
*  - Fixed some users having double rage counts.	
* 1.1
*  - Timeouts are no longer counted
*  - Kicks are no longer counted
* 1.0									
*  - Initial Release			
* 
* 		
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.5.3"

new raged
new String:ragedid[128]
new rages
new Handle:fileHandle = INVALID_HANDLE
new Handle:sm_rage_autoreset = INVALID_HANDLE

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
	sm_rage_autoreset = CreateConVar("sm_rage_autoreset", "1", "Reset rages when a new game starts? 0=off, 1=use ragemaps.txt, 2=only maps with 01_in name, 3=use ragemaps.txt and maps with 01_ in name", FCVAR_NOTIFY, true, 0.0, true, 3.0)
	CreateConVar("sm_rage_version", PLUGIN_VERSION, "Rage Counter Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	RegAdminCmd("sm_rage_reset", Command_EmptyRages, ADMFLAG_KICK, "resets rage count")
	//RegAdminCmd("sm_rage", Command_AddRage, ADMFLAG_KICK, "Debug: adds one rage")
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"/configs/ragemaps.txt");
	if(!FileExists(path)){
		fileHandle = OpenFile(path,"a");
		WriteFileLine(fileHandle,"l4d_vs_hospital01_apartment");
		WriteFileLine(fileHandle,"l4d_vs_smalltown01_caves");
		WriteFileLine(fileHandle,"l4d_vs_farm01_hilltop");
		WriteFileLine(fileHandle,"l4d_vs_airport01_greenhouse");
		CloseHandle(fileHandle);
	}
	rages = 0;
}

public RageCount(Handle:event, const String:name[], bool:dontBroadcast){
	new client_id = GetEventInt(event, "userid")
	new client = GetClientOfUserId(client_id)
	new String:steamid[128]
	GetClientAuthString(client, steamid, sizeof(steamid))
	if (client == 0){
			return
	}
	if(IsClientInGame(client) && !IsFakeClient(client) && !IsClientTimingOut(client) && !IsClientInKickQueue(client)){
		if(client != raged && !StrEqual(steamid, ragedid)){
			rages++;
			if(rages == 1){
				PrintToChatAll("\x04[Rage Counter]\x01 There has been \x04%i\x01 rage quit.", rages)
			}else{	
				PrintToChatAll("\x04[Rage Counter]\x01 There have been \x04%i\x01 rage quits.", rages)
			}
			new ragesound = GetRandomInt(1, 21);
			for (new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					switch (ragesound)
					{
						case 21:
							//[Improv non-verbal displeasure sounds]
							ClientCommand(i, "playgamesound Player.Biker_NegativeNoise08");
						case 20:
							//Goddamn it!  I need to get the hell out of here!
							ClientCommand(i, "playgamesound Player.Biker_CallForRescue13");
						case 19:
							//You and me gotta find some tougher friends.
							ClientCommand(i, "playgamesound npc.Biker_DoubleDeathResponse03");
						case 18:
							//Ah bullshit.
							ClientCommand(i, "playgamesound npc.Biker_Swear08");
						case 17:
							//Bullshit.
							ClientCommand(i, "playgamesound npc.Biker_Swear10");
						case 16:
							//Oh man, this is just like counter-strike.
							ClientCommand(i, "playgamesound Player.Manager_TakeSubMachineGun03");
						case 15:
							//Dammit.
							ClientCommand(i, "playgamesound npc.Manager_Swears02");
						case 14:
							//Shit, shit, shit!
							ClientCommand(i, "playgamesound npc.Manager_Swears07");
						case 13:
							//That's some country-ass bullshit.
							ClientCommand(i, "playgamesound npc.Manager_Swears16");
						case 12:
							//God dammit
							ClientCommand(i, "playgamesound Player.NamVet_ReactionNegative07");
						case 11:
							//Son of a bitch
							ClientCommand(i, "playgamesound Player.NamVet_ReactionNegative09");
						case 10:
							//I didn't sign up for this shit!
							ClientCommand(i, "playgamesound npc.NamVet_DoubleDeathResponse02");
						case 9:
							//Go to hell.
							ClientCommand(i, "playgamesound npc.NamVet_SwearCoupdeGrace02");
						case 8:
							//Bull-frickin-horseshit.
							ClientCommand(i, "playgamesound npc.NamVet_Swears04");
						case 7:
							//God DAMMIT.
							ClientCommand(i, "playgamesound npc.NamVet_Swears09");
						case 6:
							//[Improv non-verbal displeasure sounds]
							ClientCommand(i, "playgamesound Player.TeenGirl_NegativeNoise13");
						case 5:
							//[Improv non-verbal displeasure sounds]
							ClientCommand(i, "playgamesound Player.TeenGirl_NegativeNoise14");						case 4:
							//Oh my god.
							ClientCommand(i, "playgamesound Player.TeenGirl_ReactionDisgusted06");
						case 3:
							//Ah bullshit.
							ClientCommand(i, "playgamesound npc.TeenGirl_Swear09");
						case 2:
							//Dammit.
							ClientCommand(i, "playgamesound npc.TeenGirl_Swear10");
						case 1:
							//What a dick.
							ClientCommand(i, "playgamesound npc.TeenGirl_WorldAirport05NPC07");
					}
				}
			}
			raged = client
			ragedid = steamid
		}
	}
}

public Action:Command_Rages(client, args){
	if(rages == 1){
		ReplyToCommand(client, "\x04[Rage Counter]\x01 There has been \x04%i\x01 rage quit.", rages)
	}else{	
		ReplyToCommand(client, "\x04[Rage Counter]\x01 There have been \x04%i\x01 rage quits.", rages)
	}
}


public OnClientAuthorized(client, const String:auth[]){
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

public OnMapStart(){
	new String:map[128]
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
			if(strcmp(line, map, false) == 0){
				rages = 0
			}
		}
		CloseHandle(fileHandle);
	}
	if(GetConVarInt(sm_rage_autoreset) == 2 || GetConVarInt(sm_rage_autoreset) == 3){
		if (StrContains(map, "01_") != -1 )
		{
			rages = 0
		}
	}
}

public Action:Command_EmptyRages(client, args){
	rages = 0
}

/*public Action:Command_AddRage(client, args){
	rages++
}*/
