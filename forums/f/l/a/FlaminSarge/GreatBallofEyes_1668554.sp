/*
* [TF2] Monoculus Spawner
* Author(s): DarthNinja (based on Geit, modifications by FlaminSarge, retsam, naris)
* File: GreatBallofEyes.sp
* Description: Allows admins to spawn Monoculus at aim.
*
* Ability to specify model and precache the models & sounds.
* On admin menu
* Public voting and cvars
* Native to spawn at client's aim
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.1.1b"

#define ADMFLAG_EYEBOSS	ADMFLAG_CUSTOM3

#define INVIS			{ 255,255,255,0 }
#define NORMAL		{ 255,255,255,255 }

#define EYEBOSS_MODEL	"models/props_halloween/halloween_demoeye.mdl"

new Handle:Cvar_Eyeboss_AllowPublic = INVALID_HANDLE;
new Handle:Cvar_Eyeboss_Votesneeded = INVALID_HANDLE;
new Handle:Cvar_Eyeboss_VoteDelay = INVALID_HANDLE;

new Handle:hAdminMenu = INVALID_HANDLE;

new Float:g_pos[3];
new Float:g_fVotesNeeded;

new g_iVotes = 0;
new g_Voters = 0;
new g_VotesNeeded = 0;
new g_voteDelayTime;

new bool:g_bIsEnabled = true;
new bool:g_bVotesStarted = false;
new bool:g_bHasVoted[MAXPLAYERS + 1] = { false, ... };

new g_iLetsChangeThisEvent = 0;
new Handle:v_BaseHP_Level2 = INVALID_HANDLE;
new Handle:v_HP_Per_Player = INVALID_HANDLE;
new Handle:v_HP_Per_Level = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Monoculus Spawner",
	author = "DarthNinja",
	description = "Spawns a Monoculus where you're looking.",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

/**
 * Description: Manage precaching resources.
 */
#tryinclude "ResourceManager"
#if !defined _ResourceManager_included
// Trie to hold precache status of sounds
new Handle:g_soundTrie = INVALID_HANDLE;
new Handle:g_modelTrie = INVALID_HANDLE;

stock PrepareSound(const String:sound[], bool:preload=false)
{
	if (g_soundTrie == INVALID_HANDLE)
		g_soundTrie = CreateTrie();

	// If the sound hasn't been played yet, precache it first
	// :( IsSoundPrecached() doesn't work ):
	//if (!IsSoundPrecached(sound))
	new bool:value;
	if (!GetTrieValue(g_soundTrie, sound, value))
	{
		PrecacheSound(sound, preload);
		SetTrieValue(g_soundTrie, sound, true);
	}
}

stock PrepareModel(const String:model[], &index=0, bool:preload=false)
{
	if (g_modelTrie == INVALID_HANDLE)
		g_modelTrie = CreateTrie();

	if (index <= 0)
		GetTrieValue(g_modelTrie, model, index);

	if (index <= 0)
	{
		index = PrecacheModel(model, preload);
		SetTrieValue(g_modelTrie, model, index);
	}
	return index;
}
#endif

//SM CALLBACKS

