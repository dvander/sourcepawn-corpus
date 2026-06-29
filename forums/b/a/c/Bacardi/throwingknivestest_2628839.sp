
/*
Server event "weapon_fire", Tick 25840:
- "userid" = "24"
- "weapon" = "weapon_knife"
- "silenced" = "0"
Server event "player_hurt", Tick 25840:
- "userid" = "28"
- "attacker" = "24"
- "health" = "66"
- "armor" = "97"
- "weapon" = "knife"
- "dmg_health" = "34"
- "dmg_armor" = "3"
- "hitgroup" = "0"
client 2 entity 284 other 6
*/



ConVar enabled;

#include <sdktools>
#include <sdkhooks>

public void OnPluginStart()
{
	char game[128];
	GetGameFolderName(game, sizeof(game));

	if(!StrEqual(game, "csgo", false)) SetFailState("Plugin made CS:GO only");

	enabled = CreateConVar("sm_throwingknives_enable", "0", "Enable throwingknives", _, true, 0.0, true, 1.0);
	HookEventEx("weapon_fire", weapon_fire);

}

public void weapon_fire(Event event, const char[] name, bool dontBroadcast)
{
	char buffer[30];
	event.GetString("weapon", buffer, sizeof(buffer));
	if(StrContains(buffer, "weapon_knife", false) != 0) return;

	if(!enabled.BoolValue) return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	if(client == 0) return;


	int knife = CreateEntityByName("weapon_knife");

	if(knife == -1) return;

	if(!DispatchSpawn(knife))
	{
		if(!AcceptEntityInput(knife, "Kill")) SetFailState("Something wrong in this game");

		return;
	}

	DispatchKeyValue(knife, "OnUser1", "!self,Kill,,5.0,-1");
	AcceptEntityInput(knife, "FireUser1");

	SetEntProp(knife, Prop_Data, "m_bCanBePickedUp", 0);
	SetEntPropEnt(knife, Prop_Send, "m_hOwnerEntity", client);



	float pos[3], angle[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angle);

	float knife_pos[3];
	GetAngleVectors(angle, knife_pos, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(knife_pos, 10.0);
	AddVectors(knife_pos, pos, knife_pos);

	// knife flying direction and speed/power
	float player_velocity[3], velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", player_velocity);
	GetAngleVectors(angle, velocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(velocity, 1500.0);
	AddVectors(velocity, player_velocity, velocity);


	if(!TeleportEntity(knife, knife_pos, angle, velocity))
	{
		return;
	}

	SDKHookEx(knife, SDKHook_TouchPost, touch);

}


public void touch(int entity, int other)
{
	if( !(0 < other <= MaxClients) ) return;

	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if(other == client) return;

	SDKUnhook(entity, SDKHook_TouchPost, touch);


	//PrintToServer("client %i entity %i other %i", client, entity, other);

	SDKHooks_TakeDamage(other, entity, client,
		25.0, _, entity,
		NULL_VECTOR, NULL_VECTOR);


}