#include <sourcemod>
#include <sdktools>
static LaserCache;
static Killer[MAXPLAYERS-1];
static Float:KillTime[MAXPLAYERS-1];
static BeamColor[4] = {255, 0, 0 ,200}

new Handle:Cv_Beam;
new Handle:Cv_BeamWidth;
new Handle:Cv_BeamTime;
new Handle:Cv_BeamModel;
new Handle:Cv_BeamColorRed;
new Handle:Cv_BeamColorGreen;
new Handle:Cv_BeamColorBlue;
new Handle:Cv_BeamColorAlpha;

public Plugin:myinfo = 
{
	name = "Death Beam",
	author = "Benni aka benjamin1995",
	description = "the killed client will see a beam to the killer",
	version = "1.0.2",
	url = "http://www.bennisgameservers.com"
}

public OnPluginStart()
{
	
	Cv_Beam = CreateConVar("sm_follow_beam", "0", "The Beam will follow you");
	Cv_BeamWidth = CreateConVar("sm_beam_width", "3.0", "The Beam Width");
	Cv_BeamTime = CreateConVar("sm_beam_time", "7.5", "How long the Beam will be alive");
	Cv_BeamModel = CreateConVar("sm_beam_model", "materials/sprites/laser.vmt", "The Texture of the Beam");
	Cv_BeamColorRed = CreateConVar("sm_beam_color_red", "255", "Red Color");
	Cv_BeamColorGreen = CreateConVar("sm_beam_color_green", "20", "Green Color");
	Cv_BeamColorBlue = CreateConVar("sm_beam_color_blue", "20", "BlueColor");
	Cv_BeamColorAlpha = CreateConVar("sm_beam_color_alhpa", "200", "Alpha Color");
	AutoExecConfig(true, "killbeam");
	
	HookConVarChange(Cv_BeamModel, Cv_Callback)
	HookConVarChange(Cv_BeamColorRed, Cv_Callback)
	HookConVarChange(Cv_BeamColorGreen, Cv_Callback)
	HookConVarChange(Cv_BeamColorBlue, Cv_Callback)
	HookConVarChange(Cv_BeamColorAlpha, Cv_Callback)

	HookEvent("player_death", EventDeath, EventHookMode_Pre)
	


	
	//Server Variable:
	CreateConVar("benni_death_beam_version", "1.2", "Benni's Death Beam",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{
	new String:strBeamModel[128]
	GetConVarString(Cv_BeamModel, strBeamModel, 128);
	
	//Precache:
	LaserCache = PrecacheModel(strBeamModel);
}


public Cv_Callback(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BeamColor[0] = GetConVarInt(Cv_BeamColorRed)
	BeamColor[1] = GetConVarInt(Cv_BeamColorGreen)
	BeamColor[2] = GetConVarInt(Cv_BeamColorBlue)
	BeamColor[3] = GetConVarInt(Cv_BeamColorAlpha)

	new String:strBeamModel[128]
	GetConVarString(Cv_BeamModel, strBeamModel, 128);
	
	//Precache:
	LaserCache = PrecacheModel(strBeamModel);
}

public Action:BeamTimer(Handle:Timer, any:Client)
{
	new Float:Time;
	decl Float:ClientOrigin[3], Float:EntOrigin[3];
	EntOrigin[2] += 50
	
	//Initialize:
	GetClientAbsOrigin(Client, ClientOrigin);
	GetClientAbsOrigin(Killer[Client], EntOrigin);
	
	
	TE_SetupBeamPoints(ClientOrigin, EntOrigin, LaserCache, 0, 0, 66, 0.1, GetConVarFloat(Cv_BeamWidth), 3.0, 0, 0.0, BeamColor, 0);
	TE_SendToClient(Client);
	Time += 0.1;
	CreateTimer(0.1, BeamTimer, Client);
	
	if(KillTime[Client] <= (GetGameTime() - 7.5))
	{
		
		Killer[Client] = 0;	
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

//Death:
public Action:EventDeath(Handle:Event, const String:Name[], bool:Broadcast)
{
	
	//Declare:
	decl Client, Attacker;
	
	//Initialize:
	Client = GetClientOfUserId(GetEventInt(Event, "userid"));
	Attacker = GetClientOfUserId(GetEventInt(Event, "attacker"));
	
	if(IsClientInGame(Client) && IsClientConnected(Client) && IsClientConnected(Attacker) && IsClientInGame(Attacker))
	{
		decl String:weapon[32];
		GetEventString(Event, "weapon", weapon, sizeof(weapon));
		
		new Float:Dist, Float:ClientOrigin[3], Float:EntOrigin[3];
		//Initialize:
		GetClientAbsOrigin(Client, ClientOrigin);
		GetClientAbsOrigin(Attacker, EntOrigin);
		Dist = GetVectorDistance(ClientOrigin, EntOrigin);
		EntOrigin[2] += 50;
		Killer[Client] = Attacker;
		
		KillTime[Client] = GetGameTime();
		if(Dist >= 500)
		{
			if(GetConVarInt(Cv_Beam) == 1)
			{			
				CreateTimer(0.0, BeamTimer, Client);
			}
			else
			{
				TE_SetupBeamPoints(ClientOrigin, EntOrigin, LaserCache, 0, 0, 66, GetConVarFloat(Cv_BeamTime), GetConVarFloat(Cv_BeamWidth), 3.0, 0, 0.0, BeamColor, 0);
				TE_SendToClient(Client);
			}
		}
		else if(StrEqual(weapon, "grenade_frag") || StrEqual(weapon, "weapon_shotgun") || StrEqual(weapon, "crossbow_bolt") || StrEqual(weapon, "357") || StrEqual(weapon, "combine_ball") || StrEqual(weapon, "physics")) 
		{	
			
			if(GetConVarInt(Cv_Beam) == 1)
			{			
				CreateTimer(0.0, BeamTimer, Client);
			}
			else
			{
				TE_SetupBeamPoints(ClientOrigin, EntOrigin, LaserCache, 0, 0, 66, GetConVarFloat(Cv_BeamTime), GetConVarFloat(Cv_BeamWidth), 3.0, 0, 0.0, BeamColor, 0);
				TE_SendToClient(Client);
			}
			
		}
	}
}

