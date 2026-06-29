#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define MAX_ATTRS			21
#define TANK_ZOMBIE_CLASS	8

public Plugin myinfo =
{
	name		= "L4D2 Weapon Attributes",
	author		= "Jahze, $atanic $pirit",
	version		= "1.2",
	description	= "Allowing tweaking of the attributes of all weapons"
};

any iWeaponAttributes[MAX_ATTRS] = 
{
	L4D2IWA_Damage,
	L4D2IWA_Bullets,
	L4D2IWA_ClipSize,
	L4D2FWA_MaxPlayerSpeed,
	L4D2FWA_SpreadPerShot,
	L4D2FWA_MaxSpread,
	L4D2FWA_SpreadDecay,
	L4D2FWA_MinDuckingSpread,
	L4D2FWA_MinStandingSpread,
	L4D2FWA_MinInAirSpread,
	L4D2FWA_MaxMovementSpread,
	L4D2FWA_PenetrationNumLayers,
	L4D2FWA_PenetrationPower,
	L4D2FWA_PenetrationMaxDist,
	L4D2FWA_CharPenetrationMaxDist,
	L4D2FWA_Range,
	L4D2FWA_RangeModifier,
	L4D2FWA_CycleTime,
	L4D2FWA_PelletScatterPitch,
	L4D2FWA_PelletScatterYaw,
	-1
};

char sWeaponAttrNames[MAX_ATTRS][32] = 
{
	"Damage",
	"Bullets",
	"Clip Size",
	"Max player speed",
	"Spread per shot",
	"Max spread",
	"Spread decay",
	"Min ducking spread",
	"Min standing spread",
	"Min in air spread",
	"Max movement spread",
	"Penetraion num layers",
	"Penetration power",
	"Penetration max dist",
	"Char penetration max dist",
	"Range",
	"Range modifier",
	"Cycle time",
	"Pellet scatter pitch",
	"Pellet scatter yaw",
	"Tank damage multiplier"
};

char sWeaponAttrShortName[MAX_ATTRS][32] = 
{
	"damage",
	"bullets",
	"clipsize",
	"speed",
	"spreadpershot",
	"maxspread",
	"spreaddecay",
	"minduckspread",
	"minstandspread",
	"minairspread",
	"maxmovespread",
	"penlayers",
	"penpower",
	"penmaxdist",
	"charpenmaxdist",
	"range",
	"rangemod",
	"cycletime",
	"scatterpitch",
	"scatteryaw",
	"tankdamagemult"
};

bool bLateLoad;

KeyValues kvTankDamage;

