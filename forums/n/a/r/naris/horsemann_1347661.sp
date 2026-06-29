/*
* [TF2] Horseless Headless Horsemann
* Author(s): Geit (edited by: retsam, FlaminSarge and Naris)
* File: horsemann.sp
* Description: Allows admins to spawn Horseless Headless Horsemann where youre looking and also allows public voting.
*
* 1.5  - Added sm_makemehhh to turn the client into the hatman!
* 1.4  - Added ability to specify model and precache the models & sounds.
* 1.3  - Added to admin menu
* 1.2r - Changed OnClientPostAdminCheck to OnClientConnected. Possible cause of issues?
* 1.1r - Added public voting and cvars to the plugin. :)
* 1.0  - Initial release. 
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PL_VERSION "1.6"

#define ADMFLAG_HORSEMANN	ADMFLAG_CUSTOM3	

#define INVIS			{255,255,255,0}
#define NORMAL			{255,255,255,255}

#define HATMAN_MODEL		"models/bots/headless_hatman.mdl"

new Handle:Cvar_Horseman_AllowPublic = INVALID_HANDLE;
new Handle:Cvar_Horseman_Votesneeded = INVALID_HANDLE;
new Handle:Cvar_Horseman_VoteDelay = INVALID_HANDLE;

new Handle:hAdminMenu = INVALID_HANDLE;

new Float:g_pos[3];
new Float:g_fVotesNeeded;

new g_iVotes = 0;
new g_Voters = 0;
new g_VotesNeeded = 0;
new g_voteDelayTime;

new bool:g_bIsEnabled = true;
new bool:g_bVotesStarted = false;
new bool:g_bSoundsPrecached = false;
new bool:g_bHasVoted[MAXPLAYERS + 1] = { false, ... };
new bool:g_IsHHH[MAXPLAYERS+1] = { false, ...};

public Plugin:myinfo = 
{
	name = "[TF2] Horseless Headless Horsemann",
	author = "Geit, modified by retsam, FlaminSarge and Naris",
	description = "Spawn Horseless Headless Horsemann where you're looking, can set its model and allows public voting.",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
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
			PrecacheSound(sound,preload);
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
	CreateConVar("sm_horsemann_version", PL_VERSION, "Horsemann Spaner Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Cvar_Horseman_AllowPublic = CreateConVar("sm_horsemann_allowvoting", "0", "Allow public horsemann voting?(1/0 = yes/no)");
	Cvar_Horseman_Votesneeded = CreateConVar("sm_horsemann_votesneeded", "0.50", "Percent of votes required for successful horseman vote. (0.50 = 50%)", _, true, 0.10, true, 1.0);
	Cvar_Horseman_VoteDelay = CreateConVar("sm_horsemann_votedelay", "120.0", "Delay time in seconds between calling votes.");

	RegAdminCmd("sm_makemehhh", Command_Summon, ADMFLAG_CHEATS);
	RegAdminCmd("sm_horsemann", Command_Spawn, ADMFLAG_HORSEMANN);
	RegConsoleCmd("votehorsemann", Command_VoteSpawnHorseman, "Trigger to vote to spawn headless horsemann.");
	RegConsoleCmd("votehhh", Command_VoteSpawnHorseman, "Trigger to vote to spawn headless horsemann.");

	HookConVarChange(Cvar_Horseman_AllowPublic, Cvars_Changed);
	HookConVarChange(Cvar_Horseman_Votesneeded, Cvars_Changed);

	AutoExecConfig(true, "plugin.votehorsemann");

	if (LibraryExists("adminmenu"))
	{
		new Handle:topmenu = GetAdminTopMenu();
		if (topmenu != INVALID_HANDLE)
			OnAdminMenuReady(topmenu);
	}
}

public OnClientConnected(client)
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
	g_bIsEnabled = GetConVarBool(Cvar_Horseman_AllowPublic);
	g_fVotesNeeded = GetConVarFloat(Cvar_Horseman_Votesneeded);
}

public OnMapStart()
{
	g_bSoundsPrecached = false;
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
}

PrepareHatmanModel(const String:model[])
{
	PrepareModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl");
	PrepareModel(HATMAN_MODEL);

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

PrepareHatmanSounds()
{
	g_bSoundsPrecached = true;
	PrepareSound("ui/halloween_boss_summon_rumble.wav");
	PrepareSound("vo/halloween_boss/knight_alert.wav");
	PrepareSound("vo/halloween_boss/knight_alert01.wav");
	PrepareSound("vo/halloween_boss/knight_alert02.wav");
	PrepareSound("vo/halloween_boss/knight_attack01.wav");
	PrepareSound("vo/halloween_boss/knight_attack02.wav");
	PrepareSound("vo/halloween_boss/knight_attack03.wav");
	PrepareSound("vo/halloween_boss/knight_attack04.wav");
	PrepareSound("vo/halloween_boss/knight_death01.wav");
	PrepareSound("vo/halloween_boss/knight_death02.wav");
	PrepareSound("vo/halloween_boss/knight_dying.wav");
	PrepareSound("vo/halloween_boss/knight_laugh01.wav");
	PrepareSound("vo/halloween_boss/knight_laugh02.wav");
	PrepareSound("vo/halloween_boss/knight_laugh03.wav");
	PrepareSound("vo/halloween_boss/knight_laugh04.wav");
	PrepareSound("vo/halloween_boss/knight_pain01.wav");
	PrepareSound("vo/halloween_boss/knight_pain02.wav");
	PrepareSound("vo/halloween_boss/knight_pain03.wav");
	PrepareSound("vo/halloween_boss/knight_spawn.wav");
	PrepareSound("weapons/halloween_boss/knight_axe_hit.wav");
	PrepareSound("weapons/halloween_boss/knight_axe_miss.wav");
	PrepareSound("ui/halloween_boss_chosen_it.wav");
	PrepareSound("ui/halloween_boss_defeated_fx.wav");
	PrepareSound("ui/halloween_boss_player_becomes_it.wav");
	PrepareSound("ui/halloween_boss_summoned_fx.wav");
	PrepareSound("ui/halloween_boss_tagged_other_it.wav");
}

// FUNCTIONS

public Action:Command_VoteSpawnHorseman(client, args)
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
		
		PrintToChat(client, "\x01[SM] There are %d seconds remaining before another horsemann vote is allowed.", timeleft);
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
		PrintToChatAll("[SM] Vote to spawn Horsemann was successful! [%d/%d]", g_iVotes, g_VotesNeeded);
		Command_Spawn(client, 0);
		g_voteDelayTime = GetTime() + GetConVarInt(Cvar_Horseman_VoteDelay);
		ResetAllVotes();
	}
	else
	{
		PrintToChatAll("\x01[SM] \x03%N \x01has voted to spawn Headless Horsemann: Type \x04!votehhh \x01/ \x04!votehorsemann \x01to vote YES. [%d/%d]", client, g_iVotes, g_VotesNeeded);
	}
	
	return Plugin_Handled;
}

public Action:Command_Spawn(client, args)
{
	if(!SetTeleportEndPoint(client))
	{
		PrintToChat(client, "[SM] Could not find spawn point.");
		return Plugin_Stop;
	}
	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkin lords. Change maps.");
		return Plugin_Stop;
	}

	decl String:modelname[256];
	if (args == 0)
		modelname[0] = '\0';
	else
	{
		GetCmdArgString(modelname, sizeof(modelname));
		if (!FileExists(modelname, true))
		{
			ReplyToCommand(client, "[SM] Model is invalid. sm_horsemann [modelname].");
			return Plugin_Handled;
		}
	}
	
	PrepareHatmanModel(modelname);
	if (modelname[0] != '\0' && !IsModelPrecached(modelname))
	{
		ReplyToCommand(client, "[SM] Model is invalid. sm_horsemann [modelname].");
		return Plugin_Handled;
	}

	if (!g_bSoundsPrecached)
		PrepareHatmanSounds();

	new entity = CreateEntityByName("headless_hatman");
	if (entity > 0 && IsValidEntity(entity))
	{
		if (DispatchSpawn(entity))
		{
			if (modelname[0] != '\0')
				SetEntityModel(entity, modelname);

			g_pos[2] -= 10.0;
			TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
			return Plugin_Handled;
		}
	}
	return Plugin_Stop;
}

SetTeleportEndPoint(client)
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

public Action:Command_Summon(client, args)
{
	decl String:modelname[256];
	if (args == 0)
		modelname[0] = '\0';
	else
	{
		GetCmdArgString(modelname, sizeof(modelname));
		if (!FileExists(modelname, true))
		{
			ReplyToCommand(client, "[SM] Model is invalid. sm_horsemann [modelname].");
			return Plugin_Handled;
		}
	}
	
	PrepareHatmanModel(modelname);
	if (modelname[0] != '\0' && !IsModelPrecached(modelname))
	{
		ReplyToCommand(client, "[SM] Model is invalid. sm_horsemann [modelname].");
		return Plugin_Handled;
	}

	if (IsPlayerAlive(client) && IsValidEntity(client) && !g_IsHHH[client])
	{
		SetVariantString(modelname[0] ? modelname : HATMAN_MODEL);
		AcceptEntityInput(client, "SetCustomModel");
		SetVariantInt(1);
		AcceptEntityInput(client, "SetCustomModelRotates");
		Colorize(client, INVIS);
		
		g_IsHHH[client] = true;
		PrintToChat(client, "\x04[\x03Horsemann\x04]\x01: You are now the Horsemann!");
	}
	else if (IsValidEntity(client) && g_IsHHH[client])
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		Colorize(client, NORMAL);

		g_IsHHH[client] = false;
		PrintToChat(client, "\x04[\x03Horsemann\x04]\x01: You are now back to normal!");
	}
	
	return Plugin_Handled;
}

/*
Credit to pheadxdll for invisibility code.
*/
public Colorize(client, color[4])
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
			if((StrContains(classname, "tf_weapon_",false) >= 0))
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	//Colorize the wearables, such as hats
	SetWearablesRGBA_Impl( client, "tf_wearable_item", "CTFWearableItem",color );
	SetWearablesRGBA_Impl( client, "tf_wearable_item_demoshield", "CTFWearableItemDemoShield", color);
	
	//Colorize the player
	//SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	//SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	if(color[3] > 0)
		type = 1;
	
	InvisibleHideFixes(client, class, type);
}

