#include <sourcemod>
#include <sdktools>

new Float:velocidad = 1.0;

new Handle:cvar_velocidad = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);

	cvar_velocidad = CreateConVar("sm_csgospeed", "1.0", "Speed of players");

	HookConVarChange(cvar_velocidad, CVarChange);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {


	velocidad = StringToFloat(newValue);

        for (new i = 1; i < GetMaxClients(); i++)
                if (IsClientInGame(i) && IsPlayerAlive(i))
			SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", velocidad)

}




public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", velocidad)


}