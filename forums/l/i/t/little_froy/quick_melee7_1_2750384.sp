#define PATH	"quick_melee7.1"

#define CMD		"give"

#pragma tabsize 0
#include <sourcemod>
#include <sdktools>

bool Gived[MAXPLAYERS+1] = {false, ...};
bool Backup[MAXPLAYERS+1] = {false, ...};
char Pistolname[MAXPLAYERS+1][256];

int Pistol_clip[MAXPLAYERS+1] = {8, ...};

bool Random = false;
int M_Index = 1;

ConVar C_qm_random = null;
ConVar C_qm_order = null;

enum {
	I_CROWBAR = 0,
	I_FIREAXE,
	I_KATANA,
	I_CHAINSAW,
	I_CRICKET_BAT,
	I_BASEBALL_BAT,
	I_FRYING_PAN,
	I_ELECTRIC_GUITAR,
	I_TONFA,
	I_MACHETE,
	I_SHOVEL,
	I_PITCHFORK,
	I_KNIFE,
	THE_LAST
}

char Melee_range[THE_LAST][256] = {
	"crowbar", "fireaxe", "katana", "chainsaw", "cricket_bat", "baseball_bat", "frying_pan", "electric_guitar", "tonfa", "machete", "shovel", "pitchfork", "knife"
};

public void Do_SpawnItem(client, char[] name) {
	new flags = GetCommandFlags(CMD);
	SetCommandFlags(CMD, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", CMD, name);
	SetCommandFlags(CMD, flags);
}

public bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}
public bool IsPlayerFallen(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}
public bool IsPlayerAlright(int client)
{
	return !(IsPlayerFalling(client) || IsPlayerFallen(client));
}

public bool IsValidSurvivor(int client)
{
	if(client >= 1 && client <= MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client) == 2)
			{
				return true;
			}
		}
	}
	return false;
}

public void return_pistol(int client)
{
	if(Gived[client] == true)
	{
		int slot2 = GetPlayerWeaponSlot(client, 1);
		if(slot2 != -1)
		{
			char Meleename[256];
			GetEdictClassname(slot2, Meleename[client], 256);
			int melee = StrContains(Meleename[client], "melee");
			int chainsaw = StrContains(Meleename[client], "chainsaw");
			int pistol = StrContains(Meleename[client], "pistol");
			if((melee != -1 || chainsaw != -1) && pistol == -1)
			{
				RemovePlayerItem(client, slot2);
				if(StrContains(Pistolname[client], "pistol") != -1)
				{
					if(StrContains(Pistolname[client], "pistol_magnum") != -1)
					{
						Do_SpawnItem(client, Pistolname[client]);
					}
					else
					{
						Do_SpawnItem(client, Pistolname[client]);
						Do_SpawnItem(client, Pistolname[client]);
					}
					int slot2_pistol = GetPlayerWeaponSlot(client, 1);
					if(slot2_pistol != -1)
					{
						char name[256];
						GetEdictClassname(slot2_pistol, name, 256);
						if(StrContains(name, "pistol") != -1)
						{
							SetEntProp(slot2_pistol, Prop_Send, "m_iClip1", Pistol_clip[client]);
						}
					}
				}
			}
		}
		Gived[client] = false;
	}
}

public void return_pistol_incap(int client)
{
	int slot2 = GetPlayerWeaponSlot(client, 1);
	if(slot2 != -1)
	{
		RemovePlayerItem(client, slot2);
		if(StrContains(Pistolname[client], "pistol") != -1)
		{
			if(StrContains(Pistolname[client], "pistol_magnum") != -1)
			{
				Do_SpawnItem(client, Pistolname[client]);
			}
			else
			{
				Do_SpawnItem(client, Pistolname[client]);
				Do_SpawnItem(client, Pistolname[client]);
			}
			int slot2_pistol = GetPlayerWeaponSlot(client, 1);
			if(slot2_pistol != -1)
			{
				char name[256];
				GetEdictClassname(slot2_pistol, name, 256);
				if(StrContains(name, "pistol") != -1)
				{
					SetEntProp(slot2_pistol, Prop_Send, "m_iClip1", Pistol_clip[client]);
				}
			}
		}
	}
}

public void quick_melee(int client)
{
	if(Gived[client] == false)
	{
		int slot2 = GetPlayerWeaponSlot(client, 1);
		if(slot2 != -1)
		{
			GetEdictClassname(slot2, Pistolname[client], 256);
			int melee = StrContains(Pistolname[client], "melee");
			int chainsaw = StrContains(Pistolname[client], "chainsaw");
			int pistol = StrContains(Pistolname[client], "pistol");
			if(melee != -1 || chainsaw != -1)
			{
				return;
			}
			if((melee == -1 && chainsaw == -1) && pistol != -1)
			{
				RemovePlayerItem(client, slot2);
				if(Random == true)
				{
					int index = GetRandomInt(0, THE_LAST - 1);
					Do_SpawnItem(client, Melee_range[index]);
				}
				else
				{
					Do_SpawnItem(client, Melee_range[M_Index]);
				}	
			}
		}
		Gived[client] = true;
	}
}

