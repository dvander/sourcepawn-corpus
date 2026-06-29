#pragma semicolon 1


#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#tryinclude <goomba>
#tryinclude <rtd>
#tryinclude <rtd2>

#define VERSION_NUMER "0.924"

#define CHAT_PREFIX "\x03[Friendly]\x01"

#define SLOT_COUNT 6
#define SLOT_PRIMARY 0
#define SLOT_SECONDARY 1
#define SLOT_MELEE 2

#define DELAY 5


//The plugin will only do some work on these entity classnames editing.
//Editing that is unnecessary and can cause harm when removing.
new const String:filter_clsname[][] = {

	{"func_button"},
	{"trigger_capture_area"},
	{"item_teamflag"},
	{"item_healthkit_full"},
	{"item_healthkit_medium"},
	{"item_healthkit_small"},
	{"item_ammopack_full"},
	{"item_ammopack_medium"},
	{"item_ammopack_small"},
	{"tf_ammo_pack"},
	{"item_currencypack_large"},
	{"item_currencypack_medium"},
	{"item_currencypack_small"},
	{"tf_spell_pickup"},
	{"item_powerup_temp"}, //I think that's the crit powerup from mannpower when it was in beta
	{"item_powerup_crit"}, //The actual crit powerup from mannpower
	{"item_powerup_uber"}, //Uber powerup from mannpower
	{"info_powerup_spawn"} //The randomly spawned mannpower powerup

};


//You cannot taunt with these weapon classnames.
//If you wish to define specific IDs head to banned_weapons_ids straight below.
new const String:banned_weapon_classnames[][] = {

	{"tf_weapon_knife"},
	{"tf_weapon_compound_bow"},
	{"tf_weapon_shotgun_pyro"},
	{"tf_weapon_flaregun"},
	{"tf_weapon_flaregun_revenge"}, //Manmelter only
	//ADDITIONALY, PYROS CAN'T TAUNT WITH tf_weapon_shotgun!
	//I didn't want to put it here, because other classes
	//are harmless with it, Pyros though... they have to
	//be damn difficult, don't they...

};


//You cannot taunt with these weapon IDs.
//If you wish to define whole classnames head to banned_weapon_classnames straight above.
new const banned_weapons_ids[] = {

	37,		//Ubersaw
	128,	//Equalizer
	304,	//Amputator
	775,	//Escape Plan
	1003	//Fesitive Ubersaw

};


//Weapons which have these classnames will be removed from the player who's going Friendly.
//Keep in mind that they'd have to visit the resupply locker after they've gone hostile and want them back.
new const String:banned_classes[][] = {

	{"tf_weapon_pda_engineer_build"},
	{"tf_weapon_pda_engineer_destroy"},
	{"tf_weapon_builder"},
	{"tf_weapon_pda_spy"},
	{"tf_weapon_invis"},
	{"tf_weapon_medigun"},
	{"tf_weapon_sapper"}

};


new Handle:fwd_Friendly;
new Handle:fwd_Hostile;

new bool:IsFriendly[MAXPLAYERS+1]	= {false, ...};
new bool:IsInSpawn[MAXPLAYERS+1]	= {false, ...};
new cmd_delay[MAXPLAYERS+1]		= {0, ...};


public Plugin:myinfo = {
	name			= "[TF2] Friendly Simple",
	author			= "Phil25 (original by Derek D. Howard)",
	description	= "Allows players to become invulnerable to damage from other players, while also being unable to attack other players.",
	version		= VERSION_NUMER,
	url			= "https://forums.alliedmods.net/showthread.php?p=2358678"
};

