#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = {
	name = "ProDODS",
	author = "Saber, HellaMadMax, <eVa>Dog and drixevel",
	description = "Fade to Black, Pistols and damage modifier",
	version = "1.1",
	url = "https://discord.gg/tFavYq9"
}

#define MAX_WEAPONS 64

enum struct DamageModifier {
	char entity[64];
	float base_damage;
	float headshot_damage;

	void Add(const char[] entity, float base_damage, float headshot_damage = -1.0) {
		strcopy(this.entity, sizeof(DamageModifier::entity), entity);
		this.base_damage = base_damage;
		this.headshot_damage = headshot_damage;
	}
}

DamageModifier g_DamageModifier[MAX_WEAPONS + 1];
int g_Total;

ConVar g_Cvar_PistolAmmoGer
ConVar g_Cvar_PistolAmmoUS
ConVar g_Cvar_FtbDelay
public void OnPluginStart() {
	CreateConVar("sm_dod_pistols_version", "1.0.201", "DoD Pistols", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	CreateConVar("sm_dod_ftb_version", "1.0.201", "Version of sm_dod_ftb", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_PistolAmmoGer = CreateConVar("sm_dod_pistols_ammo_ger", "16", "The amount of ammo to give to Germans  <16 default>")
	g_Cvar_PistolAmmoUS = CreateConVar("sm_dod_pistols_ammo_us", "14", "The amount of ammo to give to Allies  <14 default>")
	g_Cvar_FtbDelay = CreateConVar("sv_dod_ftb_delay", "5", " The duration of the Fade to Black screen fade")
	HookEvent("player_spawn", PlayerSpawnEvent)
	HookEvent("player_death", PlayerDeathEvent)

	g_DamageModifier[g_Total++].Add("weapon_spring", 134.0, -1.0);
	g_DamageModifier[g_Total++].Add("weapon_k98", 134.0, -1.0);
	g_DamageModifier[g_Total++].Add("weapon_k98_scoped", 134.0, -1.0);
	g_DamageModifier[g_Total++].Add("weapon_colt", 45.0, -1.0);
	g_DamageModifier[g_Total++].Add("weapon_p38", 45.0, -1.0);
	g_DamageModifier[g_Total++].Add("weapon_mp44", 60.0, -1.0);
	g_DamageModifier[g_Total++].Add("weapon_bar", 60.0, -1.0);
	g_DamageModifier[g_Total++].Add("weapon_garand", 90.0, -1.0);
	g_DamageModifier[g_Total++].Add("weapon_mp40", 38.0, -1.0);
	g_DamageModifier[g_Total++].Add("weapon_thompson", 38.0, -1.0);

	RegAdminCmd("sm_reloaddamage", Command_ReloadDamage, ADMFLAG_GENERIC, "Reload damage modifiers from the config file.");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i)
		}
	}
}

public void OnMapStart() {
	ParseConfig();
}

void ParseConfig() {
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/damage-modifiers.cfg");

	if (!FileExists(sPath)) {
		return;
	}

	KeyValues kv = new KeyValues("damage-modifiers");

	if (kv.ImportFromFile(sPath) && kv.GotoFirstSubKey()) {
		g_Total = 0;
		char entity[64]; float base_damage; float headshot_damage;
		do {
			kv.GetSectionName(entity, sizeof(entity));
			base_damage = kv.GetFloat("base_damage", -1.0);
			headshot_damage = kv.GetFloat("headshot_damage", -1.0);
			g_DamageModifier[g_Total++].Add(entity, base_damage, headshot_damage);
		} while (kv.GotoNextKey());
	}

	delete kv;
}

public Action Command_ReloadDamage(int client, int args) {
	ParseConfig();
	return Plugin_Continue;
}

public OnEventShutdown() {
	UnhookEvent("player_spawn", PlayerSpawnEvent)
	UnhookEvent("player_death", PlayerDeathEvent)
}

public void PlayerSpawnEvent(Event event, const char[] event_name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"))
	CreateTimer(0.1, GiveClientPistol, client)
}

public Action GiveClientPistol(Handle timer, any client) {
	if (IsClientInGame(client)) {
		int team = GetClientTeam(client)
		int ammo_offset = FindSendPropInfo("CDODPlayer", "m_iAmmo")
		int class = GetEntProp(client, Prop_Send, "m_iPlayerClass")
		if ((class == 0) || (class == 2)) {
			if (team == 2) {
				GivePlayerItem(client, "weapon_colt")
				SetEntData(client, ammo_offset+4, GetConVarInt(g_Cvar_PistolAmmoUS), 4, true)
			}
			if (team == 3) {
				GivePlayerItem(client, "weapon_p38")
				SetEntData(client, ammo_offset+8, GetConVarInt(g_Cvar_PistolAmmoGer), 4, true)
			}
		} else {
			if (team == 2) {
				SetEntData(client, ammo_offset+4, GetConVarInt(g_Cvar_PistolAmmoUS), 4, true)
			}
			if (team == 3) {
				SetEntData(client, ammo_offset+8, GetConVarInt(g_Cvar_PistolAmmoGer), 4, true)
			}
		}
	}
	return Plugin_Handled
}

public void PlayerDeathEvent(Event event, const char[] event_name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"))
	ScreenFade(client, 0, 0, 0, 255, GetConVarInt(g_Cvar_FtbDelay), 0x0002)
}

public void ScreenFade(client, red, green, blue, alpha, delay, type) {
	Handle msg = StartMessageOne("Fade", client)
	if (msg != null) {
		BfWriteShort(msg, 500)
		BfWriteShort(msg, delay * 1000)
		BfWriteShort(msg, type)
		BfWriteByte(msg, red)
		BfWriteByte(msg, green)
		BfWriteByte(msg, blue)	
		BfWriteByte(msg, alpha)
		EndMessage()
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack)
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
	int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

	if (!IsValidEntity(weapon)) {
		return Plugin_Continue;
	}

	char class[32];
	GetEntityClassname(weapon, class, sizeof(class));

	int index = GetModIndex(class);
	Action result = Plugin_Continue;

	//Entity name was found with modifiers, apply them.
	if (index != -1) {
		//base damage
		if (g_DamageModifier[index].base_damage != -1.0) {
			damage = g_DamageModifier[index].base_damage;
			result = Plugin_Changed;
		}

		//headshots
		if (g_DamageModifier[index].headshot_damage != -1.0 && hitgroup == 1) {
			damage = g_DamageModifier[index].headshot_damage;
			result = Plugin_Changed;
		}
	}
	
	//arm / leg
	if (hitgroup == 4 || hitgroup == 7) {
		damage *= 1.33; //divide by 33%
		result = Plugin_Changed;
	}

	return result;
}

int GetModIndex(const char[] entity) {
	for (int i = 0; i < g_Total; i++) {
		if (StrEqual(entity, g_DamageModifier[i].entity, false)) {
			return i;
		}
	}
	return -1;
}