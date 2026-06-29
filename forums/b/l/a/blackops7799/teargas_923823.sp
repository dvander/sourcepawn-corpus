#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.0.1"

#define FFADE_IN        0x0001
#define FFADE_OUT       0x0002
#define FFADE_MODULATE  0x0004
#define FFADE_STAYOUT   0x0008
#define FFADE_PURGE     0x0010

#define CS_TEAM_T 2
#define CS_TEAM_CT 3

#define TEAMFLAG_T  (1 << 0)						// 1
#define TEAMFLAG_CT (1 << 1)						// 2
#define TEAMFLAG_BOTH (TEAMFLAG_T | TEAMFLAG_CT)	// 3

float g_NextCoughTime[MAXPLAYERS + 1];

new Handle:g_radius;
new Handle:g_damage;
new Handle:g_enabled;
new Handle:g_coughing;
new Handle:g_damageDelay;
new Handle:g_damageTeam;

StringMap g_TearGasInstances;

public Plugin:myinfo = {
	name = "Tear Gas",
	author = "BlackOps7799",
	description = "Smoke grenades deal periodic damage to players in radius",
	version = VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("sm_teargas_version", VERSION, "Current version", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_enabled = CreateConVar("sm_teargas_enabled", "1", "Enable/Disable smoke grenade teargas damage", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_radius = CreateConVar("sm_teargas_radius", "200", "How close a player needs to be to take damage", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0);
	g_coughing = CreateConVar("sm_teargas_coughing", "1", "Enable/Disable player coughing sounds", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_damage = CreateConVar("sm_teargas_damage", "5", "How much damage the player should take every damage tick", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0);
	g_damageDelay = CreateConVar("sm_teargas_damage_delay", "0.5", "How often a player should take damage", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0);
	g_damageTeam = CreateConVar("sm_teargas_damage_team", "3", "Which teams take damage: 1=T, 2=CT, 3=Both", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);

	g_TearGasInstances = new StringMap();

	for (int i = 1; i <= 4; i++)
	{
		char path[64];
		Format(path, sizeof(path), "ambient/voices/cough%d.wav", i);
		PrecacheSound(path, true);
	}

	HookEvent("smokegrenade_detonate", OnSmokeDetonate);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// Reset next cough times randomly between now + 0 to 2 seconds
	float now = GetGameTime();
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			g_NextCoughTime[i] = now + GetRandomFloat(0.0, 4.0);
	}

	StringMapSnapshot snap = g_TearGasInstances.Snapshot();
	int count = snap.Length;

	for (int i = 0; i < count; i++)
	{
		char key[64];
		snap.GetKey(i, key, sizeof(key));

		ArrayList record;
		if (g_TearGasInstances.GetValue(key, record))
		{
			KillTimer(view_as<Handle>(record.Get(0)));
			KillTimer(view_as<Handle>(record.Get(1)));
			delete record;
		}
	}

	delete snap;
	g_TearGasInstances.Clear();
}

int FindSmokeProjectileByPosition(const float pos[3])
{
	float pos2[3];
	int ent = MaxClients + 1;

	while ((ent = FindEntityByClassname(ent, "smokegrenade_projectile")) != -1)
	{
		if (!IsValidEntity(ent))
			continue;

		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos2);

		if (pos[0] == pos2[0] && pos[1] == pos2[1] && pos[2] == pos2[2])
		{
			return ent;
		}
	}

	return -1;
}

public Action OnSmokeDetonate(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(g_enabled))
		return Plugin_Continue;

	float pos[3];
	pos[0] = GetEventFloat(event, "x");
	pos[1] = GetEventFloat(event, "y");
	pos[2] = GetEventFloat(event, "z");

	// Find grenade entity index for the position of this detonation
	int grenade = FindSmokeProjectileByPosition(pos);

	if (!IsValidEntity(grenade)) {
		return Plugin_Continue;
	}

	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(attacker))
		attacker = 0;

	int grenadeRef = EntIndexToEntRef(grenade);

	// Data for our damage timer
	DataPack pack = new DataPack();
	pack.WriteCell(grenadeRef); // inflictor (attributes smokegrenade_projectile as the damage source)
	pack.WriteCell(attacker);	// attacker (person who threw the smokegrenade_projectile)
	pack.WriteFloat(pos[0]);
	pack.WriteFloat(pos[1]);
	pack.WriteFloat(pos[2]);

	float delay = GetConVarFloat(g_damageDelay);
	Handle damageTimer = CreateTimer(delay, TearGas_DamageThink, pack, TIMER_REPEAT);
	Handle cleanupTimer = CreateTimer(18.0, TearGas_StopDamage, grenadeRef);

	char key[16];
	IntToString(grenadeRef, key, sizeof(key));

	// Store both timers
	ArrayList timers = new ArrayList();
	timers.Push(damageTimer);
	timers.Push(cleanupTimer);
	g_TearGasInstances.SetValue(key, timers);

	return Plugin_Continue;
}

void ShakeClient(int client, float amplitude = 5.0, float frequency = 2.0, float duration = 2.0)
{
	if (!IsClientInGame(client))
		return;

	Handle shake = StartMessageOne("Shake", client);
	if (shake != INVALID_HANDLE)
	{
		BfWriteByte(shake, 0); // shake command (0 = start shaking)
		BfWriteFloat(shake, amplitude);  // shake intensity
		BfWriteFloat(shake, frequency);  // shake speed
		BfWriteFloat(shake, duration);   // shake duration
		EndMessage();
	}
}


