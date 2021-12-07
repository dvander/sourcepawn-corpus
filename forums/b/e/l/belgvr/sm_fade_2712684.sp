#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define IN  0x0001
#define OUT 0x0002

new Handle:Cvar_FtbDelay = INVALID_HANDLE
new Handle:Cvar_RedAmmount = INVALID_HANDLE
new Handle:Cvar_GreenAmmount = INVALID_HANDLE
new Handle:Cvar_BlueAmmount = INVALID_HANDLE
new Handle:Cvar_AlphaAmmount = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "Fade",
	author = "Ribas",
	description = "Fades Screen to a color on death",
	version = PLUGIN_VERSION,
	url = "http://oppressiveteCvar_RedAmmountitory.ddns.net"
}

public OnPluginStart()
{
	CreateConVar("sm_fade_version", PLUGIN_VERSION, "Version of this plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_FtbDelay = CreateConVar("sm_fade_delay", "2000", "Duration of the screen fade effect (miliseconds)" )
	Cvar_RedAmmount = CreateConVar("sm_fade_red", "0", "Ammount of RED color of the fade effect",FCVAR_NONE,true,0.0,true,255.0 )
	Cvar_GreenAmmount = CreateConVar("sm_fade_green", "0", "Ammount of GREEN color of the fade effect",FCVAR_NONE,true,0.0,true,255.0 )
	Cvar_BlueAmmount = CreateConVar("sm_fade_blue", "0", "Ammount of BLUE color of the fade effect",FCVAR_NONE,true,0.0,true,255.0 )
	Cvar_AlphaAmmount = CreateConVar("sm_fade_alpha", "125", "Ammount of ALPHA of the fade effect",FCVAR_NONE,true,0.0,true,255.0 )
	AutoExecConfig(true,"sm_fade")
	HookEvent("player_death", PlayerDeathEvent)
}

public OnEventShutdown()
{
	UnhookEvent("player_death", PlayerDeathEvent)
}


public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))

	ScreenFade(client, GetConVarInt(Cvar_RedAmmount), GetConVarInt(Cvar_GreenAmmount), GetConVarInt(Cvar_BlueAmmount), GetConVarInt(Cvar_AlphaAmmount), GetConVarInt(Cvar_FtbDelay), OUT)
}


//Fade the screen
public ScreenFade(client, red, green, blue, alpha, delay, type)
{
	new Handle:msg
	new duration
	duration=delay*10000000
	
	msg = StartMessageOne("Fade", client)
	BfWriteShort(msg, delay)
	BfWriteShort(msg, duration)
	BfWriteShort(msg, type)
	BfWriteByte(msg, red)
	BfWriteByte(msg, green)
	BfWriteByte(msg, blue)	
	BfWriteByte(msg, alpha)
	EndMessage()
}