#include <sourcemod>
#include <sdktools>
#include <shavit>

public Plugin:myinfo = 
{
	name = "[shavit] Die On Finish",
	author = "Ofir",
	description = "When player finish he get slayed.",
	version = "1.0",
	url = ""
};

public void Shavit_OnFinish(int client, int style, float time, int jumps)
{
	ForcePlayerSuicide(client);
}