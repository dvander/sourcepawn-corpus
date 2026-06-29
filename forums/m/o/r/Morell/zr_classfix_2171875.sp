#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <zombiereloaded>

new zombie1, zombie2, zombie3;

public Plugin:myinfo =
{
	name = "ZR Class Fix",
	author = "Mapeadores",
	description = "Class Fix",
	version = "1.5",
	url = "http://Mapeadores.com/"
};

public OnPluginStart()
{
	//Edit this with your zombie classes
	zombie1 = ZR_GetClassByName("Clasico");
	zombie2 = ZR_GetClassByName("Zombie Rapido");
	zombie3 = ZR_GetClassByName("Zombie Resistente");
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	new vida = GetClientHealth(client);
	if(vida < 300)
	{
		CreateTimer(0.5, TimerAsegurarClase, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:TimerAsegurarClase(Handle:timer, any:client)
{
	AsegurarClaseDefault(client);
}

public AsegurarClaseDefault(client)
{
	SetEntityHealth(client, 5000);
	new randomnum = GetRandomInt(0, 2);
	switch(randomnum)
	{
		case 0:
		{
			SetEntityModel(client, "models/player/mapeadores/morell/zh/zh3fix.mdl");
			ZR_SelectClientClass(client, zombie3, true, true);
		}
		case 1:
		{
			SetEntityModel(client, "models/player/mapeadores/kaem/zh/zh1fix.mdl");
			ZR_SelectClientClass(client, zombie1, true, true);
		}
		case 2:
		{
			SetEntityModel(client, "models/player/mapeadores/kaem/zh/zh2fix.mdl");
			ZR_SelectClientClass(client, zombie2, true, true);
		}
	}
}