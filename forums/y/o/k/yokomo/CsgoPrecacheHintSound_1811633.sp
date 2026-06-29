#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Precache Hint Sound",
	author = "wbyokomo",
	description = "Precache Hint Sound",
	version = "0.0.1",
	url = "http://wbyokomo.tk"
}

public OnMapStart()
{
	PrecacheSound("ui/hint.wav", true)
}