public OnPluginStart()
{
	CreateConVar("sm_monospawn_version", PLUGIN_VERSION, "Monoculus Spawner Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_Eyeboss_AllowPublic = CreateConVar("sm_eyeboss_allowvoting", "0", "Allow public Monoculus voting?(1/0 = yes/no)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	Cvar_Eyeboss_Votesneeded = CreateConVar("sm_eyeboss_votesneeded", "0.50", "Percent of votes required for successful Monoculus vote. (0.50 = 50%)", FCVAR_PLUGIN, true, 0.10, true, 1.0);
	Cvar_Eyeboss_VoteDelay = CreateConVar("sm_eyeboss_votedelay", "120.0", "Delay time in seconds between calling votes.", FCVAR_PLUGIN);

	v_BaseHP_Level2 = FindConVar("tf_eyeball_boss_health_at_level_2");
	v_HP_Per_Player = FindConVar("tf_eyeball_boss_health_per_player");
	v_HP_Per_Level = FindConVar("tf_eyeball_boss_health_per_level");
	RegAdminCmd("sm_eyeboss", GreatBallRockets, ADMFLAG_EYEBOSS, "Spawns Monoculus");
//	RegAdminCmd("sm_eyeboss_map", SpawnMapMonoculus, ADMFLAG_EYEBOSS, "Spawns Monoculus via the debug command");
	RegAdminCmd("voteeyeboss", Command_VoteSpawnEyeboss, 0, "Trigger to vote to spawn Monoculus.");
	RegAdminCmd("voteeye", Command_VoteSpawnEyeboss, 0, "Trigger to vote to spawn Monoculus.");

	HookEvent("eyeball_boss_summoned", BossSummoned, EventHookMode_Pre);
	HookConVarChange(Cvar_Eyeboss_AllowPublic, Cvars_Changed);
	HookConVarChange(Cvar_Eyeboss_Votesneeded, Cvars_Changed);

	AutoExecConfig(true, "plugin.voteeyeboss");

	if (LibraryExists("adminmenu"))
	{
		new Handle:topmenu = GetAdminTopMenu();
		if (topmenu != INVALID_HANDLE)
			OnAdminMenuReady(topmenu);
	}
}
public Action:BossSummoned(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iLetsChangeThisEvent != 0)
	{
		new Handle:hEvent = CreateEvent(name);
		if (hEvent == INVALID_HANDLE)
			return Plugin_Handled;

		SetEventInt(hEvent, "level", g_iLetsChangeThisEvent);
		g_iLetsChangeThisEvent = 0;
		FireEvent(hEvent);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	if(IsFakeClient(client))
		return;

	g_bHasVoted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_fVotesNeeded);
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;

	if(g_bHasVoted[client])
	{
		g_iVotes--;
		g_bHasVoted[client] = false;
	}

	g_Voters--;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_fVotesNeeded);
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_Eyeboss_AllowPublic);
	g_fVotesNeeded = GetConVarFloat(Cvar_Eyeboss_Votesneeded);
}

public OnMapStart()
{
	g_bVotesStarted = false;
	g_iVotes = 0;
	g_Voters = 0;
	g_VotesNeeded = 0;

#if !defined _ResourceManager_included
	if (g_soundTrie == INVALID_HANDLE)
		g_soundTrie = CreateTrie();
	else
		ClearTrie(g_soundTrie);

	if (g_modelTrie == INVALID_HANDLE)
		g_modelTrie = CreateTrie();
	else
		ClearTrie(g_modelTrie);
#endif
	PrepareEyebossModel("");
	PrepareEyebossSounds(true);
}

stock PrepareEyebossModel(const String:model[]="")
{
	PrepareModel("models/props_halloween/eyeball_projectile.mdl");
	PrepareModel(EYEBOSS_MODEL);

	if (model[0] != '\0')
		PrepareModel(model);

	/*
	PrepareModel("models/props_halloween/ghost.mdl");
	PrepareModel("models/props_halloween/halloween_gift.mdl");
	PrepareModel("models/props_halloween/halloween_medkit_large.mdl");
	PrepareModel("models/props_halloween/halloween_medkit_medium.mdl");
	PrepareModel("models/props_halloween/halloween_medkit_small.mdl");
	PrepareModel("models/props_halloween/pumpkin_loot.mdl");
	PrepareModel("models/props_manor/tractor_01.mdl");
	PrepareModel("models/props_manor/baby_grand_01.mdl");
	*/
}

