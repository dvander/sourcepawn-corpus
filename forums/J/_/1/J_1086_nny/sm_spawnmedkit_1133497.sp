#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[L4D] Advanced spawn medkit",
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_spawnmedkit", Command_SpawnMedKit, ADMFLAG_RCON, "sm_spawnmedkit");
}

public Action:Command_SpawnMedKit(client, args)
{
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];

	new medkit = CreateEntityByName("weapon_first_aid_kit");

	if (medkit == -1)
	{
		ReplyToCommand(client, "[SM] %t", "medkitFailed", LANG_SERVER);
	}

	DispatchKeyValue(medkit, "model", "medkit_1");
	DispatchKeyValueFloat (medkit, "MaxPitch", 360.00);
	DispatchKeyValueFloat (medkit, "MinPitch", -360.00);
	DispatchKeyValueFloat (medkit, "MaxYaw", 90.00);
	DispatchSpawn(medkit);

	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 32;
	VecOrigin[1] += VecDirection[1] * 32;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;

	PrintToChat(client, "\x03sm_advspawnitem weapon_first_aid_kit %f %f %f %f %f %f %f", VecDirection[0], VecDirection[1], VecDirection[2], VecOrigin[0], VecOrigin[1], VecOrigin[2], VecAngles[1]);

	DispatchKeyValueVector(medkit, "Angles", VecAngles);
	DispatchSpawn(medkit);
	TeleportEntity(medkit, VecOrigin, NULL_VECTOR, NULL_VECTOR);
}
