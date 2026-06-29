#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Mommy-Medic Sound",
	author = "FeuerSturm",
	description = "Players yell for their mommy instead of a medic!",
	version = "1.0",
	url = "http://community.dodsourceplugins.net"
}

new String:MedicSound[] = { "mommy/mommy.wav" }

public OnPluginStart()
{
	RegAdminCmd("voice_medic", cmdVoiceMedic, 0)
	AddFileToDownloadsTable("sound/mommy/mommy.wav")
	PrecacheSound(MedicSound)
}

public Action:cmdVoiceMedic(client, args)
{
	new Float:Origin[3]
	GetClientAbsOrigin(client, Origin)
	EmitAmbientSound(MedicSound, Origin)
	return Plugin_Handled
}