public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLate, String:strError[], iErr_Max){

	decl String:s_game[32]; s_game[0] = '\0';
	GetGameFolderName(s_game, sizeof(s_game));
	if(!StrEqual(s_game, "tf")){
		Format(strError, iErr_Max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	
	CreateNative("FriendlySimple_IsFriendly", Native_CheckIfFriendly);
	CreateNative("FriendlySimple_IsInSpawn", Native_CheckIfInSpawn);
	CreateNative("FriendlySimple_HasAccess", Native_CheckIfHasAccess);
	CreateNative("FriendlySimple_SetFriendly", Native_SetFriendly);
	
	RegPluginLibrary("Friendly Simple");

	return APLRes_Success;

}

public OnAllPluginsLoaded(){

	if(FindPluginByFile("friendly.smx") != INVALID_HANDLE){
		PrintToServer("[ERROR]");
		PrintToServer("[ERROR] Friendly Simple may NOT work alongside the original Friendly plugin; unloading friendlysimple.smx");
		PrintToServer("[ERROR]");
		ServerCommand("sm plugins unload friendlysimple");
	}

}

public OnPluginStart(){

	for(new client = 1; client <= MaxClients; client++){
		if(IsValidClient(client))
			OnClientPutInServer(client);
	}
	
	CreateConVar("sm_friendlysimple_version", VERSION_NUMER, "Current Friendly Simple Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	
	fwd_Friendly	= CreateGlobalForward("FriendlySimple_OnEnableFriendly", ET_Ignore, Param_Cell);
	fwd_Hostile		= CreateGlobalForward("FriendlySimple_OnDisableFriendly", ET_Ignore, Param_Cell);
	
	RegAdminCmd("sm_f", Command_ToggleFriendly, 0, "Toggles Friendly mode while the client is in spawn.");
	RegAdminCmd("sm_friendly", Command_ToggleFriendly, 0, "Toggles Friendly mode while the client is in spawn.");
	RegAdminCmd("sm_fierndly", Command_ToggleFriendly, 0, "Toggles Friendly mode while the client is in spawn.");
	RegAdminCmd("sm_feirndly", Command_ToggleFriendly, 0, "Toggles Friendly mode while the client is in spawn.");
	RegAdminCmd("sm_firendly", Command_ToggleFriendly, 0, "Toggles Friendly mode while the client is in spawn.");
	
	AddCommandListener(Event_TauntCommand, "taunt");
	AddCommandListener(Event_TauntCommand, "+taunt");

}

public OnPluginEnd(){

	for(new i = 1; i <= MaxClients; i++){
	
		if(IsValidClient(i) && IsFriendly[i])
			SetClientFriendly(i, false, true, true);
	
	}
	UnhookEvent("player_spawn", Event_PlayerSpawn);
	UnhookEvent("post_inventory_application", Event_Resupply);

}

public OnMapStart(){

	HookThings();
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_Resupply);

}

public OnMapEnd(){

	UnhookEvent("player_spawn", Event_PlayerSpawn);
	UnhookEvent("post_inventory_application", Event_Resupply);

}

public OnClientPutInServer(client){

	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	
}

public OnClientDisconnect(client){

	IsFriendly[client]	= false;
	IsInSpawn[client]	= false;
	
	SDKUnhook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	
}

public Action:Command_ToggleFriendly(client, args){

	if(!IsValidClient(client))	return Plugin_Handled;
	
	if(!HasAccess(client)){
		ReplyToCommand(client, "%s You do not have access to this command.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	if(!IsInSpawn[client]){
		ReplyToCommand(client, "%s You may only use this command in spawn.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	new time = GetTime() -cmd_delay[client];
	if(time < DELAY){
		ReplyToCommand(client, "%s You have to wait %d seconds.", CHAT_PREFIX, DELAY -time);
		return Plugin_Handled;
	}
	
	SetClientFriendly(client, IsFriendly[client] ? false : true);
	cmd_delay[client] = GetTime();
	
	return Plugin_Handled;

}

SetClientFriendly(client, bool:set, bool:broadcast=true, bool:force=false){ //force is used only when the plugin itself gets unloaded/reloaded

	if(set){
	
		IsFriendly[client] = true;
		if(broadcast) PrintToChat(client, "%s Friendly mode enabled.", CHAT_PREFIX);
		
		if(GetForwardFunctionCount(fwd_Friendly) > 0){
			Call_StartForward(fwd_Friendly);
			Call_PushCell(client);
			Call_Finish();
		}
		
		MakePlayerFriendly(client);
		MakeHatsFriendly(client);
		MakeLoadoutFriendly(client);
		
		RemovePlayerBuildings(client);
		
		SetNotarget(client, true);
		
	}else{
	
		IsFriendly[client] = false;
		if(broadcast) PrintToChat(client, force ? "%s You have been forced out of Friendly mode." : "%s Friendly mode disabled.", CHAT_PREFIX);
		
		if(GetForwardFunctionCount(fwd_Hostile) > 0){
			Call_StartForward(fwd_Hostile);
			Call_PushCell(client);
			Call_Finish();
		}
		
		MakePlayerHostile(client);
		MakeHatsHostile(client);
		MakeLoadoutHostile(client);
		
		SetNotarget(client, false);
		
	}

}

MakeLoadoutFriendly(client){
	
	new weapon;
	for(new i = 0; i < SLOT_COUNT; i++){
	
		weapon = GetPlayerWeaponSlot(client, i);
		
		if(!IsWeaponClassnameBanned(weapon)) SetWeapon(weapon, true); else{
			
			TF2_RemoveWeaponSlot(client, i);
		
			if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == weapon)
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, SLOT_MELEE));
		
		}
		
	}

}

MakeLoadoutHostile(client){
	
	TF2_RegeneratePlayer(client);
	
	SetWeapon(GetPlayerWeaponSlot(client, SLOT_PRIMARY), false);
	SetWeapon(GetPlayerWeaponSlot(client, SLOT_SECONDARY), false);
	SetWeapon(GetPlayerWeaponSlot(client, SLOT_MELEE), false);

}

SetWeapon(ent, bool:friendly){

	if(ent > MaxClients && IsValidEntity(ent)){
		
		new col = friendly ? 128 : 255;
		SetEntityRenderColor(ent, col, 255, col, col);
	
		new index = GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex");
		if(index == 237 || index == 265) return;	//237 - Rocket Jumper, 265 - Stick Jumper
		
		SetEntPropFloat(ent, Prop_Data, "m_flNextPrimaryAttack", friendly ? GetGameTime() + 86400.0 : 0.1);
		SetEntPropFloat(ent, Prop_Data, "m_flNextSecondaryAttack", friendly ? GetGameTime() + 86400.0 : 0.1);
	
	}

}

MakePlayerFriendly(client){
	
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
	
	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth"));
	
	if(TF2_GetPlayerClass(client) == TFClass_Engineer)
		SetEntProp(client, Prop_Data, "m_iAmmo", 200, 4, 3);
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 128, 255, 128, 128);

}

MakePlayerHostile(client){
	
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
	
	SetEntityRenderMode(client, RENDER_NORMAL);
	SetEntityRenderColor(client, 255, 255, 255, 255);

}

MakeHatsFriendly(client){

	new i = -1;
	while((i = FindEntityByClassname(i, "tf_wearable")) != INVALID_ENT_REFERENCE){
		
		if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")){
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
			SetEntityRenderColor(i, 128, 255, 128, 128);
		}
		
	}

}