public APLRes AskPluginLoad2( Handle plugin, bool late, char[] error, int errMax ) 
{
	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() 
{
	RegServerCmd("sm_weapon", Weapon);
	RegConsoleCmd("sm_weapon_attributes", WeaponAttributes);

	kvTankDamage = new KeyValues("DamageVsTank");

	if ( bLateLoad ) 
	{
		for ( int i = 1; i < MaxClients+1; i++ ) 
		{
			if ( IsClientInGame(i) ) 
			{
				SDKHook(i, SDKHook_OnTakeDamage, DamageBuffVsTank);
			}
		}
	}
}

public void OnClientPutInServer( int client ) 
{
	SDKHook(client, SDKHook_OnTakeDamage, DamageBuffVsTank);
}

public void OnPluginEnd() 
{
	if ( kvTankDamage != null ) 
	{
		CloseHandle(kvTankDamage);
		kvTankDamage = null;
	}
}

int GetWeaponAttributeIndex( char sAttrName[128] ) 
{
	for ( int i = 0; i < MAX_ATTRS; i++ ) {
		if ( StrEqual(sAttrName, sWeaponAttrShortName[i]) ) {
			return i;
		}
	}

	return -1;
}

int GetWeaponAttributeInt( char[] sWeaponName, int idx ) 
{
	return L4D2_GetIntWeaponAttribute(sWeaponName, iWeaponAttributes[idx]);
}

float GetWeaponAttributeFloat( char[] sWeaponName, int idx ) 
{
	return L4D2_GetFloatWeaponAttribute(sWeaponName, iWeaponAttributes[idx]);
}

void SetWeaponAttributeInt( char[] sWeaponName, int idx, int value ) 
{
	L4D2_SetIntWeaponAttribute(sWeaponName, iWeaponAttributes[idx], value);
}

void SetWeaponAttributeFloat( char[] sWeaponName, int idx, float value ) 
{
	L4D2_SetFloatWeaponAttribute(sWeaponName, iWeaponAttributes[idx], value);
}

public Action Weapon( int args ) 
{
	int iValue;
	float fValue;
	int iAttrIdx;
	char sWeaponName[128];
	char sWeaponNameFull[128];
	char sAttrName[128];
	char sAttrValue[128];

	if ( GetCmdArgs() < 3 ) 
	{
		PrintToServer("Syntax: sm_weapon <weapon> <attr> <value>");
		return;
	}

	GetCmdArg(1, sWeaponName, sizeof(sWeaponName));
	GetCmdArg(2, sAttrName, sizeof(sAttrName));
	GetCmdArg(3, sAttrValue, sizeof(sAttrValue));

	if ( L4D2_IsValidWeapon(sWeaponName) ) 
	{
		PrintToServer("Bad weapon name: %s", sWeaponName);
		return;
	}

	iAttrIdx = GetWeaponAttributeIndex(sAttrName);

	if ( iAttrIdx == -1 ) 
	{
		PrintToServer("Bad attribute name: %s", sAttrName);
		return;
	}

	sWeaponNameFull[0] = 0;
	StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), "weapon_");
	StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), sWeaponName);

	iValue = StringToInt(sAttrValue);
	fValue = StringToFloat(sAttrValue);

	if ( iAttrIdx < 3 ) 
	{
		SetWeaponAttributeInt(sWeaponNameFull, iAttrIdx, iValue);
		PrintToServer("%s for %s set to %d", sWeaponAttrNames[iAttrIdx], sWeaponName, iValue);
	}
	else if ( iAttrIdx < MAX_ATTRS-1 ) 
	{
		SetWeaponAttributeFloat(sWeaponNameFull, iAttrIdx, fValue);
		PrintToServer("%s for %s set to %.2f", sWeaponAttrNames[iAttrIdx], sWeaponName, fValue);
	}
	else 
	{
		kvTankDamage.SetFloat(sWeaponNameFull, fValue);
		PrintToServer("%s for %s set to %.2f", sWeaponAttrNames[iAttrIdx], sWeaponName, fValue);
	}
}

public Action WeaponAttributes( int client, int args ) 
{
	char sWeaponName[128];
	char sWeaponNameFull[128];

	if ( GetCmdArgs() < 1 ) 
	{
		ReplyToCommand(client, "Syntax: sm_weapon_attributes <weapon>");
		return;
	}

	GetCmdArg(1, sWeaponName, sizeof(sWeaponName));

	if ( L4D2_IsValidWeapon(sWeaponName) ) 
	{
		ReplyToCommand(client, "Bad weapon name: %s", sWeaponName);
		return;
	}

	sWeaponNameFull[0] = 0;
	StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), "weapon_");
	StrCat(sWeaponNameFull, sizeof(sWeaponNameFull), sWeaponName);

	ReplyToCommand(client, "Weapon stats for %s", sWeaponName);

	for ( int i = 0; i < 3; i++ ) 
	{
		int iValue = GetWeaponAttributeInt(sWeaponNameFull, i);
		ReplyToCommand(client, "%s: %d", sWeaponAttrNames[i], iValue);
	}

	for ( int i = 3; i < MAX_ATTRS-1; i++ ) 
	{
		float fValue = GetWeaponAttributeFloat(sWeaponNameFull, i);
		ReplyToCommand(client, "%s: %.2f", sWeaponAttrNames[i], fValue);
	}

	float fBuff = kvTankDamage.GetFloat(sWeaponNameFull, 0.0);

	if ( fBuff )
		ReplyToCommand(client, "%s: %.2f", sWeaponAttrNames[MAX_ATTRS-1], fBuff);
}

public Action DamageBuffVsTank(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
	if (attacker <= 0 || attacker > MaxClients+1)
		return Plugin_Continue;

	if ( !IsTank(victim) )
		return Plugin_Continue;

	char sWeaponName[128];
	GetClientWeapon(attacker, sWeaponName, sizeof(sWeaponName));
	float fBuff = kvTankDamage.GetFloat(sWeaponName, 0.0);

	if ( !fBuff )
		return Plugin_Continue;

	damage *= fBuff;

	return Plugin_Changed;
}

bool IsTank( int client ) 
{
	if ( client <= 0
	|| client > MaxClients+1
	|| !IsClientInGame(client)
	|| GetClientTeam(client) != 3
	|| !IsPlayerAlive(client) ) 
	{
		return false;
	}

	int playerClass = GetEntProp(client, Prop_Send, "m_zombieClass");

	if ( playerClass == TANK_ZOMBIE_CLASS ) 
		return true;

	return false;
}