#pragma semicolon 1	// Fixed error "Exception reported: Entity -1 (-1) is invalid"
#pragma newdecls required

#define MAX_PLAYERS	8	// maximum number of players on the NMRiH server

#if SOURCEMOD_V_MINOR > 10
	#define PL_NAME	"[NMRiH] Infinity"
	#define PL_VER	"1.3.0_04.10.2021"
#endif

#include <sdkhooks>
#include <sdktools_entinput>
#include <sdktools_functions>

static const int
	IN_SHOVE	= (1 << 27);

static const char
#if SOURCEMOD_V_MINOR < 11
	PL_NAME[]	= "[NMRiH] Infinity",
	PL_VER[]	= "1.3.0_04.10.2021",
#endif
	PL_TAG[]	= ",infinite_ammo",
	AMMO[][]	=
{
	"",
	"9mm",		// 1
	".45 ACP",	// 2
	".357",		// 3
	"12 Gauge",	// 4
	".22 LR",	// 5
	".308",		// 6
	"5.56mm",	// 7
	"7.62x39",	// 8
	"M67",		// 9
	"Molotov",	// 10
	"TNT",		// 11
	"Arrow",	// 12
	"Fuel",		// 13
	"Boards",	// 14
	"Flare"		// 15
};

enum
{
	O_Ammo,
	O_Stamina,
	O_Bleed,
	O_Sprint,
	O_Type,
	O_Clip,

	O_Total
};

Handle
	hHUD,
	hTimer;
bool
	bLate,
	bShow,
	bInfStamina,
	bIsAdmin[MAXPLAYERS+1];
int
	iOffset[O_Total],
	iMode[2],
	iColor,
	iWeapon[MAXPLAYERS+1],
	iClip[MAXPLAYERS+1];
