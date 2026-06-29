/*
DoD One Weapon Mod
Hell Phoenix
http://www.charliemaurice.com/plugins

Description:
	Allows for a single weapon to be used by everyone.  Also gives them infinate
	ammo.

Thanks To:
	twistedeuphoria for the infiniteammo plugin...I used some of the code here
	
Versions:
	1.0
		* First Public Release!
	1.1
		* Fixed getting weapon while a spectator
		* Fixed a bug where anyone could enable OWM...whoops
	1.2
		* Fixed the menu not turning on/off OWM
		* Changed the way weapons are removed to hopefully get rid of the crash on linux
		* Optimised some code

Todo:
	* unlimited clips...not ammo (if this is possible...not sure how to do it yet)
	* add PKN type mode
	 
Cvarlist (default value):
	dod_owm_weapon 6 - Use the values below for each weapon.
	dod_owm_mode 1 - 1 kills user before giving them weapon, 0 just strips all 
		weapons and give the current allowed weapon.
	dod_oneweapon 0 - 0 is Disable, 1 is Enable (use this in a config file if you 
		want to turn it on for a certain map).

Admin Commands:
	dod_owm_menu - Brings up weapon menu and enable/disable
	
User Commands:
	None

Weapon values (for using with cvar):
	1 spade
	2 american knife
	3 c96
	4 p38
	5 colt
	6 bar
	7 thompson
	8 m1carbine
	9 mp40
	10 mp44
	11 bazooka
	12 panzerschreck
	13 garand
	14 k98
	15 k98_scoped
	16 springfield
	17 mg42
	18 30cal
	19 German Nades
	20 US Nades
	
	
*/




#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"
#define WEAPONNUM 21

// Plugin definitions
public Plugin:myinfo = 
{
	name = "DoD One Weapon Mod",
	author = "Hell Phoenix",
	description = "DoD One Weapon Mod",
	version = PLUGIN_VERSION,
	url = "http://www.charliemaurice.com/plugins/"
};

new Handle:owm_weapon;
new Handle:owm_mode;
new Handle:weapon_timer;
new Handle:ammo_timer;
new owmweapon;
new activeoffset;
new clipoffset;
new bool:OneWeaponEnabled = false;

new String:WeaponName[WEAPONNUM][] = {
	"",
	"weapon_spade", "weapon_amerknife",
	"weapon_c96", "weapon_p38", "weapon_colt",
	"weapon_bar", "weapon_thompson", "weapon_m1carbine", "weapon_mp40", "weapon_mp44",
	"weapon_bazooka", "weapon_pschreck", "weapon_garand", "weapon_k98", "weapon_k98_scoped",
	"weapon_spring", "weapon_mg42", "weapon_30cal",
	"weapon_frag_ger", "weapon_frag_us"
};

new WeaponAmmo[WEAPONNUM] = {
	0,
	0, 0,
	30, 30, 30,
	40, 40, 30, 40, 40,
	5, 5, 50, 50, 50,
	50, 150, 150,
	3, 3
};




public OnPluginStart(){
	CreateConVar("dod_owm_version", PLUGIN_VERSION, "DoD One Weapon Mod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	owm_weapon = CreateConVar("dod_owm_weapon","6","Set the weapon index",FCVAR_PLUGIN);
	owm_mode = CreateConVar("dod_owm_mode","1","1 kills user before giving them weapon, 0 just strips all weapons and give the current allowed weapon",FCVAR_PLUGIN);
	RegAdminCmd("dod_oneweapon", Command_Activate, ADMFLAG_BAN, "sm_oneweapon <0|1> : 0 is Disable, 1 is Enable");
	RegAdminCmd("dod_owm_menu", owm_menu, ADMFLAG_BAN, "Brings up OWM Menu");
	HookEvent("player_spawn", Event_PlayerSpawn);

	new off = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
	if(off != -1){
		activeoffset = off;
	}
	off = -1;
	off = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	if(off != -1){
		clipoffset = off;
	}
}

public OnMapEnd(){
	ServerCommand("dod_oneweapon 0");
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	if(!OneWeaponEnabled)
		return;
	
	new clientId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientId);

	if (!IsPlayerAlive(client))
		return;
	
	new Handle:pack;
	CreateDataTimer(0.5,player_give,pack);
	WritePackCell(pack, client);
	
	return;
}

