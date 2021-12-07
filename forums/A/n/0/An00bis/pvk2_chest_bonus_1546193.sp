#include <sourcemod>

#define PLUGIN_VERSION "1.1.2"

new specialOffset
new Handle:bCaptureBonusEnabled		= INVALID_HANDLE
new Handle:iCaptureBonusPercentage	= INVALID_HANDLE
new Handle:hServerTags					= INVALID_HANDLE
new bool:bIsEnabled = true

new Float:specialval[] = { 165.0, 165.0, 165.0, 190.0, 190.0, 190.0, 190.0, 190.0, 200.0, 200.0, 200.0,	185.0, 185.0, 185.0, 260.0,	260.0,
						165.0, 165.0, 165.0, 165.0, 165.0, 165.0, 210.0, 210.0, 210.0, 210.0, 210.0, 210.0
						}
new String:weapons[][] = { 
							"weapon_cutlass", 
							"weapon_flintlock", 
							"weapon_powderkeg", 
							"weapon_cutlass2", 
							"weapon_blunderbuss", 
							"weapon_parrot", 
							"weapon_bigaxe", 
							"weapon_axesword", 
							"weapon_twoaxe", 
							"weapon_vikingshield", 
							"weapon_throwaxe", 
							"weapon_spear", 
							"weapon_seaxshield", 
							"weapon_javelin", 
							"weapon_twosword", 
							"weapon_swordshield", 
							"weapon_longbow", 
							"weapon_archersword", 
							"weapon_crossbow",
							"weapon_ssflintlock",
							"weapon_ssrifle",
							"weapon_dagger",
							"weapon_halberd",
							"weapon_maceshield",
							"weapon_crossbow2",
							"weapon_flatbow",
							"weapon_atlatl",
							"weapon_seax"
							}

public Plugin:myinfo =
{
name			= "Chest Capture Bonus",
author			= "An00bis",
description	= "Capturing a chest now increases the specialbar.",
version		= PLUGIN_VERSION,
url			= "https://forums.alliedmods.net/member.php?u=153377"
};
 
public OnPluginStart()
{
	CreateConVar("sm_chestcapturebonus_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	bCaptureBonusEnabled		= CreateConVar("sm_chestcapturebonus_enabled", "1", "Enabled/Disabled", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	iCaptureBonusPercentage	= CreateConVar("sm_chestcapturebonus_percentage", "25.0", "How much should the specialbar increase in percent", FCVAR_PLUGIN, true, 0.0, true, 100.0);
	HookEvent("chest_capture", OnChestCapture);
	HookConVarChange(bCaptureBonusEnabled, OnEnabledChange);
}

public OnMapStart()
{
	specialOffset = FindSendPropOffs("CPVK2Player", "m_iSpecial");
	hServerTags = FindConVar("sv_tags");
	decl String:tags[255];
	GetConVarString(hServerTags, tags, sizeof(tags));
	if(StrEqual(tags, "", false))
	{
		SetConVarString(hServerTags, "Chest Capture Bonus");
	}
	else
	{
		if(StrContains(tags, "Chest Capture Bonus", false) == -1)
		{
		decl String:newtags[255];
		Format(newtags, sizeof(newtags), "%s, Chest Capture Bonus", tags);
		SetConVarString(hServerTags, newtags);
		}
	}
}

public OnEventShutdown()
{
	UnhookEvent("chest_capture", OnChestCapture);
}

public OnMapEnd()
{
	UnhookConVarChange(bCaptureBonusEnabled, OnEnabledChange);
	CloseHandle(hServerTags);
}

public Action:OnChestCapture(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bIsEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new oldvalue;
		new newvalue;
		new String:waffe[64];
		oldvalue = GetEntData(client, specialOffset, 4);
		GetClientWeapon(client, waffe, sizeof(waffe));
		for(new i = 0; i < sizeof(weapons); i++)
		{
			if(StrEqual(waffe, weapons[i], false) )
			{
				newvalue = RoundToZero(doMath(specialval[i], oldvalue));
				SetEntData(client, specialOffset, newvalue, 4);
				if(newvalue == specialval[i] && newvalue != oldvalue)
				{
					ClientCommand(client, "playgamesound player/special.wav");
				}
			}
		}
	}
}

public Float:doMath(Float:maxvalue, oldvalue)
{
	decl Float:x;
	x = maxvalue / 100 * GetConVarFloat(iCaptureBonusPercentage) + oldvalue;
	if(x >= maxvalue)
	{ return maxvalue; }
	else 
	{ return x; }
}

public OnEnabledChange(Handle:cvar, const String:oldval[], const String:newval[])
{
	if(StringToInt(newval) == 0)
	{
		bIsEnabled = false;
		PrintToServer("Chest Capture Bonus Disabled");
	}
	else
	{
		bIsEnabled = true;
		PrintToServer("Chest Capture Bonus Enabled");
	}
}