MakeHatsHostile(client){

	new i = -1;
	while((i = FindEntityByClassname(i, "tf_wearable")) != INVALID_ENT_REFERENCE) {
		if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable")){
			SetEntityRenderMode(i, RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
	}

}

RemovePlayerBuildings(client){
	
	new i = -1;
	while((i = FindEntityByClassname(i, "obj_sentrygun")) != INVALID_ENT_REFERENCE){
	
		if(GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client){
			AcceptEntityInput(i, "Kill");
		}
		
	}
	
	i = -1;
	while((i = FindEntityByClassname(i, "obj_dispenser")) != INVALID_ENT_REFERENCE){
	
		if(GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client){
			AcceptEntityInput(i, "Kill");
		}
		
	}
	
	i = -1;
	while((i = FindEntityByClassname(i, "obj_teleporter")) != INVALID_ENT_REFERENCE){
	
		if(GetEntPropEnt(i, Prop_Send, "m_hBuilder") == client){
			AcceptEntityInput(i, "Kill");
		}
		
	}

}

SetNotarget(ent, bool:apply){

	new flags;
	if(apply)	flags = GetEntityFlags(ent)|FL_NOTARGET;
	else		flags = GetEntityFlags(ent)&~FL_NOTARGET;
	
	SetEntityFlags(ent, flags);

}

public OnEntityCreated(ent, const String:classname[]){

	if(!IsValidEntity(ent)) return;
	
	if(StrEqual(classname, "func_respawnroom", false)){
	
		SDKHook(ent, SDKHook_Touch, SpawnTouch);
		SDKHook(ent, SDKHook_EndTouch, SpawnEndTouch);
		
		return;
	
	}
	
	if(!IsClassnameInFilter(classname)) return;
	
	SDKHook(ent, SDKHook_StartTouch, OnEntStartTouch);
	SDKHook(ent, SDKHook_Touch, OnEntStartTouch);

	if(StrEqual(classname, "tf_ammo_pack", false))
		SDKHook(ent, SDKHook_Spawn, OnDropSpawned);
	
	if(StrEqual(classname, "func_button", false))
		SDKHook(ent, SDKHook_Use, ButtonUsed);

}

HookThings(){

	new ent;

	for(new i = 0; i < sizeof(filter_clsname); i++){
	
		ent = -1;
		while((ent = FindEntityByClassname(ent, filter_clsname[i])) != INVALID_ENT_REFERENCE){
		
			SDKHook(ent, SDKHook_StartTouch, OnEntStartTouch);
			SDKHook(ent, SDKHook_Touch, OnEntStartTouch);
		
			if(StrEqual(filter_clsname[i], "tf_ammo_pack", false))
				SDKHook(ent, SDKHook_Spawn, OnDropSpawned);
		
		}
		
	}
	
	ent = -1;
	while((ent = FindEntityByClassname(ent, "func_respawnroom")) != INVALID_ENT_REFERENCE){
	
		SDKHook(ent, SDKHook_Touch, SpawnTouch);
		SDKHook(ent, SDKHook_EndTouch, SpawnEndTouch);
	
	}
	
}



/**************************\
	-	N A T I V E S  -
\**************************/

public Native_CheckIfFriendly(Handle:plugin, numParams){

	new client = GetNativeCell(1);
	
	if(client < 1 || client > MaxClients){
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return false;
	}
	
	if(!IsClientInGame(client)){
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return false;
	}
	
	return IsFriendly[client];

}

public Native_CheckIfInSpawn(Handle:plugin, numParams){

	new client = GetNativeCell(1);
	
	if(client < 1 || client > MaxClients){
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return false;
	}
	
	if(!IsClientInGame(client)){
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return false;
	}
	
	return IsInSpawn[client];

}

public Native_CheckIfHasAccess(Handle:plugin, numParams){

	new client = GetNativeCell(1);
	
	if(client < 1 || client > MaxClients){
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return false;
	}
	
	if(!IsClientInGame(client)){
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return false;
	}
	
	return HasAccess(client);

}

public Native_SetFriendly(Handle:plugin, numParams){

	new client = GetNativeCell(1);
	new direction = GetNativeCell(2);
	
	if(client < 1 || client > MaxClients){
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client index %i", client);
		return -3;
	}
	
	if(!IsClientInGame(client)){
		ThrowNativeError(SP_ERROR_PARAM, "Client %i is not in game!", client);
		return -2;
	}
	
	if((IsFriendly[client] && direction > 0) || (!IsFriendly[client] && direction == 0)){
		return -1;
		//Client is already in the requested Friendly state
	}
	
	if(direction < 0){			//Toggle
	
		SetClientFriendly(client, IsFriendly[client] ? false : true);
	
	}else if(direction == 0){		//Disable
	
		if(!IsFriendly[client]) return -1;
		
		SetClientFriendly(client, false);
	
	}else{							//Enable
	
		if(IsFriendly[client]) return -1;
		
		SetClientFriendly(client, true);
	
	}
	
	return -4;
	
}



/************************\
	-	E V E N T S  -
\************************/

public Action:OnEntStartTouch(point, client){

	if(!IsValidClient(client)) return Plugin_Continue;
	
	if(IsFriendly[client]) return Plugin_Handled;
	
	return Plugin_Continue;
	
}

public Action:TF2_OnPlayerTeleport(client, teleporter, &bool:result){

	if(!IsValidClient(client)) return Plugin_Continue;
	
	if(IsFriendly[client]){
		result = false;
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
	
}

public OnDropSpawned(entity){

	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if(!IsValidClient(client)) return;
	
	if(IsFriendly[client]) AcceptEntityInput(entity, "Kill");
	
}

public Action:SpawnTouch(spawn, client){

	if(!IsValidClient(client)) return Plugin_Continue;
	
	if(GetEntProp(spawn, Prop_Send, "m_iTeamNum") == GetClientTeam(client)) IsInSpawn[client] = true;
	
	return Plugin_Continue;
	
}

public Action:SpawnEndTouch(spawn, client){

	if(!IsValidClient(client)) return Plugin_Continue;
	
	IsInSpawn[client] = false;
	
	return Plugin_Continue;
	
}

public Action:ButtonUsed(entity, activator, caller, UseType:type, Float:value){

	if(!IsValidClient(activator)) return Plugin_Continue;
	
	if (IsFriendly[activator]) return Plugin_Handled;
	
	return Plugin_Continue;
	
}

public Action:Event_Resupply(Handle:event, const String:name[], bool:dontBroadcast){

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client)) return Plugin_Continue;
	
	if(IsFriendly[client]){
		MakeLoadoutFriendly(client);
		MakeHatsFriendly(client);
		//return Plugin_Handled;
	}
	
	return Plugin_Continue;
	
}

