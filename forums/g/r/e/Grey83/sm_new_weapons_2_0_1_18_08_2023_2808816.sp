#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools_entinput>
#include <sdktools_functions>
#include <sdktools_sound>
#include <sdktools_stringtables>

static const char
	PL_NAME[]	= "New Weapons",
	PL_VER[]	= "2.0.1_18.08.2023";

bool
	bEnable;
int
	iTime;

ArrayList
	hCmds;
StringMap
	hParent,
	hPlay,
	hSound,
	hAmmo,
	hDmgMult,
	hAccuracy,
	hPrice;
Menu
	hMenu;
float
	fStart;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "<- Add New Weapons ->",
	author		= "cjsrk, Grey83"
}

public void OnPluginStart()
{
	CreateConVar("sm_new_weapons_version", PL_NAME, PL_VER, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);

	ConVar cvar;
	cvar = CreateConVar("sm_new_weapons_enable", "1", "Whether to enable the plugin (1: enabled; 0: disabled)", _, true, _, true, 1.0);
	HookConVarChange(cvar, CVarChange_Enable);
	bEnable = GetConVarBool(cvar);

	cvar = CreateConVar("sm_allow_buytime", "30", "Set the time limit for acquiring new weapons after the start of the round, unit: seconds (range: 5-300 seconds)", _, true, 5.0, true, 300.0);
	HookConVarChange(cvar, CVarChange_Time);
	iTime = GetConVarInt(cvar);

	AutoExecConfig(true, "plugin.new_weapons");

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("weapon_fire", Event_WeaponOldSound);

	RegConsoleCmd("sm_new_weapons", Cmd_Menu, "Menu for buying new weapons");

	hCmds = new ArrayList(ByteCountToCells(36));
	hParent = new StringMap();
	hPlay = new StringMap();
	hSound = new StringMap();
	hAmmo = new StringMap();
	hDmgMult = new StringMap();
	hAccuracy = new StringMap();
	hPrice = new StringMap();
}

public void CVarChange_Enable(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	bEnable = cvar.BoolValue;
}

public void CVarChange_Time(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	iTime = cvar.IntValue;
}

