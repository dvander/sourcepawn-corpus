/********************************************************************************************
* Plugin	: L4D2 Original Survivors Unlocker
* Version	: 1.0
* Game		: Left 4 Dead 2
* Author	: KPu3uC B Poccuu, some functions were take from L4DSwitchPlayers by SkyDavid (djromero)
* Website	:
* 
* Purpose	: This plugin allows admins to spawn Original Survivors in the game and makes them to join the Survivor team.
* 
* Version 1.0:
* 		- Initial release.
* Version 1.1:
* 		- Rewritten the whole code, from base functions by SkyDavid left almost nothing.
* Version 1.2:
* 		- Added public cvars modifies behavior of the plugin.
*********************************************************************************************/

#define PLUGIN_VERSION "1.2"
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <halflife>
#undef REQUIRE_PLUGIN
new EndCheckpointDoor,bool:IsCompetiveMode,bool:AlreadySpawned,bool:IsFirstMap,Handle:l4d2_original_survivors_spawner,Handle:l4d2_original_survivors_autospawn;

public Plugin:myinfo = 
{
	name = "[L4D2] Original Survivors Enabler",
	author = "ZzZombo",
	description = "Allows to play with original survivors from Left 4 Dead together with new ones",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	LoadTranslations("l4d2_L4D1survivors_spawner.phrases");
	HookEvent("player_team", Event_PlayerTeam);//serves only debug purposes
	//HookEvent("round_freeze_end",Event_RoundFreezeEnd);
	HookEvent("player_entered_start_area",Event_PlayerEnteredStartArea);
	HookEvent("player_first_spawn",Event_PlayerFirstSpawn);
	HookEvent("player_entered_checkpoint",Event_PlayerEnteredCheckpoint);//kicks unnecessary bots to prevent glitches
	HookEvent("finale_vehicle_leaving",Event_FinaleEnd);//same
	//HookEvent("round_end",Event_FinaleEnd);//should say "same" but it doesn't work :(
	//HookEvent("round_start",Event_RoundStart);
	l4d2_original_survivors_spawner=CreateConVar("l4d2_original_survivors_spawner","1","Enables the plugin. 0 - disable, 1 - auto detect competetive gamemode and self-disable in them, 2 - work on any modes (not recommended).",FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d2_original_survivors_autospawn=CreateConVar("l4d2_original_survivors_autospawn","1","Allows autospawn on map start, if plugins is enabled.",FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("l4d2_original_survivors_spawn",L4D1Survivors_spawn,ADMFLAG_SLAY,"Spawns Original Survivors.");
	RegAdminCmd("l4d2_original_survivors_forceteam",L4D1Survivors_forceteam,ADMFLAG_SLAY,"Forces an Original Survivor to join Survivors team.");
	RegAdminCmd("l4d2_original_survivors_remove",L4D1Survivors_remove,ADMFLAG_SLAY,"Removes Original Survivors if possible. Kick commands also can be used for that.");
	AutoExecConfig(true,"l4d2_Original_Survivors_Enabler");
	CreateConVar("l4d2_original_survivors_spawner_version",PLUGIN_VERSION,"Version of Original Survivors Spawner plugin",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
}

public OnMapStart()
{
	new ent=-1;
	AlreadySpawned=false;
	while((ent=FindEntityByClassname(ent,"prop_door_rotating_checkpoint"))!=-1)
	{
		if(IsValidEntity(ent)&&IsValidEdict(ent))
		{
			// The end saferoom door is the unlocked one
			if(GetEntProp(ent,Prop_Send,"m_bLocked")==0)EndCheckpointDoor=ent;
		}
	}
	IsFirstMap=FindEntityByClassname(-1,"info_survivor_position")>=0;
	CheckGameMode();
	//PrintToServer("[SM] End checkpoint door entity is %d.",EndCheckpointDoor);
}

public OnMapEnd()
{
	AlreadySpawned=false;
}

CheckGameMode()
{
	new GameModeEntity=CreateEntityByName("info_gamemode");
	DispatchSpawn(GameModeEntity);
	HookSingleEntityOutput(GameModeEntity,"OnCoop",Output_CheckGamemode,true);
	HookSingleEntityOutput(GameModeEntity,"OnSurvival",Output_CheckGamemode,true);
	HookSingleEntityOutput(GameModeEntity,"OnVersus",Output_CheckGamemode,true);
	HookSingleEntityOutput(GameModeEntity,"OnScavenge",Output_CheckGamemode,true);
	AcceptEntityInput(GameModeEntity,"PostSpawnActivate");
	AcceptEntityInput(GameModeEntity,"Kill");
}

public Output_CheckGamemode(const String:output[],caller,activator,Float:delay)
{
	decl String:gamemode[200];
	GetConVarString(FindConVar("mp_gamemode"),gamemode,200);
	//PrintToServer("[SM] Game mode output is %s.",output);
	IsCompetiveMode=StrEqual(output,"OnVersus")||StrEqual(output,"OnScavenge")||StrEqual(gamemode,"mutation15");
}

public Action:L4D1Survivors_spawn(client,args)
{
	if(AlreadySpawned)
	{
		ReplyToCommand(client,"Already spawned! You can use l4d2_original_survivors_remove command to clear the spawn state bit.");
		return Plugin_Handled;
	}
	ServerCommand("sb_add biker;sb_add manager;sb_add teengirl");//no Namvet (Bill) due to server crashes he made :(((
	AlreadySpawned=true;
	PrintToChatAll("\x05%t","L4D1SurvivorsSpawned");
	return Plugin_Handled;
}

public Action:L4D1Survivors_remove(client,args)
{
	RemoveOriginalSurvivors(true);
	return Plugin_Handled;
}

public Action:L4D1Survivors_forceteam(client,args)
{
	if(args>0)
	{
		new String:arg[128];
		GetCmdArg(1,arg,sizeof(arg));
		if(strlen(arg))ForceTeam(StringToInt(arg));
	}
	else ForceTeam();
	return Plugin_Handled;
}

public Action:Event_FinaleEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	RemoveOriginalSurvivors();//to prevent outro stats messing
}

public Action:Event_PlayerEnteredStartArea(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(IsPluginEnabled()&&Autospawn())
	{
		PrintToServer("[SM] Creating autospawn timers.");
		CreateTimer(25.0,Timer_Autospawn,0,TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(26.0,Timer_ForceTeam,0,TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:Event_PlayerFirstSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(Autospawn()&&IsPluginEnabled()&&!IsFirstMap)
	{
		PrintToServer("[SM] Creating autospawn timers.");
		CreateTimer(5.0,Timer_Autospawn,0,TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(6.0,Timer_ForceTeam,0,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Event_PlayerEnteredCheckpoint(Handle:event,const String:name[],bool:dontBroadcast)
{
	decl String:Name[200],String:auth[200];
	new client=GetClientOfUserId(GetEventInt(event,"userid")),door=GetEventInt(event,"door");
	if(!client||!IsPluginEnabled())return Plugin_Continue;
	if(!GetClientName(client,Name,200))Name="undefined";
	//PrintToServer("[SM] End checkpoint door entity is %d. Player %d (%s) entered %d door.",EndCheckpointDoor,client,Name,door);
	if(!GetClientAuthString(client,auth,200))auth="undefined";
	if(GetClientTeam(client)==2&&StrEqual(auth,"BOT")&&(StrEqual(Name,"Francis")||StrEqual(Name,"Zoey")||StrEqual(Name,"Louis"))&&door==EndCheckpointDoor)CreateTimer(3.0,Timer_KickL4D1Survivor,client,TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Timer_Autospawn(Handle:timer,Handle:client)
{
	L4D1Survivors_spawn(0,0);
	return Plugin_Stop;
}

public Action:Timer_ForceTeam(Handle:timer,Handle:client)
{
	ForceTeam(client);
	return Plugin_Stop;
}

public Action:Timer_KickL4D1Survivor(Handle:timer,Handle:client)
{
	KickClient(client,"This Bot can mess with the team on next map.");
	return Plugin_Stop;
}

public Action:Event_PlayerTeam(Handle:event,const String:name[],bool:dontBroadcast)//just for debugging
{
	new OldTeam=GetEventInt(event,"oldteam"),Team=GetEventInt(event,"team"),client=GetClientOfUserId(GetEventInt(event,"userid"));
	decl String:Name[200],String:TeamName[200],String:OldTeamName[200];
	if(!client)return Plugin_Handled;
	if(!GetClientName(client,Name,200))Name="undefined";
	if(!GetTeamName(Team,TeamName,200))TeamName="undefined";
	if(!GetTeamName(OldTeam,OldTeamName,200))OldTeamName="undefined";
	PrintToServer("[SM] Player %s joined the %s team (%d) from the %s team (%d).",Name,TeamName,Team,OldTeamName,OldTeam);
	return Plugin_Handled;
}

bool:Autospawn()
{
	return GetConVarBool(l4d2_original_survivors_autospawn)&&!AlreadySpawned;
}

bool:IsPluginEnabled()
{
	decl String:MapName[200];
	if(!GetCurrentMap(MapName,200))MapName="undefined";
	return GetConVarInt(l4d2_original_survivors_spawner)==1&&(!IsCompetiveMode||GetConVarInt(l4d2_original_survivors_spawner)==2)&&!(StrEqual(MapName,"c6m1_riverbank")||StrEqual(MapName,"c6m3_port"));
}

RemoveOriginalSurvivors(const bool:Forceful=false)
{
	if(!IsPluginEnabled()||Forceful)return;
	decl String:Name[200],String:auth[200],String:MapName[200];
	if(!GetCurrentMap(MapName,200))MapName="undefined";
	if(StrEqual(MapName,"c6m1_riverbank")||StrEqual(MapName,"c6m3_port"))return;
	new clients=MaxClients;
	for(new i=1;i<=clients;i++)
	{
		if(IsClientConnected(i))
		{
			if(!GetClientAuthString(i,auth,200))auth="undefined";
			if(!GetClientName(i,Name,200))Name="undefined";
			if(GetClientTeam(i)==2&&StrEqual(auth,"BOT")&&(StrEqual(Name,"Francis")||StrEqual(Name,"Zoey")||StrEqual(Name,"Louis")))
			{
				KickClient(i,"Request to remove Original Survivors.");
			}
		}
	}
	AlreadySpawned=false;
}

ForceTeam(const client=0)
{
	decl String:Name[200],String:auth[200];
	if(!IsPluginEnabled())return;
	//PrintToServer("[SM] (forceteam) Client #%d.",client);
	if(client)
	{
		if(IsClientConnected(client)&&GetClientTeam(client)==4)
		{
			PerformSwitch(client);
			return;
		}
	}else for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientConnected(i))
		{
			if(!GetClientAuthString(i,auth,200))auth="undefined";
			if(!GetClientName(i,Name,200))Name="undefined";
			if(GetClientTeam(i)==4&&StrEqual(auth,"BOT")&&(StrEqual(Name,"Francis")||StrEqual(Name,"Zoey")||StrEqual(Name,"Louis")))PerformSwitch(i);
		}
	}
}

PerformSwitch(target)
{
	//PrintToServer("[SM] trying to switch an Original Survivor.");
	if((!IsClientConnected(target))||(!IsClientInGame(target)))
	{
		PrintToServer("[SM] The player is not available anymore.");
		return;
	}
	// If teams are the same...
	if(GetClientTeam(target)==2)
	{
		PrintToServer("[SM] The player is already on that team.");
		return;
	}
	ChangeClientTeam(target,2);
	decl String:Name[200];new Item;
	if(!GetClientName(target,Name,200))Name="undefined";
	if(StrEqual(Name,"Francis"))
	{
		//Item=GivePlayerItem(target,"weapon_first_aid_kit");//spammy and they get full health at spawn
		//if(Item)EquipPlayerWeapon(target,Item);
		if(!IsFirstMap)//first maps no needed in weapon supply
		{
			Item=GivePlayerItem(target,"weapon_pumpshotgun");
			if(Item)EquipPlayerWeapon(target,Item);
		}
	}else if(StrEqual(Name,"Zoey")||StrEqual(Name,"Louis"))
	{
		//Item=GivePlayerItem(target,"weapon_first_aid_kit");//same as above
		//if(Item)EquipPlayerWeapon(target,Item);
		if(!IsFirstMap)//first maps no needed in weapon supply
		{
			Item=GivePlayerItem(target,"weapon_smg");
			if(Item)EquipPlayerWeapon(target,Item);
		}
	}
}
/* !!! «амечани€:
* ѕри перемещении в команду больше одного (?) лишнего бота игра аварийно завершаетс€ через некоторое врем€ без сообщений об ошибке.
** Ёти вылеты вызывало добавление Ѕилла.
* ѕри добавлении новых (L4D2) персонажей при полностью укомплектованной команде они удал€ютс€ с сервера игрой.
** ¬озможно обойти созданием поддельного клиента в команде ¬ыживших, который затем перемещаетс€ к зрител€м и отключаетс€.
* Ћишние боты не перемещаютс€ на следующий уровень.
** ќни перемещаютс€ при survivor_limit>4, но ломают новых персонажей, занима€ их место, из-за чего они не по€вл€ютс€.
* “олько любые четыре персонажа полностью корректно воспринимаютс€ игрой.
 */