public Action:Event_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom){
	
	new bool:validVictim = IsValidClient(victim), bool:validAttacker = IsValidClient(attacker);
	
	if(validVictim && validAttacker) if(victim == attacker) return Plugin_Continue;	
	if(validVictim)		if(IsFriendly[victim])		return Plugin_Handled;
	if(validAttacker)	if(IsFriendly[attacker])	return Plugin_Handled;

	return Plugin_Continue;

}

public Action:Event_TauntCommand(client, const String:command[], args){

	if(!IsValidClient(client)) return Plugin_Continue;
	
	if(!IsFriendly[client]) return Plugin_Continue;
	
	if(IsWeaponBanned(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))) return Plugin_Handled;
	
	return Plugin_Continue;

}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) return Plugin_Continue;
	
	if(IsFriendly[client]) SetClientFriendly(client, true, false);
	
	return Plugin_Continue;

}

public Action:RTD_CanRollDice(client){

	if(!IsValidClient(client)) return Plugin_Continue;

	if(IsFriendly[client]){
		PrintToChat(client, "%s Cannot RTD while Friendly.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;

}

public Action:RTD2_CanRollDice(client){

	if(!IsValidClient(client)) return Plugin_Continue;

	if(IsFriendly[client]){
		PrintToChat(client, "%s Cannot RTD while Friendly.", CHAT_PREFIX);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;

}

public Action:OnStomp(attacker, victim, &Float:damageMultiplier, &Float:damageBonus, &Float:JumpPower){

	if((IsFriendly[attacker] || IsFriendly[victim])){
		return Plugin_Handled;
	}
	
	return Plugin_Continue;

}



/************************\
	-	S T O C K S  -
\************************/

stock bool:HasAccess(client){

	return CheckCommandAccess(client, "sm_friendly", ADMFLAG_GENERIC);

}

stock bool:IsClassnameInFilter(const String:clsname[]){
	
	for(new i = 0; i < sizeof(filter_clsname); i++){

		if(StrEqual(clsname, filter_clsname[i], false))
			return true;
		
	}
	
	return false;

}

stock bool:IsWeaponBanned(client, weapon){

	if(weapon <= MaxClients || !IsValidEntity(weapon)) return true;

	new String:classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	for(new i = 0; i < sizeof(banned_weapon_classnames); i++){
	
		if(StrEqual(classname, banned_weapon_classnames[i])) return true;
	
	}
	
	//Check if the client class is Pyro so they also cannot taunt with tf_weapon_shotgun
	if(TF2_GetPlayerClass(client) == TFClass_Pyro && StrEqual(classname, "tf_weapon_shotgun"))
		return true;

	new index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	for(new i = 0; i < sizeof(banned_weapons_ids); i++){
	
		if(index == banned_weapons_ids[i]) return true;
	
	}
	
	return false;

}

stock bool:IsWeaponClassnameBanned(weapon){

	if(weapon <= MaxClients || !IsValidEntity(weapon)) return true;

	new String:classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	for(new i = 0; i < sizeof(banned_classes); i++){
	
		if(StrEqual(classname, banned_classes[i])) return true;
	
	}
	
	return false;

}

stock bool:IsValidClient(client){

	if(client > 4096){
		client = EntRefToEntIndex(client);
	}

	if(client < 1 || client > MaxClients)				return false;

	if(!IsClientInGame(client))						return false;

	if(IsFakeClient(client))							return false;
	
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))	return false;
	
	return true;
	
}