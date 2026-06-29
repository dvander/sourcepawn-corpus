/*
 * BLOOD
 *
 * emmits blood if a player is hurt
 * by Silent_Water
 * silentspam2000@yahoo.de
 *
 *
 * CHANGELOG
 * v1.1:
 *       - added particledefault to be written if it does not exist
 *       - added particledefault to download list
 *       - increased default value of sm_blood_level to 1000
 * v1.0:
 *       - first stable release
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

new Handle:cv_amount;
new Handle:cv_flags;
new String:g_particle_file[] = "materials/particle/particledefault.vmt";
new String:g_particle[] = "UnlitGeneric\r\n{\r\n\"$translucent\" 1\r\n\"$basetexture\" \"Decals/blood_gunshot_decal\"\r\n\"$vertexcolor\" 1\r\n}\r\n";
new Handle:g_file_handle = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_blood", PLUGIN_VERSION, "Version of sm_blood", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cv_amount = CreateConVar("sm_blood_level","1000","Amount of blood that is beeing spread",FCVAR_PLUGIN);
	cv_flags = CreateConVar("sm_blood_flags","15","A number that is a sum of the following values: 1 = Random direction, 2: Blood stream, 4: On Player, 8: Spray decals",FCVAR_PLUGIN);
	if (!FileExists(g_particle_file, true)) {
		g_file_handle = OpenFile(g_particle_file,"a");
		if (g_file_handle != INVALID_HANDLE) {
			WriteFileString(g_file_handle,g_particle,false);
			CloseHandle(g_file_handle);
		}
	}
	HookEvent("player_hurt", Event_PlayerHurt);
}
public OnMapStart()
{
	AddFileToDownloadsTable(g_particle_file);
}
public OnEventShutdown()
{
   UnhookEvent("player_hurt", Event_PlayerHurt);
}
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:flags[3];
	decl String:amount[6];
	GetConVarString(cv_flags, flags, sizeof(flags));
	GetConVarString(cv_amount, amount, sizeof(amount));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new ent = CreateEntityByName("env_blood");

	if ((ent == -1) || (!IsValidEdict(ent)))
	{
		return Plugin_Continue;
	}
	DispatchSpawn(ent);
	DispatchKeyValue(ent, "spawnflags", flags);
	DispatchKeyValue(ent, "amount", amount);
	DispatchKeyValue(ent, "color", "0");
	AcceptEntityInput(ent, "EmitBlood", client);
	CreateTimer(2.0, WipeBlood, ent);
	return Plugin_Continue;
}
public Action:WipeBlood(Handle:timer, any:ent){
	if ((ent == -1) || (!IsValidEdict(ent)))
	{
		return Plugin_Continue;
	}
	RemoveEdict(ent);
	return Plugin_Handled;
}