stock PrepareEyebossSounds(bool:reset = false)
{
	static g_bSoundsPrecached = false;
	if (reset) g_bSoundsPrecached = false;
	if (!g_bSoundsPrecached)
	{
		PrepareSound("vo/halloween_eyeball/eyeball_biglaugh01.wav");
		PrepareSound("vo/halloween_eyeball/eyeball_boss_pain01.wav");
		PrepareSound("vo/halloween_eyeball/eyeball_laugh01.wav");
		PrepareSound("vo/halloween_eyeball/eyeball_laugh02.wav");
		PrepareSound("vo/halloween_eyeball/eyeball_laugh03.wav");
		PrepareSound("vo/halloween_eyeball/eyeball_mad01.wav");
		PrepareSound("vo/halloween_eyeball/eyeball_mad02.wav");
		PrepareSound("vo/halloween_eyeball/eyeball_mad03.wav");
		PrepareSound("vo/halloween_eyeball/eyeball_teleport01.wav");
		PrepareSound("vo/halloween_eyeball/eyeball01.wav");
		PrepareSound("vo/halloween_eyeball/eyeball02.wav");
		PrepareSound("vo/halloween_eyeball/eyeball03.wav");
		PrepareSound("vo/halloween_eyeball/eyeball04.wav");
		PrepareSound("vo/halloween_eyeball/eyeball05.wav");
		PrepareSound("vo/halloween_eyeball/eyeball06.wav");
		PrepareSound("vo/halloween_eyeball/eyeball07.wav");
		PrepareSound("vo/halloween_eyeball/eyeball08.wav");
		PrepareSound("vo/halloween_eyeball/eyeball09.wav");
		PrepareSound("vo/halloween_eyeball/eyeball10.wav");
		PrepareSound("vo/halloween_eyeball/eyeball11.wav");
		PrepareSound("ui/halloween_boss_summon_rumble.wav");
		PrepareSound("ui/halloween_boss_chosen_it.wav");
		PrepareSound("ui/halloween_boss_defeated_fx.wav");
		PrepareSound("ui/halloween_boss_defeated.wav");
		PrepareSound("ui/halloween_boss_player_becomes_it.wav");
		PrepareSound("ui/halloween_boss_summoned_fx.wav");
		PrepareSound("ui/halloween_boss_summoned.wav");
		PrepareSound("ui/halloween_boss_tagged_other_it.wav");
		PrepareSound("ui/halloween_boss_escape.wav");
		PrepareSound("ui/halloween_boss_escape_sixty.wav");
		PrepareSound("ui/halloween_boss_escape_ten.wav");
		PrepareSound("ui/halloween_boss_tagged_other_it.wav");
		g_bSoundsPrecached = true;
	}
}

// FUNCTIONS

public Action:Command_VoteSpawnEyeboss(client, args)
{
	if(client < 1 || !IsClientInGame(client))
		return Plugin_Handled;

	if(!g_bIsEnabled)
	{
		PrintToChat(client, "\x01[SM] This vote trigger has been disabled by the server.");
		return Plugin_Handled;
	}

	if(g_voteDelayTime > GetTime())
	{
		new timeleft = g_voteDelayTime - GetTime();

		PrintToChat(client, "\x01[SM] There are %d seconds remaining before another Monoculus vote is allowed.", timeleft);
		return Plugin_Handled;
	}

	if(g_bHasVoted[client])
	{
		PrintToChat(client, "\x01[SM] You have already voted, you FOOL!");
		return Plugin_Handled;
	}

	if(!g_bVotesStarted)
	{
		g_bVotesStarted = true;
		CreateTimer(90.0, Timer_ResetVotes, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	g_iVotes++;
	g_bHasVoted[client] = true;

	if(g_iVotes >= g_VotesNeeded)
	{
		PrintToChatAll("[SM] Vote to spawn Monoculus was successful! [%d/%d]", g_iVotes, g_VotesNeeded);
		SpawnMonoculus(client);
		g_voteDelayTime = GetTime() + GetConVarInt(Cvar_Eyeboss_VoteDelay);
		ResetAllVotes();
	}
	else
	{
		PrintToChatAll("\x01[SM] \x03%N \x01has voted to spawn the MONOCULUS! Type \x04!voteeye \x01/or \x04!voteeyeboss \x01to vote YES. [%d/%d]", client, g_iVotes, g_VotesNeeded);
	}

	return Plugin_Handled;
}
stock IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}
public Action:GreatBallRockets(client, args)
{
	decl String:arg1[32];
	new iLevel = 0;
	if (!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] You must be an in-game admin to use this command!");
		return Plugin_Handled;
	}
	new String:modelname[256] = "";
	if (args > 0)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		iLevel = StringToInt(arg1);
		if (args > 1)
		{
			GetCmdArg(2, modelname, sizeof(modelname));
			if (!FileExists(modelname, true))
			{
				ReplyToCommand(client, "[SM] Model is invalid. sm_eyeboss [level] [modelname].");
				return Plugin_Handled;
			}
		}
	}