public Action:weapon_check(Handle:timer){
	if(!OneWeaponEnabled)
		return Plugin_Handled;
		
	owmweapon = GetConVarInt(owm_weapon);	
	decl String:weapondata[32];
	new playersconnected;
	playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(IsClientInGame(i)){
			if (IsPlayerAlive(i)){
				GetClientWeapon(i, weapondata, sizeof(weapondata));
				if(strcmp(weapondata,WeaponName[owmweapon]) != 0){
					StripWeapons(i);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:ammo_give(Handle:timer){
	if(!OneWeaponEnabled)
		return Plugin_Handled;
		
	owmweapon = GetConVarInt(owm_weapon);	
	new data;
	new playersconnected;
	playersconnected = GetMaxClients();
	for (new i = 1; i <= playersconnected; i++){
		if(IsClientInGame(i)){
			if(owmweapon == 19 || owmweapon == 20){
				GivePlayerItem(i, WeaponName[owmweapon]);
				data = GetEntDataEnt(i, activeoffset);
				SetEntData(data, clipoffset, WeaponAmmo[owmweapon], 4, true);
			}else{
				data = GetEntDataEnt(i, activeoffset);
				SetEntData(data, clipoffset, WeaponAmmo[owmweapon], 4, true);
			}
		}
	}
	return Plugin_Continue;
}

public Action:owm_menu(client, args){
	new Handle:owmmenu = CreateMenu(owm_menu_handler);
	SetMenuTitle(owmmenu, "DoD One Weapon Mod");
	if (OneWeaponEnabled)
		AddMenuItem(owmmenu, "disable", "Disable");
	else
		AddMenuItem(owmmenu, "enable", "Enable");
	AddMenuItem(owmmenu, "spade", "Spade");
	AddMenuItem(owmmenu, "amerknife", "American Knife");
	AddMenuItem(owmmenu, "c96", "c96");
	AddMenuItem(owmmenu, "p38", "p38");
	AddMenuItem(owmmenu, "colt", "Colt");
	AddMenuItem(owmmenu, "bar", "Bar");
	AddMenuItem(owmmenu, "thompson", "Thompson");
	AddMenuItem(owmmenu, "m1carbine", "m1carbine");
	AddMenuItem(owmmenu, "mp40", "mp40");
	AddMenuItem(owmmenu, "mp44", "mp44");
	AddMenuItem(owmmenu, "bazooka", "Bazooka");
	AddMenuItem(owmmenu, "pschreck", "Panzerschreck");
	AddMenuItem(owmmenu, "garand", "Garand");
	AddMenuItem(owmmenu, "k98", "k98");
	AddMenuItem(owmmenu, "k98_scoped", "Scoped k98");
	AddMenuItem(owmmenu, "spring", "Springfield");
	AddMenuItem(owmmenu, "mg42", "mg42");
	AddMenuItem(owmmenu, "30cal", "30cal");
	AddMenuItem(owmmenu, "frag_ger", "German Grenades");
	AddMenuItem(owmmenu, "frag_us", "US Grenades");	
	
	DisplayMenu(owmmenu, client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}

public owm_menu_handler(Handle:owmmenu, MenuAction:action, param1, param2){
	if (action == MenuAction_Select){
		decl String:info[32];
		GetMenuItem(owmmenu, param2, info, sizeof(info));
		
		if(strcmp(info,"disable") == 0){
			ServerCommand("dod_oneweapon 0");
		}else if(strcmp(info,"enable") == 0){
			ServerCommand("dod_oneweapon 1");
		}else if(strcmp(info,"spade") == 0){
			set_owm(param1, 1);
		}else if(strcmp(info,"amerknife") == 0){
			set_owm(param1, 2);
		}else if(strcmp(info,"c96") == 0){
			set_owm(param1, 3);
		}else if(strcmp(info,"p38") == 0){
			set_owm(param1, 4);
		}else if(strcmp(info,"colt") == 0){
			set_owm(param1, 5);
		}else if(strcmp(info,"bar") == 0){
			set_owm(param1, 6);
		}else if(strcmp(info,"thompson") == 0){
			set_owm(param1, 7);
		}else if(strcmp(info,"m1carbine") == 0){
			set_owm(param1, 8);
		}else if(strcmp(info,"mp40") == 0){
			set_owm(param1, 9);
		}else if(strcmp(info,"mp44") == 0){
			set_owm(param1, 10);
		}else if(strcmp(info,"bazooka") == 0){
			set_owm(param1, 11);
		}else if(strcmp(info,"pschreck") == 0){
			set_owm(param1, 12);
		}else if(strcmp(info,"garand") == 0){
			set_owm(param1, 13);
		}else if(strcmp(info,"k98") == 0){
			set_owm(param1, 14);
		}else if(strcmp(info,"k98_scoped") == 0){
			set_owm(param1, 15);
		}else if(strcmp(info,"spring") == 0){
			set_owm(param1, 16);
		}else if(strcmp(info,"mg42") == 0){
			set_owm(param1, 17);
		}else if(strcmp(info,"30cal") == 0){
			set_owm(param1, 18);
		}else if(strcmp(info,"frag_ger") == 0){
			set_owm(param1, 19);
		}else if(strcmp(info,"frag_us") == 0){
			set_owm(param1, 20);
		}
	} 
	if (action == MenuAction_End){
		CloseHandle(owmmenu);
	}

}

public Action:player_give(Handle:timer, Handle:pack){	
	ResetPack(pack);
	new client = ReadPackCell(pack);
	owmweapon = GetConVarInt(owm_weapon);
		
	if(owmweapon == 0)
		return Plugin_Handled;
	
	StripWeapons(client);
	GivePlayerItem(client, WeaponName[owmweapon]);
	new data;
	data = GetEntDataEnt(client, activeoffset);
	SetEntData(data, clipoffset, WeaponAmmo[owmweapon], 4, true);
	
	return Plugin_Continue;
}

public Action:Command_SetWeapon(client, args){
	
	if(OneWeaponEnabled){
		PrintToChat(client, "[OWM] You can't change weapon now ! Disable OWM and try again.");
		return Plugin_Handled;
	}
	owmweapon = GetConVarInt(owm_weapon);
	
	new String:arg[4];
	GetCmdArg(1, arg, sizeof(arg));
	new i = StringToInt(arg);
	
	if(i == 0){
		owmweapon = 0;
		return Plugin_Handled;
	}
	
	if( !i || i>WEAPONNUM || !WeaponName[i][0] ){
		PrintToChat(client,"[OWM] Wrong weapon ID !");
		return Plugin_Handled;
	}
	owmweapon = i;
	PrintToChat(client, "[OWM] Weapon Changed to %s !",WeaponName[owmweapon]);
	
	return Plugin_Handled;
}

public Action:Command_Activate(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[OWM] Usage: dod_oneweapon <0|1> : 0 is Disable, 1 is Enable");
		return Plugin_Handled;	
	}
	owmweapon = GetConVarInt(owm_weapon);
	
	new String:arg[2];
	GetCmdArg(1, arg, sizeof(arg));
	
	if(strcmp(arg,"1",false) == 0){
		OneWeaponEnabled = true;
	}else if(strcmp(arg,"0",false) == 0){
		OneWeaponEnabled = false;
	}else{
		new startidx = 7;
		decl String:weapondata[32];
		strcopy(weapondata, 32, WeaponName[owmweapon]);
		PrintToConsole(client, "%s Only Mode %s",weapondata[startidx],OneWeaponEnabled ? "Enabled" : "Disabled");
		return Plugin_Handled;
	}
	exec_owm(client, owmweapon);
	return Plugin_Handled;
}

set_owm(client, weapon){
	if(weapon){
		ServerCommand("dod_owm_weapon %d", weapon);
		OneWeaponEnabled = true;
		CreateTimer(1.0, weapon_check, weapon_timer, TIMER_REPEAT);
		CreateTimer(10.0, ammo_give, ammo_timer, TIMER_REPEAT);
	}else{
		OneWeaponEnabled = false;
		CloseHandle(weapon_timer);
		CloseHandle(ammo_timer);
	}
	exec_owm(client, weapon);
}

exec_owm(client, weapon){
	new owmmode = GetConVarInt(owm_mode);
	if(!owmmode){
		StripWeapons(client);
		GivePlayerItem(client, WeaponName[weapon]);
	}else{
		new playersconnected = GetMaxClients();
		for (new i = 1; i <= playersconnected; i++){
			if(IsClientInGame(i)){
				if (IsPlayerAlive(i))
					ForcePlayerSuicide(i);
			}			
		}
	}
	
	new startidx = 7;
	decl String:weapondata[32];
	strcopy(weapondata, 32, WeaponName[weapon]);

	PrintToConsole(client, "%s Only Mode %s",weapondata[startidx],OneWeaponEnabled ? "Enabled" : "Disabled");
	PrintCenterTextAll("%s Only Mode Has Been %s!",weapondata[startidx],OneWeaponEnabled ? "Enabled" : "Disabled");
	
	if(OneWeaponEnabled)
		PrintToChatAll("%s only allowed",weapondata[startidx]);
	else 
		PrintToChatAll("All guns allowed");
	
}


StripWeapons(client){
	new ent;
	for(new i = 0; i < 4; i++){
    ent = GetPlayerWeaponSlot(client, i);
    if(ent != -1)
    	RemovePlayerItem(client, ent);
  }
}


