#include <sourcemod>
#include <sdktools>
//                            the ak47.wav is for testing
static const char SOUND[] = "weapons/ak47/ak47-1.wav";

public void OnPluginStart()
{
	AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);
}

public void OnMapStart()
{
	PrecacheSound(SOUND);
}

public Action CSS_Hook_ShotgunShot(const char[] te_name, const int[] Players, int numClients, float delay)
{
	int player = TE_ReadNum("m_iPlayer") + 1;

	int weapon = GetEntPropEnt(player, Prop_Data, "m_hActiveWeapon")

	char classname[64];
	GetEdictClassname(weapon, classname, sizeof classname);

	if (!StrEqual(classname, "weapon_ak47"))
		return Plugin_Continue;

	EmitSoundToAll(SOUND, player);

	return Plugin_Stop;
}