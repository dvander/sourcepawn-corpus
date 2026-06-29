#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define COLLISION_GROUP_PLAYER              5  
#define COLLISION_GROUP_PUSHAWAY            17
#define VERSION "1.4"


public Plugin:myinfo =
{
	name = "Spawn NoBlock for CSGO",
	author = "dzej dzej",
	description = "Simple spawn noblock",
	version = VERSION,
	url = "http://gocs.pl/"
};

//Value Holders
new bool:nbEnabled								= false;
new Float:nbTime									= 0.0;


//{ ConVars Handles & Value Holders
new Handle:g_Timer_One		 = INVALID_HANDLE;
new Handle:g_Timer_Two		 = INVALID_HANDLE;
new Handle:snbTime			= INVALID_HANDLE;
new Handle:snbEnabled			= INVALID_HANDLE;
new Handle:snbfreeze			= INVALID_HANDLE;
new Handle:snbFire			= INVALID_HANDLE;


public OnPluginStart() {

	LoadTranslations("snb.phrases");
	CreateConVar("sm_snb_v", VERSION, "[CSGO] Spawn NoBlock version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	snbTime = CreateConVar("sm_snb_time", "10.0", "Spawn NoBlock time.", FCVAR_PLUGIN,true,1.0);
	snbEnabled = CreateConVar("sm_snb", "1.0", "plugin enable", FCVAR_PLUGIN,true,0.0,true,1.0);
	snbFire = CreateConVar("sm_snb_ff", "1.0", "Frendlyfire disable on spawn? If server cvar ff is 0 set it to 0", FCVAR_PLUGIN,true,0.0,true,1.0);
	snbfreeze = FindConVar("mp_freezetime");
	
	RefreshSettings();

	AutoExecConfig( true, "sm_spawn_noblock" );
	HookConVarChange(snbEnabled, MyCvarChange);
	HookConVarChange(snbTime, MyCvarChange);
	HookEvent( "round_start", Event_RoundStart );

}

// Settings Section
public MyCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strcmp(oldValue, newValue)==0) return; //No change
	RefreshSettings(convar);
}

RefreshSettings(Handle:convar=INVALID_HANDLE) {
	decl bool:boolval;

	if(convar == INVALID_HANDLE || convar == snbTime) {
		nbTime = GetConVarFloat(snbTime);
		if(nbTime<0.0) nbTime = 0.0;
		
		ServerCommand("mp_solid_teammates 0");
		
		
		if(convar != INVALID_HANDLE) return;
	}
	if(convar == INVALID_HANDLE || convar == snbEnabled) {
		boolval = GetConVarBool(snbEnabled);
		if(boolval != nbEnabled) {
			if(boolval)	{ //Enable
				nbEnabled = true;
				TryEnablePlugin();
			} else		{ //Disable
				DisablePlugin();
				nbEnabled = false;
			}
		}
		if(convar != INVALID_HANDLE) return;
	}
}

public OnMapStart() {
	RefreshSettings();
	TryEnablePlugin();
	
}

TryEnablePlugin() {
	nbEnabled 		= true;
	PrintToChatAll("\x01\x0B\x04%t", "Enabled");
}

DisablePlugin() { 
	nbEnabled = false;
	PrintToChatAll("\x01\x0B\x04%t", "Disabled");
}

//Plugn noblock part

EBlock(client)
{
 SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY); 
} 

UBlock(client)
{
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER); 
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast )
{
	PrintToChatAll("\x01\x0B\x04%t", "Enabled");

	if(GetConVarBool(snbFire) == true) 
	{
		ServerCommand("mp_friendlyfire 0");
	} 
	ServerCommand("mp_solid_teammates 0");
	
	new Float: time1;
	time1 = GetConVarInt(snbTime) + GetConVarInt(snbfreeze)- 1.0;
	g_Timer_One          = CreateTimer(time1, snbPush);
	
}

public Action:snbPush(Handle:timer)
{
		for (new i = 1; i <= MaxClients; i++)
		{	
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				EBlock(i);
			}
		}
		
		g_Timer_Two = CreateTimer(1.0, snbSolid);
		KillTimer(g_Timer_One);
}

public Action:snbSolid(Handle:timer)
{
	ServerCommand("mp_solid_teammates 1");
	
	for (new i = 1; i <= MaxClients; i++)
		{	
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				UBlock(i);
			}
		}
	
	if(GetConVarBool(snbFire) == true) {
		ServerCommand("mp_friendlyfire 1");
		}

	PrintToChatAll("\x01\x0B\x04%t", "Disabled");
	KillTimer(g_Timer_Two);
}