SetWearablesRGBA_Impl( client,  const String:entClass[], const String:serverClass[], color[4])
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

InvisibleHideFixes(client, TFClassType:class, type)
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
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public Action:Timer_ResetVotes(Handle:timer)
{
	if(g_bVotesStarted)
	{
		PrintToChatAll("[SM] Vote to spawn Horsemann FAILED! [%d/%d]", g_iVotes, g_VotesNeeded);
		g_bVotesStarted = false;
		ResetAllVotes();
	}
}

ResetAllVotes()
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
	if(convar == Cvar_Horseman_AllowPublic)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
	else if(convar == Cvar_Horseman_Votesneeded)
	{
		g_fVotesNeeded = StringToFloat(newValue);
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
					"sm_horsemann",
					TopMenuObject_Item,
					AdminMenu_horsemann, 
					server_commands,
					"sm_horsemann",
					ADMFLAG_HORSEMANN);
		}
	}
}

public AdminMenu_horsemann( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Call forth the mighty Horsemann");
	}
	else if( action == TopMenuAction_SelectOption)
	{
		Command_Spawn(param, 0);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	// Register Native
	CreateNative("SpawnHorsemann",Native_SpawnHorseMann);
	RegPluginLibrary("horsemann");
	return APLRes_Success;
}

public Native_SpawnHorseMann(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	return _:Command_Spawn(client, 0);
}

