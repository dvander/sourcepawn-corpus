#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.1"


public Plugin:myinfo = {
	name = "SM Spy with knife",
	author = "Franc1sco steam: franug",
	description = "spy",
	version = PLUGIN_VERSION,
	url = "http://www.servers-cfg.foroactivo.com"
};

public OnPluginStart() 
{
	CreateConVar("sm_spywithknife_version", PLUGIN_VERSION, "version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre)

}



public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!IsValidClient(attacker))
		return;

        decl String:Weapon[32];
        GetEventString(event, "weapon", Weapon, sizeof(Weapon));
	if(StrContains(Weapon, "knife"))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		decl String:model[PLATFORM_MAX_PATH];
		GetClientModel(client, model, sizeof(model));

		decl String:model2[PLATFORM_MAX_PATH];
		GetClientModel(attacker, model2, sizeof(model2));

		SetEntityModel(attacker,model);
		SetEntityModel(client,model2);
	}

}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}