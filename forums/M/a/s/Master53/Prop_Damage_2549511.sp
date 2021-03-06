
//Includes:
#include <sdktools>

//Terminate:
#pragma semicolon		1
#pragma compress		0

//Definitions:
#define PLUGINVERSION		"1.01.02"

//Misc
static ColourOffset;
static MaxDamage;
static MinDamage;
static TeamOnly;

//ConVars:
enum XCVar
{
	Handle:CV_MAXDAMAGE,
	Handle:CV_MINDAMAGE
	Handle:CV_TEAMONLY
}

//Cvar Handle:
static Handle:CVAR[XCVar] = {INVALID_HANDLE,...};

//Plugin Info:
public Plugin:myinfo =
{
	name = "Prop Damage and effects",
	author = "Master(D)",
	description = "Allows props to take damage",
	version = PLUGINVERSION,
	url = ""
};

//Initation:
public OnPluginStart()
{

	//Print Server If Plugin Start:
	PrintToConsole(0, "|SM| Prop Damage Successfully Loaded (v%s)!", PLUGINVERSION);

	//ConVar Hooks:
	CVAR[CV_MAXDAMAGE] = CreateConVar("sm_prop_max_damage", "3", "Max prop damage");

	CVAR[CV_MINDAMAGE] = CreateConVar("sm_prop_min_damage", "5", "Min prop damage");

	CVAR[CV_TEAMONLY] = CreateConVar("sm_prop_team_damage", "3", "if set to 1 all teams can damage (1, 2, 3)");

	//Server Version:
	CreateConVar("sm_Prop_Damage_version", PLUGINVERSION, "show the version of the zombie mod", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//Create Auto Configurate File:
	AutoExecConfig(true, "Prop_Damage");

	//Hook Cvar:
	HookConVarChange(CVAR[CV_MAXDAMAGE], MaxChanged);

	HookConVarChange(CVAR[CV_MAXDAMAGE], MinChanged);

	HookConVarChange(CVAR[CV_TEAMONLY], TeamOnlyChanged);

	//Entity Hook:
	HookEntityOutput("prop_physics", "OnTakeDamage", PropTakeDamage);

	//Entity Hook:
	HookEntityOutput("func_breakable", "OnBreak", PropBreak);

	//Entity Hook:
	HookEntityOutput("prop_physics", "OnBreak", PropBreak);

	//Entity Hook:
	HookEntityOutput("func_physbox", "OnBreak", PropBreak);
}

//Map Start:
public OnMapStart()
{

	//Find Offsets:
	ColourOffset = FindSendPropOffs("CBaseEntity", "m_clrRender");

	//Set Values:
	MaxDamage = GetConVarInt(CVAR[CV_MAXDAMAGE]);

	MinDamage = GetConVarInt(CVAR[CV_MINDAMAGE]);

	TeamOnmly = GetConVarInt(CVAR[CV_TEAMONLY]);
}

//Max
public MaxChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{

	//Initulize:
	MaxDamage = StringToInt(newValue);
}

//Min
public MinChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{

	//Initulize:
	MinDamage = StringToInt(newValue);
}

//Min
public TeamOnlyChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{

	//Initulize:
	TeamOnly = StringToInt(newValue);
}

//Take Damage Event:
public PropTakeDamage(const String:Output[], Caller, Activator, Float:Delay)
{

	//Check:
	if(Activator > 0 && Activator <= GetMaxClients() && IsClientConnected(Activator) && IsClientInGame(Activator))
	{

		//Declare:
		new Team = GetClientTeam(Client);

		//Check::
		if(TeamOnly == Team))
		{

			//Damage:
			DamageProp(Caller);
		}
	}

	//Override:
	else if(TeamOnly == 1)
	{

		//Damage:
		DamageProp(Caller);
	}
}

//Take Damage Event:
public PropBreak(const String:Output[], Caller, Activator, Float:Delay)
{

	//Declare:
	decl Float:fPos[3],Float:dir[3];

	//Initulize:
	GetEntPropVector(Caller, Prop_Send, "m_vecOrigin", fPos);

	//Create Temp Ent:
	TE_SetupSparks(fPos, dir, 8, 3);

	//Sent Effect:
	TE_SendToAll();
}

public Action:DamageProp(Ent)
{

	//Declare:
	new Color[4];

	//Initulize:
	GetEntDataArray(Ent, ColourOffset, Color, 4, 1);

	//Declare:
	new Random;

	if(MaxDamage > MinDamage)
	{

		//Initulize:
		Random = GetRandomInt(MinDamage, MaxDamage);
	}

	//Override:
	else
	{

		//Initulize:
		Random = MaxDamage;
	}

	//Math:
	Color[1] = Color[1] - Random;
	Color[2] = Color[2] - Random;

	//Is
	if(Color[1] <= 20 && Color[2] <= 20)
	{

		//Declare:
		decl Float:fPos[3],Float:dir[3];

		//Initulize:
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", fPos);

		//Create Temp Ent:
		TE_SetupSparks(fPos, dir, 8, 3);

		//Sent Effect:
		TE_SendToAll();

		//Accept Entity Input:
		AcceptEntityInput(Ent, "Kill");
	}

	//Override:
	else
	{

		//Set Colour:
		SetEntDataArray(Ent, ColourOffset, Color, 4, 1);
	}
}