public void OnMapStart()
{
	fStart = 0.0;
	delete hMenu;

	char buffer[PLATFORM_MAX_PATH];
	char data[8][64];
	while(hCmds.Length)
	{
		hCmds.GetString(0, buffer, sizeof(data[]) + 4);
		hCmds.Erase(0);
		RemoveCommandListener(Cmd_GetWeapon, buffer);
	}

	if(hParent.Size)
	{
		hParent.Clear();
		hPlay.Clear();
		hSound.Clear();
		hAmmo.Clear();
		hDmgMult.Clear();
		hAccuracy.Clear();
		hPrice.Clear();
	}

	BuildPath(Path_SM, buffer, PLATFORM_MAX_PATH, "configs/NewWeaponsInfo.txt");
	File file = OpenFile(buffer, "r");
	if(!file)
	{
		LogError("Can't open config \"%s\".", buffer);
		return;
	}

	int i_buffer, num;
	float f_buffer;
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		num++;
		if(strlen(buffer) < 21 || buffer[0] != '<'
		|| ExplodeString(buffer[1], "><", data, sizeof(data), sizeof(data[])) < 8
		|| !TrimString(data[0]) || !TrimString(data[1]))
		{
			LogError("Invalid parameters at line %i: \"%s\".", num, buffer);
			continue;
		}

		if(hParent.GetString(data[0], buffer, 32))
		{
			LogError("Weapon \"%s\" (at line %i) already exists.", data[0], num);
			continue;
		}

		hParent.SetString(data[0], data[1]);

		FormatEx(buffer, sizeof(buffer), "models/weapons/v_%s.mdl", data[0]);
		PrecacheModel(buffer);
		AddFileToDownloadsTable(buffer);
		buffer[15] = 'w';
		PrecacheModel(buffer);
		AddFileToDownloadsTable(buffer);

		static const char postfix[][] = {"_silencer", "_dropped", "_thrown"};
		int type = -1;
		if(!strcmp(data[0], "usp") || !strcmp(data[0], "m4a1"))
			type = 0;
		else if(!strcmp(data[0], "elite"))
			type = 1;
		else if(!strcmp(data[0], "hegrenade"))
			type = 2;

		if(type != -1)
		{
			FormatEx(buffer, sizeof(buffer), "models/weapons/w_%s%s.mdl", data[0], postfix[type]);
			if(FileExists(buffer, true))
			{
				PrecacheModel(buffer);
				AddFileToDownloadsTable(buffer);
			}
		}

		FormatEx(buffer, sizeof(data[]) + 4, "sm_%s", data[0]);
		if(!CommandExists(buffer))
		{
			hCmds.PushString(buffer);
			AddCommandListener(Cmd_GetWeapon, buffer);
		}
		else LogError("Command \"%s\" already exists.", buffer);

		if(!TrimString(data[2]) || (i_buffer = StringToInt(data[2])) < 0 || i_buffer > 2) i_buffer = 0;
		hPlay.SetValue(data[0], i_buffer);

		if(i_buffer)
		{
			if((i_buffer = TrimString(data[3]) - 4) > 0
			&& (!strcmp(data[3][i_buffer], ".wav", false) || !strcmp(data[3][i_buffer], ".mp3", false)))
			{
				hSound.SetString(data[0], data[3]);
				PrecacheSound(data[3]);
				FormatEx(buffer, sizeof(buffer), "sound/%s", data[3]);
				AddFileToDownloadsTable(buffer);
			}
			else
			{
				hPlay.SetValue(data[0], 0);
				LogError("Invalid sound for weapon \"%s\": \"%s\".", data[0], data[3]);
			}
		}

		if(TrimString(data[4]) && (i_buffer = StringToInt(data[4])) > 0)
			hAmmo.SetValue(data[0], i_buffer);

		if(TrimString(data[5]) && (f_buffer = StringToFloat(data[5])) > 0.0)
			hDmgMult.SetValue(data[0], f_buffer);

		if(TrimString(data[6]) && (f_buffer = StringToFloat(data[6])) > 0.0 && f_buffer <= 1.0)
			hAccuracy.SetValue(data[0], f_buffer);

		if((i_buffer = strlen(data[7]) - 1) > 0)
		{
			data[7][i_buffer] = 0;
			if(TrimString(data[7]) && (i_buffer = StringToInt(data[7])) > 0)
				hPrice.SetValue(data[0], i_buffer);
		}

		if(!hMenu) hMenu = new Menu(Handler_Menu);
		FormatEx(buffer, sizeof(buffer), "%s • $%i", data[0], i_buffer);
		data[0][0] = CharToUpper(data[0][0]);
		hMenu.AddItem(data[0], buffer);
	}
	file.Close();

	PrintToServer("Added new weapons: %i (with sound: %i)\nAdded commands: %i", hParent.Size, hSound.Size, hCmds.Length);
	if(!hParent.Size)
		return;

	hMenu.SetTitle("New weapons (%i pcs):", hMenu.ItemCount);
	hMenu.ExitButton = true;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	fStart = GetGameTime();
}

public Action Cmd_GetWeapon(int client, const char[] command, int argc)
{
	if(client) GiveWeapon(client, command[3]);

	return Plugin_Handled;
}

public Action Cmd_Menu(int client, int args)
{
	if(!client)
		return Plugin_Handled;

	if(!bEnable || !hMenu)
		PrintToChat(client, "No weapons available.");
	else if(GetClientTeam(client) < 2 || !IsPlayerAlive(client))
		PrintToChat(client, "Only alive players can buy weapons.");
	else if(fStart + iTime < GetGameTime())
		PrintToChat(client, "You can no longer get weapons in this round!.");
	else hMenu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public int Handler_Menu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char buffer[32];
		hMenu.GetItem(param, buffer, sizeof(buffer));
		GiveWeapon(client, buffer, true);
	}
	return 0;
}