public void drop_melee(int client)
{
	if(Gived[client] == false)
	{
		int slot2 = GetPlayerWeaponSlot(client, 1);
		if(slot2 != -1)
		{
			char Meleename[256];
			GetEdictClassname(slot2, Meleename[client], 256);
			int melee = StrContains(Meleename[client], "melee");
			int chainsaw = StrContains(Meleename[client], "chainsaw");
			int pistol = StrContains(Meleename[client], "pistol");
			if((melee != -1 || chainsaw != -1) && pistol == -1)
			{
				RemovePlayerItem(client, slot2);
				Do_SpawnItem(client, "pistol");
				Do_SpawnItem(client, "pistol");
				int slot2_pistol = GetPlayerWeaponSlot(client, 1);
				if(slot2_pistol != -1)
				{
					char name[256];
					GetEdictClassname(slot2_pistol, name, 256);
					if(StrContains(name, "pistol") != -1)
					{
						SetEntProp(slot2_pistol, Prop_Send, "m_iClip1", 0);
					}
				}
			}
		}
	}
}

public void OnGameFrame()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsValidSurvivor(client))
        {
			if(!IsFakeClient(client) && IsPlayerAlive(client))
			{
				int slot2 = GetPlayerWeaponSlot(client, 1);
				if(slot2 != -1)
				{
					char name[256];
					GetEdictClassname(slot2, name, 256);
					if(StrContains(name[client], "pistol") != -1)
					{
						Pistol_clip[client] = GetEntProp(slot2, Prop_Data, "m_iClip1");
					}
				}
				if(IsPlayerAlright(client))
				{
					if(Backup[client] == true)
					{
						return_pistol_incap(client);
						Backup[client] = false;
					}
				}
			}
        }
    }
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
	if(IsValidSurvivor(client))
	{
		if(!IsFakeClient(client) && IsPlayerAlive(client) && IsPlayerAlright(client))
		{
			if(Backup[client] == false)
			{
				if(buttons & IN_SPEED)
				{
					drop_melee(client);
				}
				if(buttons & IN_ZOOM)
				{
					quick_melee(client);
				}
				else
				{
					return_pistol(client);
				}
			}
		}
	}
	return Plugin_Continue;
}

public void ReSetPlayer(int client)
{
	Gived[client] = false;
	Backup[client] = false;
	Pistol_clip[client] = 8;
	strcopy(Pistolname[client], 256, "weapon_pistol");
}

public void ResetAll()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		ReSetPlayer(client);
	}
}

public void Evnet_round(Event event, const char[] name, bool dontBroadcast)
{
	ResetAll();
}

public void Event_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	if(IsValidSurvivor(client))
    {
		ReSetPlayer(client);
    }
	int client2 = GetClientOfUserId(GetEventInt(event, "bot"));
	if(IsValidSurvivor(client2))
    {
		ReSetPlayer(client2);
    }
}

public Event_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidSurvivor(client))
    {
		ReSetPlayer(client);
    }
}

public void Event_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(IsValidSurvivor(client))
    {
		if(!IsFakeClient(client) && IsPlayerAlive(client) && !IsPlayerAlright(client))
		{
			if(Gived[client] == true)
			{
				Gived[client] = false;
				Backup[client] = true;
				return_pistol_incap(client);
			}
		}
		else
		{
			ReSetPlayer(client);
		}
    }
}

public void Internal_changed()
{
	Random = GetConVarBool(C_qm_random);
	M_Index = GetConVarInt(C_qm_order);
}

public void ConvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Internal_changed();
}

public void OnConfigsExecuted()
{
	Internal_changed();
}

public void OnPluginStart()
{
	HookEvent("player_bot_replace", Event_replace);
    HookEvent("bot_player_replace", Event_replace);
	HookEvent("player_death", Event_death);
	HookEvent("player_incapacitated", Event_incapacitated);
    HookEvent("round_start", Evnet_round);
	C_qm_random = CreateConVar("qm_random", "0", "enable random melee everytime take out ?", FCVAR_SPONLY);
	C_qm_order = CreateConVar("qm_order", "1", "order the melee index", FCVAR_SPONLY, true, 0.0, true, THE_LAST - 1.0);
	C_qm_random.AddChangeHook(ConvarChanged);
	C_qm_order.AddChangeHook(ConvarChanged);
	AutoExecConfig(true, PATH);
}