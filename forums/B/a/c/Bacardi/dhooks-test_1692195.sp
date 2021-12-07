#include <sourcemod>
#include <sdktools>
#include <dhooks>

//new Handle:hFlashlightTurnOn;
new Handle:hFlashlightTurnOff;

public OnPluginStart()
{
	new Handle:conf = LoadGameConfigFile("flashlight.games"); //http://www.sourcemodplugins.org/index.php?page=vtableoffsets&appid=240
	if(conf == INVALID_HANDLE)
	{
		SetFailState("Why you no has flashlight.games.txt?\nhttp://www.sourcemodplugins.org/index.php?page=vtableoffsets&appid=240");
	}
	new offset = -1;
	//offset = GameConfGetOffset(conf, "FlashlightTurnOn()");
	//if(offset == -1)
	//{
	//	SetFailState("FlashlightTurnOn() offset invalid")
	//}
	//PrintToServer("FlashlightTurnOn %i", offset);
	//hFlashlightTurnOn = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, FlashlightTurnOn);

	offset = GameConfGetOffset(conf, "FlashlightTurnOff()");
	if(offset == -1)
	{
		SetFailState("FlashlightTurnOff() offset invalid");
	}
	//PrintToServer("FlashlightTurnOff() %i", offset);
	hFlashlightTurnOff = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, FlashlightTurnOff);
	CloseHandle(conf);

	HookEvent("player_spawn", spawn);

}

public OnClientPutInServer(client)
{
	//DHookEntity(hFlashlightTurnOn, false, client);
	DHookEntity(hFlashlightTurnOff, false, client);
}

public spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) == 3)
	{
		SetEntProp(client, Prop_Send, "m_fEffects", 4);
	}
}

public MRESReturn:FlashlightTurnOn(this, Handle:hReturn, Handle:hParams)
{
	//PrintToServer("FlashlightTurnOn %i m_fEffects %i", this, GetEntProp(this, Prop_Send, "m_fEffects"));
	return MRES_Ignored;
}

public MRESReturn:FlashlightTurnOff(this, Handle:hReturn, Handle:hParams)
{
	if(GetClientTeam(this) == 3 && IsPlayerAlive(this))
	{
		return MRES_Supercede;
	}
	return MRES_Ignored;
}