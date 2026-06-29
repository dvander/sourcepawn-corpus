#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.7"
#define PLUGIN_TAG "[NoNades]"
#define MAX_CVAR_LENGTH 128
#define MAX_WEAPON_LENGTH 64

#define NADES_FRAGS 3
#define NADES_SMOKES 12
#define NADES_RIFLES 48
#define NADES_ALL 63

new Handle:CvarEnabled
new Handle:CvarFilter
new String:WeaponNames[][] = {
	"weapon_frag_ger", "weapon_frag_us",
	"weapon_smoke_ger", "weapon_smoke_us",
	"weapon_riflegren_ger", "weapon_riflegren_us"	
}

new Filter

public Plugin:myinfo = 
{
	name = "DoD:S NoNades",
	author = "BackAgain, playboycyberclub",
	description = "Removes all the granades.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CvarEnabled = CreateConVar("sm_nonades_enabled", "1")
	CvarFilter = CreateConVar("sm_nonades_filter", "63")
	
	RegAdminCmd("sm_nonades_vote",AdminCmdVote,ADMFLAG_VOTE,"Starts a vote, whether granades are allowed or not.")
	
	HookConVarChange(CvarEnabled, OnEnabledChange)
	HookConVarChange(CvarFilter, OnFilterChange)

	if(GetConVarBool(CvarEnabled)) {
		Init()
	}
}

public Init()
{
	HookEvent("player_spawn", EventPlayerSpawn)
	Filter = GetConVarInt(CvarFilter)
}

public Dispose()
{
	UnhookEvent("player_spawn", EventPlayerSpawn)
}

public Action:AdminCmdVote(client, args)
{
	if(!IsVoteInProgress())
	{
		new Handle:voteMenu = CreateMenu(VoteMenuHandler)
		SetMenuExitButton(voteMenu, false)
		AddMenuItem(voteMenu, "all", "All")
		AddMenuItem(voteMenu, "frags_rifles", "Frags & Rifles only")
		AddMenuItem(voteMenu, "frags", "Frags only")
		AddMenuItem(voteMenu, "rifles", "Rifles only")
		AddMenuItem(voteMenu, "smokes", "Smokes only")
		AddMenuItem(voteMenu, "no_nades", "No nades")
		SetMenuTitle(voteMenu,"Allowed granades!")
		VoteMenuToAll(voteMenu,60)
	}	
}

public VoteMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_VoteStart) {
		PrintMessageToAll("Voting started!")
	}
	else if (action == MenuAction_VoteEnd) {
		PrintMessageToAll("Voting finished!")
		if(param1 == 0) {
			SetConVarBool(CvarEnabled,false,true,true)
			PrintMessageToAll("All granades are allowed!")
		} else if(param1 == 1) {
			SetConVarBool(CvarEnabled,true,true,true)
			SetConVarInt(CvarFilter,NADES_SMOKES,true)
			PrintMessageToAll("Frag and rifle granades are allowed!")
		} else if(param1 == 2) {
			SetConVarBool(CvarEnabled,true,true,true)
			SetConVarInt(CvarFilter,NADES_RIFLES+NADES_SMOKES,true)
			PrintMessageToAll("Frag granades are allowed!")
		} else if(param1 == 3) {
			SetConVarBool(CvarEnabled,true,true,true)
			SetConVarInt(CvarFilter,NADES_FRAGS+NADES_SMOKES,true)
			PrintMessageToAll("Rifle granades are allowed!")
		} else if(param1 == 4) {
			SetConVarBool(CvarEnabled,true,true,true)
			SetConVarInt(CvarFilter,NADES_FRAGS+NADES_RIFLES,true)
			PrintMessageToAll("Smoke granades are allowed!")
		} else if(param1 == 5) {
			SetConVarBool(CvarEnabled,true,true,true)
			SetConVarInt(CvarFilter,NADES_ALL,true)
			PrintMessageToAll("All granades are forbidden!")
		}
		
	}
	else if (action == MenuAction_Cancel) {
		PrintMessageToAll("Voting aborted!")
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu)
	}
}


public OnEnabledChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) == 1)
	{
		Init()
		PrintMessageToAll("Enabled!")
	}
	else
	{
		Dispose()
		PrintMessageToAll("Disabled!")
	}
}

public OnFilterChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	Filter = StringToInt(newVal)
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"))
	if(client > -1) {
		RemoveNades(client)
	}
}

public bool:IsFilteredNade(ent)
{
	if(ent > -1) 
	{
		new String:entName[MAX_WEAPON_LENGTH]
		GetEdictClassname(ent,entName,MAX_WEAPON_LENGTH)
		
		for(new i=0; i < sizeof(WeaponNames); i++) 
		{
			new pow = RoundToZero(Pow(float(2),float(i)))
			if(StrEqual(entName,WeaponNames[i],false) && (pow&Filter) == pow)
			{
				return true
			}
		}
	}
	return false
}

public RemoveNades(client) {

	new ent = -1
	
	for(new i=0; i < 4; i++)
	{
		ent = GetPlayerWeaponSlot(client,i)
		if(IsFilteredNade(ent))
		{
			RemovePlayerItem(client, ent)
			RemoveEdict(ent)
		}
	}
}

public PrintMessageToAll(const String:message[])
{
	PrintToChatAll("\x04%s \x01%s",PLUGIN_TAG,message)
}

