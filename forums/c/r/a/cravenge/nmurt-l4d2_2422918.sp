#pragma semicolon 1
#include <sourcemod>
#include <left4downtown>

#define TRT_SEQUENCE_ONEHAND 49
#define TRT_SEQUENCE_UNDERHAND 50
#define TRT_SEQUENCE_TWOHAND 51

public Plugin:myinfo =
{
	name = "[L4D2] No More UnderHand Rock Throws",
	author = "cravenge",
	description = "Removes Tank's Underhand Rock Throw Sequence and Replaces With Either Onehand Or Twohand Rock Throw Sequences.",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	CreateConVar("nmurt-l4d2_version", "1.0", "No More Underhand Rock Throws Version", FCVAR_NOTIFY|FCVAR_REPLICATED);
}

public Action:L4D2_OnSelectTankAttack(client, &sequence)
{
	if (sequence == TRT_SEQUENCE_UNDERHAND)
	{
		sequence = GetRandomInt(0, 1) ? TRT_SEQUENCE_ONEHAND : TRT_SEQUENCE_TWOHAND;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

