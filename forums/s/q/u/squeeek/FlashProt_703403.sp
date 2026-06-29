/*
* 	Original idea by Shaman, this is a rewritten version of WhoBangedMe?
* 
* 	Plugin by: trixX aka. SQuEeeK (trixXhu@gmail.com)
* 	Version 1.6 RC
* 	
* 	The plugin punishes players who flash their teammates.
* 	CVARs:
* 		flashprot_enable		- Turns plugin on or off. 0,1
* 		flashprot_mode			- Automatic or manual punishment. 0,1
* 		flashprot_time			- When a player is teamflashed and gets killed in this amount of time, the plugin throws up a punishment menu
* 		flashprot_punishment	- Sets the type of punishment. 0 - none, 1 - slap, 2 - slay, 3 - kick
* 		flashprot_limit			- Number of teamflashes after punishment is carried out (PER FLASHBANG, NOT PER FLASHED PERSON)
* 		flashprot_reset			- When should the plugin reset team-flash counter for players. 0 - round end, 1 - only after punishment
* 		flashprot_team			- Will slay flasher immediately if he flashes this amount or more of his team (when 0, its off)
* 		flashprot_announce		- Whom should the plugin inform about team-flash: 0 - flasher only, 1 - flasher and victim, 2 - team, 3 - everyone
* 
* 	Changelog:
*	
*	1.6.1 - 21.02.2009
*	====================================
*	Added german translation
*	
*	1.6 RC - 12.10.2008
* 	====================================
* 	Fixed translation bugs 
* 
* 	1.5 - 11.01.2008
* 	====================================
* 	Added new CVARs:
* 	- flashprot_mode
* 	  When set to 0, plugin will punish teamflasher automatically (after limit is reached)
* 	  When 1, if the flashed player is killed within a few seconds after the bang the plugin shows a punishment menu
* 	- flashprot_time
* 	  When a player is teamflashed and gets killed in this amount of time, the plugin throws up a punishment menu
* 
* 	1.4 - 10.25.2008
* 	====================================
* 	Plugin will now inform players accordingly when one of these cvar changes:
* 	flashprot_enable, flashprot_punishment, flashprot_limit
* 	
* 	1.  - 10.23.2008
*	====================================
* 	Added announcements, see flashprot_announce CVAR
* 
* 
* 	1.2 - 10.22.2008
*	====================================
* 	Initial release
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "1.6 RC"

new mpls;

new lastbanger;
new lastbangcount[MAXPLAYERS+1];
new Float:lastbangtime[MAXPLAYERS+1];
new teamflashcount[MAXPLAYERS+1];
new bool:annexclu[MAXPLAYERS+1];

new Handle:hEnabled = INVALID_HANDLE;
new Handle:hMode = INVALID_HANDLE;
new Handle:hTime = INVALID_HANDLE;
new Handle:hPunishment = INVALID_HANDLE;
new Handle:hLimit = INVALID_HANDLE;
new Handle:hReset = INVALID_HANDLE;
new Handle:hTeam = INVALID_HANDLE;
new Handle:hAnnounce = INVALID_HANDLE;


public Plugin:myinfo = {
	name = "FlashProt",
	author = "trixX",
	description = "This plugin adds punishment for team flashing",
	version = VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart(){
	CreateConVar("flashprot_version","1.5","Plugin version",FCVAR_CHEAT|FCVAR_PROTECTED);
	hEnabled	= CreateConVar("flashprot_enabled","1","Turns FlashProt on/off",FCVAR_PROTECTED);
	hMode		= CreateConVar("flashprot_mode","1","0 - players are punished automatically after limit is reached, 1 - flashed players get a punishmed menu if they are killed",FCVAR_PROTECTED);
	hTime		= CreateConVar("flashprot_time","3.0","If flashed players get killed within this amount of time, they get a punishment menu",FCVAR_PROTECTED,true,0.0,true,10.0);
	hPunishment = CreateConVar("flashprot_punishment","1","Type of autopunishment: 0 - off, 1 - slap, 2 - slay, 3 - kick",FCVAR_PROTECTED);
	hLimit 		= CreateConVar("flashprot_limit","5","Number of teamflashes after autopunishment is carried out",FCVAR_PROTECTED);
	hReset 		= CreateConVar("flashprot_reset","1","0 - reset counters at round start, 1 - reset counters only after punishment is carried out",FCVAR_PROTECTED);
	hTeam 		= CreateConVar("flashprot_team","1.0","When a player flashes this fraction or more of his team, he is slayed immediately (0 means off)",FCVAR_PROTECTED,true,0.0,true,1.0);
	hAnnounce 	= CreateConVar("flashprot_announce","1","Whom should the plugin inform about team-flash: 0 - flasher only, 1 - flasher and victim, 2 - team, 3 - everyone",FCVAR_PROTECTED);
	
	HookEvent("flashbang_detonate",Event_Flash);
	HookEvent("player_blind",Event_Blind);
	HookEvent("round_start",Event_RoundStart);
	
	HookConVarChange(hEnabled,cvcEnable);
	HookConVarChange(hPunishment,cvcPunishment);
	HookConVarChange(hLimit,cvcLimit);
	
	LoadTranslations("plugin.flashprot.base");
}

public cvcEnable(Handle:handle, const String:oldValue[], const String:newValue[]){
	if(StrEqual(oldValue,newValue)) return;
	if(Enabled()){
		if(StrEqual(newValue,"0"))
			PrintToChatAll("\x04[FlashProt] \x01%t","FP Off");
		else
			PrintToChatAll("\x04[FlashProt] \x01%t","FP On");
	}
}

public cvcPunishment(Handle:handle, const String:oldValue[], const String:newValue[]){
	if(StrEqual(oldValue,newValue)) return;
	if(Enabled()){
		switch(StringToInt(newValue)){
			case 0: PrintToChatAll("\x04[FlashProt] \x01%t","FP Punishment Off");
			case 1: PrintToChatAll("\x04[FlashProt] \x01%t","FP Punishment Slap"); 
			case 2: PrintToChatAll("\x04[FlashProt] \x01%t","FP Punishment Slay");
			case 3: PrintToChatAll("\x04[FlashProt] \x01%t","FP Punishment Kick");
		}
	}
}

public cvcLimit(Handle:handle, const String:oldValue[], const String:newValue[]){
	if(StrEqual(oldValue,newValue)) return;
	if(Enabled()) PrintToChatAll("\x04[FlashProt] \x01%t","FP Limit Changed",StringToInt(newValue));
}

public OnMapStart(){
	mpls = GetMaxClients();
}

public OnClientPutInServer(client){
	lastbangcount[client]=0;
	lastbangtime[client]=0.0;
	teamflashcount[client]=0;
	annexclu[client]=false;
	if(Enabled()) PrintToChat(client,"\x03[FlashProt] \x01%t","FP Running");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	if(!Enabled() || GetConVarInt(hReset) != 0) return;
	for(new p=1;p<=mpls;p++){
		lastbangcount[p]=0;
		teamflashcount[p]=0;
	}
}

public Event_Blind(Handle:event, const String:name[], bool:dontBroadcast){
	if(!Enabled()) return;
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(lastbanger == 0 || !IsPlayerAlive(client) || client == lastbanger || !IsClientInGame(lastbanger) || (GetClientTeam(client) != GetClientTeam(lastbanger))) return;
	new Float:time = GetGameTime();
	new Handle:data;
	Announce(lastbanger);
	if(GetConVarInt(hMode) == 0){
		CreateDataTimer(0.1,TeamBang,data);
		WritePackCell(data,lastbanger);
		WritePackCell(data,client);
		WritePackFloat(data,time);
	} else {
		CreateDataTimer(GetConVarFloat(hTime),ManualPunish,data);
		WritePackCell(data,lastbanger);
		WritePackCell(data,client);
	}
}

public Event_Flash(Handle:event, const String:name[], bool:dontBroadcast){
	if(!Enabled() || GetConVarInt(hMode) == 1) return;
	lastbanger = GetClientOfUserId(GetEventInt(event,"userid"));
	lastbangtime[lastbanger] = GetGameTime();
	CreateTimer(0.2,EvalBang,lastbanger);
}

public Action:TeamBang(Handle:timer, Handle:data){
	ResetPack(data);
	new flasher = ReadPackCell(data);
	new victim = ReadPackCell(data);
	new Float:time = ReadPackFloat(data);
	
	if(FloatCompare(lastbangtime[flasher],time) != 0){
		lastbangcount[flasher] = 1;
		lastbangtime[flasher] = time;
	} else lastbangcount[flasher]++;
	
	if(GetConVarInt(hAnnounce) > 0){
		annexclu[victim]=true;
		new String:fn[MAX_NAME_LENGTH];
		GetClientName(flasher,fn,MAX_NAME_LENGTH);
		PrintToChat(victim,"\x04[FlashProt] \x01%t","FP Flashed V",fn);
	}
}

public Action:ManualPunish(Handle:timer, Handle:data){
	ResetPack(data);
	new flasher = ReadPackCell(data);
	new victim = ReadPackCell(data);
	if(IsPlayerAlive(victim)) return;
	new Handle:menu = CreateMenu(PunishMenu);
	new String:name[MAX_NAME_LENGTH];
	GetClientName(flasher,name,MAX_NAME_LENGTH);
	SetMenuTitle(menu,"%t","FP Menu Died",name);
	new String:tmp[4];
	IntToString(flasher,tmp,sizeof(tmp));
	AddMenuItem(menu,tmp,"Forgive");
	AddMenuItem(menu,tmp,"Slap");
	AddMenuItem(menu,tmp,"Slay");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu,victim,6);
}
public PunishMenu(Handle:menu, MenuAction:action, victim, param2){
	if (action == MenuAction_Select){
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		new flasher = StringToInt(info);
		if(param2==0){
			new String:name[MAX_NAME_LENGTH];
			GetClientName(victim,name,MAX_NAME_LENGTH);
			PrintToChat(flasher,"\x04[FlashProt] \x01%t","FP Forgive",name);
		} else if(param2==1){
			new val = RoundToFloor(GetClientHealth(flasher)*0.5);
			SlapPlayer(flasher,val);
			PrintToChat(flasher,"\x04[FlashProt] \x01%t","FP Punished");
		} else if(param2==2){
			ForcePlayerSuicide(flasher);
			PrintToChat(flasher,"\x04[FlashProt] \x01%t","FP Punished");
		}
	}
	else if (action == MenuAction_Cancel){
		//
	}
	else if (action == MenuAction_End){
		CloseHandle(menu);
	}
}

public Action:EvalBang(Handle:timer, any:flasher){
	if(lastbangcount[flasher] == 0) return;
	if(IsClientInGame(flasher)){
		teamflashcount[flasher]++;
		new limit = GetConVarInt(hLimit);
		new pnsh = GetConVarInt(hPunishment);
		new diff = limit - teamflashcount[flasher];
		new tsize = GetTeamClientCount(GetClientTeam(flasher));
		if(GetConVarInt(hTeam) > 0 && tsize*GetConVarFloat(hTeam) <= lastbangcount[flasher]) diff=0;
		
		if(diff==0){
			new String:pname[MAX_NAME_LENGTH];
			GetClientName(flasher,pname,MAX_NAME_LENGTH);
		
			if(pnsh==1){
				new val = RoundToFloor(GetClientHealth(flasher)*0.5);
				SlapPlayer(flasher,val);
				PrintToChat(flasher,"\x04[FlashProt] \x01%t","FP Punished");
			}
			else if(pnsh==2){
				ForcePlayerSuicide(flasher);
				PrintToChat(flasher,"\x04[FlashProt] \x01%t","FP Punished");
			}
			else if(pnsh==3){
				KickClient(flasher,"%T","FP Kicked",flasher);
				PrintToChatAll("\x04[FlashProt] \x01%t","FP Kicked All",pname);
			}
			teamflashcount[flasher]=0;
		}
		else if(pnsh==0){
			teamflashcount[flasher]=0;
			PrintToChat(flasher,"\x04[FlashProt] \x01%t","FP Watch Short");
		}
		else
			PrintToChat(flasher,"\x04[FlashProt] \x01%t","FP Watch",diff);
	}
	lastbangcount[flasher] = 0;
}

Enabled(){
	return GetConVarBool(hEnabled);
}

Announce(const flasher){
	new a = GetConVarInt(hAnnounce);
	if(!Enabled() || a < 2) return;
	new ft = GetClientTeam(flasher);
	new String:fn[MAX_NAME_LENGTH];
	GetClientName(flasher,fn,MAX_NAME_LENGTH);
	
	for(new p=1;p<=mpls;p++){
		if(IsClientInGame(p) && !annexclu[p] && flasher!=p){
			if(!(a==2 && GetClientTeam(p)!=ft)){
				PrintToChat(p,"\x04[FlashProt] \x01%t","FP Flashed A",fn);
			}
		}
		annexclu[p]=false;
	}
}