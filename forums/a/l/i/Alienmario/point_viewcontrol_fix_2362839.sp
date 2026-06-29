#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "point_viewcontrol fix",
	author = "Alienmario",
	description = "Fixes point_viewcontrol not exiting for multiple players",
	version = "1.0",
}

public OnPluginStart(){
	HookEntityOutput("point_viewcontrol", "OnEndFollow", OnViewEnd);
	AddCommandListener(BlockKill, "kill");
	AddCommandListener(BlockKill, "explode");
	HookEvent("player_death", Event_Death);
}

public Action:BlockKill(client, const String:command[], argc) {
	if( isInView(client) )
		return Plugin_Handled;
	return Plugin_Continue;
}

public Event_Death (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isInView(client)){
		SetClientViewEntity(client, client);
		SetEntityFlags(client, GetEntityFlags(client) &~ FL_FROZEN);
	}
}

bool:isInView(client){
	new m_hViewEntity = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
	decl String:classname[20];
	if( IsValidEdict(m_hViewEntity) && GetEdictClassname(m_hViewEntity, classname, sizeof(classname) ) ){
		if(StrEqual(classname, "point_viewcontrol")){
			return true;
		}
	}
	return false;
}

public OnViewEnd(const String:output[], caller, activator, Float:delay){
	for (new client=1; client<=MaxClients; client++){
		if(IsClientInGame(client) && IsPlayerAlive(client)){
			new m_hViewEntity = GetEntPropEnt(client, Prop_Data, "m_hViewEntity");
			if( m_hViewEntity == caller){
				
				if ( GetEntPropEnt(m_hViewEntity, Prop_Data, "m_hPlayer") != client){
					SetEntPropEnt(m_hViewEntity, Prop_Data, "m_hPlayer", client);
					AcceptEntityInput(m_hViewEntity, "Disable");
				}
			}
		}
	}
}