float
	fCD,
	fPosX,
	fPosY,
	fMaxStamina;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Makes infinite clip/ammo and stamina and shows their current values",
	author		= "Grey83",
	url			= "https://forums.alliedmods.net/showthread.php?p=2378796"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if((iOffset[O_Ammo]		= FindSendPropInfo("CNMRiH_Player", "m_iAmmo")) < 1)
	{
		FormatEx(error, err_max, "Can't find offset 'CNMRiH_Player::m_iAmmo'!");
		return APLRes_Failure;
	}

	if((iOffset[O_Stamina]	= FindSendPropInfo("CNMRiH_Player", "m_flStamina")) < 1)
	{
		FormatEx(error, err_max, "Can't find offset 'CNMRiH_Player::m_flStamina'!");
		return APLRes_Failure;
	}

	if((iOffset[O_Bleed]	= FindSendPropInfo("CNMRiH_Player", "_bleedingOut")) < 1)
	{
		FormatEx(error, err_max, "Can't find offset 'CNMRiH_Player::_bleedingOut'!");
		return APLRes_Failure;
	}

	if((iOffset[O_Sprint]	= FindSendPropInfo("CNMRiH_Player", "m_bSprintEnabled")) < 1)
	{
		FormatEx(error, err_max, "Can't find offset 'CNMRiH_Player::m_bSprintEnabled'!");
		return APLRes_Failure;
	}

	if((iOffset[O_Type]		= FindSendPropInfo("CNMRiH_WeaponBase", "m_iPrimaryAmmoType")) < 1)
	{
		FormatEx(error, err_max, "Can't find offset 'CNMRiH_WeaponBase::m_iPrimaryAmmoType'!");
		return APLRes_Failure;
	}

	if((iOffset[O_Clip]		= FindSendPropInfo("CNMRiH_WeaponBase", "m_iClip1")) < 1)
	{
		FormatEx(error, err_max, "Can't find offset 'CNMRiH_WeaponBase::m_iClip1'!");
		return APLRes_Failure;
	}

	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("nmrih_infinity_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_inf_ammo",		"1", "Ammo mode for all:\n 0 - Normal mode\n 1 - Infinite ammo\n 2 - Infinite clip", _, true, _, true, 2.0);
	cvar.AddChangeHook(CVarChanged_Ammo);
	iMode[0] = cvar.IntValue;

	cvar = CreateConVar("sm_inf_adm",		"1", "Ammo mode for admins:\n 0 - Normal mode\n 1 - Infinite ammo\n 2 - Infinite clip", _, true, _, true, 2.0);
	cvar.AddChangeHook(CVarChanged_Adm);
	iMode[1] = cvar.IntValue;

	cvar = CreateConVar("sm_inf_stamina",	"1", "On/Off Infinite stamina.", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Stamina);
	bInfStamina = cvar.BoolValue;

	cvar = CreateConVar("sm_inf_hud",		"1", "On/Off display ammo number in the HUD", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_HUD);
	CVarChanged_HUD(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_inf_hud_color",	"ccc", "HUD info color. Set by HEX (RGB or RRGGBB, values 0 - F or 00 - FF, resp.). Wrong color code = white", FCVAR_PRINTABLEONLY);
	cvar.AddChangeHook(CVarChanged_Color);
	CVarChanged_Color(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_inf_hud_update","1.0", "Update info every x seconds (0.0 - show only changes)", _, true, _, true, 5.0);
	cvar.AddChangeHook(CVarChanged_CD);
	CVarChanged_CD(cvar, NULL_STRING, NULL_STRING);

	cvar = CreateConVar("sm_inf_hud_x",		"-0.01", "HUD info position X (0.0 - 1.0 left to right or -1 for center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_PosX);
	fPosX = cvar.FloatValue;

	cvar = CreateConVar("sm_inf_hud_y",		"1.0", "HUD info position Y (0.0 - 1.0 top to bottom or -1 for center)", _, true, -2.0, true, 1.0);
	cvar.AddChangeHook(CVarChanged_PosY);
	fPosY = cvar.FloatValue;

	if((cvar = FindConVar("sv_max_stamina")))
	{
		cvar.AddChangeHook(CVarChanged_MaxStamina);
		fMaxStamina = cvar.FloatValue;
	}

	AutoExecConfig(true, "nmrih_infinity");
	Server_Tag();

	HookEvent("state_change",	Event_State);
	HookEvent("weapon_fired",	Event_Weapon);
	HookEvent("weapon_reload",	Event_Weapon);

	if(bLate)
	{
		bShow = true;
		for(int i = 1, wpn = FindSendPropInfo("CNMRiH_Player", "m_hActiveWeapon"); i <= MaxClients; i++)
			if(IsClientInGame(i))
			{
				if(IsClientAuthorized(i)) OnClientPostAdminCheck(i);
				OnClientPutInServer(i);
				if(wpn > 0 && IsPlayerAlive(i))
				{
					if((iWeapon[i] = GetEntDataEnt2(i, wpn)) > MaxClients) iClip[i] = GetClipSize(iWeapon[i]);
					else iWeapon[i] = 0;
				}
			}
		bLate = false;
	}
}

public void OnPluginEnd()
{
	iMode[0] = iMode[1] = 0;
	Server_Tag();
}

public void CVarChanged_Ammo(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMode[0] = cvar.IntValue;
	Server_Tag();
}

public void CVarChanged_Adm(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iMode[1] = cvar.IntValue | iMode[0];
	Server_Tag();
}

stock void Server_Tag()
{
	static ConVar cvar;
	if(!cvar && !(cvar = FindConVar("sv_tags")))
		return;

	char currentTags[128];
	cvar.GetString(currentTags, sizeof(currentTags));

	if((StrContains(currentTags, PL_TAG, false) == -1) == !iMode[1])
		return;

	if(iMode[1]) StrCat(currentTags, sizeof(currentTags), PL_TAG);
	else ReplaceString(currentTags, sizeof(currentTags), PL_TAG, NULL_STRING);
	cvar.SetString(currentTags);
}

public void CVarChanged_Stamina(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bInfStamina = cvar.BoolValue;
}

public void CVarChanged_HUD(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(!cvar.BoolValue == !(hHUD)) return;

	if(!hHUD) hHUD = CreateHudSynchronizer();
	else delete hHUD;
}

public void CVarChanged_Color(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	char clr[8];
	cvar.GetString(clr, sizeof(clr));
	clr[7] = 0;	// чтобы проверялось максимум 7 первых символов

	int i;
	while(clr[i])
	{
		if(!(clr[i] >= '0' && clr[i] <= '9') && !(clr[i] >= 'A' && clr[i] <= 'F') && !(clr[i] >= 'a' && clr[i] <= 'f'))
		{	// не HEX-число
			iColor = -1;
			LogError("HEX color '%s' isn't valid!\nHUD color is 0x%x (%d %d %d)!\n", clr, iColor, (iColor & 0xFF0000) >> 16, (iColor & 0xFF00) >> 8, iColor & 0xFF);
			return;
		}
		i++;
	}

	clr[6] = 0;
	if(i == 3)	// короткая форма => полная форма
	{
		clr[4] = clr[5] = clr[2];
		clr[2] = clr[3] = clr[1];
		clr[1] = clr[0];
		i = 6;
	}

	if(i != 6) iColor = -1;	// невалидный цвет
	else StringToIntEx(clr, iColor , 16);
}

public void CVarChanged_CD(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fCD = cvar.FloatValue;
	UpdateTimer();
}

public void CVarChanged_PosX(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosX = cvar.FloatValue;
}

public void CVarChanged_PosY(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fPosY = cvar.FloatValue;
}

public void CVarChanged_MaxStamina(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	fMaxStamina = cvar.FloatValue;
}

stock void UpdateTimer()
{
	OnMapEnd();
	OnMapStart();
}

public void OnMapStart()
{
	if(bShow && hHUD && fCD > 0) hTimer = CreateTimer(fCD, Timer_UpdateInfo, _, TIMER_REPEAT);
}

public void OnEntityCreated(int ent, const char[] cls)
{
	if(iMode[0] && ent > MaxClients && (!strcmp(cls, "item_ammo_box", false)))
		AcceptEntityInput(ent, "Kill");
}

public void Event_State(Event event, const char[] name, bool dontBroadcast)
{
	if((bShow = event.GetInt("state") == 3) && iMode[0])
	{
		int ent = MaxClients+1;
		while((ent = FindEntityByClassname(ent, "item_ammo_box")) != -1) AcceptEntityInput(ent, "Kill");
	}
	UpdateTimer();
}

public Action Timer_UpdateInfo(Handle timer)
{
	static int i;
	for(i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && IsPlayerAlive(i)) ShowAmmo(i);

	return Plugin_Continue;
}

public void OnMapEnd()
{
	if(hTimer) delete hTimer;
}

public void OnClientPostAdminCheck(int client)
{
	bIsAdmin[client] = !IsFakeClient(client) && GetUserAdmin(client) != INVALID_ADMIN_ID;
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client)) return;

	SDKHook(client, SDKHook_WeaponSwitchPost, Hook_Switch);
	SDKHook(client, SDKHook_WeaponDropPost, Hook_Drop);
	SDKHook(client, SDKHook_FireBulletsPost, Hook_Fire);
}

