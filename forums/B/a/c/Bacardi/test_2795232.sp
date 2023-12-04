

#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define ZPS_TEAM_NONE			0	// player running on map but haven't choose team
#define ZPS_TEAM_SPECTATOR	1	// observer
#define ZPS_TEAM_HUMAN		2	// human
#define ZPS_TEAM_ZOMBIE		3	// zombie


// 29	CZP_GameMovement::CheckJumpButton(void)
DynamicDetour DCheckJumpButton;

ConVar sm_zps_carrier_jumpscale;
ConVar sm_zps_carrier_movespeed;

public void OnPluginStart()
{
	char folder[PLATFORM_MAX_PATH];
	GetGameFolderName(folder, sizeof(folder));

	if(!StrEqual(folder, "zps", false))
		SetFailState("This plugin is only for: Zombie Panic! Source");


	GameData data = new GameData("zps_test.games");
	
	if(data == null)
		SetFailState("Failed to load gamedata file zps_test.games.txt");
	
	Address addr = data.GetMemSig("CheckJumpButton");

	if(!addr)
		SetFailState("CheckJumpButton - Address Failed");

	DCheckJumpButton = new DynamicDetour(addr, CallConv_THISCALL, ReturnType_Bool, ThisPointer_Address);
	
	if(!DCheckJumpButton.Enable(Hook_Post, CheckJumpButton)) SetFailState("CheckJumpButton - Detour failed");

	HookEvent("player_spawn", player_spawn);

	sm_zps_carrier_jumpscale = CreateConVar("sm_zps_carrier_jumpscale", "1.5", "Scale for increase or decrease jump velocity");
	sm_zps_carrier_movespeed = CreateConVar("sm_zps_carrier_movespeed", "1.3", "Scale for increase or decrease move speed");

	LogMessage("debug: OnPluginStart, folder %s, data %X, addr %X, DCheckJumpButton %X", folder, data, addr, DCheckJumpButton);

}

public MRESReturn CheckJumpButton(Address pThis, DHookReturn hReturn)
{
	if(!hReturn.Value)
		return MRES_Ignored;

	int playeraddr = LoadFromAddress(pThis+view_as<Address>(0x4), NumberType_Int32); // This offset works on Windows

	LogMessage("debug: CheckJumpButton pThis %X\nload 0x0 %X\nplayeraddr 0x4 %X\nload 0x8 %X\nload 0x12 %X",
																							pThis,
																							LoadFromAddress(pThis+view_as<Address>(0x0), NumberType_Int32),
																							playeraddr,
																							LoadFromAddress(pThis+view_as<Address>(0x8), NumberType_Int32),
																							LoadFromAddress(pThis+view_as<Address>(0x12), NumberType_Int32));


	int client = GetClientOfAddress(playeraddr);

	if(client)
	{
		//PrintToServer("CZP_GameMovement::CheckJumpButton(void) %X %N %i", pThis, client, hReturn.Value);
		RequestFrame(delay, GetClientUserId(client));
	}

	return MRES_Ignored;
}

public void delay(any data)
{
	int client = GetClientOfUserId(data);

	if(!client || !IsClientInGame(client) || !ZPS_IsCarrier(client))
		return;

	float velocity[3];

	velocity[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	velocity[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	velocity[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

	ScaleVector(velocity, sm_zps_carrier_jumpscale.FloatValue);

	//PrintToServer("velocity %f %f %f", velocity[0],
	//									velocity[1],
	//									velocity[2]);

	LogMessage("debug: delay TeleportEntity - %f %f %f", velocity[0],
										velocity[1],
										velocity[2]);

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
}

public void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	LogMessage("debug: player_spawn - userid %i, entindex %i", event.GetInt("userid"), event.GetInt("entindex"));

	int client = event.GetInt("entindex");

	if(GetClientTeam(client) == ZPS_TEAM_ZOMBIE && ZPS_IsCarrier(client))
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", sm_zps_carrier_movespeed.FloatValue);
	}
}

stock bool ZPS_IsCarrier(int client)
{
	if(HasEntProp(client, Prop_Send, "m_bIsCarrier") &&
		GetEntProp(client, Prop_Send, "m_bIsCarrier"))
	{
		return true;
	}

	return false;
}

stock int GetClientOfAddress(int addr)
{
	if(addr <= 0)
		return 0;

	int tmp;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		tmp = view_as<int>(GetEntityAddress(i));

		LogMessage("debug: GetClientOfAddress %i %X == %X", i, tmp, addr);

		if(addr == tmp)
		{
			return i;
		}
	}

	return 0;
}

