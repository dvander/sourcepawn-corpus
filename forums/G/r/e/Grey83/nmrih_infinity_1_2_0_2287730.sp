#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

static const char	PLUGIN_NAME[]		= "[NMRiH] Infinity",
					PLUGIN_VERSION[]	= "1.2.0",
					PLUGIN_TAG[]		= ",infinite ammo";

static const int	IN_SHOVE			= (1 << 27);

bool bInfStamina;
int iModeAll,
	iModeAdm;
float fMaxStamina;

bool bLate,
	bClean,
	bIsAdmin[MAXPLAYERS+1];
//int iWeaponsNum;

int iAmmoOffset, iClip1Offset;

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "Make endless clip/ammo & stamina in NMRiH",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=2378796"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	if((iAmmoOffset = FindSendPropInfo("CNMRiH_Player", "m_iAmmo")) < 1)
		SetFailState("Can't find offset 'm_iAmmo'!");
	if((iClip1Offset = FindSendPropInfo("CNMRiH_WeaponBase", "m_iClip1")) < 1)
		SetFailState("Can't find offset 'm_iClip1'!");

//	iWeaponsNum = sizeof(sWeaponName);

	CreateConVar("nmrih_infinity_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_inf_ammo",		"1",	"Ammo mode for all:\n 0 - Normal mode\n 1 - Infinite ammo\n 2 - Infinite clip", FCVAR_NOTIFY, true, 0.0, true, 2.0)).AddChangeHook(CVarChanged_Ammo);
	iModeAll = CVar.IntValue;
	(CVar = CreateConVar("sm_inf_adm",		"1",	"Ammo mode for admins:\n 0 - Normal mode\n 1 - Infinite ammo\n 2 - Infinite clip", FCVAR_NOTIFY, true, 0.0, true, 2.0)).AddChangeHook(CVarChanged_Adm);
	iModeAdm = CVar.IntValue;
	(CVar = CreateConVar("sm_inf_stamina",	"1",	"On/Off Infinite stamina.", FCVAR_NOTIFY, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Stamina);
	bInfStamina = CVar.BoolValue;
	(CVar = FindConVar("sv_max_stamina")).AddChangeHook(CVarChanged_MaxStamina);
	fMaxStamina = CVar.FloatValue;

	HookEvent("state_change", StateChange);

	AutoExecConfig(true, "nmrih_infinity");

	if(bLate)
	{
		for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i)) OnClientPostAdminCheck(i);
		bLate = false;
	}
}

public void OnConfigsExecuted()
{
	Server_Tag();
}

public void CVarChanged_Ammo(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iModeAll = CVar.IntValue;
	Server_Tag();
}

public void CVarChanged_Adm(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	iModeAdm = CVar.IntValue;
	Server_Tag();
}

public void CVarChanged_Stamina(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bInfStamina = CVar.BoolValue;
}

public void CVarChanged_MaxStamina(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	fMaxStamina = CVar.FloatValue;
}

public void OnClientPostAdminCheck(int client)
{
	if(0 < client <= MaxClients) bIsAdmin[client] = GetUserAdmin(client) != INVALID_ADMIN_ID;
}