public void OnClientDisconnect_Post(int client)
{
	iWeapon[client] = iClip[client] = 0;
}

public void Hook_Switch(int client, int weapon)
{
	iWeapon[client] = weapon;
	iClip[client] = GetClipSize(weapon);

	if(bShow) ShowAmmo(client);
}

public void Hook_Drop(int client, int weapon)
{
	if(bShow) ShowAmmo(client);
}

public void Hook_Fire(int client, int shots, const char[] weaponname)
{
	if(bShow) ShowAmmo(client);
}

public void Event_Weapon(Event event, const char[] name, bool dontBroadcast)
{
	if(!bShow) return;

	int client = event.GetInt("player_id");
	if(name[7] == 'r') client = GetClientOfUserId(client);
	if(client && IsPlayerAlive(client)) ShowAmmo(client);
}

stock void ShowAmmo(int client)
{
	if(iWeapon[client] <= MaxClients || !IsValidEdict(iWeapon[client])) return;

	static int type;
	static char txt[20];
	type = GetEntData(iWeapon[client], iOffset[O_Type]);
	if(type == -1)
	{
		if(!GetEntityClassname(iWeapon[client], txt, sizeof(txt)) || txt[0] != 'i') return;

		switch(txt[5])
		{
			case 'b': FormatEx(txt, sizeof(txt), "Bandages\n ");
			case 'f': FormatEx(txt, sizeof(txt), "First Aid\n ");
			case 'g':
			{
				if(txt[6] != 'e') return;

				FormatEx(txt, sizeof(txt), "Gene Therapy\n ");
			}
			case 'p': FormatEx(txt, sizeof(txt), "Pills\n ");
			default: return;
		}
	}
	else if((iMode[view_as<int>(bIsAdmin[client])] < 2)	// clip for this player is not infinite
	&& (0 < type && type < 9 || 11 < type && type < sizeof(AMMO)))
		FormatEx(txt, sizeof(txt), "%s\n%i / %i", AMMO[type], GetEntData(iWeapon[client], iOffset[O_Clip]), GetEntData(client, (iOffset[O_Ammo] + (type << 2))));
	else return;

	SetHudTextParams(fPosX, fPosY, fCD, (iColor & 0xFF0000) >> 16, (iColor & 0xFF00) >> 8, iColor & 0xFF, 127, 0, 0.0, 0.1, 0.1);
	ShowSyncHudText(client, hHUD, txt);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!buttons || !IsValidClient(client))
		return Plugin_Continue;

	if(bInfStamina && buttons & (IN_JUMP|IN_DUCK|IN_FORWARD|IN_LEFT|IN_RIGHT|IN_MOVELEFT|IN_MOVERIGHT|IN_SPEED|IN_SHOVE))
	{
		SetEntDataFloat(client, iOffset[O_Stamina], fMaxStamina, true);
		SetEntData(client, iOffset[O_Bleed], 0, true);
		SetEntData(client, iOffset[O_Sprint], 1, true);
	}

	if(!iMode[view_as<int>(bIsAdmin[client])] || !iClip[client] || !iWeapon[client])
		return Plugin_Continue;

	if(buttons & IN_RELOAD) SetClip(client);

	if(iMode[view_as<int>(bIsAdmin[client])] & 2)	// Infinite clip
	{
		if(buttons & IN_ATTACK) SetEntData(iWeapon[client], iOffset[O_Clip], iClip[client], _, true);
		if(buttons & IN_BULLRUSH)
		{
			buttons &= ~IN_BULLRUSH;	// ...и изъятие патронов при бесконечной обойме
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

stock void SetClip(int client)
{
	static int ammo, clip;
	ammo = iOffset[O_Ammo] + (GetEntData(iWeapon[client], iOffset[O_Type]) << 2);
	if((clip = iClip[client] - GetEntData(iWeapon[client], iOffset[O_Clip])) != GetEntData(client, ammo))
		SetEntData(client, ammo, clip, _, true);
}

stock bool IsValidClient(int client)
{
	return 0 < client && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client);
}

stock int GetClipSize(int weapon)
{
	static char cls[12];
	if(weapon <= MaxClients || !GetEntityClassname(weapon, cls, sizeof(cls)) || strlen(cls) < 6)
		return 0;

	switch(cls[0])
	{
		case 'b','e':	return 1;	// bow_deerhunter, exp_
		case 't':		if(cls[5] == 'b' || cls[5] == 'f') return 1;	// tool_barricade, tool_flare_gun
		case 'm':
		{
			switch(cls[5])
			{
				case 'r':	return 80;	// me_abrasivesaw
				case 'a':	return 100;	// me_chainsaw
			}
		}
		case 'f':	// fa_
		{
			switch(cls[3])
			{
				case '1':	return !cls[7] ? (cls[5] == '1' ? 7 : 10) : 25;	// fa_1911, fa_1022, fa_1022_25mag
				case '5':	return 5;	// fa_500a
				case '8':	return 8;	// fa_870
				case 'c':	return 30;	// fa_cz858
				case 'f':	return 20;	// fa_fnfal
				case 'g':	return 17;	// fa_glock17
				case 'j':	return 10;	// fa_jae700
				case 'w':	return 15;	// fa_winchester1892
				case 'm','s':
					switch(cls[6])
					{
						case '0':		return 2;	// fa_sv10
						case '8':		return 6;	// fa_sw686
						case 'a','1':	return 30;	// fa_m16a4, fa_m16a4_carryhandle, fa_mp5a3, fa_mac10
						case 'e','o':	return 5;	// fa_superx3, fa_sako85, fa_sako85_ironsights
						case 'f':		return 15;	// fa_m92fs
						case 'i',0,'_':	return 10;	// fa_mkiii, fa_sks, fa_sks_nobayo
					}
			}
		}
	}
	return 0;
}