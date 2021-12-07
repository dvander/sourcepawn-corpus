#pragma semicolon 1
#include <sourcemod>
//#pragma newdecls required
#include <colors>

char cls[128], sModel[128], sWeapon[64];

public Plugin myinfo =
{
	name = "[Left 4 Dead] Breaks Weapon",
	author = "AlexMY",
	description = "",
	version = "1.0",
	url = "SourceMod.net"
};

public void OnPluginStart()
{
	HookEvent("break_prop",  eventBreak_Prop);
	HookEvent("weapon_fire", eventWeapon_Fire);
	
	LoadTranslations("l4d_BreaksWeapon.phrases");
}

public void eventWeapon_Fire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, "molotov"))
	{
		CPrintToChatAll("%t", "sMolotov", client);
	}
	else if(StrEqual(sWeapon, "pipe_bomb")) 
	{
		CPrintToChatAll("%t", "sPipeBomb", client);
	}
}

public void eventBreak_Prop(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int id = event.GetInt("entindex");
	{
		if(IsValidEntity(id) && GetEntityClassname(id, cls, sizeof(cls)) && StrEqual(cls, "prop_physics"))
		{
			GetEntPropString(id, Prop_Data, "m_ModelName", sModel, sizeof(sModel)); 
			if (StrEqual(sModel, "models/props_junk/gascan001a.mdl"))
			{
				CPrintToChatAll("%t", "sGasCan", client);
			}
			else if (StrEqual(sModel, "models/props_equipment/oxygentank01.mdl"))
			{
				CPrintToChatAll("%t", "sOxygenTank", client);
			}
			else if (StrEqual(sModel, "models/props_junk/propanecanister001a.mdl"))
			{
				CPrintToChatAll("%t", "sPropaneCanister", client);
			}
		}
	}
}