/*	else
	{
		GetCmdArgString(modelname, sizeof(modelname));
		stringindex = BreakString(modelname, arg1, sizeof(arg1));
		strcopy(modelname, sizeof(modelname), modelname[stringindex]);
		if (!FileExists(modelname, true))
		{
			ReplyToCommand(client, "[SM] Model is invalid. sm_eyeboss [modelname].");
			return Plugin_Handled;
		}
	}*/
	PrepareEyebossSounds();
	PrepareEyebossModel(modelname);
	if (modelname[0] != '\0' && !IsModelPrecached(modelname))
	{
		ReplyToCommand(client, "[SM] Model is invalid. sm_eyeboss [level] [modelname].");
		return Plugin_Handled;
	}

	SpawnMonoculus(client, iLevel, modelname);
	return Plugin_Handled;
}
stock bool:SpawnMonoculus(client, iLevel=0, String:modelname[]="")
{
	if (!IsValidClient(client)) return false;
	if (!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Spawning Monoculus: Could not find spawn point.");
		return false;
	}
/*	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkin lords. Change maps.");
		return Plugin_Stop;
	}*/

	new entity = CreateEntityByName("eyeball_boss");
	if (entity > 0 && IsValidEntity(entity))
	{
		if (DispatchSpawn(entity))
		{
			if (modelname[0] != '\0')
				SetEntityModel(entity, modelname);
			if (iLevel > 1)
			{
				new iBaseHP = GetConVarInt(v_BaseHP_Level2);		//def 17,000
				new iHPPerLevel = GetConVarInt(v_HP_Per_Level);		//def  3,000
				new iHPPerPlayer = GetConVarInt(v_HP_Per_Player);	//def	400
				new iNumPlayers = GetClientCount(true);

				new iHP = iBaseHP;
				iHP = (iHP + ((iLevel - 2) * iHPPerLevel));
				if (iNumPlayers > 10)
					iHP = (iHP + ((iNumPlayers - 10)*iHPPerPlayer));

				SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHP);
				SetEntProp(entity, Prop_Data, "m_iHealth", iHP);

				g_iLetsChangeThisEvent = iLevel;
			}
			g_pos[2] -= 10.0;
			TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
			return true;
		}
	}
	return false;
}

stock bool:SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}
//Does not work.
/*public Action:SpawnMapMonoculus(client, args)
{
	PrepareEyebossModel("");
	PrepareEyebossSounds();

	new iFlags = GetCommandFlags("tf_halloween_force_boss_spawn");
	SetCommandFlags("tf_halloween_force_boss_spawn", iFlags & ~FCVAR_CHEAT);
	ClientCommand(client, "tf_halloween_force_boss_spawn");
	SetCommandFlags("tf_halloween_force_boss_spawn", iFlags);
	ReplyToCommand(client, "[SM] Spawned Monoculus via 'tf_halloween_force_boss_spawn'.");
	return Plugin_Handled;
}*/
/*public Action:Command_Summon(client, args)
{
	decl String:modelname[256];
	if (args == 0)
		modelname[0] = '\0';
	else
	{
		GetCmdArgString(modelname, sizeof(modelname));
		if (!FileExists(modelname, true))
		{
			ReplyToCommand(client, "[SM] Model is invalid. sm_eyeboss [modelname].");
			return Plugin_Handled;
		}
	}

	PrepareEyebossModel(modelname);
	if (modelname[0] != '\0' && !IsModelPrecached(modelname))
	{
		ReplyToCommand(client, "[SM] Model is invalid. sm_eyeboss [modelname].");
		return Plugin_Handled;
	}

	if (IsPlayerAlive(client) && IsValidEntity(client) && !g_IsHHH[client])
	{
		SetVariantString(modelname[0] ? modelname : EYEBOSS_MODEL);
		AcceptEntityInput(client, "SetCustomModel");
		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");
		Colorize(client, INVIS);

		g_IsHHH[client] = true;
		PrintToChat(client, "\x04[\x03eyeboss\x04]\x01: You are now the eyeboss!");
	}
	else if (IsValidEntity(client) && g_IsHHH[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		Colorize(client, NORMAL);

		g_IsHHH[client] = false;
		PrintToChat(client, "\x04[\x03eyeboss\x04]\x01: You are now back to normal!");
	}

	return Plugin_Handled;
}*/