void GiveWeapon(int client, const char[] weapon, const bool menu = false)
{
	if(!bEnable)
	{
		PrintToChat(client, "No weapons available.");
		return;
	}

	if(GetClientTeam(client) < 2 || !IsPlayerAlive(client))
	{
		PrintToChat(client, "Only alive players can buy weapons.");
		return;
	}

	if(fStart + iTime < GetGameTime())
	{
		PrintToChat(client, "You can no longer get weapons in this round!.");
		return;
	}

	char parent[32];
	if(!hParent.GetString(weapon, parent, sizeof(parent)))
	{
		PrintToChat(client, "Weapon \"%s\" is not available.", weapon);
		if(menu) hMenu.Display(client, MENU_TIME_FOREVER);
		return;
	}

	int price, money = GetEntProp(client, Prop_Send, "m_iAccount");
	if(hPrice.GetValue(weapon, money) && (money -= price) >= 0)
	{
		PrintToChat(client, "Not enough money to buy.");
		if(menu) hMenu.Display(client, MENU_TIME_FOREVER);
		return;
	}

	static const char prefix[] = "weapon_%s";
	char buffer[40];

	hParent.GetString(weapon, parent, sizeof(parent));
	FormatEx(buffer, sizeof(buffer), prefix, parent);
	int ent = CreateEntityByName(buffer);
	if(ent == -1)
	{
		LogError("Can't create entity \"%s\"", buffer);
		PrintToChat(client, "Can't create weapon \"%s\".", weapon);
		if(menu) hMenu.Display(client, MENU_TIME_FOREVER);
		return;
	}

	FormatEx(buffer, sizeof(buffer), prefix, weapon);
	DispatchKeyValue(ent, "classname", buffer);

	bool have_ammo, knife = !strcmp(parent, "knife");
	int ammo;
	if(hAmmo.GetValue(weapon, ammo) && (have_ammo = ammo && !knife && strcmp(parent, "hegrenade")))
	{
		FormatEx(buffer, sizeof(buffer), "%i", ammo);
		DispatchKeyValue(ent,"ammo", buffer);
	}

	if(!DispatchSpawn(ent))
	{
		LogError("Can't spawn entity \"%s\" (%s)", weapon, buffer);
		PrintToChat(client, "Can't spawn weapon \"%s\".", weapon);
		if(menu) hMenu.Display(client, MENU_TIME_FOREVER);
		return;
	}

	ActivateEntity(ent);

	int i_buffer;
	if(knife && (i_buffer = GetPlayerWeaponSlot(client, 2)) != -1)
	{
		SDKHooks_DropWeapon(client, i_buffer);
		AcceptEntityInput(i_buffer, "Kill");
	}

	EquipPlayerWeapon(client, ent);
	if(price) SetEntProp(client, Prop_Send, "m_iAccount", money);

	if(have_ammo && (i_buffer = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType")) > -1
	&& GetEntProp(client, Prop_Data, "m_iAmmo", 4, i_buffer) < 1)
		SetEntProp(client, Prop_Data, "m_iAmmo", ammo, 4, i_buffer);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_PostThink, OnPostThink);
}

