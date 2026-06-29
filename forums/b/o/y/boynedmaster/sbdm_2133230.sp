#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

new Handle:Cvar_CashSize;
new Handle:Cvar_Enabled;
new Handle:Cvar_Amount;

public Plugin:myinfo =
{
	name = "Sentry Busters Drop Money",
	author = "Boyned",
	description = "Sentry Busters Drop Money on explosion.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("mvm_sentrybuster_detonate", Event_SentryBusterExplode);
	Cvar_CashSize = CreateConVar("sm_sdbm_cashsize", "small", "Size Of Droped Cash By Sentry Buster", FCVAR_PLUGIN|FCVAR_NOTIFY);
	Cvar_Amount = CreateConVar("sm_sdbm_cashamount", "4", "How Much Cash Will Be Dropped", FCVAR_PLUGIN|FCVAR_NOTIFY);
	Cvar_Enabled = CreateConVar("sm_sdbm_enable", "1", "Enables/Disables Sentrybuster Drop Money", FCVAR_PLUGIN|FCVAR_NOTIFY);
}

public Event_SentryBusterExplode(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(Cvar_Enabled) == 1)
	{
		for(new i; i <= GetConVarInt(Cvar_Amount); i++)
		{
			new String:Size[7];
			GetConVarString(Cvar_CashSize, Size, sizeof(Size));
			if(StrEqual(Size, "large", false))
			{
				new Float:xyz[3];
				new cash = CreateEntityByName("item_currencypack_large");
				if(cash != -1)
				{
					xyz[0] = GetEventFloat(event, "det_x");
					xyz[1] = GetEventFloat(event, "det_y");
					xyz[2] = GetEventFloat(event, "det_z");
					DispatchSpawn(cash);
					TeleportEntity(cash, xyz, NULL_VECTOR, NULL_VECTOR);
				}
			}
			else if(StrEqual(Size, "medium", false))
			{
				new Float:xyz[3];
				new cash = CreateEntityByName("item_currencypack_medium");
				if(cash != -1)
				{
					xyz[0] = GetEventFloat(event, "det_x");
					xyz[1] = GetEventFloat(event, "det_y");
					xyz[2] = GetEventFloat(event, "det_z");
					DispatchSpawn(cash);
					TeleportEntity(cash, xyz, NULL_VECTOR, NULL_VECTOR);
				}
			}
			else if(StrEqual(Size, "small", false))
			{
				new Float:xyz[3];
				new cash = CreateEntityByName("item_currencypack_small");
				if(cash != -1)
				{
					xyz[0] = GetEventFloat(event, "det_x");
					xyz[1] = GetEventFloat(event, "det_y");
					xyz[2] = GetEventFloat(event, "det_z");
					DispatchSpawn(cash);
					TeleportEntity(cash, xyz, NULL_VECTOR, NULL_VECTOR);
				}
			}
			else
			{
				switch(GetRandomInt(1, 3))
				{
					case 1:
					{
						new Float:xyz[3];
						new cash = CreateEntityByName("item_currencypack_large");
						if(cash != -1)
						{
							xyz[0] = GetEventFloat(event, "det_x");
							xyz[1] = GetEventFloat(event, "det_y");
							xyz[2] = GetEventFloat(event, "det_z");
							DispatchSpawn(cash);
							TeleportEntity(cash, xyz, NULL_VECTOR, NULL_VECTOR);
						}
					}
					case 2:
					{
						new Float:xyz[3];
						new cash = CreateEntityByName("item_currencypack_medium");
						if(cash != -1)
						{
							xyz[0] = GetEventFloat(event, "det_x");
							xyz[1] = GetEventFloat(event, "det_y");
							xyz[2] = GetEventFloat(event, "det_z");
							DispatchSpawn(cash);
							TeleportEntity(cash, xyz, NULL_VECTOR, NULL_VECTOR);
						}
					}
					case 3:
					{
						new Float:xyz[3];
						new cash = CreateEntityByName("item_currencypack_small");
						if(cash != -1)
						{
							xyz[0] = GetEventFloat(event, "det_x");
							xyz[1] = GetEventFloat(event, "det_y");
							xyz[2] = GetEventFloat(event, "det_z");
							DispatchSpawn(cash);
							TeleportEntity(cash, xyz, NULL_VECTOR, NULL_VECTOR);
						}
					}
				}
			}
		}
	}
}