/*
Credit to pheadxdll for invisibility code.
*/
/*stock Colorize(client, color[4])
{
	//Colorize the weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	new String:classname[256];
	new type;
	new TFClassType:class = TF2_GetPlayerClass(client);

	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);

		if(weapon > -1 )
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if((StrContains(classname, "tf_weapon_", false) >= 0))
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
			}
		}
	}

	//Colorize the wearables, such as hats
	SetWearablesRGBA_Impl( client, "tf_wearable", "CTFWearable",color );
	SetWearablesRGBA_Impl( client, "tf_wearable_demoshield", "CTFWearableDemoShield", color);

	//Colorize the player
	//SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	//SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);

	if(color[3] > 0)
		type = 1;

	InvisibleHideFixes(client, class, type);
}

stock SetWearablesRGBA_Impl( client,  const String:entClass[], const String:serverClass[], color[4])
{
	new ent = -1;
	while( (ent = FindEntityByClassname(ent, entClass)) != -1 )
	{
		if ( IsValidEntity(ent) )
		{
			if (GetEntDataEnt2(ent, FindSendPropOffs(serverClass, "m_hOwnerEntity")) == client)
			{
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				SetEntityRenderColor(ent, color[0], color[1], color[2], color[3]);
			}
		}
	}
}

stock InvisibleHideFixes(client, TFClassType:class, type)
{
	if(class == TFClass_DemoMan)
	{
		new decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
		if(decapitations >= 1)
		{
			if(!type)
			{
				//Removes Glowing Eye
				TF2_RemoveCondition(client, TFCond_DemoBuff);
			}
			else
			{
				//Add Glowing Eye
				TF2_AddCondition(client, TFCond_DemoBuff, 0.0);
			}
		}
	}
	else if(class == TFClass_Spy)
	{
		new disguiseWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if(IsValidEntity(disguiseWeapon))
		{
			if(!type)
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = INVIS;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
			else
			{
				SetEntityRenderMode(disguiseWeapon , RENDER_TRANSCOLOR);
				new color[4] = NORMAL;
				SetEntityRenderColor(disguiseWeapon , color[0], color[1], color[2], color[3]);
			}
		}
	}
}*/

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public Action:Timer_ResetVotes(Handle:timer)
{
	if(g_bVotesStarted)
	{
		PrintToChatAll("[SM] Vote to spawn Monoculus FAILED! [%d/%d]", g_iVotes, g_VotesNeeded);
		g_bVotesStarted = false;
		ResetAllVotes();
	}
}

stock ResetAllVotes()
{
	g_bVotesStarted = false;
	g_iVotes = 0;

	for(new x = 1; x <= MaxClients; x++)
	{
		if(!IsClientInGame(x))
		{
			continue;
		}

		if(g_bHasVoted[x])
		{
			g_bHasVoted[x] = false;
		}
	}
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Eyeboss_AllowPublic)
	{
		g_bIsEnabled = GetConVarBool(convar);
	}
	else if(convar == Cvar_Eyeboss_Votesneeded)
	{
		g_fVotesNeeded = GetConVarFloat(convar);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu != hAdminMenu)
	{
		hAdminMenu = topmenu;

		new TopMenuObject:server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
		if (server_commands != INVALID_TOPMENUOBJECT)
		{
			AddToTopMenu(hAdminMenu,
					"sm_eyeboss",
					TopMenuObject_Item,
					AdminMenu_eyeboss,
					server_commands,
					"sm_eyeboss",
					ADMFLAG_EYEBOSS);
		}
	}
}

public AdminMenu_eyeboss(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Call forth the mighty MONOCULUS!");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		SpawnMonoculus(param);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Register Native
	CreateNative("TF2_SpawnMonoculus",Native_Spawneyeboss);
	RegPluginLibrary("monoculusspawn");
	return APLRes_Success;
}

public Native_Spawneyeboss(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new iLevel = GetNativeCell(2);
	decl String:modelname[PLATFORM_MAX_PATH];
	GetNativeString(3, modelname, sizeof(modelname));
	return SpawnMonoculus(client, iLevel, modelname);
}