//Modify the new weapon damage value function
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(attacker != inflictor || inflictor > MaxClients)
		return Plugin_Continue;

	if(!IsValidEntity(attacker))
		return Plugin_Continue;

	if(HasEntProp(attacker, Prop_Send, "m_hActiveWeapon") == false)
		return Plugin_Continue;

	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEdict(weapon) || (weapon == -1))
		return Plugin_Continue;

	static char sWeapon[40];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	int start = FindCharInString(sWeapon, '_') + 1;
	Format(sWeapon, sizeof(sWeapon), sWeapon[start]);

	char parent[32];
	if(!hParent.GetString(sWeapon, parent, sizeof(parent))
	//This function has no effect on grenades
	|| !strcmp(parent, "hegrenade"))
		return Plugin_Continue;

	float mult;
	if(!hDmgMult.GetValue(sWeapon, mult))
		return Plugin_Continue;

	//New weapon damage multiplier, the initial damage value of the new weapon is equal to the damage value of the parent weapon. 1.0 means unchanged, 2.0 means change the damage value of the new weapon to twice the initial damage value
	damage *= mult;
	return Plugin_Changed;
}

//Modified new weapon accuracy difference function
public void OnPostThink(int client)
{
	if(!(GetClientButtons(client) & IN_ATTACK))
			return;

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(!IsValidEdict(weapon) || (weapon == -1))
		return;

	static char sWeapon[40];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	int start = FindCharInString(sWeapon, '_') + 1;
	Format(sWeapon, sizeof(sWeapon), sWeapon[start]);

	char parent[32];
	if(!hParent.GetString(sWeapon, parent, sizeof(parent))
	|| !strcmp(parent, "hegrenade") || !strcmp(parent, "knife"))
		return;

	float mult;
	if(hAccuracy.GetValue(sWeapon, mult)) SetEntPropFloat(weapon, Prop_Send, "m_fAccuracyPenalty", mult);
}

public void Event_WeaponOldSound(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client) return;

	FadeClientVolume(client, 100.0, 0.0, 0.04, 0.0);
	CreateTimer(0.04, Timer_PlayNewSound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PlayNewSound(Handle timer, int client)
{
	if(!(client = GetClientOfUserId(client)))
		return Plugin_Stop;

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(weapon == -1)
		return Plugin_Stop;

	char sWeapon[40];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	int start = FindCharInString(sWeapon, '_') + 1;
	Format(sWeapon, sizeof(sWeapon), sWeapon[start]);

	int play;
	hPlay.GetValue(sWeapon, play);
	char buffer[32];
	if(play)
	{
		hSound.GetString(sWeapon, buffer, sizeof(buffer));
		if(play == 1)
			ClientCommand(client, "play %s", buffer);
		else EmitSoundToClient(client, buffer, weapon, 1);
		return Plugin_Stop;
	}

	if(hParent.GetString(sWeapon, buffer, sizeof(buffer)) && !strcmp(buffer, "hegrenade"))
	{
		DataPack dp = new DataPack();
		dp.WriteCell(GetClientUserId(client));
		dp.WriteString(sWeapon);
		CreateTimer(0.01, Hegrenade_Throw, dp, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
	}

	return Plugin_Stop;
}

//Change the function of the grenade throwing model to fix the problem that the old version of the gun add-on cannot load the grenade throwing model (bug)
public Action Hegrenade_Throw(Handle timer, DataPack dp)
{
	dp.Reset();
	int client = dp.ReadCell();
	if(!(client = GetClientOfUserId(client)))
	{
		CloseHandle(dp);
		return Plugin_Stop;
	}

	char weapon[32];
	dp.ReadString(weapon, sizeof(weapon));
	CloseHandle(dp);

	int ent = -1, lastent;
	while((ent = FindEntityByClassname(ent, "hegrenade_projectile")) != -1)
	{
		if(IsValidEntity(ent) && GetEntPropEnt(ent, Prop_Send, "m_hThrower") == client)
			break;

		if((ent = FindEntityByClassname(ent, "hegrenade_projectile")) == lastent)
		{
			ent = -1;
			break;
		}

		lastent = ent;
	}

	if(ent != -1)
	{
		char path[64];
		FormatEx(path, sizeof(path), "models/weapons/w_%s_thrown.mdl", weapon);
		//If the new grenade comes with a throw model, loads the new grenade's throw model
		if(FileExists(path, true)) SetEntityModel(ent, path);
	}

	return Plugin_Stop;
}