void FadeClientInAndOut(int client, int red, int green, int blue, int alpha, int fadeIn = 250, int holdTime = 250, int fadeOut = 500, bool blend = false)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	int flags = FFADE_OUT | FFADE_PURGE;
	if (blend)
		flags |= FFADE_MODULATE;

	// Fade in
	Handle fade = StartMessageOne("Fade", client);
	if (fade != INVALID_HANDLE)
	{
		BfWriteShort(fade, fadeIn);
		BfWriteShort(fade, holdTime);
		BfWriteShort(fade, flags);
		BfWriteByte(fade, red);
		BfWriteByte(fade, green);
		BfWriteByte(fade, blue);
		BfWriteByte(fade, alpha);
		EndMessage();
	}

	// Schedule fade-out
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(red);
	pack.WriteCell(green);
	pack.WriteCell(blue);
	pack.WriteCell(alpha);
	pack.WriteCell(blend ? 1 : 0);
	pack.WriteCell(fadeOut);
	CreateTimer(float(fadeIn + holdTime) / 1000.0, FadeOutClient, pack);
}

public Action FadeOutClient(Handle timer, any data)
{
	DataPack pack = view_as<DataPack>(data);
	pack.Reset();

	int client = pack.ReadCell();
	int red = pack.ReadCell();
	int green = pack.ReadCell();
	int blue = pack.ReadCell();
	int alpha = pack.ReadCell();
	bool blend = (pack.ReadCell() != 0);
	int fadeOut = pack.ReadCell();
	delete pack;

	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	int flags = FFADE_IN | FFADE_PURGE;
	if (blend)
		flags |= FFADE_MODULATE;

	Handle fade = StartMessageOne("Fade", client);
	if (fade != INVALID_HANDLE)
	{
		BfWriteShort(fade, fadeOut);
		BfWriteShort(fade, 0);
		BfWriteShort(fade, flags);
		BfWriteByte(fade, red);
		BfWriteByte(fade, green);
		BfWriteByte(fade, blue);
		BfWriteByte(fade, alpha);
		EndMessage();
	}

	return Plugin_Stop;
}

public Action TearGas_DamageThink(Handle timer, any data)
{
	DataPack pack = view_as<DataPack>(data);
	pack.Reset();

	int inflictor = pack.ReadCell();
	if (!IsValidEntity(inflictor))
		inflictor = 0;

	int attacker = pack.ReadCell();
	if (!IsValidEntity(attacker))
		attacker = 0;

	float origin[3];
	origin[0] = pack.ReadFloat();
	origin[1] = pack.ReadFloat();
	origin[2] = pack.ReadFloat();

	float radius = GetConVarFloat(g_radius);
	float damage = GetConVarFloat(g_damage);
	float delay = GetConVarFloat(g_damageDelay);

	int players[MAXPLAYERS + 1];
	int count = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			players[count++] = i;
		}
	}

	// Shuffle list of players (Randomize who will die first if multiple people are ticking down)
	for (int i = count - 1; i > 0; i--)
	{
		int j = GetRandomInt(0, i);
		int temp = players[i];
		players[i] = players[j];
		players[j] = temp;
	}

	// Apply damage
	for (int i = 0; i < count; i++)
	{
		int client = players[i];

		int teamFlags = GetConVarInt(g_damageTeam);
		int clientTeam = GetClientTeam(client);
		bool isT  = (clientTeam == CS_TEAM_T);
		bool isCT = (clientTeam == CS_TEAM_CT);

		if ((isT  && !(teamFlags & TEAMFLAG_T)) ||
			(isCT && !(teamFlags & TEAMFLAG_CT)))
		{
			// skip this client, not an affected team
			continue;
		}

		float target[3];
		GetClientAbsOrigin(client, target);

		if (GetVectorDistance(origin, target) <= radius)
		{
			// Apply damage to players (DMG_FALL ignores body armor)
			SDKHooks_TakeDamage(client, inflictor, attacker, damage, DMG_FALL);

			// Make player cough
			if (GetConVarBool(g_coughing))
				EmitCoughSound(client);

			// Figure out screen fade times based on damage delay
			int delayMs  = RoundFloat(delay * 1000.0);
			int fadeInHold = delayMs / 4;
			int fadeOut = delayMs / 2;

			// Flash damaged players screen green
			FadeClientInAndOut(client, 64, 200, 64, 48, fadeInHold, fadeInHold, fadeOut);
		}
	}

	return Plugin_Continue;
}

public Action TearGas_StopDamage(Handle timer, any grenadeRef)
{
	char key[16];
	IntToString(grenadeRef, key, sizeof(key));

	ArrayList record;
	if (g_TearGasInstances.GetValue(key, record))
	{
		Handle dmgTimer = view_as<Handle>(record.Get(0));
		Handle cleanup  = view_as<Handle>(record.Get(1));

		KillTimer(dmgTimer);
		KillTimer(cleanup);
		delete record;

		g_TearGasInstances.Remove(key);
	}

	return Plugin_Stop;
}

void EmitCoughSound(int client)
{
	float now = GetGameTime();

	// Only cough if randomized interval has passed
	if (now < g_NextCoughTime[client])
		return;

	// 50% chance to cough even if cooldown passed
	if (GetRandomInt(0, 1) == 0)
		return;

	int coughIndex = GetRandomInt(1, 4);

	char sound[64];
	Format(sound, sizeof(sound), "ambient/voices/cough%d.wav", coughIndex);

	// Emit sound to all players from the client's position
	EmitSoundToAll(sound, client, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);

	// Shake screen during cough
	ShakeClient(client);

	// Schedule next cough randomly between 2.5 and 4 seconds
	g_NextCoughTime[client] = now + GetRandomFloat(2.5, 4.0);
}