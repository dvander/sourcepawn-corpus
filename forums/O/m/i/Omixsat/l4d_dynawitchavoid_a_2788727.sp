#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.3.1a"
#define DEBUG 0

enum struct WitchInfo
{
	int entref;
	bool IsRage;
	bool oneshot;
}

char witcheventnames[][] = {
	"witch_harasser_set",
	"witch_killed"
};

ConVar hWitchDangerDistance;
ArrayList ListOWitches;
float fWitchDangerDistance;
Handle h_CheckWitchRageTimer=INVALID_HANDLE;
int WitchList;

public Plugin myinfo =
{
	name = "[L4D] Dynamic Witch Avoidance - Type A",
	author = "Omixsat, Bacardi",
	description = "Survivor bots will avoid any enraged witch within a specified range",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=339488"
}

public void OnPluginStart()
{
	for(int x = 0; x < sizeof(witcheventnames); x++)
		HookEventEx(witcheventnames[x], witchevents);

	ListOWitches = new ArrayList(3);

	CreateConVar("l4d_dynawitchavoid_version", PLUGIN_VERSION, "[L4D] Dynamic Witch Avoidance Version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_SPONLY);
	hWitchDangerDistance = CreateConVar("l4d_dynawitchavoidancerange", "300.0", "The range the survivor bots must keep a distance from any enraged witch", FCVAR_NOTIFY|FCVAR_REPLICATED);

	// if plugin is loaded manually, look all spawned witch entities on map
	
	int ent = -1;
	WitchInfo witch; // sugar coated array

	while((ent = FindEntityByClassname(ent, "witch")) != -1)
	{
		witch.entref = EntIndexToEntRef(ent);
		ListOWitches.PushArray(witch);
	}

	AutoExecConfig(true, "l4d_dynamicwitchavoidance");
}

public void OnMapEnd()
{
	delete h_CheckWitchRageTimer;
	ListOWitches.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{	
	if(entity < 1) return;
	int entref = EntIndexToEntRef(entity); 

	if(IsValidWitch(entity))
	{
		WitchInfo witch;
		witch.entref = entref;
		ListOWitches.PushArray(witch);
	}
	
	if (h_CheckWitchRageTimer == INVALID_HANDLE)
	{
		#if DEBUG
			PrintToChatAll("TYPE-A: Enraged witch avoidance algorithm has started");
		#endif
		h_CheckWitchRageTimer = CreateTimer(0.1, BotControlTimer, _, TIMER_REPEAT);
	}
}

public void OnEntityDestroyed(int entity)
{
	if(entity < 0)
	{
		return;
	}
	else
	{
		static char classname[8];
		WitchList = ListOWitches.Length;
		GetEntityClassname(entity,classname,sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			for(int w = 0; w < WitchList; w++)
			{
				if(EntIndexToEntRef(entity) == ListOWitches.Get(w,0))
				{
					#if DEBUG
						PrintToChatAll("A witch has despawned");
						PrintToChatAll("Deleting UID ref %i. It is the same as Witch Ref %i.", EntIndexToEntRef(entity), ListOWitches.Get(w,0));
					#endif
					ListOWitches.Erase(w);
					break;
				}
			}
		}
	}
}

void witchevents(Event event, const char[] name, bool dontBroadcast)
{
	int entref = EntIndexToEntRef(event.GetInt("witchid", 0));
	WitchList = ListOWitches.Length;
	// Try find entref value from block 0, "entref"
	int index = ListOWitches.FindValue(entref, 0);

	if(StrEqual(name, "witch_harasser_set"))
	{
		if(index != -1)
		{
			ListOWitches.Set(index, true, 1);
			
			#if DEBUG
				PrintToChatAll("Witch ID %i Rage status: %i",index,ListOWitches.Get(index,1));
				PrintToChatAll("Witch ID via ArrayList is %i", EntRefToEntIndex(index));
			#endif
		}
	}
	else if(StrEqual(name, "witch_killed"))
	{
		if(index != -1)
		{
			ListOWitches.Set(index, event.GetBool("oneshot"), 2);
		}
		for(int w = 0; w < WitchList; w++)
		{
			if(entref == ListOWitches.Get(w,0))
			{
				#if DEBUG
					PrintToChatAll("A witch must've died");
					PrintToChatAll("Deleting UID ref %i. It is the same as Witch Ref %i.", entref, ListOWitches.Get(w,0));
				#endif
				ListOWitches.Erase(w);
				break;
			}
		}
	}
}


Action BotControlTimer(Handle timer)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && !IsIncapacitated(i))
		{	
			WitchList = ListOWitches.Length;
			for(int w = 0; w < WitchList; w++)
			{
				int WitchIndex = EntRefToEntIndex(ListOWitches.Get(w,0));
				if (IsValidWitch(WitchIndex) && ListOWitches.Get(w,1) == 1 && ListOWitches.Get(w,2) != 1)
				{
					fWitchDangerDistance = hWitchDangerDistance.FloatValue;
					float WitchPosition[3];
					GetEntPropVector(WitchIndex, Prop_Send, "m_vecOrigin", WitchPosition);
					float BotPosition[3];
					GetClientAbsOrigin(i, BotPosition);
					if (GetVectorDistance(BotPosition, WitchPosition) < fWitchDangerDistance)
					{
						L4D2_RunScript("CommandABot({cmd=2,bot=GetPlayerFromUserID(%i),target=EntIndexToHScript(%i)})", GetClientUserId(i), WitchIndex);
						#if DEBUG
							PrintToChatAll("GAME: L4D2 - Survivor Bot ID %i is moving away from Witch ID %i",i,WitchIndex);
							PrintToChatAll("Witch ID %i has rage status %i meaning oneshot is %i", WitchIndex, ListOWitches.Get(w,1), ListOWitches.Get(w,2));
						#endif
					}
				}
			}
		}
	}	  
	return Plugin_Continue;
}

//Credits to Timocop for the stock :D
/**
* Runs a single line of vscript code.
* NOTE: Dont use the "script" console command, it starts a new instance and leaks memory. Use this instead!
*
* @param sCode		The code to run.
* @noreturn
*/

stock void L4D2_RunScript(const char[] sCode, any ...)
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			SetFailState("Could not create 'logic_script'");
		
		DispatchSpawn(iScriptLogic);
	}
	
	static char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

stock bool IsValidWitch(int spwnEntity)
{
	if(IsValidEdict(spwnEntity) && IsValidEntity(spwnEntity))
	{
		static char classname[8];
		GetEntityClassname(spwnEntity,classname,sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			return true;
		}
	}
	
	return false;
}

stock bool IsIncapacitated(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
		return true;
	return false;
}