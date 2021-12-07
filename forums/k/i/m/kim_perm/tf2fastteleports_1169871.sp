/**
 * vim: set ai et ts=4 sw=4 syntax=sourcepawn :
 * File: tf2fastteleports.sp
 * Description: Change the time the teleport takes to recharge (completly rewrited tf2teleporter by Nican132)
 * Author(s): kim_perm
 */           

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "0.0.2"

public Plugin:myinfo = 
{
    name = "Fast Teleport",
    author = "kim_perm",
    description = "Change the time the teleport takes to recharge",
    version = PL_VERSION,
    url = "http://tf2.perm.ru/"
};       

//main list of player/teleport relation
enum telelist {
	tele_entity,			//teleport entity
	tele_owner_team,		//team of teleport owner
	Float: tele_ind_time	//individual teleport time (set by native call)
};
new TeleporterList[MAXPLAYERS + 1][telelist];

//cvars handles
new Handle:g_cvars_enabled = INVALID_HANDLE;
new Handle:g_cvars_bluetime = INVALID_HANDLE;
new Handle:g_cvars_redtime = INVALID_HANDLE;

//cvars values
new g_cvar_enabled;		//plugin status enabled/disabled
new Float:g_cvar_bluetime;	//blue team recharge time
new Float:g_cvar_redtime;	//red team recharge time

/* ------------------------------------------------------ */
public OnPluginStart() {
	//global cvar for showing in A2S_RULES reply
	CreateConVar("sm_tf_fasttele", PL_VERSION, "Fast Teleports", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_cvars_enabled = CreateConVar("sm_tele_on", "1", "Enable/Disable fast teleports");
	g_cvars_bluetime = CreateConVar("sm_teleblue_time", "0.3", "Amount of time for blue tele to recharge, 0.0=disable");
	g_cvars_redtime = CreateConVar("sm_telered_time", "0.3", "Amount of time for red tele to recharge, 0.0=disable");

	HookEvent("player_builtobject", event_player_builtobject);
	HookEvent("player_teleported", event_player_teleported);
}

public OnConfigsExecuted() {
	//initialize values
	g_cvar_enabled = GetConVarInt(g_cvars_enabled);
	g_cvar_bluetime = GetConVarFloat(g_cvars_bluetime);
	g_cvar_redtime = GetConVarFloat(g_cvars_redtime);

	//hook cvar changes
	HookConVarChange(g_cvars_enabled,  TF2ConfigsChanged );
	HookConVarChange(g_cvars_bluetime, TF2ConfigsChanged ); 
	HookConVarChange(g_cvars_redtime,  TF2ConfigsChanged );
}

//cvar change processing
public TF2ConfigsChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(convar == g_cvars_enabled) {
		g_cvar_enabled = StringToInt(newValue);
		if(StrEqual(oldValue, "0") && g_cvar_enabled > 0) {
			//plugin change status disabled -> enabled
			//must collect all builded teleports
			new owner;
			decl String:classname[19];

			for(new i = MaxClients + 1; i <= GetMaxEntities(); i++) {
				if(IsValidEntity(i)) {
					GetEntityNetClass(i, classname, sizeof(classname));
					if(StrEqual(classname, "CObjectTeleporter")) {
						if(GetEntProp(i, Prop_Send, "m_iObjectMode") == 0) {
							owner = GetEntPropEnt(i, Prop_Send, "m_hBuilder");
							TeleporterList[owner][tele_entity] = i;
							TeleporterList[owner][tele_owner_team] = GetEntProp(i, Prop_Send, "m_iTeamNum");
							TeleporterList[owner][tele_ind_time] = 0.0;
						}	
					}
				}
			}
		}
	} else if(convar == g_cvars_bluetime) {
		g_cvar_bluetime = StringToFloat(newValue);
	} else if(convar == g_cvars_redtime) {
		g_cvar_redtime = StringToFloat(newValue);
	}
}

public Action:event_player_teleported(Handle:event, const String:name[], bool:dontBroadcast) {
	if(g_cvar_enabled) {
		new owner, entity;
		owner = GetClientOfUserId(GetEventInt(event, "builderid"));
		entity = TeleporterList[owner][tele_entity];
		if(IsValidEntity(entity)) {
			new Float:time;
			if(TeleporterList[owner][tele_ind_time] != 0.0) {
				time = TeleporterList[owner][tele_ind_time];
			} else {
				if(TeleporterList[owner][tele_owner_team] == 2) time = g_cvar_redtime;
				else time = g_cvar_bluetime;
			}
			if(time != 0.0) SetEntPropFloat(entity, Prop_Send, "m_flRechargeTime", GetGameTime() + time);
		}
	}
	return Plugin_Continue;
}

public Action:event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast) {
	//check for teleport
	if ( GetEventInt(event, "object") != 1) return Plugin_Continue;

	new entity = GetEventInt(event, "index");
	if(IsValidEntity(entity)) {
		new owner = GetClientOfUserId(GetEventInt(event, "userid"));
		//check for entrance (0 = entrance, 1 = exit)
		if(GetEntProp(entity, Prop_Send, "m_iObjectMode") == 0) {
			TeleporterList[owner][tele_entity] = entity;
			TeleporterList[owner][tele_owner_team] = GetEntProp(entity, Prop_Send, "m_iTeamNum");
		}
	}
	return Plugin_Continue;
}

/* change teleport time for single player from other plugins
 * sample usage: SetTeleporterTime(client, 0.01);
 * also check for sample in plugin thread: http://forums.alliedmods.net/showthread.php?t=125962
 */ 
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
    // Register Natives
    CreateNative("SetTeleporterTime", native_setteleportertime);
    RegPluginLibrary("tf2fastteleports");
    return APLRes_Success;
}

public native_setteleportertime(Handle:plugin, numParams) {
    if (numParams >= 1 && numParams <= 2) {
        TeleporterList[GetNativeCell(1)][tele_ind_time] = (numParams >= 2)?(Float:GetNativeCell(2)):0.0;
    }
}