public void StateChange(Event event, const char[] name, bool dontBroadcast)
{
	if(iModeAll && event.GetInt("state") == 3)
	{
		CreateTimer(10.0, RemoveAmmoBoxes, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		bClean = true;
	}
	else bClean = false;
}

public Action RemoveAmmoBoxes(Handle timer)
{
	static int ent;
	ent = MaxClients+1;
	while((ent = FindEntityByClassname(ent, "item_ammo_box")) != -1) AcceptEntityInput(ent, "Kill");

	return bClean ? Plugin_Continue : Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!buttons || !IsValidClient(client)) return Plugin_Continue;
/*
	(1 << 0)	= IN_ATTACK		+attack
	(1 << 1)	= IN_JUMP		+jump
	(1 << 2)	= IN_DUCK		+duck
	(1 << 3)	= IN_FORWARD	+forward
	(1 << 4)	= IN_BACK		+back
	(1 << 5)	= IN_USE		+use
	(1 << 6)	= IN_CANCEL
	(1 << 7)	= IN_LEFT		+left
	(1 << 8)	= IN_RIGHT		+right
	(1 << 9)	= IN_MOVELEFT	+moveleft
	(1 << 10)	= IN_MOVERIGHT	+moveright
	(1 << 11)	= IN_ATTACK2	+attack2
	(1 << 12)	= IN_RUN
	(1 << 13)	= IN_RELOAD		+reload
	(1 << 14)	= IN_ALT1		+alt1		// не работает
	(1 << 15)	= IN_ALT2		+dropweapon
	(1 << 16)	= IN_SCORE		+showscores
	(1 << 17)	= IN_SPEED		+speed
	(1 << 18)	= IN_WALK		+walk		// не работает
	(1 << 19)	= IN_ZOOM		+zoom		// не работает
	(1 << 20)	= IN_WEAPON1
	(1 << 21)	= IN_WEAPON2
	(1 << 22)	= IN_BULLRUSH	+unload
	(1 << 23)	= IN_GRENADE1	+grenade1	// не работает
	(1 << 24)	= IN_GRENADE2	+selectfire
	(1 << 25)	= IN_ATTACK3	+attack3	// не работает
	(1 << 26)	= 				+maglite
	(1 << 27)	= 				+shove
	(1 << 28)	= 				+compass
	(1 << 29)	= 				+inventory
	(1 << 30)	= 				+ammoinv
	(1 << 31)	= 				+voicecmd
*/

	if(bInfStamina && (buttons & IN_JUMP || buttons & IN_DUCK || buttons & IN_FORWARD || buttons & IN_LEFT || buttons & IN_RIGHT || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT || buttons & IN_SPEED || buttons & IN_SHOVE))
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", fMaxStamina);
		SetEntProp(client, Prop_Send, "_bleedingOut", 0);
		SetEntProp(client, Prop_Send, "m_bSprintEnabled", 1);
	}

	// if infinite ammo & clip disabled for all
	if(!(iModeAdm|iModeAll)) return Plugin_Continue;

	static bool changed;
	static int active_weapon, clip;
	changed = false;
	switch(bIsAdmin[client] ? (iModeAdm|iModeAll) : iModeAll)
	{
		case 1:		// Infinite ammo
		{
			if(buttons & IN_RELOAD && (clip = GetClipSize(client)))
			{
				static int ammo;
				if(!IsValidEdict((active_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon")))) return Plugin_Continue;
				ammo = iAmmoOffset + GetEntProp(active_weapon, Prop_Data, "m_iPrimaryAmmoType") * 4;
				if((clip -= (GetEntData(active_weapon, iClip1Offset) + GetEntData(client, ammo))) > 0) SetEntData(client, ammo, clip, _, true);
			}
		}
		case 2,3:	// Infinite clip
		{
//			if((buttons & IN_ATTACK || buttons & IN_ATTACK2 || buttons & IN_ATTACK3)
			if(buttons & IN_ATTACK && IsValidEdict((active_weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon"))) && (clip = GetClipSize(client)) > 0) SetEntData(active_weapon, iClip1Offset, clip, _, true);

			if(buttons & IN_RELOAD)
			{
				buttons &= ~IN_RELOAD;		// Блочим перезарядку...
				changed = true;
			}
			if(buttons & IN_BULLRUSH)
			{
				buttons &= ~IN_BULLRUSH;	// ...и изъятие патронов при бесконечной обойме
				changed = true;
			}
		}
	}

	return changed ? Plugin_Changed : Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client);
}
/*
static const char sWeaponName[][] = {
	"bow_",				// 1
	"exp_",				// 1
	"fa_1022_25mag",	// 25 (must be before 'fa_1022' in this array)
	"fa_1022",			// 10
	"fa_1911",			// 7
	"fa_500a",			// 5
	"fa_870",			// 8
	"fa_cz858",			// 30
	"fa_fnfal",			// 20
	"fa_glock17",		// 17
	"fa_jae700",		// 10
	"fa_m16a4",			// 30
	"fa_m92fs",			// 15
	"fa_mac10",			// 30
	"fa_mkiii",			// 10
	"fa_mp5a3",			// 30
	"fa_sako85",		// 5
	"fa_sks",			// 10
	"fa_superx3",		// 5
	"fa_sv10",			// 2
	"fa_sw686",			// 6
	"fa_winchester1892",// 15
	"me_abrasivesaw",	// 80
	"me_chainsaw",		// 100
	"tool_barricade",	// 1
	"tool_flare_gun"	// 1
};

static const int iWeaponClip[] = {1, 1, 25, 10, 7, 5, 8, 30, 20, 17, 10, 30, 15, 30, 10, 30, 5, 10, 5, 2, 6, 15, 80, 100, 1, 1};

stock int GetClipSize(int client)
{
	static int i;
	static char wpn[32];
	GetClientWeapon(client, wpn, sizeof(wpn));
	if(strlen(wpn) > 5) for(i = 0; i < iWeaponsNum; i++) if(!StrContains(wpn, sWeaponName[i])) return iWeaponClip[i];
	return 0;
}
*/
stock int GetClipSize(int client)
{
	static char wpn[32];
	GetClientWeapon(client, wpn, sizeof(wpn));
	if(strlen(wpn) < 6) return 0;

	switch(wpn[0])
	{
		case 'b','e':	return 1;
		case 't':		if(wpn[5] == 'b' || wpn[5] == 'f') return 1;
		case 'm':
		{
			switch(wpn[5])
			{
				case 'r':	return 80;
				case 'a':	return 100;
				default:	return 0;
			}
		}
		case 'f':
		{
			switch(wpn[3])
			{
				case '1':	return !wpn[7] ? (wpn[6] == '1' ? 7 : 10) : 25;
				case '5':	return 5;
				case '8':	return 8;
				case 'c':	return 30;
				case 'f':	return 20;
				case 'g':	return 17;
				case 'j':	return 10;
				case 'w':	return 15;
				case 'm','s':
					switch(wpn[6])
					{
						case '0':		return 2;
						case '8':		return 6;
						case 'a','1':	return 30;
						case 'e','o':	return 5;
						case 'f':		return 15;
						case 'i',0,'_':	return 10;
					}
			}
		}
	}
	return 0;
}

stock void Server_Tag()
{
	static ConVar cvarTags;
	if(cvarTags == null && (cvarTags = FindConVar("sv_tags")) == null) return;

	static char currentTags[255];
	cvarTags.GetString(currentTags, sizeof(currentTags));

	if((StrContains(currentTags, PLUGIN_TAG, false) == -1) == !(iModeAll|iModeAdm)) return;

	if(iModeAll|iModeAdm) StrCat(currentTags, sizeof(currentTags), PLUGIN_TAG);
	else ReplaceString(currentTags, sizeof(currentTags), PLUGIN_TAG, "");
	cvarTags.SetString(currentTags);
}