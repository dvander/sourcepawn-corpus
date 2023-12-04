#include <sourcemod>
#include <sdktools>
#include <cstrike>

//-----------------------------------------------------------------------------
public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end",		RoundEndEvent);
	PrintToServer("ABS_CSGO_Hs Loaded");
}

//-----------------------------------------------------------------------------
public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	bool hasHealthShot;
	int entity;
	char classname[64];
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			hasHealthShot = false;
			int arraysize = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
			for(int x = 0; x < arraysize; x++)
			{
				entity = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", x);
				if(entity != -1)
				{
					GetEntityClassname(entity, classname, sizeof(classname));
					//PrintToServer("iNVENTORY iTEM = %s", classname);

					CS_GetTranslatedWeaponAlias(classname, classname, sizeof(classname));
					CSWeaponID weaponID = CS_AliasToWeaponID(classname);

					if(weaponID == CSWeapon_HEALTHSHOT)
						hasHealthShot = true;
				}
			}
			if(!hasHealthShot)
				GivePlayerItem(client, "weapon_healthshot");
		}
	}
	return Plugin_Continue;
}

//-----------------------------------------------------------------------------
public Action:RoundEndEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	RemoveAllHealthShots();
	return Plugin_Continue;
}

//---------------------------------------------------------------------------
public RemoveAllHealthShots()
{
	new ent = -1;
	new prev = 0;

	while ((ent = FindEntityByClassname(ent, "weapon_healthshot")) != -1)
	{
		if (prev)
			RemoveEdict(prev);
		prev = ent;
	}
	if (prev)
		RemoveEdict(prev);
}
